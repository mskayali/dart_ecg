# skills.md

## Amaç

Bu dosya, NeuroKit2 kütüphanesinin ECG işleme bölümünü Dart ekosistemine taşımak için çalışacak agent'ın sahip olması gereken teknik yetenekleri, karar sınırlarını ve kalite beklentilerini tanımlar.

Agent'ın ana hedefi, Python/NumPy/SciPy tabanlı NeuroKit2 ECG fonksiyonlarını Dart paket mimarisine güvenli, test edilebilir, deterministik ve üretime uygun şekilde port etmektir.

---

## Agent Profili

**Rol:** ECG signal processing porting agent  
**Kaynak teknoloji:** Python, NumPy, SciPy, pandas, NeuroKit2  
**Hedef teknoloji:** Dart, Flutter uyumlu saf Dart paketleri, opsiyonel FFI katmanı  
**Alan:** Biomedical signal processing, ECG preprocessing, R-peak detection, feature extraction

Agent yalnızca birebir sözdizimi çevirisi yapmaz. Algoritmik eşdeğerlik, sayısal davranış, test kapsamı, edge-case yönetimi ve Dart paket ergonomisini birlikte değerlendirir.

---

## Temel Skill Kategorileri

### 1. NeuroKit2 ECG Kaynak Kod Analizi

Agent aşağıdaki işleri yapabilmelidir:

- NeuroKit2 içindeki ECG fonksiyonlarının dosya ve çağrı bağımlılıklarını çıkarmak.
- `ecg_process`, `ecg_clean`, `ecg_peaks`, `ecg_rate`, `ecg_quality`, `ecg_delineate`, `ecg_phase`, `ecg_segment` gibi fonksiyonların sorumluluklarını ayırmak.
- Her fonksiyon için input, output, sampling rate, opsiyonel parametreler ve varsayılan değerleri belgelemek.
- Algoritmik çekirdeği, plotting/debug/UI yardımcılarından ayırmak.
- Python'a özgü davranışları tespit etmek:
  - NumPy array broadcasting
  - pandas DataFrame/Series dönüşleri
  - SciPy filter tasarımları
  - NaN/Inf davranışı
  - slicing/indexing semantiği
  - mutable varsayılan parametre riskleri

### 2. ECG Signal Processing Bilgisi

Agent aşağıdaki ECG kavramlarını teknik olarak doğru yorumlayabilmelidir:

- Sampling rate ve yeniden örnekleme etkileri
- Bandpass, highpass, lowpass, notch filtreleri
- Baseline wander temizleme
- Powerline noise azaltma
- QRS kompleksi
- R-peak detection
- RR interval
- Heart rate ve heart rate variability için temel türevler
- Signal quality index mantıkları
- P, Q, R, S, T dalga sınırları
- Cardiac phase hesaplama
- Beat segmentation

Agent, algoritmaları tıbbi tanı sistemi gibi sunmamalıdır. Üretilen Dart paketi biyomedikal sinyal işleme aracıdır; klinik karar destek sistemi değildir.

### 3. Dart Dil ve Paket Tasarımı

Agent aşağıdaki Dart yeteneklerine sahip olmalıdır:

- Null safety uyumlu API tasarımı
- Immutable veri modelleri
- `List<double>`, `Float64List`, `Int32List` kullanım kararları
- Extension method kullanımı
- Paket içi modüler dosya organizasyonu
- Public/private API ayrımı
- `pubspec.yaml` bağımlılık yönetimi
- Dart test framework ile birim test yazımı
- Flutter bağımsız saf Dart çekirdek tasarımı
- Flutter tarafı için opsiyonel visualization adapter tasarımı

Tercih edilen çekirdek veri tipi:

```dart
Float64List
```

Public API ergonomisi için gerekirse `List<double>` kabul edilip içerde `Float64List`'e normalize edilebilir.

### 4. Sayısal Algoritma Port Etme

Agent şu teknikleri uygulayabilmelidir:

- Python/NumPy işlemlerini Dart döngülerine çevirmek.
- Vektörize operasyonları deterministik imperative implementasyona dönüştürmek.
- Filtre katsayılarını referansla karşılaştırmak.
- Floating point toleranslarını testlerde açık tanımlamak.
- `NaN`, `Infinity`, boş sinyal, tek elemanlı sinyal, çok kısa kayıt gibi sınır durumları ele almak.
- Deterministik sonuç üretmek.
- Randomness içeren simülasyon/testlerde seed kullanmak.

Önerilen tolerans yaklaşımı:

```text
absoluteTolerance = 1e-8
relativeTolerance = 1e-6
```

Filtreleme, peak detection ve interpolasyon adımlarında tolerans fonksiyon bazında daraltılıp genişletilebilir.

### 5. Digital Filtering Skill'i

Agent şunları uygulayabilmelidir:

- Butterworth filtre tasarımı
- IIR filtreleme
- FIR filtreleme
- Forward-backward filtering karşılığı
- Moving average filtreleri
- Median benzeri robust smoothing yaklaşımları
- Savitzky-Golay alternatifi gerekiyorsa açık tasarım
- Z-transform temelli katsayı validasyonu

Python tarafında SciPy fonksiyonlarına dayanan yerlerde Dart karşılıkları açıkça belirlenmelidir:

| Python/SciPy | Dart Port Stratejisi |
|---|---|
| `scipy.signal.butter` | Dart içinde katsayı üretimi veya sabitlenmiş coefficient generator |
| `scipy.signal.filtfilt` | forward-backward IIR implementasyonu |
| `scipy.signal.find_peaks` | custom peak detection utility |
| `scipy.interpolate` | linear/cubic interpolation utility |
| `numpy.convolve` | custom convolution |

### 6. R-Peak Detection Skill'i

Agent R-peak detection için aşağıdaki algoritma ailelerini analiz edip port edebilmelidir:

- NeuroKit default detector
- Pan-Tompkins tabanlı yaklaşım
- Hamilton detector
- Christov detector
- Elgendi detector
- Engzee detector
- Visibility graph yaklaşımı
- Kalite ve düzeltme adımları

Her detector için ayrı strategy class önerilir:

```dart
abstract interface class RPeakDetector {
  RPeakDetectionResult detect(Float64List ecg, {required int samplingRate});
}
```

### 7. API Eşdeğerlik Skill'i

Agent, Python API ile Dart API arasında birebir olmasa bile açık bir eşleme kurmalıdır.

Örnek eşleme:

```text
nk.ecg_clean(ecg, sampling_rate=1000, method="neurokit")
```

Dart karşılığı:

```dart
final cleaned = EcgClean.clean(
  signal,
  samplingRate: 1000,
  method: EcgCleanMethod.neurokit,
);
```

API tasarımı şu ilkelere uymalıdır:

- String method parametreleri yerine enum kullanılmalı.
- Public sonuçlar typed result object olmalı.
- DataFrame benzeri gevşek veri yapıları kullanılmamalı.
- Hata mesajları kısa, teknik ve aksiyon alınabilir olmalı.

### 8. Test Tasarımı Skill'i

Agent aşağıdaki testleri üretmelidir:

- Unit test
- Golden vector test
- Cross-language parity test
- Edge-case test
- Performance smoke test
- Regression test
- Fixture tabanlı test

Golden test stratejisi:

1. Python NeuroKit2 ile referans ECG sinyalleri oluşturulur.
2. Her fonksiyonun intermediate ve final çıktısı `.json` veya `.csv` fixture olarak kaydedilir.
3. Dart testleri aynı input üzerinde çalışır.
4. Numeric tolerance ile karşılaştırma yapılır.

Örnek fixture yapısı:

```text
test/fixtures/ecg_clean/neurokit_1000hz_case_001.json
test/fixtures/ecg_peaks/pantompkins_250hz_case_002.json
test/fixtures/ecg_rate/default_500hz_case_003.json
```

### 9. Production Readiness Skill'i

Agent production kullanımı için aşağıdaki kriterleri gözetmelidir:

- Public API kararlılığı
- Breaking change kontrolü
- SemVer uyumu
- CI pipeline
- Lint kuralları
- Dokümantasyon örnekleri
- Benchmark dosyaları
- Bellek tahsisi kontrolü
- Büyük ECG kayıtlarında stream/chunk opsiyonu
- Platform bağımsızlık

### 10. Documentation Skill'i

Agent her port edilen fonksiyon için aşağıdaki dokümantasyonu üretmelidir:

- Amaç
- Python kaynak fonksiyon adı
- Dart public API adı
- Parametreler
- Dönüş tipi
- Algoritma özeti
- Bilinen farklar
- Edge-case davranışı
- Test fixture referansları
- Örnek kullanım

---

## Gerekli Alt Skill'ler

### Python Okuma Skill'i

Agent Python kodunu çalıştırmadan da okuyup analiz edebilmelidir:

- Fonksiyon imzaları
- Decorator etkileri
- Import bağımlılıkları
- Private helper kullanımı
- Exception davranışı
- Versiyon farkları

### Dart Yazma Skill'i

Agent idiomatic Dart üretmelidir:

- Açık tipler
- Küçük fonksiyonlar
- Guard clause kullanımı
- Enum tabanlı method seçimi
- Immutable result modelleri
- `package:test` uyumlu testler

### Matematiksel Doğrulama Skill'i

Agent port edilen fonksiyonun yalnızca derlenmesini değil, matematiksel eşdeğerliğini de kontrol etmelidir:

- Peak index farkları
- Signal amplitude farkları
- Rate interpolation farkları
- Phase labeling farkları
- Filtering delay farkları

### Performance Analizi Skill'i

Agent şunları ölçmelidir:

- Runtime complexity
- Memory allocation
- Large signal throughput
- Mobile CPU uyumluluğu
- Web target uyumluluğu

---

## Agent'ın Yapmaması Gerekenler

Agent aşağıdaki davranışlardan kaçınmalıdır:

- Python kodunu satır satır mekanik çevirmek.
- NumPy davranışını anlamadan Dart döngüsüne dönüştürmek.
- Klinik doğruluk iddiası üretmek.
- Test fixture olmadan algoritmayı tamamlanmış saymak.
- `dynamic`, `Map<String, dynamic>` ve gevşek tipleri public API'de kullanmak.
- Silent fallback uygulamak.
- Sampling rate uyumsuzluklarını görmezden gelmek.
- Hatalı inputları otomatik düzeltip kullanıcıya bildirmemek.

---

## Öncelikli Skill Sıralaması

Port sürecinde skill önceliği şu sırada olmalıdır:

1. Kaynak kod ve bağımlılık analizi
2. ECG pipeline ayrıştırma
3. Sayısal helper altyapısı
4. Filtering altyapısı
5. `ecg_clean` portu
6. `ecg_peaks` portu
7. `ecg_rate` portu
8. `ecg_quality` portu
9. `ecg_delineate` portu
10. `ecg_phase` ve `ecg_segment` portu
11. Fixture ve parity testleri
12. API dokümantasyonu
13. Benchmark ve production hardening

---

## Başarı Kriterleri

Bu skill set doğru uygulanmış sayılmak için aşağıdaki şartlar sağlanmalıdır:

- Her ECG fonksiyonu için Python-Dart davranış eşlemesi vardır.
- Her algoritma için en az bir golden test fixture vardır.
- Public API null-safe ve typed result object tabanlıdır.
- Tüm hata durumları deterministiktir.
- Büyük sinyal kayıtlarında gereksiz kopyalama azaltılmıştır.
- Sayısal farklar testlerde açıklanmıştır.
- Klinik kullanım sınırları dokümantasyonda belirtilmiştir.

---

## Minimum Kabul Kriteri

Agent, ilk üretim fazı sonunda aşağıdaki çıktıları verebilmelidir:

```text
lib/src/ecg/ecg_clean.dart
lib/src/ecg/ecg_peaks.dart
lib/src/ecg/ecg_rate.dart
lib/src/signal/filtering.dart
lib/src/signal/peaks.dart
test/ecg/ecg_clean_test.dart
test/ecg/ecg_peaks_test.dart
test/fixtures/...
```

Bu dosyalar tamamlanmadan ECG portu production-ready kabul edilmemelidir.
