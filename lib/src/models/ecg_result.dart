/// ECG processing result models.
///
/// Data structures replacing pandas DataFrames for ECG pipeline output.

/// Result of ecgProcess().
class EcgProcessResult {
  /// Cleaned ECG signal.
  final List<double> ecgCleaned;

  /// Raw ECG signal.
  final List<double>? ecgRaw;

  /// R-peak binary markers (1 at R-peak, 0 elsewhere).
  final List<double> ecgRPeaks;

  /// R-peak indices.
  final List<int> rpeakIndices;

  /// Instantaneous heart rate in BPM.
  final List<double> ecgRate;

  /// Signal quality index.
  final List<double>? ecgQuality;

  /// P-wave peak indices.
  final List<double>? ecgPPeaks;

  /// Q-wave peak indices.
  final List<double>? ecgQPeaks;

  /// S-wave peak indices.
  final List<double>? ecgSPeaks;

  /// T-wave peak indices.
  final List<double>? ecgTPeaks;

  /// P-wave onset indices.
  final List<double>? ecgPOnsets;

  /// P-wave offset indices.
  final List<double>? ecgPOffsets;

  /// T-wave onset indices.
  final List<double>? ecgTOnsets;

  /// T-wave offset indices.
  final List<double>? ecgTOffsets;

  /// R-wave onset indices (QRS onset).
  final List<double>? ecgROnsets;

  /// R-wave offset indices (QRS offset).
  final List<double>? ecgROffsets;

  /// Atrial phase.
  final List<double>? ecgPhaseAtrial;

  /// Ventricular phase.
  final List<double>? ecgPhaseVentricular;

  const EcgProcessResult({
    required this.ecgCleaned,
    this.ecgRaw,
    required this.ecgRPeaks,
    required this.rpeakIndices,
    required this.ecgRate,
    this.ecgQuality,
    this.ecgPPeaks,
    this.ecgQPeaks,
    this.ecgSPeaks,
    this.ecgTPeaks,
    this.ecgPOnsets,
    this.ecgPOffsets,
    this.ecgTOnsets,
    this.ecgTOffsets,
    this.ecgROnsets,
    this.ecgROffsets,
    this.ecgPhaseAtrial,
    this.ecgPhaseVentricular,
  });

  /// Convert to a map representation (similar to DataFrame columns).
  Map<String, List<double>> toMap() {
    final map = <String, List<double>>{
      'ECG_Clean': ecgCleaned,
      'ECG_R_Peaks': ecgRPeaks,
      'ECG_Rate': ecgRate,
    };

    if (ecgRaw != null) map['ECG_Raw'] = ecgRaw!;
    if (ecgQuality != null) map['ECG_Quality'] = ecgQuality!;
    if (ecgPPeaks != null) map['ECG_P_Peaks'] = ecgPPeaks!;
    if (ecgQPeaks != null) map['ECG_Q_Peaks'] = ecgQPeaks!;
    if (ecgSPeaks != null) map['ECG_S_Peaks'] = ecgSPeaks!;
    if (ecgTPeaks != null) map['ECG_T_Peaks'] = ecgTPeaks!;
    if (ecgPOnsets != null) map['ECG_P_Onsets'] = ecgPOnsets!;
    if (ecgPOffsets != null) map['ECG_P_Offsets'] = ecgPOffsets!;
    if (ecgTOnsets != null) map['ECG_T_Onsets'] = ecgTOnsets!;
    if (ecgTOffsets != null) map['ECG_T_Offsets'] = ecgTOffsets!;
    if (ecgROnsets != null) map['ECG_R_Onsets'] = ecgROnsets!;
    if (ecgROffsets != null) map['ECG_R_Offsets'] = ecgROffsets!;
    if (ecgPhaseAtrial != null) map['ECG_Phase_Atrial'] = ecgPhaseAtrial!;
    if (ecgPhaseVentricular != null) {
      map['ECG_Phase_Ventricular'] = ecgPhaseVentricular!;
    }

    return map;
  }
}

/// Delineation result.
class DelineateResult {
  /// Binary marker signals for each wave component.
  final Map<String, List<double>> signals;

  /// Indices of wave peaks/onsets/offsets.
  final Map<String, List<double>> waves;

  const DelineateResult({required this.signals, required this.waves});
}

/// Peak detection info.
class PeakInfo {
  /// R-peak sample indices.
  final List<int> rpeaks;

  const PeakInfo({required this.rpeaks});

  /// Access as map (compatible with NeuroKit2 dict return).
  Map<String, List<int>> toMap() => {'ECG_R_Peaks': rpeaks};
}
