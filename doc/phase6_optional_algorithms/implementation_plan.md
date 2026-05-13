# Phase 6: Optional & Deferred Algorithms — Implementation Plan

## Hedef
Kullanıcı talebi doğrultusunda, önceki aşamalarda "optional" veya "deferred" (sonraki fazlara bırakılmış) olarak işaretlenen ileri seviye algoritmaların Dart portlarının yapılması ve `dart_ecg` paketine entegre edilmesi.

## Önceden Ertelenen ve Opsiyonel Olarak İşaretlenen Algoritmalar Analizi
Önceki planlarda ve `.agent` notlarında tespit edilen 2 ana eksiklik şunlardır:

1. **`ecg_rsp` (ECG-Derived Respiration):** `algorithm_mapping.md` içerisinde açıkça `deferred` olarak belirtilmiştir. Kalp hızı değişkenliğinden (ECG Rate) solunum hızı sinyali (EDR) türetmeyi sağlar.
2. **`ecg_delineate` için CWT (Continuous Wavelet Transform) Metodu:** `phase 3` notlarında ve önceki agent'ın özetinde "gelişmiş CWT metotları gelecekteki iterasyonlara bırakıldı (future iterations)" şeklinde not düşülmüştür.

## User Review Required
> [!IMPORTANT]
> Kullanıcı onayı bekleniyor.
> `ecg_rsp` (Solunum hızı türetme) ve `ecg_delineate` içindeki **CWT** (Sürekli Dalgacık Dönüşümü) metotlarının port edilmesi doğru anlaşıldı mı? Eğer eklemek istediğiniz "optional" başka bir metot (örneğin `ecg_clean` içindeki `kalidas2012` veya `ecg_findpeaks` içindeki `promac`) varsa lütfen belirtiniz. Eğer bu liste uygunsa, uygulamaya geçeceğim.

## Proposed Changes

### 1. ECG-Derived Respiration (ecg_rsp.py -> ecg_rsp.dart)
#### [NEW] `lib/src/ecg/ecg_rsp.dart`
- Kalp atış hızı (ECG Rate) sinyali üzerinden filtreleme yaparak solunum sinyalini (EDR) türeten fonksiyon.
- 4 farklı filtreleme yöntemini (vangent2019, soni2019, charlton2016, sarkar2015) içerecek. 
- Filtreleme işlemleri `signal_filter` ve `butterworth` kullanılarak yapılacak.

### 2. CWT Delineation (ecg_delineate_cwt.dart)
#### [NEW] `lib/src/ecg/ecg_delineate_cwt.dart`
- `ecg_delineate` içerisindeki `cwt` metodu (Martinez 2004) için gereken Continious Wavelet Transform ve CWT tabanlı peak detection sınırlarının bulunması.
- `fftea` kütüphanesi veya `dwt` implementasyonumuza benzer şekilde CWT transform altyapısının `lib/src/dsp/wavelet.dart` veya ayrı bir yardımcı dosyaya eklenmesi.

#### [MODIFY] `lib/src/ecg/ecg_delineate.dart`
- Delineation metodlarına `method: 'cwt'` seçeneğinin aktifleştirilip, çağrıların yeni dosyaya yönlendirilmesi.

#### [MODIFY] `lib/dart_ecg.dart`
- Yeni public fonksiyon olan `ecgRsp` fonksiyonunun dışarıya açılması.

## Verification Plan

### Automated Tests
- `ecg_rsp` için Golden Test referans verisine EDR sinyali eklenecek ve python referans koduyla `%99` korelasyon test edilecek.
- `ecg_delineate` (CWT metodu) için P, Q, R, S, T onset/offset değerlerinin toleranslı karşılaştırma testleri yapılacak.
