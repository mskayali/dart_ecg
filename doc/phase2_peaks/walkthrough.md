# Phase 2: R-Peak Detection — Walkthrough

## Yapılan Değişiklikler

### ecg_findpeaks.dart (~350 satır)
- `ecgFindpeaks()`: Method dispatch → 5 algoritma
- **NeuroKit**: `gradient()` → abs → smooth(boxcar) → avg threshold → QRS boundaries → prominence-based peak selection. `findPeaks(prominence: 0.0)` kullanarak QRS içindeki en belirgin tepeyi bulur.
- **Pan-Tompkins**: `diff()` → `square()` → `movingWindowAverage(150ms)` → `findPeaks(distance: 300ms)` → original sinyalde max arama.
- **Hamilton**: `diff().abs` → MA(80ms) → adaptive threshold (8-element signal/noise peak tracking). Missed beat detection: 1.5× ortalama RR interval kontrolü.
- **Elgendi**: `square()` → dual MWA (QRS: 97ms, beat: 611ms) → blok tespiti → blok içinde max.
- **Engzee**: `diff()` → circular buffer (5-element) threshold → sign change detection → backwards peak search + refractory period.

### ecg_peaks.dart (~60 satır)
- `ecgPeaks()`: `ecgFindpeaks()` çağrısı + optional `signalFixpeaks(method: 'kubios')`.
- Record return type: `({List<double> signals, Map<String, dynamic> info})`
- `signalFormatpeaks()` ile binary marker signal üretimi.

## Doğrulama
- `dart analyze`: 0 error, 0 warning
