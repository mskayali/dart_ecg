# agent.md

## Amaç

Bu dosya, `neurokit_ecg_dart_agent` dokümantasyon setinin ana kontrol dosyasıdır. Agent'ın hangi dosyayı ne zaman okuyacağını, hangi çıktıyı hangi kurala göre üreteceğini, dosyalar arası öncelik sırasını ve NeuroKit2 ECG işleme katmanının Dart kütüphanesine port edilmesi sırasında uygulanacak genel çalışma protokolünü tanımlar.

Bu dosya tek başına teknik implementasyon dokümanı değildir. Görevi, diğer `.md` dosyalarını yöneten üst seviye orchestration katmanı olmaktır.

---

## Kapsam

Agent aşağıdaki hedef için çalışır:

> NeuroKit2 içindeki ECG işleme fonksiyonlarını, algoritmik davranışı korunacak şekilde Dart ekosistemine taşımak; üretilebilir, test edilebilir, dokümante edilebilir ve sürdürülebilir bir Dart paketi altyapısı oluşturmak.

Ana kapsam:

- ECG signal cleaning
- R-peak detection
- Heart rate hesaplama
- ECG signal quality değerlendirme
- ECG delineation
- Cardiac phase çıkarımı
- ECG segmentation
- NeuroKit2 davranışıyla uyumlu test altyapısı
- Dart API tasarımı
- Üretim artefaktlarının yönetimi
- Agent workflow, rule ve handoff süreçlerinin standardizasyonu

Kapsam dışı:

- Klinik tanı motoru geliştirmek
- Tıbbi cihaz sertifikasyonu sağlamak
- Hasta bazlı medikal karar vermek
- NeuroKit2 dışındaki tüm biyosinyal modüllerini port etmek
- Python bağımlılığına runtime seviyesinde bağlı kalan bir Dart paketi üretmek

---

## Dokümantasyon Haritası

Agent aşağıdaki dosyaları yönetir:

```text
neurokit_ecg_dart_agent/
├── agent.md
├── README.md
├── skills.md
├── production_artifacts.md
├── handoff.md
├── workflows.md
├── rules.md
└── skill_references.md
```

### Dosya Rolleri

| Dosya | Rol | Ne zaman okunur |
|---|---|---|
| `agent.md` | Ana orchestration dosyası | Her görev başlangıcında |
| `README.md` | Proje amacı, kapsamı ve genel mimari | Yeni contributor veya agent onboarding sırasında |
| `skills.md` | Agent'ın sahip olması gereken teknik beceriler | Görev atama, agent seçimi, kalite kontrol sırasında |
| `production_artifacts.md` | Üretilecek somut çıktılar | Sprint planlama, teslimat, release hazırlığı sırasında |
| `handoff.md` | Agentlar/developerlar arası devir protokolü | Görev devri, inceleme, hata aktarımı sırasında |
| `workflows.md` | Operasyonel iş akışları | Implementasyon, test, review ve release sırasında |
| `rules.md` | Zorunlu teknik ve davranışsal kurallar | Her implementasyon ve review aşamasında |
| `skill_references.md` | Kaynaklar, referans beceriler ve doğrulama noktaları | Algoritma portu ve doğrulama sırasında |

---

## Dosya Öncelik Sırası

Çelişki durumunda agent aşağıdaki öncelik sırasını uygular:

1. `rules.md`
2. `agent.md`
3. `production_artifacts.md`
4. `workflows.md`
5. `handoff.md`
6. `skills.md`
7. `skill_references.md`
8. `README.md`

Açıklama:

- `rules.md` zorunlu davranış ve kalite sınırlarını tanımlar.
- `agent.md` orchestration kararlarını verir.
- `production_artifacts.md` teslim edilecek çıktıları sabitler.
- `workflows.md` işin nasıl yürütüleceğini belirler.
- `handoff.md` görev devri disiplinini belirler.
- `skills.md` agent yetkinliklerini tarif eder.
- `skill_references.md` öğrenme ve doğrulama referanslarını listeler.
- `README.md` genel bağlam sağlar.

---

## Agent Kimliği

### Agent Adı

`NeuroKit ECG Dart Port Agent`

### Temel Sorumluluk

NeuroKit2 ECG işleme katmanındaki algoritmaları Dart dilinde, deterministik, test edilebilir ve üretim ortamına hazırlanabilir şekilde yeniden tasarlamak ve port etmek.

### Çalışma Tarzı

Agent aşağıdaki prensiplerle çalışır:

- Kaynak davranışı önce anlar, sonra port eder.
- Algoritmayı birebir kopyalamadan önce matematiksel niyeti doğrular.
- Python/NumPy/SciPy davranışlarını Dart karşılıklarına açıkça map eder.
- Floating-point farklarını test toleranslarıyla yönetir.
- Her modül için ayrı API, test, benchmark ve dokümantasyon üretir.
- Büyük port işlemini küçük, doğrulanabilir parçalara böler.

---

## Ana Çalışma Döngüsü

Agent her görevde aşağıdaki döngüyü uygular:

```text
1. Görev bağlamını oku
2. İlgili md dosyalarını seç
3. NeuroKit2 kaynak davranışını incele
4. Dart hedef mimarisini belirle
5. Minimal implementasyon planı çıkar
6. Test fixture gereksinimlerini tanımla
7. Kod veya dokümantasyon üret
8. Referans davranışla karşılaştır
9. Hata/tolerans notlarını yaz
10. Handoff çıktısını hazırla
```

---

## Görev Tipleri

Agent aşağıdaki görev tiplerini destekler.

### 1. Source Analysis Task

NeuroKit2 içindeki ECG fonksiyonlarının davranışını analiz eder.

Beklenen çıktı:

- Fonksiyon davranış özeti
- Girdi/çıktı şeması
- Kullanılan algoritmalar
- Varsayılan parametreler
- Edge case listesi
- Dart port notları

Okunacak dosyalar:

- `agent.md`
- `rules.md`
- `skills.md`
- `skill_references.md`

---

### 2. Dart API Design Task

Dart paketindeki public API yüzeyini tasarlar.

Beklenen çıktı:

- Class/function isimleri
- Parametre modelleri
- Return type yapısı
- Error handling stratejisi
- Null-safety kararı
- Streaming/batch ayrımı

Okunacak dosyalar:

- `agent.md`
- `README.md`
- `production_artifacts.md`
- `rules.md`

---

### 3. Algorithm Port Task

NeuroKit2 algoritmasını Dart'a taşır.

Beklenen çıktı:

- Dart implementasyonu
- Unit testler
- Golden fixture karşılaştırması
- Floating-point tolerans açıklaması
- Performans notu

Okunacak dosyalar:

- `agent.md`
- `rules.md`
- `workflows.md`
- `production_artifacts.md`
- `skill_references.md`

---

### 4. Test Generation Task

Python referansı ve Dart çıktıları arasında karşılaştırmalı test altyapısı üretir.

Beklenen çıktı:

- Fixture formatı
- Test dataset listesi
- Expected output dosyaları
- Tolerans değerleri
- CI test komutları

Okunacak dosyalar:

- `agent.md`
- `production_artifacts.md`
- `workflows.md`
- `rules.md`

---

### 5. Documentation Task

Dart portunun kullanıcı ve geliştirici dokümantasyonunu üretir.

Beklenen çıktı:

- API usage örnekleri
- Algorithm notes
- Migration notes
- Limitations
- Validation notes

Okunacak dosyalar:

- `agent.md`
- `README.md`
- `production_artifacts.md`
- `rules.md`

---

### 6. Review Task

Üretilen kod, test veya dokümantasyonu inceler.

Beklenen çıktı:

- Pass/fail sonucu
- Kritik hatalar
- Uyumsuz davranışlar
- Test eksikleri
- Refactor önerileri
- Handoff notu

Okunacak dosyalar:

- `agent.md`
- `rules.md`
- `handoff.md`
- `workflows.md`

---

## ECG Modül Sınırları

Agent ECG portunu aşağıdaki modüllere böler:

```text
lib/src/ecg/
├── ecg_process.dart
├── ecg_clean.dart
├── ecg_peaks.dart
├── ecg_rate.dart
├── ecg_quality.dart
├── ecg_delineate.dart
├── ecg_phase.dart
├── ecg_segment.dart
├── models/
├── filters/
├── detectors/
├── interpolation/
└── utils/
```

### Modül Sorumlulukları

| Modül | Sorumluluk |
|---|---|
| `ecg_process.dart` | Uçtan uca ECG pipeline orchestration |
| `ecg_clean.dart` | Sinyal temizleme ve filtreleme |
| `ecg_peaks.dart` | R-peak tespiti ve peak düzeltme |
| `ecg_rate.dart` | Heart rate serisi üretimi |
| `ecg_quality.dart` | Sinyal kalite skoru |
| `ecg_delineate.dart` | P, Q, R, S, T dalga sınırları |
| `ecg_phase.dart` | Atrial/ventricular phase hesaplama |
| `ecg_segment.dart` | Beat-level segmentation |
| `models/` | Typed result modelleri |
| `filters/` | DSP filtre yardımcıları |
| `detectors/` | Peak detector algoritmaları |
| `interpolation/` | Resampling ve interpolation yardımcıları |
| `utils/` | Ortak matematik ve sinyal işleme yardımcıları |

---

## Zorunlu Kaynak Davranış İlkesi

Agent hiçbir ECG fonksiyonunu yalnızca isim benzerliğine göre port etmez.

Her fonksiyon için önce aşağıdaki bilgiler çıkarılır:

- Python fonksiyon adı
- Dosya yolu
- Public/private ayrımı
- Varsayılan parametreler
- Algoritma branch'leri
- Girdi validasyonları
- Çıktı kolonları veya veri yapısı
- Sampling rate etkileri
- Missing value davranışı
- Exception veya warning davranışı
- Test fixture gereksinimi

---

## Dart Port İlkeleri

### Dil ve Paket İlkeleri

- Dart 3 uyumluluğu hedeflenir.
- Null-safety zorunludur.
- Public API sade tutulur.
- Internal helper'lar `src/` altında tutulur.
- Runtime Python bağımlılığı kullanılmaz.
- Ağ bağlantısı gerektiren test yapılmaz.
- Deterministik sonuç üretimi önceliklidir.

### Numeric İlkeler

- Tüm sinyal serileri `List<double>` veya typed numeric abstraction ile temsil edilir.
- Gereksiz object allocation azaltılır.
- Büyük sinyaller için streaming veya chunking stratejisi ayrıca değerlendirilir.
- Floating-point karşılaştırmalarda mutlak ve göreli tolerans birlikte kullanılır.

### API İlkeleri

Örnek hedef API:

```dart
final result = EcgProcessor.process(
  signal: ecgSignal,
  samplingRate: 1000,
  options: const EcgProcessOptions(
    cleaningMethod: EcgCleaningMethod.neurokit,
    peakMethod: EcgPeakMethod.neurokit,
  ),
);
```

Beklenen sonuç modeli:

```dart
class EcgProcessResult {
  final List<double> cleaned;
  final List<int> rPeaks;
  final List<double> rate;
  final EcgQualityResult? quality;
  final EcgDelineationResult? delineation;
  final EcgPhaseResult? phase;
}
```

---

## Agent Karar Mekanizması

### Belirsiz Algoritma Davranışı

Eğer NeuroKit2 davranışı belirsizse:

1. Kaynak kodu incele.
2. Dokümantasyonla karşılaştır.
3. Python üzerinde küçük örnek fixture üret.
4. Davranışı test çıktısıyla sabitle.
5. Dart tarafında bu davranışı testle koru.
6. Belirsizliği handoff notuna yaz.

### Eksik Dart Karşılığı

Eğer SciPy/NumPy fonksiyonu için doğrudan Dart karşılığı yoksa:

1. Matematiksel fonksiyon tanımını çıkar.
2. Minimal saf Dart implementasyonunu planla.
3. Gerekirse internal DSP helper oluştur.
4. Python referans çıktısıyla karşılaştır.
5. Performans maliyetini not et.

### Performans Problemi

Eğer implementasyon yavaşsa:

1. Önce doğruluğu koru.
2. Benchmark ekle.
3. Allocation noktalarını belirle.
4. Algoritmik karmaşıklığı düşür.
5. Public API'yi bozmadan optimize et.

---

## Kalite Kapıları

Bir ECG modülü tamamlanmış sayılmaz; aşağıdaki koşullar sağlanmadan handoff yapılamaz:

- Public API tanımlı
- Internal helper'lar ayrılmış
- Unit test var
- Python reference fixture var
- Edge case testleri var
- Sampling rate varyasyonları test edilmiş
- NaN/empty/short signal davranışı belirlenmiş
- Tolerans değerleri dokümante edilmiş
- Benchmark veya performans notu var
- Limitations bölümü yazılmış

---

## Handoff Formatı

Her tamamlanan görev aşağıdaki formatla devredilir:

```markdown
## Handoff Summary

### Completed
- ...

### Changed Files
- ...

### Reference Behavior
- Python source:
- Fixture:
- Tolerance:

### Known Differences
- ...

### Tests
- ...

### Risks
- ...

### Next Recommended Task
- ...
```

---

## Risk Yönetimi

### Kritik Riskler

| Risk | Etki | Önlem |
|---|---|---|
| NeuroKit2 davranışının yanlış anlaşılması | Yanlış Dart çıktısı | Python fixture zorunlu |
| Floating-point sapmaları | Test kırılmaları | Açık tolerans politikası |
| SciPy bağımlı algoritmalar | Port zorluğu | Matematiksel yeniden implementasyon |
| Sampling rate varsayımları | Hatalı peak/rate sonucu | Çoklu sampling rate testleri |
| API'nin fazla Python-benzeri olması | Dart ergonomisi düşer | Dart-native wrapper tasarımı |
| Klinik kullanım beklentisi | Hukuki/medikal risk | Limitations ve disclaimer |

---

## Test Stratejisi

Agent testleri üç seviyeye ayırır:

### 1. Unit Tests

- Küçük helper fonksiyonları
- Filter coefficient hesapları
- Peak utility fonksiyonları
- Interpolation yardımcıları

### 2. Golden Tests

- Python NeuroKit2 çıktısıyla karşılaştırma
- Sabit fixture sinyalleri
- Farklı sampling rate kombinasyonları
- Farklı cleaning/peak method kombinasyonları

### 3. Integration Tests

- `EcgProcessor.process()` uçtan uca pipeline
- Clean → peaks → rate → quality → delineate → phase zinciri
- Public API kullanım örnekleri

---

## Üretim Artefaktı Yönetimi

Agent üretim çıktıları için `production_artifacts.md` dosyasını kaynak alır.

Minimum üretim dosya grupları:

```text
lib/
test/
benchmark/
tool/fixtures/
docs/
example/
```

Her artifact için aşağıdakiler net olmalıdır:

- Sahibi
- Amaç
- Girdi
- Çıktı
- Test yöntemi
- Güncelleme koşulu
- Handoff notu

---

## Kurallara Uyum

Agent her görevden önce `rules.md` dosyasındaki kuralları geçerli kabul eder.

Özellikle:

- Kaynak davranış doğrulanmadan port yapılmaz.
- Test fixture olmadan algoritma tamamlandı sayılmaz.
- Public API breaking change olarak değerlendirilir.
- Tıbbi doğruluk iddiası yapılmaz.
- Klinik kullanım için validasyon yapılmış gibi davranılmaz.
- Kod üretimi dokümantasyon ve testten ayrı düşünülmez.

---

## Güncelleme Politikası

Bu dosya aşağıdaki durumlarda güncellenir:

- Yeni `.md` yönetim dosyası eklendiğinde
- Dosya öncelik sırası değiştiğinde
- Yeni görev tipi tanımlandığında
- ECG modül sınırları değiştiğinde
- Agent handoff protokolü değiştiğinde
- Kalite kapıları revize edildiğinde

Her güncellemede aşağıdaki bilgiler eklenmelidir:

```markdown
## Change Log

### YYYY-MM-DD
- Değişiklik:
- Gerekçe:
- Etkilenen dosyalar:
```

---

## Change Log

### 2026-05-13

- İlk `agent.md` oluşturuldu.
- Dokümantasyon seti için ana orchestration katmanı tanımlandı.
- `README.md`, `skills.md`, `production_artifacts.md`, `handoff.md`, `workflows.md`, `rules.md` ve `skill_references.md` dosyalarının yönetim ilişkisi belirlendi.
