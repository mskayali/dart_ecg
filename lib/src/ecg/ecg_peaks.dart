/// ECG R-peak detection wrapper.
///
/// Port of neurokit2.ecg_peaks — wraps ecg_findpeaks with optional
/// artifact correction via signal_fixpeaks.
import '../signal/signal_fixpeaks.dart';
import '../signal/signal_formatpeaks.dart';
import 'ecg_findpeaks.dart';

/// Find R-peaks in an ECG signal.
///
/// [ecgCleaned] — cleaned ECG signal (from ecgClean).
/// [samplingRate] — sampling frequency in Hz.
/// [method] — peak detection algorithm.
/// [correctArtifacts] — apply Kubios artifact correction.
///
/// Returns (signals, info):
/// - signals: binary peak marker signal.
/// - info: map with 'ECG_R_Peaks' indices.
({List<double> signals, Map<String, dynamic> info}) ecgPeaks(
  List<double> ecgCleaned, {
  double samplingRate = 1000,
  String method = 'neurokit',
  bool correctArtifacts = false,
}) {
  // Detect R-peaks
  final peakResult = ecgFindpeaks(
    ecgCleaned,
    samplingRate: samplingRate,
    method: method,
  );

  var rpeaks = peakResult['ECG_R_Peaks']!;
  final info = <String, dynamic>{
    'method_peaks': method.toLowerCase(),
    'method_fixpeaks': 'None',
    'sampling_rate': samplingRate,
  };

  // Optional artifact correction
  if (correctArtifacts) {
    info['ECG_R_Peaks_Uncorrected'] = List<int>.from(rpeaks);
    rpeaks = signalFixpeaks(
      rpeaks,
      samplingRate: samplingRate,
      method: 'kubios',
    );
  }

  info['ECG_R_Peaks'] = rpeaks;

  // Format as binary signal
  final signals = signalFormatpeaks(rpeaks, ecgCleaned.length);

  return (signals: signals, info: info);
}
