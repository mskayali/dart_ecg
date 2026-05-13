/// ECG processing pipeline.
///
/// Port of neurokit2.ecg_process — orchestrates the full ECG
/// processing pipeline: clean → peaks → rate → quality → delineate → phase.
import '../models/ecg_result.dart';
import '../signal/signal_rate.dart';
import 'ecg_clean.dart';
import 'ecg_delineate.dart';
import 'ecg_peaks.dart';
import 'ecg_phase.dart';
import 'ecg_quality.dart';

/// Process an ECG signal through the full pipeline.
///
/// [ecgSignal] — raw ECG signal.
/// [samplingRate] — sampling frequency in Hz.
/// [method] — cleaning/peak method name.
///
/// Returns [EcgProcessResult] with all computed signals.
EcgProcessResult ecgProcess(
  List<double> ecgSignal, {
  double samplingRate = 1000,
  String method = 'neurokit',
}) {
  // 1. Clean
  final cleaned = ecgClean(ecgSignal,
      samplingRate: samplingRate, method: method);

  // 2. Detect R-peaks
  final peakResult = ecgPeaks(cleaned,
      samplingRate: samplingRate, method: method);
  final rpeaks = peakResult.info['ECG_R_Peaks'] as List<int>;

  // 3. Compute rate
  final rate = signalRate(rpeaks,
      samplingRate: samplingRate,
      desiredLength: ecgSignal.length);

  // 4. Quality assessment
  final quality = ecgQuality(cleaned, rpeaks,
      samplingRate: samplingRate);

  // 5. Delineation
  final delineation = ecgDelineate(cleaned, rpeaks,
      samplingRate: samplingRate);

  // 6. Phase
  final phase = ecgPhase(rpeaks, signalLength: ecgSignal.length);

  return EcgProcessResult(
    ecgCleaned: cleaned,
    ecgRaw: ecgSignal,
    ecgRPeaks: peakResult.signals,
    rpeakIndices: rpeaks,
    ecgRate: rate,
    ecgQuality: quality,
    ecgPPeaks: delineation['ECG_P_Peaks'],
    ecgQPeaks: delineation['ECG_Q_Peaks'],
    ecgSPeaks: delineation['ECG_S_Peaks'],
    ecgTPeaks: delineation['ECG_T_Peaks'],
    ecgPOnsets: delineation['ECG_P_Onsets'],
    ecgPOffsets: delineation['ECG_P_Offsets'],
    ecgTOnsets: delineation['ECG_T_Onsets'],
    ecgTOffsets: delineation['ECG_T_Offsets'],
    ecgROnsets: delineation['ECG_R_Onsets'],
    ecgROffsets: delineation['ECG_R_Offsets'],
    ecgPhaseAtrial: phase.atrial,
    ecgPhaseVentricular: phase.ventricular,
  );
}
