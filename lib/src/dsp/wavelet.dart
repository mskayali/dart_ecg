/// Discrete Wavelet Transform (DWT) for ECG delineation.
///
/// Implements Daubechies wavelet decomposition used by NeuroKit2's
/// DWT-based ECG delineator and ECG simulator.
import 'dart:math' as math;

import 'array_ops.dart';

/// Daubechies db1 (Haar) decomposition filter coefficients.
const _db1Lo = [0.7071067811865476, 0.7071067811865476];
const _db1Hi = [-0.7071067811865476, 0.7071067811865476];

/// Daubechies db3 filter coefficients.
const _db3Lo = [
  0.03522629188210, 0.08544127388224, -0.13501102001039,
  -0.45987750211933, 0.80689150931334, -0.33267055295096,
];
const _db3Hi = [
  0.33267055295096, 0.80689150931334, 0.45987750211933,
  -0.13501102001039, -0.08544127388224, 0.03522629188210,
];

/// Daubechies db6 filter coefficients (used in DWT delineation).
const _db6RecLo = [
  -0.00107730108499558, 0.00477725751094551, 0.0005538422011614,
  -0.03158203931748602, 0.02752286553030572, 0.09750160558707936,
  -0.12976686756709563, -0.22626469396516913, 0.31525035170919762,
  0.75113390802157753, 0.49462389039838539, 0.11154074335008017,
];
const _db6RecHi = [
  -0.11154074335008017, 0.49462389039838539, -0.75113390802157753,
  0.31525035170919762, 0.22626469396516913, -0.12976686756709563,
  -0.09750160558707936, 0.02752286553030572, 0.03158203931748602,
  0.0005538422011614, -0.00477725751094551, -0.00107730108499558,
];

/// Daubechies db10 reconstruction filter coefficients.
///
/// Used by ecg_simulate Daubechies method for wavelet approximation
/// of ECG waveform. 20 coefficients.
const db10RecLo = [
  -0.00000045385654,  0.00000672066638, -0.00003045886271,
  -0.00001437027600,  0.00027953908028,  0.00009228567806,
  -0.00196900031740,  0.00023969750827,  0.01023956707220,
  -0.00476375699645, -0.03567103093500,  0.02867441891750,
   0.08127811326580, -0.10224999877980, -0.10786790808580,
   0.27027768890900,  0.04434684210860, -0.62717018601720,
  -0.01976798990600,  0.76613854752540,  0.28862963175150,
   0.11408643609760,
];

/// Get wavelet filter coefficients by name.
///
/// Returns (lo_d, hi_d, lo_r, hi_r) — decomposition and reconstruction filters.
({List<double> loD, List<double> hiD, List<double> loR, List<double> hiR})
    getWaveletFilters(String wavelet) {
  switch (wavelet.toLowerCase()) {
    case 'db1':
    case 'haar':
      return (
        loD: List<double>.from(_db1Lo),
        hiD: List<double>.from(_db1Hi),
        loR: List<double>.from(_db1Lo.reversed),
        hiR: List<double>.from(_db1Hi.reversed),
      );
    case 'db3':
      return (
        loD: List<double>.from(_db3Lo),
        hiD: List<double>.from(_db3Hi),
        loR: List<double>.from(_db3Lo.reversed),
        hiR: List<double>.from(_db3Hi.reversed),
      );
    case 'db6':
      return (
        loD: List<double>.from(_db6RecHi.reversed), // dec lo = rev of rec hi
        hiD: List<double>.from(_db6RecLo.reversed), // dec hi = rev of rec lo
        loR: List<double>.from(_db6RecLo),
        hiR: List<double>.from(_db6RecHi),
      );
    default:
      throw ArgumentError('Unsupported wavelet: $wavelet');
  }
}

/// Compute DWT multiscale decomposition.
///
/// Port of NeuroKit2's _dwt_compute_multiscales.
/// Uses zero-phase convolution with the detail filter at multiple scales.
///
/// [signal] — input signal.
/// [maxScale] — number of decomposition scales.
/// [wavelet] — wavelet name (e.g., 'db6').
///
/// Returns a list of detail coefficient arrays (one per scale).
List<List<double>> dwtComputeMultiscales(
  List<double> signal, {
  int maxScale = 9,
  String wavelet = 'db6',
}) {
  final filters = getWaveletFilters(wavelet);
  final scales = <List<double>>[];

  // H filter (lowpass) and G filter (highpass/detail)
  var hFilter = List<double>.from(filters.loD);
  var gFilter = List<double>.from(filters.hiD);

  for (var scale = 0; scale < maxScale; scale++) {
    // Convolve with detail filter (G)
    final detail = _dwtConvolve(signal, gFilter);
    scales.add(detail);

    // Upsample filters (insert zeros between coefficients)
    if (scale < maxScale - 1) {
      hFilter = _upsampleFilter(hFilter);
      gFilter = _upsampleConvolution(filters.hiD, hFilter);
    }
  }

  return scales;
}

/// Single-level DWT decomposition.
///
/// Returns (approximation, detail) coefficient arrays.
({List<double> approx, List<double> detail}) dwtDecompose(
  List<double> signal,
  String wavelet,
) {
  final filters = getWaveletFilters(wavelet);

  // Convolve and downsample by 2
  final approx = _dwtConvolveDown(signal, filters.loD);
  final detail = _dwtConvolveDown(signal, filters.hiD);

  return (approx: approx, detail: detail);
}

/// Multi-level DWT decomposition.
///
/// Returns [level] detail coefficient arrays + 1 final approximation.
/// Result: [cA_n, cD_n, cD_{n-1}, ..., cD_1]
List<List<double>> wavedec(List<double> signal, String wavelet,
    {required int level}) {
  final results = <List<double>>[];
  var current = List<double>.from(signal);

  for (var i = 0; i < level; i++) {
    final result = dwtDecompose(current, wavelet);
    results.insert(0, result.detail);
    current = result.approx;
  }
  results.insert(0, current); // Final approximation

  return results;
}

/// Inverse DWT reconstruction from approximation + detail.
List<double> idwt(
  List<double> approx,
  List<double> detail,
  String wavelet,
) {
  final filters = getWaveletFilters(wavelet);
  final n = math.max(approx.length, detail.length) * 2;

  // Upsample by 2 (insert zeros)
  final upApprox = _upsample2(approx, n);
  final upDetail = _upsample2(detail, n);

  // Convolve with reconstruction filters
  final recApprox = convolve(upApprox, filters.loR, mode: 'same');
  final recDetail = convolve(upDetail, filters.hiR, mode: 'same');

  return List<double>.generate(
    recApprox.length,
    (i) => recApprox[i] + recDetail[i],
  );
}

// --- Private helpers ---

/// Convolve signal with filter (same-length output, centered).
List<double> _dwtConvolve(List<double> signal, List<double> filter) {
  return convolve(signal, filter, mode: 'same');
}

/// Convolve and downsample by 2.
List<double> _dwtConvolveDown(List<double> signal, List<double> filter) {
  final full = convolve(signal, filter, mode: 'full');
  final result = <double>[];
  // Keep even indices, skip initial filter delay
  final offset = (filter.length - 1) ~/ 2;
  for (var i = offset; i < full.length; i += 2) {
    result.add(full[i]);
  }
  return result;
}

/// Upsample by inserting zeros between samples.
List<double> _upsample2(List<double> signal, int targetLen) {
  final result = List<double>.filled(targetLen, 0.0);
  for (var i = 0; i < signal.length && i * 2 < targetLen; i++) {
    result[i * 2] = signal[i];
  }
  return result;
}

/// Upsample filter by inserting zeros.
List<double> _upsampleFilter(List<double> filter) {
  final result = List<double>.filled(filter.length * 2 - 1, 0.0);
  for (var i = 0; i < filter.length; i++) {
    result[i * 2] = filter[i];
  }
  return result;
}

/// Upsample then convolve for multi-scale decomposition.
List<double> _upsampleConvolution(
    List<double> originalFilter, List<double> upsampledH) {
  return convolve(originalFilter, upsampledH, mode: 'full');
}
