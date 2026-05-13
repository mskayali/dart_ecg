# Phase 3: Delineation + Quality + Supporting Modules — Implementation Plan

## Amaç
ECG sinyal analizi tamamlayıcı modülleri: dalga delineasyonu, kalite değerlendirmesi, kardiyak faz, segment ve inversiyon düzeltme.

## Dosyalar

### ecg_delineate.dart
PQRST dalga noktalarını tanımlar. 2 metod:
- **peak**: Basit min/max arama — R-peak'lere göre Q, S (min), P, T (max) bölgelerinde
- **dwt** (default): `dwtComputeMultiscales()` ile multiscale DWT → QRS (scale 2), P/T (scale 4) zero crossing ve peak arama

### ecg_quality.dart
Sinyal kalitesi değerlendirmesi:
- **averageqrs**: Heartbeat segmentasyonu → ortalama template → her beat'in template ile korelasyonu

### ecg_phase.dart
Kardiyak faz hesaplama:
- Ventricular: R-peak'ten %40 RR → systole (0), geri kalanı → diastole (1)
- Atrial: P-onset/T-offset arası

### ecg_segment.dart
Heartbeat segmentasyonu:
- R-peak etrafında -0.35×RR ~ +0.65×RR pencere
- Padding ile sabit uzunluk

### ecg_invert.dart
İnversiyon tespiti:
- Pozitif/negatif alan karşılaştırması
- Negatif alan > 1.5× pozitif alan → inverted
