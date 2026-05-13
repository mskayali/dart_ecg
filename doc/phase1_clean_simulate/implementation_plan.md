# Phase 1: ECG Clean + Simulate — Implementation Plan

## Amaç
NeuroKit2'nin `ecg_clean()` ve `ecg_simulate()` fonksiyonlarını Dart'a birebir port etmek.

## ecg_clean.dart

7 temizleme metodu portlandı:

| Metod | Filtre Tipi | Parametreler |
|-------|------------|-------------|
| `neurokit` (default) | Butterworth HP + Powerline | cutoff=0.5Hz, order=5 |
| `biosppy` | FIR bandpass | [0.67, 45] Hz, order=1.5×SR |
| `pantompkins1985` | Butterworth BP | [5, 15] Hz, order=1 |
| `hamilton2002` | Butterworth BP | [8, 16] Hz, order=1 |
| `elgendi2010` | Butterworth BP | [8, 20] Hz, order=2 |
| `engzeemod2012` | Butterworth BS (notch) | 48-52 Hz, order=4 |
| `vg` | Butterworth HP | cutoff=4Hz, order=2 |

### Python→Dart Eşleştirme
- `signal_filter(method="butterworth")` → `butterworthHighpass()` / `butterworthBandpass()`
- `signal_filter(method="butterworth_zi")` → Aynı Butterworth filtre (zi farkı minimal)
- `signal_filter(method="powerline")` → `powerlineFilter()`
- `scipy.signal.firwin` + `filtfilt` → `firFilter()`

## ecg_simulate.dart

2 simülasyon metodu:

| Metod | Açıklama |
|-------|----------|
| `simple` / `daubechies` | db10 wavelet katsayılarını cardiac cycle olarak kullanır, tile + resample |
| `ecgsyn` (default) | McSharry et al. (2003) dinamik model — RK4 ODE solver |

### ECGSYN Bileşenleri
- `_ecgSimulateRrprocess()`: Spektral RR interval üretimi (LF/HF ratio)
- `_ecgsynDerivs()`: 3-değişkenli ODE (x, y, z) — PQRST Gaussian bileşenleri
- `_rk4Step()`: 4th order Runge-Kutta integrator
- `_signalDistort()`: Laplace noise ekleme
