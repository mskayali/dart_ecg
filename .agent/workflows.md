# workflows.md

## Amaç

Bu dosya, NeuroKit2 ECG işleme katmanının Dart kütüphanesine port edilmesi için agent'ın takip edeceği operasyonel workflow'ları tanımlar.

Workflow'lar; kaynak analizinden Dart implementasyonuna, sayısal doğrulamadan release hazırlığına kadar tüm üretim hattını kapsar. Her workflow tek başına çalıştırılabilir olmalı, fakat ana port sürecinde birbirine bağlı şekilde ilerlemelidir.

---

## Global Workflow İlkeleri

Agent her workflow'da aşağıdaki temel ilkeleri uygular:

1. **Kaynak sabitleme:** Her analiz ve port işlemi belirli bir NeuroKit commit hash'i üzerinden yapılır.
2. **Algoritmik izlenebilirlik:** Her Dart fonksiyonu ilgili Python fonksiyonu, helper fonksiyonu ve test fixture'ı ile eşlenir.
3. **Davranış uyumluluğu:** Dart çıktısı, Python çıktısına belirlenen toleranslar içinde yakın olmalıdır.
4. **Dart-native tasarım:** Python veri yapıları kör biçimde taşınmaz; Dart için kararlı, null-safe, immutable API tasarlanır.
5. **Medikal sınır:** Çıktılar klinik teşhis, tedavi önerisi veya hasta değerlendirmesi gibi sunulmaz.
6. **Test önce yaklaşımı:** Kompleks algoritmalar port edilmeden önce Python fixture ve beklenen çıktı üretilir.
7. **Kademeli teslim:** Her fonksiyon ailesi ayrı analiz, implementasyon, validasyon ve review döngüsünden geçer.

---

## Workflow 1 — Upstream Source Intake

### Hedef

NeuroKit2 ECG kaynak kodunun port edilecek sürümünü sabitlemek ve analiz edilebilir hale getirmek.

### Input

```text
UPSTREAM_REPO=https://github.com/neuropsychology/NeuroKit
UPSTREAM_COMMIT=<full_commit_hash>
UPSTREAM_ECG_PATH=neurokit2/ecg/
UPSTREAM_SIGNAL_PATH=neurokit2/signal/
```

### Adımlar

1. NeuroKit repository'sini belirtilen commit ile klonla.
2. `neurokit2/ecg/` klasöründeki tüm dosyaları listele.
3. ECG fonksiyonlarının `signal`, `stats`, `misc`, `epochs` ve diğer NeuroKit alt modülleriyle bağımlılıklarını çıkar.
4. Her Python dosyası için şu alanları belgeleyen source map üret:
   - Public functions
   - Internal helper functions
   - Default parameters
   - Return shape
   - Warning/exception behavior
   - External dependency usage
   - Test fixture ihtiyacı
5. Commit hash, branch/tag, doküman versiyonu ve analiz tarihiyle baseline kaydı oluştur.

### Output

```text
docs/source_maps/ecg_source_inventory.md
docs/source_maps/ecg_dependency_graph.md
docs/source_maps/upstream_baseline.json
```

### Acceptance Criteria

- Her ECG Python dosyası envantere girmiştir.
- Her public fonksiyon için en az bir Dart hedef dosyası atanmıştır.
- Commit hash olmadan workflow tamamlanmış sayılmaz.

---

## Workflow 2 — Function Classification

### Hedef

ECG modülündeki fonksiyonları port önceliği, algoritmik risk ve bağımlılık ağırlığına göre sınıflandırmak.

### Fonksiyon Grupları

```text
Core pipeline:
  ecg_process
  ecg_clean
  ecg_peaks
  ecg_findpeaks
  ecg_rate

Morphology and phase:
  ecg_delineate
  ecg_phase
  ecg_segment

Quality and validation:
  ecg_quality
  ecg_invert

Simulation and fixtures:
  ecg_simulate

Non-core or optional:
  ecg_plot
  ecg_analyze
  ecg_eventrelated
  ecg_intervalrelated
  ecg_rsp
```

### Risk Sınıfları

| Risk | Kriter | Örnek |
|---|---|---|
| Low | Basit veri dönüşümü veya wrapper | `ecg_rate` |
| Medium | DSP filtreleri, peak listesi, interpolation | `ecg_clean`, `ecg_segment` |
| High | Çoklu algoritma varyantı, morphology inference | `ecg_peaks`, `ecg_delineate` |
| Optional | Plotting, raporlama, araştırma workflow'u | `ecg_plot`, `ecg_analyze` |

### Output

```text
docs/planning/ecg_function_classification.md
docs/planning/port_priority_matrix.md
```

### Acceptance Criteria

- Her fonksiyon bir risk sınıfına atanmıştır.
- Her fonksiyon için `port`, `defer`, `drop`, `replace`, `manual-review` kararlarından biri verilmiştir.
- Gerekçesiz karar kabul edilmez.

---

## Workflow 3 — API Design Workflow

### Hedef

Dart tarafında stabil, anlaşılır ve üretime uygun public API tasarlamak.

### Ana API Hedefi

```dart
final result = EcgProcessor.process(
  signal: samples,
  samplingRate: 1000,
  method: EcgMethod.neurokit,
);
```

### Adımlar

1. Python fonksiyon imzalarını çıkar.
2. Python parametrelerini Dart tiplerine eşle:
   - `array-like` → `List<double>` public input, internal `Float64List`
   - `sampling_rate` → `int samplingRate`
   - `method` → `EcgMethod enum`
   - `show`, plotting flags → core pakette desteklenmez veya debug-only yapılır
   - `kwargs` → typed options modeline ayrılır
3. Return modellerini tasarla:
   - `EcgProcessResult`
   - `EcgSignals`
   - `EcgInfo`
   - `EcgPeaksResult`
   - `EcgDelineationResult`
   - `EcgQualityResult`
4. Nullable alanları minimumda tut.
5. Hata durumları için typed exception sınıfları üret.
6. Public API export listesini sabitle.

### Output

```text
docs/api/ecg_public_api.md
lib/neurokit_ecg.dart
lib/src/models/*.dart
```

### Acceptance Criteria

- Public API Python'a aşırı bağımlı görünmez.
- Her model için `toString`, equality ve test kapsamı vardır.
- `dynamic`, gevşek `Map<String, dynamic>` ve magic string kullanımı public API'de minimumdur.

---

## Workflow 4 — DSP Primitive Port Workflow

### Hedef

ECG fonksiyonlarının ihtiyaç duyduğu genel sinyal işleme primitive'lerini Dart'a taşımak.

### Kapsam

```text
signal_filter
signal_smooth
signal_rate
signal_interpolate
signal_resample
signal_zerocrossings
signal_findpeaks
signal_fixpeaks
standardize
as_vector
```

### Adımlar

1. ECG tarafından doğrudan kullanılan signal helper'larını belirle.
2. SciPy/NumPy bağımlı bölümleri çıkar.
3. Dart DSP karşılıklarını tasarla:
   - FIR/IIR filtre yapıları
   - Butterworth coefficient üretimi
   - Forward-backward filtering gerekiyorsa `filtfilt` eşdeğeri
   - Convolution
   - Moving average / median smoothing
   - Peak search
   - Interpolation
4. Her primitive için Python fixture üret.
5. Dart primitive'i fixture ile karşılaştır.
6. Performans hassas fonksiyonları `Float64List` ile optimize et.

### Output

```text
lib/src/dsp/*.dart
lib/src/signal/*.dart
test/dsp/*_test.dart
test/signal/*_test.dart
test/fixtures/signal/*.json
```

### Acceptance Criteria

- ECG core fonksiyonları genel DSP logic'i tekrar yazmaz.
- Primitive fonksiyonlar bağımsız test edilebilir.
- Tolerans değerleri fixture metadata içinde kayıtlıdır.

---

## Workflow 5 — `ecg_clean` Port Workflow

### Hedef

NeuroKit2 ECG temizleme yöntemlerini Dart'ta kademeli ve test edilebilir şekilde port etmek.

### Desteklenecek Yöntemler

İlk faz:

```text
neurokit
biosppy
pantompkins1985
hamilton2002
elgendi2010
engzeemod2012
```

Sonraki faz / opsiyonel:

```text
vg
emrich2023
templateconvolution
```

### Adımlar

1. Her method için Python source map çıkar.
2. Filtre zincirlerini sampling rate'e göre ayrıştır.
3. Her filtre için katsayı üretim mantığını belirle.
4. Dart `EcgCleaner.clean()` API'sini uygula.
5. Python fixture üret:
   - sentetik temiz ECG
   - baseline wander içeren ECG
   - powerline noise içeren ECG
   - düşük sampling rate
   - kısa sinyal
   - NaN/Inf içeren sinyal
6. Dart çıktısını fixture ile karşılaştır.
7. Yöntem bazlı toleransları belgeye ekle.

### Output

```text
lib/src/ecg/ecg_clean.dart
lib/src/ecg/cleaning/*.dart
test/ecg/ecg_clean_test.dart
test/fixtures/ecg_clean/*.json
```

### Acceptance Criteria

- Her method için ayrı test bloğu vardır.
- Unsupported method açık exception üretir.
- Kısa sinyal ve geçersiz sampling rate deterministik hata verir.

---

## Workflow 6 — R-Peak Detection Port Workflow

### Hedef

`ecg_peaks` ve `ecg_findpeaks` fonksiyon ailesini Dart'a taşımak.

### Kapsam

```text
ecg_peaks
ecg_findpeaks
correct_artifacts
Lipponen-Tarvainen artifact correction
method-specific peak detectors
```

### Adımlar

1. Peak detection yöntemlerini listele.
2. Her yöntemin preprocessing bağımlılığını çıkar.
3. Threshold, refractory period, search window ve local maxima kurallarını belgeye işle.
4. R-peak indexlerinin sample index olarak döneceğini sabitle.
5. Python fixture üret:
   - normal rhythm
   - noisy rhythm
   - missing beat
   - ectopic-like interval pattern
   - short segment
   - low amplitude ECG
6. Dart detector implementasyonlarını method bazında ayır.
7. Artifact correction opsiyonunu ayrı modül yap.
8. Index toleransı ve event-level precision/recall metriğiyle test et.

### Output

```text
lib/src/ecg/ecg_peaks.dart
lib/src/ecg/ecg_findpeaks.dart
lib/src/ecg/peaks/*.dart
test/ecg/ecg_peaks_test.dart
test/fixtures/ecg_peaks/*.json
```

### Acceptance Criteria

- R-peak indexleri integer sample index olarak döner.
- Python fixture ile index farkı kabul edilen tolerans içindedir.
- Artifact correction açık/kapalı test edilir.
- Peak detector plotting bağımlılığı içermez.

---

## Workflow 7 — Rate and Phase Port Workflow

### Hedef

R-peak dizilerinden heart rate ve cardiac phase sinyallerini üretmek.

### Kapsam

```text
signal_rate
ecg_rate
ecg_phase
```

### Adımlar

1. R-peak indexlerini RR interval dizisine dönüştür.
2. BPM hesaplama mantığını uygula.
3. Interpolation yöntemini Python ile eşleştir.
4. Phase hesaplaması için atrial/ventricular faz ayrımını belgeye işle.
5. Beat boundary ve missing peak davranışlarını test et.
6. Output sinyal uzunluğunu input sinyal uzunluğuyla hizala.

### Output

```text
lib/src/ecg/ecg_rate.dart
lib/src/ecg/ecg_phase.dart
test/ecg/ecg_rate_test.dart
test/ecg/ecg_phase_test.dart
```

### Acceptance Criteria

- Rate output uzunluğu beklenen formata uyar.
- Phase sinyalleri `0..1` aralığında normalize edilir veya NeuroKit uyumu gereği belgelenmiş formatta döner.
- Boş veya yetersiz peak listesi deterministik hata veya boş sonuç üretir; davranış dokümante edilir.

---

## Workflow 8 — Delineation Port Workflow

### Hedef

ECG morphology işaretlerini Dart tarafında üretmek.

### Kapsam

```text
ecg_delineate
P peaks
Q peaks
R peaks
S peaks
T peaks
P onset / offset
QRS onset / offset
T onset / offset
```

### Adımlar

1. NeuroKit delineation method'larını listele.
2. Wavelet, derivative, prominence ve peak-search tabanlı alt adımları ayır.
3. R-peak bağımlılığını açıkça modelle.
4. Her marker için sample index sözleşmesi belirle.
5. Eksik marker davranışını tanımla:
   - `null`
   - `-1`
   - empty list
   - nullable typed field
6. Python fixture üret.
7. Dart result modelini uygula.
8. Event-level tolerance ile doğrula.

### Output

```text
lib/src/ecg/ecg_delineate.dart
lib/src/ecg/delineation/*.dart
lib/src/models/ecg_delineation_result.dart
test/ecg/ecg_delineate_test.dart
```

### Acceptance Criteria

- R-peak inputu olmayan delineation çalıştırılamaz.
- Eksik dalga işaretleri sessizce yanlış index üretmez.
- Her morphology alanının birimi sample index olarak belgelenir.

---

## Workflow 9 — Quality Assessment Port Workflow

### Hedef

`ecg_quality` çıktısını Dart'ta üretmek ve sinyal kalitesi değerlendirme metriklerini port etmek.

### Adımlar

1. NeuroKit kalite yöntemlerini kaynak koda göre sınıflandır.
2. Quality score aralığını ve yorumunu belgeye işle.
3. Gerekli peak, cleaned signal ve template bağımlılıklarını çıkar.
4. Dart result modelini tasarla.
5. Gürültü seviyesine göre fixture üret.
6. Python-Dart skor farkını toleransla karşılaştır.

### Output

```text
lib/src/ecg/ecg_quality.dart
lib/src/models/ecg_quality_result.dart
test/ecg/ecg_quality_test.dart
```

### Acceptance Criteria

- Score range ve anlamı API dokümantasyonunda açıktır.
- Quality output klinik tanı gibi sunulmaz.
- Gürültü artışıyla kalite metriği beklenen yönde değişir.

---

## Workflow 10 — Full Pipeline Port Workflow

### Hedef

`ecg_process` fonksiyonunun Dart karşılığını üretmek.

### Beklenen Pipeline

```text
raw signal
  -> validate input
  -> clean signal
  -> detect R-peaks
  -> compute heart rate
  -> compute quality
  -> delineate morphology
  -> compute cardiac phase
  -> return EcgProcessResult
```

### Adımlar

1. Alt modüller tamamlanmadan full pipeline implementasyonuna başlanmaz.
2. `EcgProcessor.process()` orchestrator olarak yazılır.
3. Yan etkisiz ve deterministik olmalıdır.
4. Debug metadata opsiyonel tutulur.
5. Python `ecg_process()` fixture'ı ile tam çıktı karşılaştırılır.
6. Büyük sinyal performansı ölçülür.

### Output

```text
lib/src/ecg/ecg_processor.dart
lib/src/models/ecg_process_result.dart
test/ecg/ecg_process_test.dart
benchmark/ecg_process_benchmark.dart
```

### Acceptance Criteria

- Pipeline tek çağrıyla çalışır.
- Alt modüller ayrı ayrı test edilebilir kalır.
- Pipeline hataları typed exception olarak yükseltilir.
- Output modeli stabil public API içindedir.

---

## Workflow 11 — Fixture Generation Workflow

### Hedef

Python NeuroKit2 ve Dart sonuçlarını karşılaştırmak için tekrarlanabilir fixture setleri üretmek.

### Adımlar

1. Fixture üretim scriptini Python tarafında hazırla.
2. NeuroKit versiyonunu ve commit hash'i fixture metadata içine yaz.
3. Random seed kullan.
4. Her fixture için input, params, expected output ve tolerans alanlarını kaydet.
5. Büyük fixture dosyalarını sıkıştır veya parçalara ayır.
6. Dart test runner'ın okuyacağı JSON formatını sabitle.

### Fixture Formatı

```json
{
  "name": "ecg_clean_neurokit_250hz_noise_02",
  "upstream_commit": "<full_commit_hash>",
  "function": "ecg_clean",
  "params": {
    "sampling_rate": 250,
    "method": "neurokit"
  },
  "input": {
    "signal": []
  },
  "expected": {
    "cleaned": []
  },
  "tolerance": {
    "absolute": 1e-6,
    "relative": 1e-5
  }
}
```

### Output

```text
tool/generate_fixtures.py
test/fixtures/**/*.json
docs/testing/fixture_manifest.md
```

### Acceptance Criteria

- Fixture tekrar üretildiğinde metadata aynı kalır.
- Random fixture'lar seed ile deterministiktir.
- Her fixture bir NeuroKit commit hash'ine bağlıdır.

---

## Workflow 12 — Numerical Validation Workflow

### Hedef

Dart çıktısının Python NeuroKit2 çıktısına sayısal olarak yakınlığını ölçmek.

### Metrikler

```text
max_absolute_error
mean_absolute_error
root_mean_squared_error
relative_error
index_distance
precision
recall
f1_score
```

### Adımlar

1. Dart test çıktısını JSON olarak üret.
2. Python expected fixture ile karşılaştır.
3. Continuous signal çıktıları için hata metriklerini hesapla.
4. Peak/index çıktıları için event-level eşleştirme yap.
5. Toleransı aşan alanları raporla.
6. Kırılan fixture için upstream source, Dart source ve test dosyasına link ver.

### Output

```text
tool/compare_with_neurokit.py
docs/testing/numerical_validation_report.md
```

### Acceptance Criteria

- Validation raporu otomatik üretilebilir.
- Tolerans aşımı merge blocker kabul edilir.
- Bilerek farklılaştırılan davranışlar `known_deviations.md` içinde açıklanır.

---

## Workflow 13 — Edge Case and Error Workflow

### Hedef

Kısa sinyal, hatalı input, NaN/Inf ve sampling rate problemleri için deterministik davranış oluşturmak.

### Test Edilecek Durumlar

```text
empty signal
single-sample signal
very short ECG segment
negative sampling rate
zero sampling rate
NaN values
Infinity values
constant signal
all-zero signal
very low amplitude signal
very high amplitude signal
irregular peak intervals
```

### Adımlar

1. Her fonksiyon için minimum input uzunluğunu belirle.
2. Input validation helper'larını merkezi hale getir.
3. Exception sınıflarını tanımla:
   - `EcgInputException`
   - `EcgSamplingRateException`
   - `EcgProcessingException`
   - `EcgUnsupportedMethodException`
4. Hata mesajlarını teknik ve kısa tut.
5. Edge-case fixture'ları üret.
6. Testlerde exception type ve mesajı doğrula.

### Output

```text
lib/src/utils/input_validation.dart
lib/src/models/ecg_exceptions.dart
test/ecg/ecg_edge_cases_test.dart
```

### Acceptance Criteria

- Hatalı input sessizce yanlış sonuç üretmez.
- Hata mesajları medikal yorum içermez.
- Public API exception davranışı dokümante edilir.

---

## Workflow 14 — Performance Workflow

### Hedef

Dart implementasyonunun mobil, server ve CLI kullanımına uygun performans profiline sahip olmasını sağlamak.

### Adımlar

1. Baseline benchmark senaryolarını oluştur:
   - 10 saniye, 250 Hz
   - 60 saniye, 250 Hz
   - 5 dakika, 250 Hz
   - 10 saniye, 1000 Hz
   - 12-lead batch senaryosu opsiyonel
2. CPU ve memory ölçümleri al.
3. `List<double>` ve `Float64List` farkını ölç.
4. Gereksiz allocation noktalarını tespit et.
5. Hot path fonksiyonları optimize et.
6. Çok pahalı algoritmalar için FFI veya isolate seçeneğini değerlendir.

### Output

```text
benchmark/*.dart
docs/performance/performance_report.md
```

### Acceptance Criteria

- Benchmark sonuçları release öncesi güncellenmiştir.
- Performance regression CI tarafından yakalanabilir.
- Optimize edilen kod test davranışını değiştirmez.

---

## Workflow 15 — Documentation Workflow

### Hedef

Dart paketinin kullanılabilir, denetlenebilir ve bakım yapılabilir dokümantasyonunu üretmek.

### Doküman Seti

```text
README.md
API_REFERENCE.md
MIGRATION_FROM_NEUROKIT.md
KNOWN_DEVIATIONS.md
ALGORITHM_MAPPING.md
TESTING.md
PERFORMANCE.md
SAFETY_AND_LIMITATIONS.md
```

### Adımlar

1. Her public fonksiyon için kısa kullanım örneği yaz.
2. Python NeuroKit karşılığını belirt.
3. Parametre eşlemesini tablo halinde ver.
4. Bilerek farklılaştırılan davranışları açıkla.
5. Medikal sınırlamaları ayrı bölümde belirt.
6. Fixture ve tolerans stratejisini dokümante et.

### Output

```text
docs/**/*.md
README.md
```

### Acceptance Criteria

- Kullanıcı tek README ile temel pipeline'ı çalıştırabilir.
- Geliştirici API mapping dokümanından kaynak fonksiyona geri dönebilir.
- Bilinen sapmalar gizlenmez.

---

## Workflow 16 — CI and Release Workflow

### Hedef

Paketin her değişiklikte otomatik test edilmesi, analiz edilmesi ve release için hazırlanması.

### CI Aşamaları

```text
format check
static analysis
unit tests
fixture tests
numerical validation
benchmark smoke test
documentation link check
package dry-run
```

### Adımlar

1. GitHub Actions workflow dosyası oluştur.
2. Dart stable SDK ile test et.
3. Platform bağımsız testler yaz.
4. Fixture dosyalarını CI'da doğrula.
5. `dart pub publish --dry-run` çalıştır.
6. Release tag formatını belirle.

### Output

```text
.github/workflows/dart.yml
.github/workflows/numerical-validation.yml
CHANGELOG.md
```

### Acceptance Criteria

- Ana branch'e kırık test merge edilemez.
- Release öncesi dry-run başarılıdır.
- Version bump ve changelog zorunludur.

---

## Workflow 17 — Review Workflow

### Hedef

Kod, algoritma, test ve dokümantasyon kalitesini merge öncesinde denetlemek.

### Review Kontrol Listesi

```text
[ ] Upstream commit hash belirtilmiş
[ ] Python fonksiyonu ile Dart fonksiyonu eşlenmiş
[ ] Fixture eklenmiş
[ ] Tolerans belgelenmiş
[ ] Edge-case testleri var
[ ] Public API stable
[ ] Medikal iddia yok
[ ] Performance etkisi değerlendirilmiş
[ ] Known deviation varsa kayıtlı
```

### Roller

```text
Source Reviewer
DSP Reviewer
Dart Reviewer
Test Reviewer
Release Reviewer
```

### Acceptance Criteria

- High-risk fonksiyonlarda en az iki review gerekir.
- Test fixture olmadan algoritmik port kabul edilmez.
- Belirsiz davranışlar issue olarak kayıt altına alınır.

---

## Workflow 18 — Issue Triage Workflow

### Hedef

Port sırasında çıkan hataları, belirsizlikleri ve upstream farklarını yönetmek.

### Issue Tipleri

```text
bug
numerical-mismatch
api-design
performance
upstream-ambiguity
unsupported-method
known-deviation
documentation
```

### Adımlar

1. Issue tipini belirle.
2. İlgili upstream fonksiyon ve commit hash'i ekle.
3. Reproduction fixture oluştur.
4. Expected vs actual çıktı ekle.
5. Risk seviyesini ata.
6. Fix, defer veya document kararı ver.

### Acceptance Criteria

- Numerical mismatch issue'su fixture olmadan kapatılamaz.
- Unsupported method public API'de sessizce yok sayılamaz.
- Upstream belirsizliği dokümante edilmeden geçilemez.

---

## Workflow 19 — Optional FFI Workflow

### Hedef

Saf Dart ile performans veya algoritmik uyumluluk sağlanamayan sınırlı alanlarda opsiyonel native hızlandırma stratejisini değerlendirmek.

### Kullanım Şartları

FFI yalnızca aşağıdaki durumlarda değerlendirilir:

```text
large batch processing
expensive wavelet operations
high-order filtering bottlenecks
mobile real-time constraints
```

### Kurallar

1. Core paket saf Dart kalır.
2. FFI ayrı paket veya opsiyonel backend olur.
3. Public API FFI backend'e bağımlı hale gelmez.
4. Saf Dart fallback zorunludur.
5. FFI numerical output fixture ile doğrulanır.

### Output

```text
docs/architecture/ffi_strategy.md
packages/neurokit_ecg_native/    # opsiyonel
```

### Acceptance Criteria

- FFI olmadan paket kullanılabilir.
- FFI backend API davranışını değiştirmez.
- Platform desteği açıkça belirtilir.

---

## Workflow 20 — Final Release Readiness Workflow

### Hedef

Dart ECG paketinin üretim/release için hazır olup olmadığını belirlemek.

### Release Checklist

```text
[ ] All core ECG functions implemented or explicitly deferred
[ ] Public API frozen for current release
[ ] Numerical validation report passed
[ ] Known deviations documented
[ ] Edge-case tests passed
[ ] CI green
[ ] README examples tested
[ ] Package dry-run passed
[ ] License compatibility reviewed
[ ] Safety limitations documented
[ ] Changelog updated
[ ] Version tag prepared
```

### Release Kararları

```text
release-ready
release-blocked
release-with-known-deviations
internal-preview-only
```

### Acceptance Criteria

- Release kararı tek satırlık karar değil, evidence-backed raporla verilir.
- Core pipeline çalışmıyorsa public release yapılmaz.
- Bilinen sapmalar kullanıcıya açıkça sunulur.

---

## Önerilen Sprint Sıralaması

### Sprint 1 — Baseline and Architecture

```text
source intake
function classification
API design
package skeleton
DSP primitive inventory
```

### Sprint 2 — Core Signal Helpers

```text
filtering
smoothing
interpolation
rate calculation
fixture generation infrastructure
```

### Sprint 3 — Cleaning

```text
ecg_clean neurokit
cleaning method variants
edge cases
fixture validation
```

### Sprint 4 — R-Peaks

```text
ecg_findpeaks
ecg_peaks
artifact correction
peak validation metrics
```

### Sprint 5 — Pipeline

```text
ecg_process
rate integration
quality initial support
full pipeline fixtures
```

### Sprint 6 — Morphology

```text
ecg_delineate
ecg_phase
ecg_segment
known deviations
```

### Sprint 7 — Hardening and Release

```text
performance
CI
API documentation
release readiness
pub.dev dry-run
```

---

## Agent Execution Contract

Agent bir workflow'u çalıştırırken şu formatta ilerleme kaydı üretmelidir:

```text
WORKFLOW=<workflow_name>
UPSTREAM_COMMIT=<hash>
TARGET_MODULE=<dart_module>
STATUS=<not_started|in_progress|blocked|done>
BLOCKERS=<list>
ARTIFACTS=<list>
TESTS=<list>
KNOWN_DEVIATIONS=<list>
NEXT_ACTION=<single_next_action>
```

Her workflow sonunda aşağıdaki sorular cevaplanmalıdır:

1. Hangi upstream davranışı port edildi?
2. Hangi Dart dosyaları değişti?
3. Hangi fixture'lar eklendi?
4. Sayısal fark var mı?
5. Public API değişti mi?
6. Known deviation oluştu mu?
7. Bir sonraki güvenli adım nedir?
