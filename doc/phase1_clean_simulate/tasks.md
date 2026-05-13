# Phase 1: ECG Clean + Simulate — Tasks

## Durum: ✅ Tamamlandı

- [x] `lib/src/ecg/ecg_clean.dart` — 7 cleaning method (neurokit, biosppy, pantompkins, hamilton, elgendi, engzee, vgraph)
- [x] `lib/src/ecg/ecg_simulate.dart` — Daubechies wavelet + ECGSYN dynamical model
  - [x] `_ecgSimulateDaubechies()` — db10 wavelet cycle tiling
  - [x] `_ecgSimulateEcgsyn()` — McSharry ODE model
  - [x] `_ecgSimulateRrprocess()` — RR interval spectral generation
  - [x] `_ecgsynDerivs()` — ECGSYN ODE derivatives
  - [x] `_rk4Step()` — RK4 ODE integrator
  - [x] `_signalDistort()` — Laplace noise injection
- [x] Barrel export aktifleştirildi
- [x] Static analysis: 0 error, 0 warning
