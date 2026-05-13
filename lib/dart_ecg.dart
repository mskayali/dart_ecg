/// Pure Dart port of NeuroKit2 ECG processing module.
///
/// Provides ECG signal cleaning, R-peak detection, delineation,
/// quality assessment, simulation, and full processing pipeline.
library dart_ecg;

// DSP utilities
export 'src/dsp/array_ops.dart';
export 'src/dsp/filter.dart';
export 'src/dsp/interpolate.dart';
export 'src/dsp/peak_utils.dart';
export 'src/dsp/psd.dart';
export 'src/dsp/resample.dart';
export 'src/dsp/statistics.dart';
export 'src/dsp/wavelet.dart';

// ECG functions
export 'src/ecg/ecg_clean.dart';
export 'src/ecg/ecg_delineate.dart';
export 'src/ecg/ecg_findpeaks.dart';
export 'src/ecg/ecg_invert.dart';
export 'src/ecg/ecg_peaks.dart';
export 'src/ecg/ecg_phase.dart';
export 'src/ecg/ecg_process.dart';
export 'src/ecg/ecg_quality.dart';
export 'src/ecg/ecg_rsp.dart';
export 'src/ecg/ecg_segment.dart';
export 'src/ecg/ecg_simulate.dart';

// Signal utilities
export 'src/signal/signal_fillmissing.dart';
export 'src/signal/signal_fixpeaks.dart';
export 'src/signal/signal_formatpeaks.dart';
export 'src/signal/signal_phase.dart';
export 'src/signal/signal_rate.dart';

// Models
export 'src/models/ecg_result.dart';
