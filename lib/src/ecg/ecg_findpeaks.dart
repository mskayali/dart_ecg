/// ECG R-peak detection algorithms.
///
/// Port of neurokit2.ecg_findpeaks — 5 core algorithms:
/// - neurokit (default): gradient-based QRS detection
/// - pantompkins1985: diff → square → MWA → threshold
/// - hamilton2002: abs diff → MA → adaptive threshold
/// - elgendi2010: dual MWA comparison
/// - engzeemod2012: modified Engelse-Zeelenberg
import 'dart:math' as math;

import '../dsp/array_ops.dart';
import '../dsp/filter.dart';
import '../dsp/peak_utils.dart';

/// Find R-peaks in a cleaned ECG signal.
///
/// [ecgCleaned] — cleaned ECG signal (e.g., from ecgClean).
/// [samplingRate] — sampling frequency in Hz.
/// [method] — detection algorithm name.
///
/// Returns map with 'ECG_R_Peaks' key containing peak indices.
Map<String, List<int>> ecgFindpeaks(
  List<double> ecgCleaned, {
  double samplingRate = 1000,
  String method = 'neurokit',
}) {
  final m = method.toLowerCase();
  List<int> rpeaks;

  if (['nk', 'nk2', 'neurokit', 'neurokit2'].contains(m)) {
    rpeaks = _ecgFindpeaksNeurokit(ecgCleaned, samplingRate);
  } else if (['pantompkins', 'pantompkins1985'].contains(m)) {
    rpeaks = _ecgFindpeaksPantompkins(ecgCleaned, samplingRate);
  } else if (['hamilton', 'hamilton2002'].contains(m)) {
    rpeaks = _ecgFindpeaksHamilton(ecgCleaned, samplingRate);
  } else if (['elgendi', 'elgendi2010'].contains(m)) {
    rpeaks = _ecgFindpeaksElgendi(ecgCleaned, samplingRate);
  } else if (['engzee', 'engzee2012', 'engzeemod', 'engzeemod2012']
      .contains(m)) {
    rpeaks = _ecgFindpeaksEngzee(ecgCleaned, samplingRate);
  } else {
    throw ArgumentError(
      "ecgFindpeaks: '$method' not implemented. "
      "Use 'neurokit', 'pantompkins1985', 'hamilton2002', "
      "'elgendi2010', or 'engzeemod2012'.",
    );
  }

  return {'ECG_R_Peaks': rpeaks};
}

/// NeuroKit default algorithm.
///
/// Gradient-based QRS detection with adaptive thresholding.
/// Port of _ecg_findpeaks_neurokit.
List<int> _ecgFindpeaksNeurokit(
  List<double> signal,
  double samplingRate, {
  double smoothwindow = 0.1,
  double avgwindow = 0.75,
  double gradthreshweight = 1.5,
  double minlenweight = 0.4,
  double mindelay = 0.3,
}) {
  // Compute gradient
  final grad = gradient(signal);
  final absgrad = grad.abs;

  // Smooth and average
  final smoothKernel = (smoothwindow * samplingRate).round();
  final avgKernel = (avgwindow * samplingRate).round();
  final smoothgrad = signalSmooth(absgrad, kernelSize: smoothKernel);
  final avggrad = signalSmooth(smoothgrad, kernelSize: avgKernel);

  // Threshold
  final gradthreshold = avggrad.scale(gradthreshweight);
  final minDelay = (samplingRate * mindelay).round();

  // Identify QRS complexes (where smoothgrad > threshold)
  final qrs = List<bool>.generate(
      signal.length, (i) => smoothgrad[i] > gradthreshold[i]);

  // Find QRS boundaries
  final begQrs = <int>[];
  final endQrs = <int>[];
  for (var i = 0; i < signal.length - 1; i++) {
    if (!qrs[i] && qrs[i + 1]) begQrs.add(i + 1);
    if (qrs[i] && !qrs[i + 1]) endQrs.add(i);
  }

  if (begQrs.isEmpty) return [];

  // Remove endQrs before first begQrs
  final filteredEndQrs = endQrs.where((e) => e > begQrs[0]).toList();

  // Find R-peaks within each QRS
  final numQrs = math.min(begQrs.length, filteredEndQrs.length);
  if (numQrs == 0) return [];

  // Minimum QRS length
  var totalLen = 0.0;
  for (var i = 0; i < numQrs; i++) {
    totalLen += filteredEndQrs[i] - begQrs[i];
  }
  final minLen = (totalLen / numQrs) * minlenweight;

  final peaks = <int>[];
  var lastPeak = -minDelay - 1;

  for (var i = 0; i < numQrs; i++) {
    final beg = begQrs[i];
    final end = filteredEndQrs[i];
    final lenQrs = end - beg;

    if (lenQrs < minLen) continue;

    // Find most prominent local maximum within QRS
    final data = signal.sublist(beg, end + 1);
    final localPeaks = findPeaks(data, prominence: 0.0);

    if (localPeaks.peaks.isNotEmpty) {
      // Find the peak with highest prominence
      var bestIdx = 0;
      var bestProm = 0.0;
      if (localPeaks.prominences != null) {
        for (var j = 0; j < localPeaks.prominences!.length; j++) {
          if (localPeaks.prominences![j] > bestProm) {
            bestProm = localPeaks.prominences![j];
            bestIdx = j;
          }
        }
      }
      final peak = beg + localPeaks.peaks[bestIdx];

      // Enforce minimum delay
      if (peak - lastPeak > minDelay) {
        peaks.add(peak);
        lastPeak = peak;
      }
    }
  }

  return peaks;
}

/// Pan-Tompkins (1985) algorithm.
///
/// diff → square → moving window average → adaptive threshold.
/// Adapted from BioSPPy.
List<int> _ecgFindpeaksPantompkins(
  List<double> signal,
  double samplingRate,
) {
  // Differentiate
  final diffSignal = diff(signal);

  // Square
  final squared = diffSignal.square;

  // Moving window integration (150ms window)
  final winSize = (0.15 * samplingRate).round();
  final mwa = movingWindowAverage(squared, winSize);

  // Find peaks in MWA signal
  final mwaPeaks = findPeaks(mwa,
      distance: (0.3 * samplingRate).round());

  // Locate R-peak as max of original signal within QRS region
  final rpeaks = <int>[];
  final searchWindow = (0.15 * samplingRate).round();

  for (final p in mwaPeaks.peaks) {
    final start = math.max(0, p - searchWindow);
    final end = math.min(signal.length, p + searchWindow);
    var maxIdx = start;
    for (var i = start + 1; i < end; i++) {
      if (signal[i] > signal[maxIdx]) maxIdx = i;
    }
    rpeaks.add(maxIdx);
  }

  return rpeaks;
}

/// Hamilton (2002) algorithm.
///
/// abs diff → moving average → adaptive threshold with missed beat detection.
/// Adapted from BioSPPy.
List<int> _ecgFindpeaksHamilton(
  List<double> signal,
  double samplingRate,
) {
  // Absolute difference
  final diffSignal = diff(signal).abs;

  // Moving average (80ms window)
  final windowLen = (0.08 * samplingRate).round();
  final kernel = List<double>.filled(windowLen, 1.0 / windowLen);
  var ma = convolve(diffSignal, kernel, mode: 'same');

  // Zero out filter transient
  for (var i = 0; i < windowLen * 2 && i < ma.length; i++) {
    ma[i] = 0.0;
  }

  // Adaptive thresholding with signal/noise peak tracking
  final nPks = <double>[];
  final sPks = <double>[];
  final qrs = <int>[0];
  final rr = <double>[];
  var th = 0.0;

  for (var i = 1; i < ma.length - 1; i++) {
    // Local maximum detection
    if (ma[i - 1] < ma[i] && ma[i + 1] < ma[i]) {
      if (ma[i] > th &&
          (i - qrs.last) > 0.3 * samplingRate) {
        qrs.add(i);
        sPks.add(ma[i]);
        if (sPks.length > 8) sPks.removeAt(0);

        if (qrs.length > 2) {
          rr.add((qrs.last - qrs[qrs.length - 2]).toDouble());
          if (rr.length > 8) rr.removeAt(0);
        }
      } else {
        nPks.add(ma[i]);
        if (nPks.length > 8) nPks.removeAt(0);
      }

      final nPksAve = nPks.isEmpty ? 0.0 : nPks.mean;
      final sPksAve = sPks.isEmpty ? 0.0 : sPks.mean;
      th = nPksAve + 0.45 * (sPksAve - nPksAve);
    }
  }

  qrs.removeAt(0); // Remove initial dummy
  return qrs;
}

/// Elgendi (2010) algorithm.
///
/// Dual moving window average comparison.
/// Adapted from py-ecg-detectors.
List<int> _ecgFindpeaksElgendi(
  List<double> signal,
  double samplingRate,
) {
  // Square the signal
  final squared = signal.square;

  // QRS window (97ms) and beat window (611ms)
  final qrsWindow = math.max(1, (0.097 * samplingRate).round());
  final beatWindow = math.max(1, (0.611 * samplingRate).round());

  // Moving averages
  final mwaQrs = movingWindowAverage(squared, qrsWindow);
  final mwaBeat = movingWindowAverage(squared, beatWindow);

  // Threshold
  final blocks = List<double>.filled(signal.length, 0.0);
  final beta = 0.02; // Offset for threshold
  for (var i = 0; i < signal.length; i++) {
    if (mwaQrs[i] > mwaBeat[i] + beta) {
      blocks[i] = 1.0;
    }
  }

  // Find block boundaries
  final rpeaks = <int>[];
  var blockStart = -1;

  for (var i = 0; i < signal.length; i++) {
    if (blocks[i] == 1.0 && blockStart < 0) {
      blockStart = i;
    } else if (blocks[i] == 0.0 && blockStart >= 0) {
      // Find max within block
      var maxIdx = blockStart;
      for (var j = blockStart + 1; j < i; j++) {
        if (signal[j] > signal[maxIdx]) maxIdx = j;
      }
      rpeaks.add(maxIdx);
      blockStart = -1;
    }
  }

  // Handle last block
  if (blockStart >= 0) {
    var maxIdx = blockStart;
    for (var j = blockStart + 1; j < signal.length; j++) {
      if (signal[j] > signal[maxIdx]) maxIdx = j;
    }
    rpeaks.add(maxIdx);
  }

  return rpeaks;
}

/// Modified Engelse-Zeelenberg (2012) algorithm.
///
/// Adapted from py-ecg-detectors.
List<int> _ecgFindpeaksEngzee(
  List<double> signal,
  double samplingRate,
) {

  // Differentiate
  final diffSignal = diff(signal);

  // Threshold based on signal characteristics
  final ci = <double>[0.0, 0.0, 0.0, 0.0, 0.0]; // circular index buffer
  final negThreshold = <double>[];
  final posThreshold = <double>[];

  for (var i = 0; i < diffSignal.length; i++) {
    ci[i % 5] = diffSignal[i];
    negThreshold.add(0.01 * ci.reduce(math.min));
    posThreshold.add(0.01 * ci.reduce(math.max));
  }

  // Engzee thresholding
  final mSign = List<int>.filled(diffSignal.length, 0);
  for (var i = 0; i < diffSignal.length; i++) {
    if (diffSignal[i] > posThreshold[i]) {
      mSign[i] = 1;
    } else if (diffSignal[i] < negThreshold[i]) {
      mSign[i] = -1;
    }
  }

  // Find zero crossings in mSign (positive to negative)
  final rpeaks = <int>[];
  final refractoryPeriod = (0.3 * samplingRate).round();

  for (var i = 1; i < mSign.length; i++) {
    if (mSign[i - 1] > 0 && mSign[i] <= 0) {
      // Peak candidate — search backwards for maximum
      final searchStart = math.max(0, i - (0.2 * samplingRate).round());
      var maxIdx = searchStart;
      for (var j = searchStart; j <= i && j < signal.length; j++) {
        if (signal[j] > signal[maxIdx]) maxIdx = j;
      }

      // Enforce refractory period
      if (rpeaks.isEmpty || maxIdx - rpeaks.last > refractoryPeriod) {
        rpeaks.add(maxIdx);
      }
    }
  }

  return rpeaks;
}
