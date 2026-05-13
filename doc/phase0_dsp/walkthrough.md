# Phase 0: DSP Altyapısı — Walkthrough

## Yapılan Değişiklikler

### DSP Katmanı (`lib/src/dsp/`)
- **array_ops.dart**: NumPy benzeri array operasyonları (linspace, diff, gradient, cumsum, convolve, tile, zeros, signalSmooth). `List<double>` üzerinde extension methodlar (mean, std, min, max, abs, square, scale).
- **filter.dart**: `iirjdart` wrapper ile zero-phase `filtfilt` filtering. Butterworth LP/HP/BP/BS filtreleri. FIR windowed-sinc bandpass. Hanning window. Powerline notch filter (50/60 Hz + harmonikler).
- **peak_utils.dart**: `scipy.signal.find_peaks` portu (height, distance, prominence). Zero crossing detection. Moving Window Average. Simple threshold peak detect.
- **interpolate.dart**: Linear, nearest, previous, cubic spline interpolation.
- **statistics.dart**: Kurtosis (Pearson), rescale, standardize, correlation, distance, normalPdf.
- **wavelet.dart**: Daubechies wavelet coefficients (db1/db3/db6/db10). DWT decomposition/reconstruction. Multiscale DWT. `wavedec`/`idwt`.
- **psd.dart**: Welch PSD estimation (`fftea` FFT üzerine). Frequency band power computation.
- **resample.dart**: Signal resampling via interpolation.

### Signal Katmanı (`lib/src/signal/`)
- **signal_fillmissing.dart**: NaN interpolation.
- **signal_phase.dart**: Phase completion computation.
- **signal_formatpeaks.dart**: Binary peak marker creation.
- **signal_rate.dart**: Peak indices → BPM rate interpolation.
- **signal_fixpeaks.dart**: Kubios artifact correction (ectopic/missed/extra beats).

### Model Katmanı (`lib/src/models/`)
- **ecg_result.dart**: `EcgProcessResult`, `DelineateResult`, `PeakInfo` data models.

## Doğrulama
- `dart analyze`: 0 error, 0 warning
- `dart pub get`: Tüm bağımlılıklar çözüldü (iirjdart, fftea, collection)

## Tasarım Kararları
1. `filtfilt` zero-phase filtering: forward-backward filtering + reflect padding (scipy davranışı)
2. Hardcoded Daubechies katsayıları: pywt bağımlılığı ortadan kaldırıldı
3. `Float64List` ve `fftea` pure Dart FFT: platform bağımsız
4. Extension methods ile NumPy-like syntax
