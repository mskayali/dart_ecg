/// Power Spectral Density estimation using Welch's method.
///
/// Uses fftea for FFT computation.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fftea/fftea.dart' as fftea;

import 'filter.dart' show hanningWindow;

/// Welch PSD result.
class PsdResult {
  /// Frequency bins.
  final List<double> frequencies;

  /// Power spectral density values.
  final List<double> power;

  const PsdResult({required this.frequencies, required this.power});
}

/// Compute Power Spectral Density using Welch's method.
///
/// [signal] — input signal.
/// [samplingRate] — sampling frequency in Hz.
/// [windowSize] — segment size (default: 1024).
/// [overlap] — fraction of overlap between segments (default: 0.5).
///
/// Returns PSD in power/Hz.
PsdResult welchPsd(
  List<double> signal, {
  required double samplingRate,
  int? windowSize,
  double overlap = 0.5,
}) {
  final n = signal.length;
  final nperseg = windowSize ?? math.min(256, n);
  final noverlap = (nperseg * overlap).round();
  final step = nperseg - noverlap;

  // Number of segments
  final nSegments = math.max(1, (n - noverlap) ~/ step);

  // Window
  final window = hanningWindow(nperseg);
  final windowPower =
      window.fold<double>(0.0, (s, v) => s + v * v) / nperseg;

  // FFT size
  final nfft = nperseg;
  final freqBins = nfft ~/ 2 + 1;

  // Accumulate periodograms
  final psd = List<double>.filled(freqBins, 0.0);

  for (var seg = 0; seg < nSegments; seg++) {
    final start = seg * step;
    final end = math.min(start + nperseg, n);
    final segLen = end - start;

    // Extract segment and apply window
    final segment = List<double>.filled(nfft, 0.0);
    for (var i = 0; i < segLen; i++) {
      segment[i] = signal[start + i] * window[math.min(i, nperseg - 1)];
    }

    // FFT using fftea
    final fft = fftea.FFT(nfft);
    final input = Float64List.fromList(segment);
    final freq = fft.realFft(input);

    // Accumulate power
    for (var i = 0; i < freqBins && i < freq.length; i++) {
      final re = freq[i].x;
      final im = freq[i].y;
      psd[i] += (re * re + im * im);
    }
  }

  // Average and normalize
  final scale = 1.0 / (samplingRate * windowPower * nSegments);
  for (var i = 0; i < freqBins; i++) {
    psd[i] *= scale;
    // Double non-DC, non-Nyquist bins for one-sided spectrum
    if (i > 0 && i < freqBins - 1) {
      psd[i] *= 2.0;
    }
  }

  // Frequency axis
  final frequencies = List<double>.generate(
    freqBins,
    (i) => i * samplingRate / nfft,
  );

  return PsdResult(frequencies: frequencies, power: psd);
}

/// Compute signal power in specific frequency bands.
///
/// [signal] — input signal.
/// [samplingRate] — sampling frequency.
/// [frequencyBands] — list of [low, high] frequency pairs.
///
/// Returns power for each band.
List<double> signalPower(
  List<double> signal, {
  required double samplingRate,
  required List<List<double>> frequencyBands,
  int? windowSize,
}) {
  final psd = welchPsd(signal,
      samplingRate: samplingRate, windowSize: windowSize);

  return frequencyBands.map((band) {
    final low = band[0];
    final high = band[1];
    var power = 0.0;
    for (var i = 0; i < psd.frequencies.length; i++) {
      if (psd.frequencies[i] >= low && psd.frequencies[i] <= high) {
        power += psd.power[i];
      }
    }
    // Multiply by frequency resolution for integration
    final df =
        psd.frequencies.length > 1 ? psd.frequencies[1] - psd.frequencies[0] : 1.0;
    return power * df;
  }).toList();
}
