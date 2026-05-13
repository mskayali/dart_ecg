# Phase 0: DSP Altyapısı — Tasks

## Durum: ✅ Tamamlandı

- [x] Dart paketi oluştur (`pubspec.yaml`, barrel export)
- [x] `lib/src/dsp/array_ops.dart` — NumPy array operations (linspace, diff, gradient, cumsum, convolve, extensions)
- [x] `lib/src/dsp/filter.dart` — filtfilt/lfilter wrapper (iirjdart üzerine zero-phase filtering)
- [x] `lib/src/dsp/peak_utils.dart` — find_peaks (scipy port), zero crossings, MWA
- [x] `lib/src/dsp/interpolate.dart` — Linear, nearest, previous, cubic spline interpolation
- [x] `lib/src/dsp/resample.dart` — Signal resampling via interpolation
- [x] `lib/src/dsp/statistics.dart` — kurtosis, rescale, standardize, correlation, distance
- [x] `lib/src/dsp/wavelet.dart` — DWT (Daubechies db1/db3/db6/db10), wavedec, idwt
- [x] `lib/src/dsp/psd.dart` — Welch PSD (fftea üzerine)
- [x] `lib/src/signal/signal_fillmissing.dart`
- [x] `lib/src/signal/signal_phase.dart`
- [x] `lib/src/signal/signal_formatpeaks.dart`
- [x] `lib/src/signal/signal_rate.dart`
- [x] `lib/src/signal/signal_fixpeaks.dart`
- [x] `lib/src/models/ecg_result.dart`
- [x] Static analysis: 0 error, 0 warning
