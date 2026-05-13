# Phase 0: DSP Altyapısı — Implementation Plan

## Amaç
NeuroKit2 ECG modülünün Dart'a portlanması için temel DSP (Digital Signal Processing) katmanını oluşturmak. Bu katman scipy/numpy fonksiyonlarının Dart karşılıklarını sağlar.

## Bağımlılıklar

| Paket | Versiyon | Kullanım Amacı |
|-------|----------|---------------|
| `iirjdart` | ^0.1.0 | Butterworth IIR filter design (LP/HP/BP/BS) |
| `fftea` | ^1.5.0 | FFT/IFFT, pure Dart |
| `collection` | ^1.18.0 | Dart team collection utilities |

## Oluşturulan Dosyalar

### DSP Katmanı (`lib/src/dsp/`)

| Dosya | Satır | Python Karşılığı | Açıklama |
|-------|-------|------------------|----------|
| `array_ops.dart` | ~260 | `numpy` | linspace, diff, gradient, cumsum, convolve + List<double> extensions |
| `filter.dart` | ~310 | `scipy.signal.filtfilt`, `signal_filter` | filtfilt, FIR, powerline notch, smoothing |
| `peak_utils.dart` | ~220 | `scipy.signal.find_peaks` | findPeaks, zerocrossings, MWA, peakDetect |
| `interpolate.dart` | ~150 | `scipy.interpolate` | Linear, nearest, previous, cubic spline |
| `statistics.dart` | ~120 | `scipy.stats` | kurtosis, rescale, standardize, correlation |
| `wavelet.dart` | ~220 | `pywt` | Daubechies coefficients, DWT decomposition, wavedec/idwt |
| `psd.dart` | ~110 | `scipy.signal.welch` | Welch PSD (fftea üzerine) |
| `resample.dart` | ~40 | `scipy.signal.resample` | Rate conversion via interpolation |

### Signal Katmanı (`lib/src/signal/`)

| Dosya | Satır | Açıklama |
|-------|-------|----------|
| `signal_fillmissing.dart` | ~30 | NaN interpolasyonu |
| `signal_phase.dart` | ~45 | Phase completion |
| `signal_formatpeaks.dart` | ~15 | Binary peak markers |
| `signal_rate.dart` | ~50 | Peak→BPM rate |
| `signal_fixpeaks.dart` | ~100 | Kubios artifact correction |

### Model Katmanı (`lib/src/models/`)

| Dosya | Satır | Açıklama |
|-------|-------|----------|
| `ecg_result.dart` | ~140 | EcgProcessResult, DelineateResult, PeakInfo |

## Temel Tasarım Kararları

1. **`iirjdart` wrapper**: `filtfilt()` zero-phase filtering — sinyal forward filtrele → reverse → tekrar filtrele → reverse. Reflect padding ile edge effect azaltma.
2. **Pure Dart FFT**: `fftea` Float64List API'si ile Welch PSD.
3. **Hardcoded wavelet coefficients**: db1, db3, db6, db10 Daubechies filter bank katsayıları — pywt bağımlılığını ortadan kaldırır.
4. **Extension methods**: `List<double>.mean`, `.std`, `.abs` etc. — NumPy sözdizimini taklit eder.
