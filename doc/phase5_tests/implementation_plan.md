# Phase 5: Golden Reference Testing — Implementation Plan

## Amaç
NeuroKit2 (Python) referans alarak yazılan `dart_ecg` kodlarının klinik doğruluğunu ve mantık bütünlüğünü kanıtlamak. Bunun için Python tarafında üretilen "Golden Reference" verileri ile Dart tarafındaki çıktıları karşılaştıran bir test altyapısı kurmak.

## Yaklaşım
1. **Python Veri Üretici (`test/golden/generate_golden.py`)**
   - `neurokit2.ecg_simulate()` kullanılarak sentetik ve gürültülü bir EKG sinyali üretilir.
   - `neurokit2.ecg_process()` ile sinyal işlenir (Temizleme, R-Peak tespiti, Hız, Kalite vb.).
   - Üretilen raw sinyal ve işlenmiş sinyal dizileri bir JSON dosyasına (`ecg_process_golden.json`) aktarılır.

2. **Dart Test Suiti (`test/ecg/ecg_process_test.dart`)**
   - Üretilen JSON dosyası okunur.
   - Raw sinyal, `dart_ecg` kütüphanesindeki `ecgProcess()` fonksiyonuna verilir.
   - Elde edilen sonuçlar ile JSON içerisindeki referans (Golden) veriler karşılaştırılır.

## Doğrulama Kriterleri
- **Clean Signal:** IIR (Filtfilt) filtrelerinin başlatma koşullarındaki küçük matematiksel farklar nedeniyle (Scipy vs. Dart) tamamen aynı olmasa bile, Pearson korelasyonunun **> 0.85** olması beklenir.
- **R-Peak Noktaları:** Klinik olarak en önemli bulgu budur. Tespit edilen R-Peak noktalarının referans ile aynı sayıda olması ve aralarındaki farkın en fazla **±2 sample** (yüksek doğruluk) olması beklenir.
- **Derived Signals (Rate & Quality):** Hız (BPM) ve kalite indekslerinin hesaplandığı ve makul limitler içinde olduğu doğrulanır (Rate: 30-200 BPM arası, Quality: 0.0 - 1.0 arası).
