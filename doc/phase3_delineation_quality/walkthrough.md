# Phase 3: Delineation + Quality + Supporting Modules — Walkthrough

## Yapılan Değişiklikler

### ecg_delineate.dart (~190 satır)
- `ecgDelineate()`: Method dispatch (peak / dwt)
- `_delineatePeak()`: R-peak'ler arası bölgelerde basit min/max arama
  - Q: prevRpeak midpoint ~ R-peak arası minimum
  - S: R-peak ~ nextRpeak midpoint arası minimum
  - T: S bölgesi sonrası %70 RR arası maximum
  - P: %70 RR öncesi ~ Q bölgesi arası maximum
- `_delineateDwt()`: `dwtComputeMultiscales(wavelet: 'db6')` kullanarak
  - QRS scale (index 1): zero-crossing ile Q onset, S offset
  - P/T scale (index 3): max absolute value ile P, T peaks

### ecg_quality.dart (~100 satır)
- `ecgQuality()`: averageQRS metodu
- `_ecgQualityAverageqrs()`:
  1. `ecgSegment()` ile heartbeat segmentasyonu
  2. Normalize to shortest segment length
  3. Mean template hesapla
  4. Her beat'in template ile `correlation()` değeri
  5. R-peak'ler arası bölgelere interpolate

### ecg_phase.dart (~50 satır)
- Ventricular: R-peak'ten %40 RR = systole(0), kalan = diastole(1)
- Atrial: P-onset'ten T-offset'e kadar = 1

### ecg_segment.dart (~70 satır)
- Mean RR interval hesaplama
- [-0.35×RR, +0.65×RR] pencere
- Edge padding

### ecg_invert.dart (~55 satır)
- `forceInversion` parametresi desteği
- Positive vs negative area ratio ile auto-detection

## Doğrulama
- `dart analyze`: 0 error, 0 warning
