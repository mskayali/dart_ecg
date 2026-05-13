# rules.md

## Amaç

Bu dosya, NeuroKit2 ECG işleme katmanını Dart kütüphanesine port edecek agent'ın uyması gereken zorunlu kuralları tanımlar.

Kurallar; kaynak izlenebilirliği, algoritmik doğruluk, sayısal tutarlılık, Dart API kalitesi, test stratejisi, güvenlik sınırları, medikal sorumluluk ve üretim disiplinini kapsar.

Bu dokümandaki kurallar öneri değildir. Agent her implementasyon, refactor, test, dokümantasyon ve handoff adımında bu kuralları uygulamalıdır.

---

## 1. Genel Çalışma Kuralları

### 1.1 Kaynak Sabitleme Zorunluluğu

Agent hiçbir ECG fonksiyonunu belirsiz bir upstream sürüme göre port etmemelidir.

Her çalışma başlamadan önce aşağıdaki bilgiler kayıt altına alınmalıdır:

```text
UPSTREAM_REPO=https://github.com/neuropsychology/NeuroKit
UPSTREAM_COMMIT=<full_commit_hash>
UPSTREAM_BRANCH_OR_TAG=<branch_or_tag>
UPSTREAM_ECG_PATH=neurokit2/ecg/
UPSTREAM_SIGNAL_PATH=neurokit2/signal/
PORT_DATE=<yyyy-mm-dd>
AGENT_RUN_ID=<id>
```

Commit hash yoksa agent implementasyona başlamamalı; önce kaynak sabitleme workflow'unu çalıştırmalıdır.

### 1.2 Tahmine Dayalı Port Yasaktır

Agent, NeuroKit2 fonksiyon davranışını yalnızca isimden veya dokümantasyondan tahmin ederek Dart kodu üretmemelidir.

Her port kararı şu kaynaklardan en az biriyle desteklenmelidir:

- Upstream Python source code
- Upstream documentation
- NeuroKit2 testleri
- Python referans çıktıları
- Literatürde tanımlı algoritma açıklaması
- Explicit project decision record

### 1.3 Algoritmik Anlam Korunmalıdır

Python kodu Dart'a satır satır çevrilmeyecekse bile algoritmik davranış korunmalıdır.

Korunması gereken ana davranışlar:

- Input validation
- Sampling rate kullanımı
- Filter cutoff frekansları
- Window uzunlukları
- Peak threshold hesapları
- Index mapping
- Boundary handling
- Missing value davranışı
- Warning ve exception koşulları
- Return shape ve field isimleri

### 1.4 Klinik İddia Üretmek Yasaktır

Agent veya üretilen Dart kütüphanesi aşağıdakileri yapmamalıdır:

- Hastalık teşhisi koymak
- Tedavi önermek
- Acil durum tespiti yaptığını iddia etmek
- FDA/CE/medical-grade uygunluğu ima etmek
- Klinik karar destek sistemi gibi sunulmak

İzin verilen ifade:

```text
This library provides ECG signal processing utilities for research, engineering, and non-diagnostic analysis workflows.
```

Yasak ifade:

```text
This library detects cardiac disease or provides diagnostic ECG interpretation.
```

---

## 2. Kapsam Kuralları

### 2.1 İlk Port Kapsamı

İlk Dart portunda öncelik sırası aşağıdaki gibidir:

1. Core signal utilities required by ECG functions
2. `ecg_clean`
3. `ecg_peaks`
4. `signal_rate` equivalent
5. `ecg_quality`
6. `ecg_delineate`
7. `ecg_phase`
8. `ecg_process`
9. `ecg_segment`
10. Fixture, benchmark, documentation, examples

### 2.2 Kapsam Dışı Bileşenler

Aşağıdaki alanlar ilk çekirdek paket kapsamına alınmamalıdır:

- Plotting API
- Matplotlib eşdeğeri grafik üretimi
- pandas DataFrame emülasyonu
- Notebook odaklı yardımcılar
- Klinik rapor üretimi
- Otomatik tıbbi yorumlama
- Flutter UI bileşenleri

Gerekirse bu bileşenler ayrı paket olarak tasarlanmalıdır:

```text
neurokit_ecg              # pure Dart core
neurokit_ecg_flutter      # optional Flutter visualization
neurokit_ecg_cli          # optional command line tooling
```

### 2.3 Public API Minimumluğu

Public API yalnızca stabil ve test edilmiş fonksiyonları dışa açmalıdır.

`lib/neurokit_ecg.dart` içinde deneysel helper fonksiyonlar export edilmemelidir.

Public API'ye alınan her öğe için şu koşullar sağlanmalıdır:

- Unit test mevcut
- Documentation comment mevcut
- Input validation mevcut
- Golden fixture karşılaştırması mevcut veya açıkça neden gerekli olmadığı belirtilmiş
- Breaking change etkisi değerlendirilmiş

---

## 3. Dart Kodlama Kuralları

### 3.1 Saf Dart Önceliği

Çekirdek paket saf Dart olmalıdır.

Flutter, platform channel, native dependency veya FFI bağımlılığı çekirdek işleme hattına eklenmemelidir.

FFI yalnızca performans darboğazı kanıtlandıktan sonra opsiyonel extension olarak düşünülebilir.

### 3.2 Null Safety Zorunludur

Tüm kod null-safe Dart ile yazılmalıdır.

Kurallar:

- Nullable input yalnızca gerçekten anlamlıysa kullanılmalıdır.
- `!` operatörü minimumda tutulmalıdır.
- API çıktıları mümkün olduğunca immutable olmalıdır.
- Eksik sonuçlar için `null` yerine explicit model veya empty collection tercih edilmelidir.

Örnek:

```dart
class EcgPeaksResult {
  const EcgPeaksResult({
    required this.rPeaks,
    required this.signals,
    required this.info,
  });

  final List<int> rPeaks;
  final EcgPeakSignals signals;
  final EcgPeaksInfo info;
}
```

### 3.3 Mutable Global State Yasaktır

Agent şu yapılardan kaçınmalıdır:

- Global cache
- Static mutable state
- Shared random state
- Hidden singleton processing state
- Environment-dependent behavior

Aynı input her zaman aynı output'u üretmelidir.

### 3.4 Deterministik Random Kullanımı

Simülasyon veya fixture üretiminde randomness gerekirse seed zorunludur.

```dart
final rng = Random(seed);
```

Seed verilmeden rastgele sinyal üreten public API tasarlanmamalıdır.

### 3.5 Veri Yapısı Kuralları

ECG sinyal verisi için ana input tipi:

```dart
List<double>
```

Internal computation için gerektiğinde typed data kullanılabilir:

```dart
Float64List
Int32List
Uint8List
```

Kurallar:

- Public API basit ve Dart-native kalmalıdır.
- Büyük sinyal işleme fonksiyonları gereksiz kopyalama yapmamalıdır.
- Internal conversion açıkça belgelenmelidir.
- Output indexleri her zaman orijinal input sinyal indekslerine göre verilmelidir.

### 3.6 Exception Tipleri

Input hataları için standart exception davranışı kullanılmalıdır:

```dart
ArgumentError
RangeError
StateError
UnsupportedError
```

Özel exception sınıfı yalnızca kullanıcıya anlamlı ek bilgi sağlayacaksa oluşturulmalıdır.

Örnek:

```dart
if (samplingRate <= 0) {
  throw ArgumentError.value(samplingRate, 'samplingRate', 'Must be positive.');
}
```

---

## 4. Sayısal İşlem Kuralları

### 4.1 Floating Point Toleransı

Dart ve Python çıktıları bit-bit aynı olmak zorunda değildir.

Ancak her algoritma için tolerans açıkça tanımlanmalıdır:

```text
absolute_tolerance=<value>
relative_tolerance=<value>
index_tolerance_samples=<value>
```

Önerilen başlangıç toleransları:

```text
Cleaned signal amplitude: abs <= 1e-6 or rel <= 1e-5
Heart rate signal: abs <= 1e-4 bpm
R-peak index: exact for synthetic fixtures, ±1 sample for noisy real-world fixtures
Delineation boundaries: ±2 to ±8 samples depending on method and sampling rate
Quality score: abs <= 1e-5 where algorithmic parity is expected
```

Toleranslar algoritmaya göre `validation_matrix.md` veya ilgili test dosyasında netleştirilmelidir.

### 4.2 Sampling Rate Davranışı

Her ECG fonksiyonu `samplingRate` parametresini açıkça almalıdır.

Kurallar:

- Varsayılan sampling rate NeuroKit2 davranışıyla uyumlu olmalıdır.
- Sampling rate integer kabul edilebilir, fakat internal hesaplarda double dönüşümü gerekebilir.
- Window size hesaplarında rounding stratejisi upstream ile eşlenmelidir.
- Sampling rate değiştiğinde cutoff, interval ve window hesapları yeniden ölçeklenmelidir.

### 4.3 Index Tabanı

Dart output indexleri 0-based olmalıdır.

Bu, Python/NumPy index davranışıyla uyumludur.

Kurallar:

- R-peak indexleri input sinyal dizisine göre verilmelidir.
- Cleaned signal uzunluğu input sinyal uzunluğuyla aynı olmalıdır.
- Segment outputlarında start/end indeksleri açıkça inclusive/exclusive olarak belgelenmelidir.
- Delineation outputlarında bulunamayan noktalar için sentinel kullanımından kaçınılmalı, nullable veya sparse yapı tercih edilmelidir.

### 4.4 NaN ve Infinity Politikası

Agent her public fonksiyonda NaN/Infinity davranışını belirlemelidir.

Varsayılan kural:

- Input içinde `NaN` varsa fonksiyon ya açık exception fırlatmalı ya da NeuroKit2 ile uyumlu biçimde sanitize etmelidir.
- `double.infinity` ve `double.negativeInfinity` inputları geçerli ECG sample değeri olarak kabul edilmemelidir.
- Silent propagation yasaktır.

Örnek input validation:

```dart
for (final value in signal) {
  if (!value.isFinite) {
    throw ArgumentError('ECG signal must contain only finite values.');
  }
}
```

### 4.5 Filtre Tasarım Uyumluluğu

Filter implementasyonlarında şu bilgiler belgelenmelidir:

- Filter type
- Order
- Cutoff frequency/frequencies
- Sampling rate normalization
- Coefficient generation method
- Forward-only veya zero-phase uygulama
- Boundary padding stratejisi

SciPy `filtfilt`, `butter`, `savgol_filter` gibi davranışların Dart karşılığı birebir yoksa fark açıkça belgelenmelidir.

---

## 5. NeuroKit2 ECG Fonksiyon Kuralları

### 5.1 `ecg_clean` Kuralları

`ecg_clean` portunda method seçimi enum ile yapılmalıdır:

```dart
enum EcgCleanMethod {
  neurokit,
  biosppy,
  pantompkins1985,
  hamilton2002,
  elgendi2010,
  engzeeMod2012,
  vg,
  templateConvolution,
}
```

Kurallar:

- Method stringleri public API'de enum ile temsil edilmelidir.
- Upstream alias davranışı desteklenecekse alias mapping ayrı helper'da tutulmalıdır.
- Her method için filter zinciri ayrı test edilmelidir.
- Unsupported method `UnsupportedError` üretmelidir.
- Output uzunluğu input uzunluğuyla aynı olmalıdır.

### 5.2 `ecg_peaks` Kuralları

R-peak detection portunda şu davranışlar korunmalıdır:

- Cleaned signal inputu desteklenmeli
- Raw signal doğrudan verilirse temizleme stratejisi açık olmalı
- R-peak indexleri `List<int>` olarak dönmeli
- Peak correction opsiyonu ayrı parametre olmalı
- Method-specific info alanları korunmalı

Önerilen model:

```dart
class EcgPeaksInfo {
  const EcgPeaksInfo({
    required this.rPeaks,
    required this.samplingRate,
    required this.method,
    this.extra = const {},
  });

  final List<int> rPeaks;
  final int samplingRate;
  final EcgPeakMethod method;
  final Map<String, Object?> extra;
}
```

### 5.3 `signal_rate` / ECG Rate Kuralları

Heart rate sinyali R-peak indexlerinden türetilmelidir.

Kurallar:

- Rate birimi bpm olmalıdır.
- Output uzunluğu istenen length parametresine göre belirlenmelidir.
- Interpolation yöntemi upstream ile eşlenmelidir.
- Çok az peak varsa davranış açık exception veya empty/constant output olarak belgelenmelidir.

### 5.4 `ecg_quality` Kuralları

ECG quality portunda kalite skoru klinik tanı olarak sunulmamalıdır.

Kurallar:

- Quality method enum ile seçilmelidir.
- Output range belgelenmelidir.
- Beat-level ve signal-level quality ayrımı açık olmalıdır.
- Missing peak veya kısa sinyal durumları test edilmelidir.

### 5.5 `ecg_delineate` Kuralları

Delineation fonksiyonları yüksek hata riski taşıdığı için kademeli port edilmelidir.

Öncelik:

1. R-peak anchored wave boundaries
2. Peak-based method
3. CWT method
4. DWT method
5. Prominence veya ek upstream yöntemleri

Kurallar:

- P, Q, R, S, T peak/onset/offset alanları ayrı listelerle tutulmalıdır.
- Bulunamayan noktalar için nullable integer listeleri kullanılabilir.
- Her dalga sınırı için index tolerance ayrı tanımlanmalıdır.
- Çok kısa beat segmentlerinde graceful degradation uygulanmalıdır.

### 5.6 `ecg_phase` Kuralları

Cardiac phase hesapları R-peak ve delineation çıktılarıyla uyumlu olmalıdır.

Kurallar:

- Atrial ve ventricular phase ayrımı korunmalıdır.
- Phase output uzunluğu input sinyal uzunluğuyla aynı olmalıdır.
- Phase completion değerleri normalize edilmelidir.
- Eksik delineation noktalarında davranış belgelenmelidir.

### 5.7 `ecg_process` Kuralları

`ecg_process` public high-level API olmalıdır.

Kurallar:

- Pipeline sırası NeuroKit2 ile uyumlu olmalıdır.
- Her alt adımın parametresi explicit config ile verilebilmelidir.
- Output tek model altında toplanmalıdır.
- Intermediate signals kaybolmamalıdır.

Önerilen model:

```dart
class EcgProcessResult {
  const EcgProcessResult({
    required this.signals,
    required this.info,
  });

  final EcgSignals signals;
  final EcgInfo info;
}
```

---

## 6. Test Kuralları

### 6.1 Test Önce Fixture Zorunluluğu

Her port edilen fonksiyon için önce Python referans fixture üretilmelidir.

Minimum fixture içeriği:

```text
input_signal
sampling_rate
method
parameters
python_output
upstream_commit
neurokit_version
fixture_generation_script
```

### 6.2 Golden Test Zorunluluğu

Core algoritmalar golden test olmadan tamamlanmış sayılmaz.

Golden test gerektiren fonksiyonlar:

- `ecg_clean`
- `ecg_peaks`
- `signal_rate`
- `ecg_quality`
- `ecg_delineate`
- `ecg_phase`
- `ecg_process`

### 6.3 Edge Case Testleri

Her public fonksiyon aşağıdaki durumlarla test edilmelidir:

- Empty signal
- Single sample signal
- Very short signal
- Constant signal
- All-zero signal
- NaN input
- Infinity input
- Very low sampling rate
- Very high sampling rate
- No detected peak
- Too few peaks
- Noisy synthetic signal
- Inverted ECG signal where relevant

### 6.4 Property-Based Testler

Mümkün olan fonksiyonlarda property-based test kullanılmalıdır.

Örnek invariantlar:

```text
cleaned.length == input.length
all peak indices are within [0, signal.length)
peak indices are strictly increasing
rate.length == desiredLength
phase.length == signal.length
all finite input produces finite output unless explicitly documented
```

### 6.5 Python-Dart Karşılaştırma Testleri

Karşılaştırma scripti şu dosyada tutulmalıdır:

```text
tool/compare_with_neurokit.py
```

Bu script:

- Python NeuroKit2 outputlarını üretmeli
- Dart outputlarını okumalı
- Toleransları uygulamalı
- Fark raporu üretmeli
- CI ortamında çalıştırılabilir olmalı

---

## 7. Dokümantasyon Kuralları

### 7.1 Her Public API Belgelenmelidir

Public class, enum, method ve function için Dart doc comment zorunludur.

Doc comment şunları içermelidir:

- Fonksiyonun amacı
- Input parametreleri
- Output yapısı
- Sampling rate beklentisi
- NeuroKit2 karşılığı
- Medikal kullanım sınırı
- Hata durumları

### 7.2 Kaynak Referansı Zorunludur

Her port edilen fonksiyonun dokümantasyonunda upstream referans yer almalıdır:

```text
NeuroKit2 source: neurokit2/ecg/ecg_clean.py::<function_name>
Upstream commit: <commit_hash>
```

### 7.3 README Abartılı İddia İçermemelidir

README içinde şu tür ifadeler kullanılmamalıdır:

- clinically validated
- diagnostic grade
- detects heart disease
- medical device ready
- FDA ready

Kullanılabilecek ifade:

```text
Designed for research and engineering workflows that need deterministic ECG signal processing utilities in Dart.
```

---

## 8. Performans Kuralları

### 8.1 Önce Doğruluk, Sonra Optimizasyon

Agent performans için algoritmik davranışı değiştirmemelidir.

Optimizasyon ancak şu koşullarda yapılmalıdır:

- Golden testler geçiyor
- Benchmark darboğazı gösteriyor
- Değişiklik output toleranslarını bozmuyor
- Kod okunabilirliği kabul edilebilir seviyede kalıyor

### 8.2 Gereksiz Kopyalama Azaltılmalıdır

Uzun sinyallerde gereksiz `List<double>` kopyaları engellenmelidir.

Ancak mutable aliasing riski varsa defensive copy tercih edilebilir.

Her kritik fonksiyon için memory davranışı review edilmelidir.

### 8.3 Benchmark Zorunluluğu

Aşağıdaki senaryolar benchmarklanmalıdır:

```text
10 seconds ECG @ 250 Hz
60 seconds ECG @ 250 Hz
5 minutes ECG @ 250 Hz
10 seconds ECG @ 1000 Hz
60 seconds ECG @ 1000 Hz
```

Benchmark dosyaları:

```text
benchmark/ecg_clean_benchmark.dart
benchmark/ecg_peaks_benchmark.dart
benchmark/ecg_process_benchmark.dart
```

---

## 9. Dependency Kuralları

### 9.1 Minimum Bağımlılık

Dart paketi minimum dış bağımlılıkla tasarlanmalıdır.

Kurallar:

- Matematik ve DSP için küçük, bakımlı paketler tercih edilebilir.
- Kritik algoritmalar üçüncü parti pakete kör biçimde devredilmemelidir.
- Her dependency için lisans kontrolü yapılmalıdır.
- Dependency eklenmeden önce saf Dart implementasyon maliyeti değerlendirilmelidir.

### 9.2 Lisans Uyumluluğu

NeuroKit2 kaynak lisansı ve kullanılan algoritmaların referansları kontrol edilmelidir.

Agent şunları üretmelidir:

```text
docs/legal/upstream_license_review.md
docs/legal/dependency_license_matrix.md
```

Her port edilen dosyada upstream atıf korunmalıdır.

---

## 10. Review ve Handoff Kuralları

### 10.1 Done Definition

Bir ECG fonksiyonu şu koşullar sağlanmadan tamamlanmış sayılmaz:

- Source map üretildi
- Dart implementation tamamlandı
- Unit test yazıldı
- Golden fixture karşılaştırması geçti
- Edge case testleri geçti
- Documentation comment eklendi
- API review yapıldı
- Performance smoke test yapıldı
- Handoff notu güncellendi

### 10.2 Deviation Kaydı

NeuroKit2 davranışından sapma varsa mutlaka deviation kaydı oluşturulmalıdır.

Format:

```text
Deviation ID: DEV-ECG-<number>
Function: <function_name>
Upstream behavior: <description>
Dart behavior: <description>
Reason: <reason>
Impact: <impact>
Tests: <test references>
Approval: <reviewer/date>
```

### 10.3 Review Checklist

Her pull request veya agent tesliminde şu liste kontrol edilmelidir:

```text
[ ] Upstream commit recorded
[ ] Source function mapped
[ ] Dart API documented
[ ] Input validation implemented
[ ] Numerical tolerances defined
[ ] Golden tests added
[ ] Edge cases tested
[ ] No clinical claims introduced
[ ] No unstable public export added
[ ] Dependency impact reviewed
[ ] Handoff document updated
```

---

## 11. Güvenlik ve Sorumluluk Kuralları

### 11.1 Medical Safety Boundary

Paket dokümantasyonunda açık uyarı bulunmalıdır:

```text
This package is not a medical device and must not be used as the sole basis for diagnosis, treatment, or clinical decision-making.
```

### 11.2 Kullanıcı Verisi Gizliliği

ECG sinyalleri kişisel sağlık verisi olabilir.

Agent ve örnek uygulamalar:

- Kullanıcı ECG verisini varsayılan olarak dış servise göndermemelidir.
- Örneklerde gerçek hasta verisi kullanılmamalıdır.
- Fixture verileri synthetic veya public dataset lisansına uygun olmalıdır.
- Logging içinde raw ECG sinyali basılmamalıdır.

### 11.3 Hata Mesajları

Hata mesajları teknik ve sınırlı olmalıdır.

Yasak:

```text
Possible arrhythmia detected.
```

İzin verilen:

```text
R-peak detection failed because no local maxima passed the configured threshold.
```

---

## 12. CI/CD Kuralları

### 12.1 Zorunlu CI Adımları

CI pipeline şu adımları içermelidir:

```text
dart format --set-exit-if-changed .
dart analyze
dart test
dart run tool/fixture_validate.dart
dart run benchmark/smoke_benchmark.dart
```

Python fixture generation CI içinde opsiyonel olabilir, fakat fixture validation zorunlu olmalıdır.

### 12.2 Breaking Change Kontrolü

Public API değişiklikleri için CHANGELOG güncellenmelidir.

Breaking change varsa major version etkisi değerlendirilmelidir.

### 12.3 Artifact Saklama

CI şu artifactleri saklamalıdır:

```text
test_reports/
coverage/
benchmark_reports/
validation_reports/
```

---

## 13. Yasaklar

Agent aşağıdakileri yapmamalıdır:

1. Upstream commit belirtmeden port yapmak
2. Testsiz public API eklemek
3. Klinik teşhis iddiası üretmek
4. Python pandas veri modelini Dart'a birebir taşımak
5. Silent NaN propagation yapmak
6. Sampling rate'i ignore etmek
7. R-peak indexlerini yeniden ölçeklemeden döndürmek
8. Plotting kodunu core pakete almak
9. Global mutable state kullanmak
10. Performans için doğruluğu bozmak
11. Fixture üretmeden golden test yazdığını varsaymak
12. Lisans etkisini incelemeden dependency eklemek
13. Unsupported methodları sessizce default methoda düşürmek
14. Output shape değişikliklerini dokümante etmemek
15. Handoff olmadan fonksiyonu tamamlandı saymak

---

## 14. Agent Karar Önceliği

Çakışan karar durumlarında öncelik sırası:

1. Kullanıcı güvenliği ve medikal sınır
2. Upstream algoritmik doğruluk
3. Test edilebilirlik
4. Public API stabilitesi
5. Dart-native ergonomi
6. Performans
7. Kod kısalığı

Kod kısa ama doğrulanamazsa reddedilmelidir.

Kod hızlı ama NeuroKit2 davranışını bozuyorsa reddedilmelidir.

Kod upstream ile uyumlu ama public API kötü ise internal olarak tutulmalı, public API ayrıca tasarlanmalıdır.

---

## 15. Minimum Başarı Kriteri

Agent'ın ilk üretim iterasyonu aşağıdaki sonucu vermelidir:

```text
- Pure Dart package compiles
- ecg_clean works for at least one NeuroKit-compatible method
- ecg_peaks detects R-peaks on synthetic ECG fixture
- signal_rate derives bpm series from R-peaks
- ecg_process returns structured output
- Golden tests compare Dart output with Python NeuroKit2 output
- No medical diagnostic claims exist
- Handoff package documents current limitations
```

Bu kriterler sağlanmadan proje üretim entegrasyonuna hazır kabul edilmemelidir.
