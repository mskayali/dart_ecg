# Phase 2: R-Peak Detection — Tasks

## Durum: ✅ Tamamlandı

- [x] `lib/src/ecg/ecg_findpeaks.dart` — 5 R-peak detection algorithm
  - [x] `_ecgFindpeaksNeurokit()` — gradient-based QRS detection
  - [x] `_ecgFindpeaksPantompkins()` — diff → square → MWA
  - [x] `_ecgFindpeaksHamilton()` — abs diff → adaptive threshold
  - [x] `_ecgFindpeaksElgendi()` — dual MWA comparison
  - [x] `_ecgFindpeaksEngzee()` — diff → zero crossing detection
- [x] `lib/src/ecg/ecg_peaks.dart` — Wrapper + Kubios artifact correction
- [x] Barrel export aktifleştirildi
- [x] Static analysis: 0 error, 0 warning
