# Phase 2: R-Peak Detection — Implementation Plan

## Amaç
NeuroKit2'nin `ecg_findpeaks()` ve `ecg_peaks()` fonksiyonlarını Dart'a port etmek. 5 temel R-peak algılama algoritmasını implement etmek.

## ecg_findpeaks.dart

5 algılama algoritması:

| Algoritma | Teknik | Referans |
|-----------|--------|----------|
| `neurokit` (default) | Gradient → smooth → threshold → QRS → prominence | NeuroKit2 (unpublished) |
| `pantompkins1985` | diff → square → MWA → peak search | Pan & Tompkins (1985) |
| `hamilton2002` | abs diff → MA → adaptive threshold + missed beat | Hamilton (2002) |
| `elgendi2010` | Square → dual MWA → block detection | Elgendi et al. (2010) |
| `engzeemod2012` | diff → circular buffer threshold → zero crossing | Engelse & Zeelenberg (1979) |

### Algoritma Detayları

#### NeuroKit
1. `gradient(signal)` → `abs()` → `signalSmooth(boxcar)`
2. Average gradient threshold: `avggrad * 1.5`
3. QRS complex: `smoothgrad > threshold`
4. Her QRS içinde en prominent local maximum → R-peak
5. Minimum delay: 300ms

#### Pan-Tompkins
1. `diff()` → `square()`
2. MWA (150ms window)
3. `findPeaks(distance: 300ms)`
4. Original sinyalde max arama

#### Hamilton
1. `diff().abs` → MA (80ms)
2. Signal/noise peak tracking (8 element deque)
3. Threshold: `nPksAve + 0.45 * (sPksAve - nPksAve)`
4. Missed beat detection (1.5× RR)

## ecg_peaks.dart
- `ecgPeaks()`: `ecgFindpeaks()` wrapper
- Optional Kubios artifact correction (`signalFixpeaks`)
- Binary peak signal output
