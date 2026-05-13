/// Continuous Wavelet Transform (CWT) based ECG delineation.
///
/// Port of neurokit2.ecg_delineate (method="cwt") — Martinez 2004 algorithm.
import 'dart:math' as math;

import '../dsp/array_ops.dart';
import '../dsp/peak_utils.dart';
import '../dsp/wavelet_gaus1.dart';

/// Delineate ECG waves using CWT.
Map<String, List<double>> delineateCwt(
  List<double> ecg,
  List<int> rpeaks,
  double samplingRate,
  Map<String, List<double>> waves,
) {
  final n = ecg.length;
  if (rpeaks.length < 3) return waves;

  // Compute CWT multiscales (1, 2, 4, 8, 16)
  final cwtmatr = [
    convolve(ecg, gaus1_scale_1.reversed.toList(), mode: 'same'),
    convolve(ecg, gaus1_scale_2.reversed.toList(), mode: 'same'),
    convolve(ecg, gaus1_scale_4.reversed.toList(), mode: 'same'),
    convolve(ecg, gaus1_scale_8.reversed.toList(), mode: 'same'),
    convolve(ecg, gaus1_scale_16.reversed.toList(), mode: 'same'),
  ];

  final tppeaks = _peaksDelineator(ecg, rpeaks, samplingRate, cwtmatr);
  final tpeaks = tppeaks[0];
  final ppeaks = tppeaks[1];

  final qrsOnsetsOffsets = _onsetOffsetDelineator(ecg, rpeaks.map((e) => e.toDouble()).toList(), 'rpeaks', samplingRate, cwtmatr);
  final pOnsetsOffsets = _onsetOffsetDelineator(ecg, ppeaks, 'ppeaks', samplingRate, cwtmatr);
  final tOnsetsOffsets = _onsetOffsetDelineator(ecg, tpeaks, 'tpeaks', samplingRate, cwtmatr);

  // No CWT defined method for Q and S peak, adopting manual method
  for (var i = 0; i < rpeaks.length; i++) {
    final rpeak = rpeaks[i];
    final prevRpeak = i > 0 ? rpeaks[i - 1] : 0;
    final nextRpeak = i < rpeaks.length - 1 ? rpeaks[i + 1] : n;

    // Q-wave
    final qStart = (prevRpeak + rpeak) ~/ 2;
    if (rpeak > qStart) {
      var qIdx = qStart;
      for (var j = qStart; j < rpeak; j++) {
        if (ecg[j] < ecg[qIdx]) qIdx = j;
      }
      waves['ECG_Q_Peaks']![qIdx] = 1.0;
    }

    // S-wave
    final sStart = rpeak + 1;
    final sEnd = math.min((rpeak + nextRpeak) ~/ 2, n);
    if (sEnd > sStart) {
      var sIdx = sStart;
      for (var j = sStart; j < sEnd; j++) {
        if (ecg[j] < ecg[sIdx]) sIdx = j;
      }
      waves['ECG_S_Peaks']![sIdx] = 1.0;
    }
    
    // Assign R peak
    // We don't populate ECG_R_Peaks here, it's done outside usually, but we populate onsets
    if (!qrsOnsetsOffsets[0][i].isNaN) waves['ECG_R_Onsets']![qrsOnsetsOffsets[0][i].toInt()] = 1.0;
    if (!qrsOnsetsOffsets[1][i].isNaN) waves['ECG_R_Offsets']![qrsOnsetsOffsets[1][i].toInt()] = 1.0;

    if (!pOnsetsOffsets[0][i].isNaN) waves['ECG_P_Onsets']![pOnsetsOffsets[0][i].toInt()] = 1.0;
    if (!pOnsetsOffsets[1][i].isNaN) waves['ECG_P_Offsets']![pOnsetsOffsets[1][i].toInt()] = 1.0;

    if (!tOnsetsOffsets[0][i].isNaN) waves['ECG_T_Onsets']![tOnsetsOffsets[0][i].toInt()] = 1.0;
    if (!tOnsetsOffsets[1][i].isNaN) waves['ECG_T_Offsets']![tOnsetsOffsets[1][i].toInt()] = 1.0;

    if (!ppeaks[i].isNaN) waves['ECG_P_Peaks']![ppeaks[i].toInt()] = 1.0;
    if (!tpeaks[i].isNaN) waves['ECG_T_Peaks']![tpeaks[i].toInt()] = 1.0;
  }

  return waves;
}

List<List<double>> _peaksDelineator(
  List<double> ecg,
  List<int> rpeaks,
  double samplingRate,
  List<List<double>> cwtmatr,
) {
  final searchBoundary = (0.9 * 0.1 * samplingRate / 2).toInt();
  final significantPeaksGroups = <List<double>>[];
  
  for (var i = 0; i < rpeaks.length - 1; i++) {
    final start = rpeaks[i] + searchBoundary;
    final end = rpeaks[i + 1] - searchBoundary;
    if (start >= end || end > cwtmatr[4].length) {
      significantPeaksGroups.add([double.nan, double.nan]);
      continue;
    }
    
    final searchWindow = cwtmatr[4].sublist(start, end);
    final rms = math.sqrt(searchWindow.square.mean);
    final height = 0.25 * rms;
    
    final peaksTpResult = findPeaks(searchWindow.abs, height: height);
    final peaksTp = peaksTpResult.peaks.map((p) => p + start).toList();
    final heightsTp = peaksTpResult.heights!;
    
    final threshold = 0.125 * searchWindow.max;
    final significantPeaksTp = <int>[];
    for (var j = 0; j < peaksTp.length; j++) {
      if (heightsTp[j] > threshold) {
        significantPeaksTp.add(peaksTp[j]);
      }
    }
    
    significantPeaksGroups.add(_findTppeaks(ecg, significantPeaksTp, samplingRate, cwtmatr));
  }
  
  // For the last peak, we don't have rpeaks[i+1], append NaN
  significantPeaksGroups.add([double.nan, double.nan]);

  final tpeaks = significantPeaksGroups.map((g) => g.first).toList();
  final ppeaks = significantPeaksGroups.map((g) => g.last).toList();
  
  return [tpeaks, ppeaks];
}

List<double> _findTppeaks(
  List<double> ecg,
  List<int> keepTp,
  double samplingRate,
  List<List<double>> cwtmatr,
) {
  final maxSearchDuration = 0.05;
  final tppeaks = <double>[];
  
  if (keepTp.length < 2) return [double.nan, double.nan];
  
  for (var i = 0; i < keepTp.length - 1; i++) {
    final indexCur = keepTp[i];
    final indexNext = keepTp[i + 1];
    
    final correctSign = cwtmatr[4][indexCur] < 0 && cwtmatr[4][indexNext] > 0;
    if (correctSign) {
      // Find zero crossing
      var indexZeroCr = indexCur;
      for (var j = indexCur; j <= indexNext; j++) {
        if (j + 1 <= indexNext && cwtmatr[4][j] * cwtmatr[4][j + 1] <= 0) {
          indexZeroCr = j;
          break;
        }
      }
      
      final nbIdx = (maxSearchDuration * samplingRate).toInt();
      final searchStart = math.max(0, indexZeroCr - nbIdx);
      final searchEnd = math.min(ecg.length, indexZeroCr + nbIdx);
      
      var maxIdx = searchStart;
      for (var j = searchStart; j < searchEnd; j++) {
        if (ecg[j] > ecg[maxIdx]) maxIdx = j;
      }
      tppeaks.add(maxIdx.toDouble());
    }
  }
  
  if (tppeaks.isEmpty) {
    return [double.nan, double.nan];
  }
  return tppeaks;
}

List<List<double>> _onsetOffsetDelineator(
  List<double> ecg,
  List<double> peaks,
  String peakType,
  double samplingRate,
  List<List<double>> cwtmatr,
) {
  final halfWaveWidth = (0.1 * samplingRate).toInt();
  final onsets = <double>[];
  final offsets = <double>[];
  
  for (final indexPeakDouble in peaks) {
    if (indexPeakDouble.isNaN) {
      onsets.add(double.nan);
      offsets.add(double.nan);
      continue;
    }
    final indexPeak = indexPeakDouble.toInt();
    
    // ----------------- ONSET -----------------
    List<double> searchWindowOnset;
    double prominenceOnset;
    int scaleIdxOnset = peakType == 'rpeaks' ? 2 : 4;
    
    final searchStartOnset = math.max(0, indexPeak - halfWaveWidth);
    if (peakType == 'rpeaks') {
      searchWindowOnset = cwtmatr[scaleIdxOnset].sublist(searchStartOnset, indexPeak);
      prominenceOnset = 0.20 * searchWindowOnset.max;
    } else {
      searchWindowOnset = cwtmatr[scaleIdxOnset].sublist(searchStartOnset, indexPeak).scale(-1);
      prominenceOnset = 0.10 * searchWindowOnset.max;
    }
    
    final wtPeaksResultOnset = findPeaks(searchWindowOnset, height: 0.0, prominence: prominenceOnset);
    final wtPeaksOnset = wtPeaksResultOnset.peaks;
    
    if (wtPeaksOnset.isEmpty) {
      onsets.add(double.nan);
    } else {
      final nfirst = wtPeaksOnset.last + searchStartOnset;
      final wtPeakHeight = wtPeaksResultOnset.heights!.last;
      
      double epsilonOnset;
      if (peakType == 'rpeaks') {
        epsilonOnset = wtPeakHeight > 0 ? 0.05 * wtPeakHeight : 0.07 * wtPeakHeight;
      } else if (peakType == 'ppeaks') {
        epsilonOnset = 0.50 * wtPeakHeight;
      } else {
        epsilonOnset = 0.25 * wtPeakHeight;
      }
      
      final candidateOnsets = <int>[];
      final nfirstStart = math.max(0, nfirst - 100);
      for (var j = nfirstStart; j < nfirst; j++) {
        if (peakType == 'rpeaks') {
          if (cwtmatr[scaleIdxOnset][j] < epsilonOnset) candidateOnsets.add(j);
        } else {
          if (-cwtmatr[scaleIdxOnset][j] < epsilonOnset) candidateOnsets.add(j);
        }
      }
      
      if (candidateOnsets.isEmpty) {
        onsets.add(nfirstStart.toDouble()); // fallback approximation
      } else {
        onsets.add(candidateOnsets.reduce(math.max).toDouble());
      }
    }
    
    // ----------------- OFFSET -----------------
    List<double> searchWindowOffset;
    double prominenceOffset;
    
    final searchEndOffset = math.min(cwtmatr[scaleIdxOnset].length, indexPeak + halfWaveWidth);
    if (peakType == 'rpeaks') {
      searchWindowOffset = cwtmatr[scaleIdxOnset].sublist(indexPeak, searchEndOffset).scale(-1);
      prominenceOffset = 0.50 * searchWindowOffset.max;
    } else {
      searchWindowOffset = cwtmatr[scaleIdxOnset].sublist(indexPeak, searchEndOffset);
      prominenceOffset = 0.10 * searchWindowOffset.max;
    }
    
    final wtPeaksResultOffset = findPeaks(searchWindowOffset, height: 0.0, prominence: prominenceOffset);
    final wtPeaksOffset = wtPeaksResultOffset.peaks;
    
    if (wtPeaksOffset.isEmpty) {
      offsets.add(double.nan);
    } else {
      final nlast = wtPeaksOffset.first + indexPeak;
      final wtPeakHeight = wtPeaksResultOffset.heights!.first;
      
      double epsilonOffset;
      if (peakType == 'rpeaks') {
        final wtNlast = cwtmatr[scaleIdxOnset][nlast];
        epsilonOffset = wtNlast > 0 ? 0.125 * wtNlast : 0.71 * wtNlast;
      } else if (peakType == 'ppeaks') {
        epsilonOffset = 0.9 * wtPeakHeight;
      } else {
        epsilonOffset = 0.4 * wtPeakHeight;
      }
      
      final candidateOffsets = <int>[];
      final nlastEnd = math.min(cwtmatr[scaleIdxOnset].length, nlast + 100);
      for (var j = nlast; j < nlastEnd; j++) {
        if (cwtmatr[scaleIdxOnset][j] < epsilonOffset) candidateOffsets.add(j);
      }
      
      if (candidateOffsets.isEmpty) {
        offsets.add(nlastEnd.toDouble()); // fallback approximation
      } else {
        offsets.add(candidateOffsets.reduce(math.min).toDouble());
      }
    }
  }
  
  return [onsets, offsets];
}
