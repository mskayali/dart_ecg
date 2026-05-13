# Implementation Plan: Agent Validation & Algorithmic Parity

Bu plan, NeuroKit2 ECG kütüphanesinin Dart portunu `.agent` kurallarına (Rule 1.3 Algoritmik Anlam Korunmalıdır ve Rule 4.1 Floating Point Toleransı) tam uyumlu hale getirmek için hazırlanmıştır.

## Mevcut Durum Analizi
- Proje `phase0` ile `phase5` arasında modüllere ayrıldı ve tüm testler yazıldı.
- R-Peak tespiti **%99.9** oranında (±1 sample sapma ile) NeuroKit2 ile eşleşmektedir.
- Ancak **Sinyal Temizleme (Clean)** adımında, Dart (`iirjdart`) ve Python (`scipy.signal.filtfilt`) arasındaki başlangıç koşulu (initial conditions - `zi`) ve padding stratejilerindeki farklardan dolayı sinyalin başlarında transient dalgalanmalar oluşmakta, bu da `ecg_clean` korelasyonunu ~0.86 seviyelerine çekmektedir.
- `.agent/rules.md`'ye göre temizlenmiş sinyal genlik sapmasının mutlak `1e-6` veya görece `1e-5` seviyesinde olması, R-Peak index'lerinin ise birebir eşleşmesi beklenmektedir.

## Hedef (Agent Yapısına Uyarlama ve Doğrulama)
1. **Agent Kurallarına Uyum (`.agent/production_artifacts.md`)**:
   - `docs/` klasöründeki dağınık süreçleri toparlayıp, `docs/algorithm_mapping.md`, `docs/numerical_validation.md` gibi beklenen artifact formatlarına uygun bir dokümantasyon mimarisine geçiş.
2. **Algoritmik Eksiklerin Giderilmesi (`filtfilt` paritesi)**:
   - Python'un kullandığı `scipy.signal.filtfilt`'in **padding (odd extension)** ve **initial state (zi)** hesaplama mantığının Dart (`lib/src/dsp/filter.dart`) tarafına birebir entegre edilmesi.
3. **Sayısal Doğrulama (Numerical Validation)**:
   - Algoritma değişiklikleri sonrasında orijinal Python kütüphanesi ile üretilen Golden Reference verilerle yeniden test yapılarak, sonucun tolerans sınırları (`1e-6`) içerisine çekilmesi.

## Proposed Changes

### 1. DSP Filtreleme (FiltFilt) Revizyonu
#### [MODIFY] `lib/src/dsp/filter.dart`
- **Padding:** Sinyalin başından ve sonundan `padlen = 3 * max(len(a), len(b))` kadar `odd` padding (yansıma) eklenmesi.
- **Initial Conditions (`zi`):** Scipy'nin `lfilter_zi` davranışının simüle edilerek veya `padlen` ile transient etkisinin absorbe edilmesinin sağlanması. Forward ve backward pass'ler arasında durum aktarımının doğru yönetilmesi.

### 2. NeuroKit2 Parite Testlerinin Sıkılaştırılması
#### [MODIFY] `test/ecg/ecg_process_test.dart`
- Temizlenmiş sinyal korelasyon limitinin `> 0.85`'ten `> 0.999`'a veya mutlak hata sınırına çekilmesi.
- Toleransların `.agent/rules.md` (Madde 4.1) standartlarına uygun hale getirilmesi.

### 3. Dokümantasyon ve Agent Mimarisinin Entegrasyonu
#### [NEW] `docs/numerical_validation.md`
- Yapılan Python-Dart karşılaştırma testlerinin sayısal sonuçları, toleransları ve onay durumu belgelendirilecek.
#### [NEW] `docs/algorithm_mapping.md`
- Tüm port edilen dosyaların NeuroKit2 içindeki karşılıkları ve test durumları tablo halinde listelenecek.
#### [MODIFY] `docs/implementation_plan.md`
- Agent'ın beklediği production artifact formatında güncellenerek tüm fazları kapsayan merkezi bir plan haline getirilecek.

## Verification Plan

### Automated Tests
1. Python'da yeni veya mevcut `test/golden/generate_golden.py` scriptini çalıştırarak en güncel golden verilerini üret.
2. Dart testlerini (`dart test`) çalıştır.
3. `filtfilt` değişiklikleri sayesinde `ecg_clean` çıktısındaki sapmanın (mean absolute error) `1e-6` mertebelerine indiğini doğrula.

### User Review Required
> [!IMPORTANT]
> `scipy.signal.filtfilt`'i tam anlamıyla kopyalamak için `lfilter_zi` hesaplaması oldukça kompleks bir matris matematiği (companion matrix eigenvalue) gerektirir. Bunu yapmak yerine, transient etkilerini tamamen ortadan kaldıran yüksek `padlen` kullanımlı pratik bir **padding + forward/backward** yaklaşımı kurmayı öneriyorum. Bu yöntem genellikle tıbbi sinyal işlemede klinik sonuçları birebir eşlemek için yeterlidir. Onaylıyor musunuz?
