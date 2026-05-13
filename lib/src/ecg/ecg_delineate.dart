/// ECG wave delineation (DWT-based).
///
/// Port of neurokit2.ecg_delineate — identifies P, Q, S, T waves.
import 'dart:math' as math;

import '../dsp/wavelet.dart';
import 'ecg_delineate_cwt.dart';

/// Delineate ECG waves.
///
/// Returns map of wave component indices (NaN = not detected).
Map<String, List<double>> ecgDelineate(
  List<double> ecgCleaned,
  List<int> rpeaks, {
  double samplingRate = 1000,
  String method = 'dwt',
}) {
  final n = ecgCleaned.length;

  // Initialize output with NaN
  final waves = <String, List<double>>{
    'ECG_P_Peaks': List.filled(n, double.nan),
    'ECG_Q_Peaks': List.filled(n, double.nan),
    'ECG_S_Peaks': List.filled(n, double.nan),
    'ECG_T_Peaks': List.filled(n, double.nan),
    'ECG_P_Onsets': List.filled(n, double.nan),
    'ECG_P_Offsets': List.filled(n, double.nan),
    'ECG_R_Onsets': List.filled(n, double.nan),
    'ECG_R_Offsets': List.filled(n, double.nan),
    'ECG_T_Onsets': List.filled(n, double.nan),
    'ECG_T_Offsets': List.filled(n, double.nan),
  };

  if (rpeaks.length < 3) return waves;

  if (method.toLowerCase() == 'peak') {
    return _delineatePeak(ecgCleaned, rpeaks, samplingRate, waves);
  } else if (method.toLowerCase() == 'cwt') {
    return delineateCwt(ecgCleaned, rpeaks, samplingRate, waves);
  }

  return _delineateDwt(ecgCleaned, rpeaks, samplingRate, waves);
}

/// Simple peak-based delineation.
Map<String, List<double>> _delineatePeak(
  List<double> signal,
  List<int> rpeaks,
  double samplingRate,
  Map<String, List<double>> waves,
) {
  final n = signal.length;

  for (var i = 0; i < rpeaks.length; i++) {
    final rpeak = rpeaks[i];
    final prevRpeak = i > 0 ? rpeaks[i - 1] : 0;
    final nextRpeak = i < rpeaks.length - 1 ? rpeaks[i + 1] : n;

    // Q-wave: minimum between previous R-peak midpoint and current R-peak
    final qStart = (prevRpeak + rpeak) ~/ 2;
    final qEnd = rpeak;
    if (qEnd > qStart) {
      var qIdx = qStart;
      for (var j = qStart; j < qEnd; j++) {
        if (signal[j] < signal[qIdx]) qIdx = j;
      }
      waves['ECG_Q_Peaks']![qIdx] = 1.0;
      waves['ECG_R_Onsets']![qIdx] = 1.0;
    }

    // S-wave: minimum between R-peak and next R-peak midpoint
    final sStart = rpeak + 1;
    final sEnd = math.min((rpeak + nextRpeak) ~/ 2, n);
    if (sEnd > sStart) {
      var sIdx = sStart;
      for (var j = sStart; j < sEnd; j++) {
        if (signal[j] < signal[sIdx]) sIdx = j;
      }
      waves['ECG_S_Peaks']![sIdx] = 1.0;
      waves['ECG_R_Offsets']![sIdx] = 1.0;
    }

    // T-wave: maximum between S-wave region and next R-peak
    final tStart = sEnd;
    final tEnd = math.min(
        rpeak + (0.7 * (nextRpeak - rpeak)).round(), n);
    if (tEnd > tStart) {
      var tIdx = tStart;
      for (var j = tStart; j < tEnd; j++) {
        if (signal[j] > signal[tIdx]) tIdx = j;
      }
      waves['ECG_T_Peaks']![tIdx] = 1.0;
    }

    // P-wave: maximum in region before Q-wave
    final pEnd = qStart;
    final pStart = math.max(
        rpeak - (0.7 * (rpeak - prevRpeak)).round(), 0);
    if (pEnd > pStart) {
      var pIdx = pStart;
      for (var j = pStart; j < pEnd; j++) {
        if (signal[j] > signal[pIdx]) pIdx = j;
      }
      waves['ECG_P_Peaks']![pIdx] = 1.0;
    }
  }

  return waves;
}

/// DWT-based delineation.
Map<String, List<double>> _delineateDwt(
  List<double> signal,
  List<int> rpeaks,
  double samplingRate,
  Map<String, List<double>> waves,
) {
  // Compute DWT multiscales
  final maxScale = math.min(9, (math.log(signal.length) / math.log(2)).floor());
  final scales = dwtComputeMultiscales(signal,
      maxScale: maxScale, wavelet: 'db6');

  if (scales.length < 5) {
    return _delineatePeak(signal, rpeaks, samplingRate, waves);
  }

  final n = signal.length;

  for (var i = 0; i < rpeaks.length; i++) {
    final rpeak = rpeaks[i];
    final prevRpeak = i > 0 ? rpeaks[i - 1] : 0;
    final nextRpeak = i < rpeaks.length - 1 ? rpeaks[i + 1] : n;

    // Use scale 2 (index 1) for QRS, scale 4 (index 3) for P/T
    final qrsScale = scales[math.min(1, scales.length - 1)];
    final ptScale = scales[math.min(3, scales.length - 1)];

    // Q-wave: zero crossing in DWT before R-peak
    final qRegionStart = math.max(0, rpeak - (0.1 * samplingRate).round());
    for (var j = rpeak - 1; j >= qRegionStart; j--) {
      if (j < qrsScale.length - 1 && qrsScale[j] * qrsScale[j + 1] < 0) {
        waves['ECG_Q_Peaks']![j] = 1.0;
        waves['ECG_R_Onsets']![j] = 1.0;
        break;
      }
    }

    // S-wave: zero crossing in DWT after R-peak
    final sRegionEnd = math.min(n, rpeak + (0.1 * samplingRate).round());
    for (var j = rpeak + 1; j < sRegionEnd; j++) {
      if (j < qrsScale.length - 1 && qrsScale[j] * qrsScale[j + 1] < 0) {
        waves['ECG_S_Peaks']![j] = 1.0;
        waves['ECG_R_Offsets']![j] = 1.0;
        break;
      }
    }

    // T-wave: max in PT scale after QRS
    final tStart = math.min(rpeak + (0.15 * samplingRate).round(), n);
    final tEnd = math.min(
        rpeak + (0.6 * (nextRpeak - rpeak)).round(), n);
    if (tEnd > tStart && tStart < ptScale.length) {
      var maxIdx = tStart;
      var maxVal = ptScale[tStart].abs();
      for (var j = tStart; j < tEnd && j < ptScale.length; j++) {
        if (ptScale[j].abs() > maxVal) {
          maxVal = ptScale[j].abs();
          maxIdx = j;
        }
      }
      waves['ECG_T_Peaks']![maxIdx] = 1.0;
    }

    // P-wave: max in PT scale before QRS
    final pEnd = math.max(0, rpeak - (0.15 * samplingRate).round());
    final pStart = math.max(
        rpeak - (0.6 * (rpeak - prevRpeak)).round(), 0);
    if (pEnd > pStart && pStart < ptScale.length) {
      var maxIdx = pStart;
      var maxVal = ptScale[pStart].abs();
      for (var j = pStart; j < pEnd && j < ptScale.length; j++) {
        if (ptScale[j].abs() > maxVal) {
          maxVal = ptScale[j].abs();
          maxIdx = j;
        }
      }
      waves['ECG_P_Peaks']![maxIdx] = 1.0;
    }
  }

  return waves;
}
