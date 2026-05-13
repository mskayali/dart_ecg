/// ECG-Derived Respiration (EDR).
///
/// Port of neurokit2.ecg_rsp — Extracts a respiration proxy signal
/// based on heart rate (ECG Rate).
///
/// Supported methods:
/// * `vangent2019` (default): Butterworth bandpass 0.1-0.4 Hz (order 2)
/// * `soni2019`: Butterworth lowpass 0.5 Hz (order 6)
/// * `charlton2016`: Butterworth bandpass 0.066-1 Hz (order 6)
/// * `sarkar2015`: Butterworth bandpass 0.1-0.7 Hz (order 6)

import '../dsp/array_ops.dart';
import '../dsp/filter.dart';

/// Extract ECG-Derived Respiration (EDR) from ECG rate.
///
/// [ecgRate] — the heart rate signal obtained via `signalRate()`.
/// [samplingRate] — sampling frequency in Hz (default: 1000).
/// [method] — extraction method name.
///
/// Returns the ECG-Derived Respiration signal.
List<double> ecgRsp(
  List<double> ecgRate, {
  double samplingRate = 1000,
  String method = 'vangent2019',
}) {
  final m = method.toLowerCase();

  final rateMean = ecgRate.nanmean;
  final rateCentered = ecgRate.map((e) => e - rateMean).toList();

  if (m == 'sarkar2015') {
    return butterworthBandpass(
      signal: rateCentered,
      order: 6,
      samplingRate: samplingRate,
      lowcut: 0.1,
      highcut: 0.7,
    );
  } else if (m == 'charlton2016') {
    return butterworthBandpass(
      signal: rateCentered,
      order: 6,
      samplingRate: samplingRate,
      lowcut: 4 / 60, // ~0.066 Hz
      highcut: 60 / 60, // 1.0 Hz
    );
  } else if (m == 'soni2019') {
    return butterworthLowpass(
      signal: rateCentered,
      order: 6,
      samplingRate: samplingRate,
      cutoff: 0.5,
    );
  } else if (m == 'vangent2019') {
    return butterworthBandpass(
      signal: rateCentered,
      order: 2,
      samplingRate: samplingRate,
      lowcut: 0.1,
      highcut: 0.4,
    );
  } else {
    throw ArgumentError(
      "`method` should be one of 'sarkar2015', 'charlton2016', "
      "'soni2019' or 'vangent2019'.",
    );
  }
}
