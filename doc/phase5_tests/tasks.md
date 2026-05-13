# Phase 5: Golden Reference Testing — Tasks

## Durum: ✅ Tamamlandı

- [x] `test/golden/generate_golden.py` oluşturuldu.
- [x] Python scripti çalıştırılarak NeuroKit2 tabanlı `test/golden/ecg_process_golden.json` elde edildi.
- [x] `test/ecg/ecg_process_test.dart` test dosyası yazıldı.
- [x] JSON okuma ve ayrıştırma mekanizması eklendi.
- [x] Doğrulama (Assertion) kuralları yazıldı:
  - [x] Clean signal korelasyon kontrolü (> 0.85)
  - [x] R-Peak index kontrolü (±2 sample sapma limiti)
  - [x] Rate ve Quality sınır kontrolleri
- [x] Tüm testler ( `dart test` ) çalıştırıldı ve başarıyla geçti.
