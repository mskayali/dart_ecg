/// Digital filter implementations wrapping iirjdart.
///
/// Provides filtfilt (zero-phase filtering), lfilter (causal filtering),
/// and FIR filter design — mirroring scipy.signal behavior.
import 'dart:math' as math;

import 'package:iirjdart/butterworth.dart';

import 'array_ops.dart';

/// Filter type enumeration.
enum FilterType { lowpass, highpass, bandpass, bandstop }

/// Apply a causal IIR/FIR filter using direct form II.
/// Equivalent to scipy.signal.lfilter(b, a, x).
///
/// [b] — numerator coefficients.
/// [a] — denominator coefficients (a[0] is assumed 1.0).
/// [x] — input signal.
List<double> lfilter(List<double> b, List<double> a, List<double> x) {
  final n = x.length;
  final nb = b.length;
  final na = a.length;
  final result = List<double>.filled(n, 0.0);

  // Normalize by a[0]
  final a0 = a[0];
  final bNorm = b.map((v) => v / a0).toList();
  final aNorm = a.map((v) => v / a0).toList();

  // State arrays
  final order = math.max(nb, na);
  final z = List<double>.filled(order, 0.0);

  for (var i = 0; i < n; i++) {
    result[i] = bNorm[0] * x[i] + z[0];
    for (var j = 1; j < order - 1; j++) {
      z[j - 1] = (j < nb ? bNorm[j] : 0.0) * x[i] -
          (j < na ? aNorm[j] : 0.0) * result[i] +
          z[j];
    }
    if (order > 1) {
      z[order - 2] = (order - 1 < nb ? bNorm[order - 1] : 0.0) * x[i] -
          (order - 1 < na ? aNorm[order - 1] : 0.0) * result[i];
    }
  }
  return result;
}

/// Apply zero-phase forward-backward filtering using iirjdart Butterworth.
///
/// This mimics scipy.signal.filtfilt behavior:
/// 1. Pad the signal to reduce edge effects
/// 2. Filter forward
/// 3. Reverse
/// 4. Filter again
/// 5. Reverse and trim
///
/// [order] — filter order.
/// [samplingRate] — sampling frequency in Hz.
/// [cutoff] — cutoff frequency (single for LP/HP, center for BP/BS).
/// [filterType] — type of filter.
/// [width] — bandwidth for bandpass/bandstop.
List<double> filtfilt({
  required int order,
  required double samplingRate,
  required List<double> signal,
  required FilterType filterType,
  required double cutoff,
  double? width,
}) {
  // Pad length: Without lfilter_zi initialization, we need a much longer padding
  // to let the filter transient decay. A 0.5 Hz highpass takes ~2 seconds to settle.
  // We use signal.length - 1 or at least 3*order.
  final padLen = math.min((samplingRate * 3.0).toInt(), signal.length - 1);

  // Edge padding (reflect)
  final padded = _reflectPad(signal, padLen);

  // Forward pass
  final forward = _applyButterworth(
    padded,
    order: order,
    samplingRate: samplingRate,
    cutoff: cutoff,
    filterType: filterType,
    width: width,
  );

  // Reverse
  final reversed = List<double>.from(forward.reversed);

  // Backward pass
  final backward = _applyButterworth(
    reversed,
    order: order,
    samplingRate: samplingRate,
    cutoff: cutoff,
    filterType: filterType,
    width: width,
  );

  // Reverse again and trim padding
  final result = List<double>.from(backward.reversed);
  return result.sublist(padLen, padLen + signal.length);
}

/// Convenience: Butterworth bandpass filtfilt.
List<double> butterworthBandpass({
  required List<double> signal,
  required int order,
  required double samplingRate,
  required double lowcut,
  required double highcut,
}) {
  final center = (lowcut + highcut) / 2.0;
  final width = highcut - lowcut;
  return filtfilt(
    order: order,
    samplingRate: samplingRate,
    signal: signal,
    filterType: FilterType.bandpass,
    cutoff: center,
    width: width,
  );
}

/// Convenience: Butterworth highpass filtfilt.
List<double> butterworthHighpass({
  required List<double> signal,
  required int order,
  required double samplingRate,
  required double cutoff,
}) {
  return filtfilt(
    order: order,
    samplingRate: samplingRate,
    signal: signal,
    filterType: FilterType.highpass,
    cutoff: cutoff,
  );
}

/// Convenience: Butterworth lowpass filtfilt.
List<double> butterworthLowpass({
  required List<double> signal,
  required int order,
  required double samplingRate,
  required double cutoff,
}) {
  return filtfilt(
    order: order,
    samplingRate: samplingRate,
    signal: signal,
    filterType: FilterType.lowpass,
    cutoff: cutoff,
  );
}

/// Convenience: Butterworth bandstop (notch) filtfilt.
List<double> butterworthBandstop({
  required List<double> signal,
  required int order,
  required double samplingRate,
  required double centerFreq,
  required double width,
}) {
  return filtfilt(
    order: order,
    samplingRate: samplingRate,
    signal: signal,
    filterType: FilterType.bandstop,
    cutoff: centerFreq,
    width: width,
  );
}

/// Powerline noise removal using notch filter at [freq] Hz and harmonics.
/// Equivalent to NeuroKit2's powerline parameter in signal_filter.
List<double> powerlineFilter({
  required List<double> signal,
  required double samplingRate,
  double powerline = 50.0,
}) {
  var result = List<double>.from(signal);
  final nyquist = samplingRate / 2.0;

  // Apply notch at powerline frequency and harmonics
  var freq = powerline;
  while (freq < nyquist) {
    result = butterworthBandstop(
      signal: result,
      order: 4,
      samplingRate: samplingRate,
      centerFreq: freq,
      width: 2.0, // 2 Hz notch width
    );
    freq += powerline;
  }
  return result;
}

/// Apply FIR filter using windowed-sinc method.
///
/// [numtaps] — number of filter coefficients (odd for type I).
/// [cutoff] — cutoff frequency or [lowcut, highcut] for bandpass.
/// [samplingRate] — sampling frequency.
/// [filterType] — lowpass, highpass, or bandpass.
List<double> firFilter({
  required List<double> signal,
  required int numtaps,
  required double samplingRate,
  required FilterType filterType,
  double? cutoff,
  double? lowcut,
  double? highcut,
}) {
  final coeffs = firwin(
    numtaps: numtaps,
    samplingRate: samplingRate,
    filterType: filterType,
    cutoff: cutoff,
    lowcut: lowcut,
    highcut: highcut,
  );

  // Apply as zero-phase filter (convolve forward + backward)
  return _firFiltfilt(signal, coeffs);
}

/// Design FIR filter coefficients using windowed-sinc method.
/// Simplified equivalent of scipy.signal.firwin.
List<double> firwin({
  required int numtaps,
  required double samplingRate,
  required FilterType filterType,
  double? cutoff,
  double? lowcut,
  double? highcut,
}) {
  final nyquist = samplingRate / 2.0;

  switch (filterType) {
    case FilterType.lowpass:
      return _firwinLowpass(numtaps, cutoff! / nyquist);
    case FilterType.highpass:
      return _firwinHighpass(numtaps, cutoff! / nyquist);
    case FilterType.bandpass:
      return _firwinBandpass(numtaps, lowcut! / nyquist, highcut! / nyquist);
    case FilterType.bandstop:
      return _firwinBandstop(numtaps, lowcut! / nyquist, highcut! / nyquist);
  }
}

// --- Private helpers ---

/// Apply iirjdart Butterworth filter sample-by-sample (single pass, causal).
List<double> _applyButterworth(
  List<double> signal, {
  required int order,
  required double samplingRate,
  required double cutoff,
  required FilterType filterType,
  double? width,
}) {
  final bw = Butterworth();

  switch (filterType) {
    case FilterType.lowpass:
      bw.lowPass(order, samplingRate, cutoff);
      break;
    case FilterType.highpass:
      bw.highPass(order, samplingRate, cutoff);
      break;
    case FilterType.bandpass:
      bw.bandPass(order, samplingRate, cutoff, width!);
      break;
    case FilterType.bandstop:
      bw.bandStop(order, samplingRate, cutoff, width!);
      break;
  }

  final result = List<double>.filled(signal.length, 0.0);
  for (var i = 0; i < signal.length; i++) {
    result[i] = bw.filter(signal[i]);
  }
  return result;
}

/// Reflect-pad signal at both ends to reduce edge effects.
/// Equivalent to scipy's pad mode in filtfilt.
List<double> _reflectPad(List<double> signal, int padLen) {
  final n = signal.length;
  if (padLen <= 0) return List<double>.from(signal);

  final padded = List<double>.filled(n + 2 * padLen, 0.0);

  // Reflect at start: 2*signal[0] - signal[padLen..1]
  for (var i = 0; i < padLen; i++) {
    padded[i] = 2.0 * signal[0] - signal[padLen - i];
  }

  // Copy original signal
  for (var i = 0; i < n; i++) {
    padded[padLen + i] = signal[i];
  }

  // Reflect at end: 2*signal[n-1] - signal[n-2..n-1-padLen]
  for (var i = 0; i < padLen; i++) {
    padded[padLen + n + i] = 2.0 * signal[n - 1] - signal[n - 2 - i];
  }

  return padded;
}

/// Zero-phase FIR filtering via convolve.
List<double> _firFiltfilt(List<double> signal, List<double> coeffs) {
  final padLen = math.min(3 * coeffs.length, signal.length - 1);
  final padded = _reflectPad(signal, padLen);

  // Forward convolution
  final forward = convolve(padded, coeffs, mode: 'same');

  // Backward convolution
  final reversed = List<double>.from(forward.reversed);
  final backward = convolve(reversed, coeffs, mode: 'same');

  // Reverse and trim
  final result = List<double>.from(backward.reversed);
  return result.sublist(padLen, padLen + signal.length);
}

// --- FIR coefficient design (windowed sinc) ---

/// Lowpass FIR via windowed sinc.
List<double> _firwinLowpass(int numtaps, double normalizedCutoff) {
  final coeffs = _sincKernel(numtaps, normalizedCutoff);
  final window = _hammingWindow(numtaps);
  for (var i = 0; i < numtaps; i++) {
    coeffs[i] *= window[i];
  }
  // Normalize
  final sum = coeffs.fold<double>(0.0, (s, v) => s + v);
  for (var i = 0; i < numtaps; i++) {
    coeffs[i] /= sum;
  }
  return coeffs;
}

/// Highpass FIR via spectral inversion of lowpass.
List<double> _firwinHighpass(int numtaps, double normalizedCutoff) {
  final lp = _firwinLowpass(numtaps, normalizedCutoff);
  final hp = List<double>.generate(numtaps, (i) => -lp[i]);
  hp[numtaps ~/ 2] += 1.0;
  return hp;
}

/// Bandpass FIR = lowpass(high) - lowpass(low).
List<double> _firwinBandpass(
    int numtaps, double normalizedLow, double normalizedHigh) {
  final lp1 = _firwinLowpass(numtaps, normalizedHigh);
  final lp2 = _firwinLowpass(numtaps, normalizedLow);
  return List<double>.generate(numtaps, (i) => lp1[i] - lp2[i]);
}

/// Bandstop FIR = 1 - bandpass.
List<double> _firwinBandstop(
    int numtaps, double normalizedLow, double normalizedHigh) {
  final bp = _firwinBandpass(numtaps, normalizedLow, normalizedHigh);
  final bs = List<double>.generate(numtaps, (i) => -bp[i]);
  bs[numtaps ~/ 2] += 1.0;
  return bs;
}

/// Generate sinc kernel.
List<double> _sincKernel(int numtaps, double normalizedCutoff) {
  final mid = numtaps ~/ 2;
  return List<double>.generate(numtaps, (i) {
    final x = i - mid;
    if (x == 0) return normalizedCutoff;
    final px = math.pi * x * normalizedCutoff;
    return math.sin(px) / (math.pi * x);
  });
}

/// Hamming window.
List<double> _hammingWindow(int n) {
  return List<double>.generate(
      n, (i) => 0.54 - 0.46 * math.cos(2.0 * math.pi * i / (n - 1)));
}

/// Hanning window.
List<double> hanningWindow(int n) {
  return List<double>.generate(
      n, (i) => 0.5 * (1.0 - math.cos(2.0 * math.pi * i / (n - 1))));
}

/// Boxcar (rectangular) window.
List<double> boxcarWindow(int n) {
  return List<double>.filled(n, 1.0 / n);
}

/// Signal smoothing via kernel convolution.
/// Equivalent to neurokit2's signal_smooth.
List<double> signalSmooth(List<double> signal,
    {int kernelSize = 5, String method = 'boxcar'}) {
  List<double> kernel;
  switch (method) {
    case 'boxcar':
      kernel = boxcarWindow(kernelSize);
      break;
    case 'hanning':
    case 'hann':
      kernel = hanningWindow(kernelSize);
      final kSum = kernel.fold<double>(0.0, (s, v) => s + v);
      kernel = kernel.map((v) => v / kSum).toList();
      break;
    default:
      kernel = boxcarWindow(kernelSize);
  }
  return convolve(signal, kernel, mode: 'same');
}
