# Phase 1: ECG Clean + Simulate — Walkthrough

## Yapılan Değişiklikler

### ecg_clean.dart (~170 satır)
- `ecgClean()`: Ana giriş noktası — NaN handling + method dispatch
- 7 private temizleme fonksiyonu:
  - `_ecgCleanNk()`: HP 0.5Hz (order 5) + powerline
  - `_ecgCleanBiosppy()`: FIR [0.67, 45] Hz + DC offset kaldırma
  - `_ecgCleanPantompkins()`: BP [5, 15] Hz
  - `_ecgCleanHamilton()`: BP [8, 16] Hz
  - `_ecgCleanElgendi()`: BP [8, 20] Hz
  - `_ecgCleanEngzee()`: BS 48-52 Hz (bandstop notch)
  - `_ecgCleanVgraph()`: HP 4 Hz
- Christov/SSF/Kalidas gibi metotlar sinyal temizlemez — doğrudan döner

### ecg_simulate.dart (~300 satır)
- `ecgSimulate()`: Ana fonksiyon — method dispatch, noise ekleme
- `_ecgSimulateDaubechies()`: Basit wavelet model
  - db10 reconstruction filter = cardiac cycle approximation
  - `tile()` + `signalResample()` ile istenen uzunluğa
- `_ecgSimulateEcgsyn()`: Tam ECGSYN portu
  - RR interval üretimi (`_ecgSimulateRrprocess()`) — FFT-based spectral method
  - RK4 ODE solver (`_rk4Step()`) — 4th order Runge-Kutta
  - ECGSYN derivatives (`_ecgsynDerivs()`) — 5 Gaussian PQRST bileşeni
  - Scaling: [-0.4, 1.2] mV aralığına normalize
- `_signalDistort()`: Laplace noise (rng-based)

## Doğrulama
- `dart analyze`: 0 error, 0 warning
