# production_artifacts.md

## Amaç

Bu dosya, NeuroKit2 ECG işleme bölümünün Dart kütüphanesine port edilmesi sırasında agent'ın üretmesi, güncellemesi ve teslim etmesi gereken somut çıktıları tanımlar.

Agent'ın başarısı yalnızca çalışan kod üretmesiyle ölçülmez. Üretim çıktıları; izlenebilir algoritma eşlemesi, test edilebilirlik, API kararlılığı, sayısal doğrulama, dokümantasyon ve bakım yapılabilirlik standartlarını birlikte sağlamalıdır.

---

## Ana Üretim Çıktıları

### 1. Dart Package Skeleton

Agent aşağıdaki gibi derlenebilir, test edilebilir ve `pub.dev` uyumlu bir Dart paket iskeleti üretmelidir:

```text
neurokit_ecg/
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
├── LICENSE
├── analysis_options.yaml
├── lib/
│   ├── neurokit_ecg.dart
│   └── src/
│       ├── ecg/
│       ├── signal/
│       ├── dsp/
│       ├── models/
│       └── utils/
├── test/
│   ├── ecg/
│   ├── signal/
│   ├── dsp/
│   ├── fixtures/
│   └── golden/
├── example/
│   └── main.dart
└── tool/
    ├── generate_fixtures.dart
    └── compare_with_neurokit.py
```

Paket iskeleti Flutter bağımlılığı içermemelidir. Çekirdek paket saf Dart olmalıdır. Flutter görselleştirme veya widget katmanı gerekirse ayrı paket olarak tasarlanmalıdır.

---

### 2. Public API Artifacts

Agent, hedef Dart API'sini açık ve kararlı şekilde üretmelidir.

Beklenen public API dosyası:

```text
lib/neurokit_ecg.dart
```

Bu dosya yalnızca stabil public export'ları içermelidir:

```dart
export 'src/ecg/ecg_processor.dart';
export 'src/ecg/ecg_clean.dart';
export 'src/ecg/ecg_peaks.dart';
export 'src/ecg/ecg_rate.dart';
export 'src/ecg/ecg_quality.dart';
export 'src/ecg/ecg_delineate.dart';
export 'src/ecg/ecg_phase.dart';
export 'src/models/ecg_process_result.dart';
export 'src/models/ecg_info.dart';
export 'src/models/ecg_signals.dart';
```

Public API şu hedef kullanım senaryolarını desteklemelidir:

```dart
final result = EcgProcessor.process(
  signal: samples,
  samplingRate: 1000,
  method: EcgMethod.neurokit,
);

final cleaned = EcgClean.clean(
  signal: samples,
  samplingRate: 1000,
  method: EcgCleanMethod.neurokit,
);

final peaks = EcgPeaks.find(
  cleanedSignal: cleaned,
  samplingRate: 1000,
  method: RPeakMethod.neurokit,
);
```

---

### 3. Algorithm Mapping Matrix

Agent her NeuroKit2 fonksiyonu için Python kaynağı ile Dart hedefini eşleyen bir matris üretmelidir.

Önerilen dosya:

```text
docs/algorithm_mapping.md
```

Beklenen tablo formatı:

```text
| NeuroKit2 Function | Python Source | Dart Target | Status | Test Fixture | Notes |
|---|---|---|---|---|---|
| ecg_process | neurokit2/ecg/ecg_process.py | EcgProcessor.process | planned | process_1000hz.json | Pipeline orchestrator |
| ecg_clean | neurokit2/ecg/ecg_clean.py | EcgClean.clean | planned | clean_neurokit_1000hz.json | Multiple methods |
| ecg_peaks | neurokit2/ecg/ecg_peaks.py | EcgPeaks.find | planned | peaks_default.json | R-peak detection |
```

Status değerleri:

```text
planned
in_progress
ported
verified
blocked
deferred
```

Her satırda en az bir doğrulama fixture'ı veya açık bir erteleme nedeni bulunmalıdır.

---

### 4. ECG Processing Pipeline Implementation

Agent, NeuroKit2 `ecg_process()` davranışına karşılık gelen Dart pipeline'ını üretmelidir.

Hedef dosyalar:

```text
lib/src/ecg/ecg_processor.dart
lib/src/models/ecg_process_result.dart
lib/src/models/ecg_signals.dart
lib/src/models/ecg_info.dart
```

Minimum pipeline sırası:

```text
sanitize input
clean ECG
find R-peaks
calculate rate
estimate signal quality
delineate ECG waves
calculate cardiac phase
format result
```

Pipeline çıktısı DataFrame benzeri gevşek yapı olmamalıdır. Dart tarafında typed model kullanılmalıdır.

Örnek model yaklaşımı:

```dart
final class EcgProcessResult {
  const EcgProcessResult({
    required this.signals,
    required this.info,
  });

  final EcgSignals signals;
  final EcgInfo info;
}
```

---

### 5. ECG Cleaning Implementations

Agent, NeuroKit2 `ecg_clean()` metodlarını ayrı strategy sınıfları olarak üretmelidir.

Hedef dosya yapısı:

```text
lib/src/ecg/cleaning/
├── ecg_cleaner.dart
├── neurokit_cleaner.dart
├── biosppy_cleaner.dart
├── pantompkins_cleaner.dart
├── hamilton_cleaner.dart
├── elgendi_cleaner.dart
├── engzee_cleaner.dart
└── visibility_graph_cleaner.dart
```

Ortak interface:

```dart
abstract interface class EcgCleaner {
  Float64List clean(
    Float64List signal, {
    required int samplingRate,
  });
}
```

Üretim kriterleri:

- Her temizleme yöntemi ayrı test dosyasına sahip olmalıdır.
- Filtre katsayıları ve cut-off değerleri kaynak fonksiyonla eşlenmelidir.
- Çok kısa sinyaller için deterministic hata veya fallback davranışı tanımlanmalıdır.
- Girdi sinyali mutate edilmemelidir.

---

### 6. R-Peak Detection Implementations

Agent, R-peak detection algoritmalarını strategy pattern ile üretmelidir.

Hedef dosya yapısı:

```text
lib/src/ecg/peaks/
├── r_peak_detector.dart
├── neurokit_r_peak_detector.dart
├── pantompkins_r_peak_detector.dart
├── hamilton_r_peak_detector.dart
├── christov_r_peak_detector.dart
├── elgendi_r_peak_detector.dart
├── engzee_r_peak_detector.dart
├── visibility_graph_r_peak_detector.dart
└── peak_correction.dart
```

Ortak result modeli:

```dart
final class RPeakDetectionResult {
  const RPeakDetectionResult({
    required this.rPeaks,
    required this.signals,
    this.metadata = const {},
  });

  final Int32List rPeaks;
  final Map<String, Float64List> signals;
  final Map<String, Object?> metadata;
}
```

Beklenen doğrulama:

- R-peak index karşılaştırması
- ±1 sample toleranslı eşleşme
- missed peak / extra peak raporu
- kısa ve gürültülü kayıt testleri
- sampling rate varyasyonları

---

### 7. DSP Utility Layer

Agent, NeuroKit2'nin sinyal işleme bağımlılıklarını Dart içinde merkezi bir DSP katmanı olarak üretmelidir.

Hedef dosya yapısı:

```text
lib/src/dsp/
├── filters.dart
├── butterworth.dart
├── filtfilt.dart
├── convolution.dart
├── interpolation.dart
├── smoothing.dart
├── resampling.dart
├── statistics.dart
└── windows.dart
```

Bu katman ECG dışındaki sinyal fonksiyonları tarafından da kullanılabilir olmalıdır.

Minimum utility set:

```text
mean
median
standard deviation
percentile
moving average
convolution
linear interpolation
finite checks
zero padding
edge padding
Butterworth coefficient generation
IIR apply
forward-backward filtering
```

DSP katmanı public API'ye doğrudan açılmamalıdır. Gerekirse `src` altında internal kalmalıdır.

---

### 8. Signal Utility Layer

NeuroKit2 ECG fonksiyonları birçok genel sinyal fonksiyonuna dayanır. Agent bu fonksiyonları ECG'den bağımsız üretmelidir.

Hedef dosya yapısı:

```text
lib/src/signal/
├── signal_sanitize.dart
├── signal_filter.dart
├── signal_findpeaks.dart
├── signal_rate.dart
├── signal_interpolate.dart
├── signal_smooth.dart
├── signal_period.dart
└── signal_formatpeaks.dart
```

Üretim kriterleri:

- ECG-specific logic bu katmana sızmamalıdır.
- Her utility fonksiyonu bağımsız testlenmelidir.
- NaN, Infinity ve boş input davranışı belgelenmelidir.
- Python eşdeğeri varsa mapping dosyasında gösterilmelidir.

---

### 9. Typed Data Models

Agent, pandas DataFrame ve dictionary tabanlı Python çıktılarını Dart typed modellerine çevirmelidir.

Hedef dosya yapısı:

```text
lib/src/models/
├── ecg_process_result.dart
├── ecg_signals.dart
├── ecg_info.dart
├── ecg_quality_result.dart
├── ecg_delineation_result.dart
├── ecg_phase_result.dart
├── peak_detection_result.dart
└── signal_rate_result.dart
```

Model kuralları:

- Modeller immutable olmalıdır.
- Constructor parametreleri `required` kullanılmalıdır.
- Büyük sinyal dizileri kopyalanırken maliyet açık değerlendirilmelidir.
- `toJson()` yalnızca fixture/debug için gerekiyorsa eklenmelidir.
- Üretim API'sinde `dynamic` kullanılmamalıdır.

---

### 10. Golden Test Fixtures

Agent, NeuroKit2 Python çıktılarından üretilmiş fixture dosyaları hazırlamalıdır.

Hedef dizin:

```text
test/fixtures/
├── raw/
├── neurokit_outputs/
├── dart_expected/
└── metadata/
```

Fixture formatı JSON olmalıdır:

```json
{
  "name": "clean_neurokit_1000hz_10s",
  "samplingRate": 1000,
  "source": "NeuroKit2 reference output",
  "inputLength": 10000,
  "absoluteTolerance": 1e-8,
  "relativeTolerance": 1e-6,
  "input": [0.0, 0.1],
  "expected": [0.0, 0.08]
}
```

Büyük sinyaller için JSON yerine sıkıştırılmış fixture kullanılabilir. Bu durumda loader ve checksum üretilmelidir.

---

### 11. Test Suite

Agent en az aşağıdaki test gruplarını üretmelidir:

```text
test/ecg/ecg_clean_test.dart
test/ecg/ecg_peaks_test.dart
test/ecg/ecg_rate_test.dart
test/ecg/ecg_quality_test.dart
test/ecg/ecg_delineate_test.dart
test/ecg/ecg_phase_test.dart
test/ecg/ecg_processor_test.dart
test/dsp/filters_test.dart
test/dsp/filtfilt_test.dart
test/signal/signal_findpeaks_test.dart
test/signal/signal_rate_test.dart
test/models/model_contract_test.dart
```

Test türleri:

```text
unit tests
golden reference tests
edge-case tests
property-like randomized tests
performance smoke tests
API contract tests
```

Minimum kalite eşiği:

```text
core ECG line coverage >= 85%
DSP utility line coverage >= 90%
all public API methods covered
all fixtures checksum validated
```

---

### 12. Python Reference Comparison Tool

Agent, Dart çıktısını NeuroKit2 referans çıktılarıyla kıyaslayan yardımcı araç üretmelidir.

Hedef dosyalar:

```text
tool/compare_with_neurokit.py
tool/generate_fixtures.py
tool/fixture_manifest.json
```

Araç görevleri:

- Python tarafında NeuroKit2 çıktısı üretmek
- Dart test fixture formatına dönüştürmek
- Tolerans değerlerini fixture içine yazmak
- Peak index farklarını raporlamak
- Sinyal uzunluğu, sampling rate ve method bilgisini kaydetmek

Çıktı manifest örneği:

```json
{
  "fixtures": [
    {
      "name": "ecg_clean_neurokit_1000hz",
      "function": "ecg_clean",
      "method": "neurokit",
      "samplingRate": 1000,
      "checksum": "sha256:...",
      "createdWith": "neurokit2"
    }
  ]
}
```

---

### 13. Documentation Artifacts

Agent aşağıdaki dokümantasyon dosyalarını üretmelidir:

```text
docs/
├── architecture.md
├── algorithm_mapping.md
├── numerical_validation.md
├── api_design.md
├── testing_strategy.md
├── limitations.md
├── migration_from_neurokit.md
└── medical_disclaimer.md
```

Dokümantasyon ilkeleri:

- Her public fonksiyon için örnek kullanım verilmelidir.
- Her algoritma için kaynak NeuroKit2 fonksiyonu belirtilmelidir.
- Bilinen sapmalar açık yazılmalıdır.
- Klinik kullanım sınırı net belirtilmelidir.
- Dart API ile Python API farkları saklanmamalıdır.

---

### 14. Performance Benchmark Artifacts

Agent, temel performans ölçüm altyapısı üretmelidir.

Hedef dosya yapısı:

```text
benchmark/
├── benchmark_clean.dart
├── benchmark_peaks.dart
├── benchmark_process.dart
└── benchmark_report.md
```

Benchmark senaryoları:

```text
10 saniye ECG, 250 Hz
10 saniye ECG, 1000 Hz
60 saniye ECG, 250 Hz
5 dakika ECG, 250 Hz
noise-heavy synthetic ECG
short invalid ECG
```

Rapor metrikleri:

```text
runtime milliseconds
allocation estimate
input length
sampling rate
method
machine/runtime info
```

Performans hedefi, önce doğruluk sonra hız olmalıdır. Optimize edilmemiş ama doğru çalışan referans implementasyon kabul edilebilir; optimize sürüm ayrı iş olarak etiketlenmelidir.

---

### 15. Error and Warning Artifacts

Agent, hata ve uyarı modelini üretmelidir.

Hedef dosyalar:

```text
lib/src/utils/ecg_exceptions.dart
lib/src/utils/warnings.dart
```

Önerilen hata tipleri:

```dart
final class InvalidSamplingRateException implements Exception {}
final class SignalTooShortException implements Exception {}
final class NonFiniteSignalException implements Exception {}
final class UnsupportedEcgMethodException implements Exception {}
final class NumericalInstabilityException implements Exception {}
```

Kurallar:

- Sessiz başarısızlık olmamalıdır.
- Hata mesajları input parametrelerini ve beklenen sınırı içermelidir.
- Klinik yorum içeren uyarı verilmemelidir.
- Sayısal fallback kullanılırsa result metadata içinde işaretlenmelidir.

---

## Teslimat Paketleri

### Minimum Viable Port

İlk çalışabilir teslimat:

```text
EcgClean.clean
EcgPeaks.find
EcgRate.compute
EcgProcessor.process minimal pipeline
basic DSP filters
reference fixtures
unit tests
README example
```

### Full ECG Port

Tam teslimat:

```text
all cleaning methods
all supported peak detectors
ecg_quality
ecg_delineate
ecg_phase
ecg_segment
ecg_simulate
full fixture set
algorithm mapping docs
benchmark report
limitations docs
```

### Production Release Candidate

Yayın adayı:

```text
pubspec ready
API docs complete
coverage thresholds passed
CI green
no analyzer warnings
numerical validation report complete
known deviations documented
semantic version assigned
```

---

## Artifact Acceptance Checklist

Her üretim çıktısı için kontrol listesi:

```text
[ ] Dart analyzer hatasız
[ ] dart format uygulanmış
[ ] unit test mevcut
[ ] NeuroKit2 mapping mevcut
[ ] edge-case davranışı belgelenmiş
[ ] fixture varsa checksum mevcut
[ ] public API ise README örneği mevcut
[ ] tıbbi teşhis iddiası içermiyor
[ ] performans veya doğruluk sınırlaması varsa yazılmış
```

---

## Artifact Öncelik Sırası

Agent işleri şu sırada üretmelidir:

```text
1. architecture and mapping docs
2. package skeleton
3. core DSP utilities
4. signal utilities
5. ecg_clean
6. ecg_peaks
7. ecg_rate
8. minimal ecg_process
9. fixtures and golden tests
10. quality, delineation, phase
11. benchmarks
12. release documentation
```

Bu sıra bozulursa agent gerekçeyi `handoff.md` veya ilgili iş raporunda açıkça yazmalıdır.

---

## Non-Artifact Sayılacak Çıktılar

Aşağıdakiler üretim artifact'ı sayılmaz:

```text
tek seferlik sohbet cevabı
kaynak göstermeyen algoritma özeti
çalıştırılmamış pseudo-code
fixture'sız doğruluk iddiası
klinik yorum
manuel test ekran görüntüsü
```

Bu tür çıktılar yalnızca yardımcı not olarak kabul edilir; teslimat kapsamını tamamlamaz.
