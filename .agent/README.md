# NeuroKit ECG → Dart Agent

## Amaç

Bu agent altyapısı, [`neuropsychology/NeuroKit`](https://github.com/neuropsychology/NeuroKit) projesindeki **ECG işleme katmanının** Dart ekosistemine taşınması için hazırlanmıştır.

Hedef, NeuroKit2'nin Python tabanlı ECG pipeline'ını birebir kopyalamak değil; algoritmik davranışı, API sözleşmelerini, test edilebilirliği ve üretim kalitesini koruyarak Dart için sürdürülebilir bir kütüphane tasarlamaktır.

Bu çalışma özellikle aşağıdaki NeuroKit2 ECG akışını temel alır:

```text
raw ECG signal
  → ecg_clean()
  → ecg_peaks()
  → signal_rate()
  → ecg_quality()
  → ecg_delineate()
  → ecg_phase()
  → ecg_process() output
```

## Hedef Dart Kütüphanesi

Önerilen paket adı:

```text
neurokit_ecg
```

Önerilen Dart import yapısı:

```dart
import 'package:neurokit_ecg/neurokit_ecg.dart';
```

Örnek hedef kullanım:

```dart
final result = EcgProcessor.process(
  signal: ecgSamples,
  samplingRate: 1000,
  method: EcgMethod.neurokit,
);

final cleaned = result.signals.cleaned;
final rPeaks = result.info.rPeaks;
final heartRate = result.signals.rate;
```

## Agent'ın Ana Görevi

Agent, NeuroKit2'nin ECG fonksiyonlarını Dart'a taşırken aşağıdaki rolleri üstlenir:

1. Python kaynak kodunu ve dokümantasyonu analiz eder.
2. Her ECG fonksiyonunu algoritmik alt adımlarına böler.
3. Python/Numpy/Pandas/SciPy bağımlılıklarını Dart karşılıklarına dönüştürür.
4. Dart API tasarımını üretir.
5. Sayısal davranış uyumluluğu için test stratejisi kurar.
6. Üretim kalitesinde paket yapısı, dokümantasyon ve handoff çıktıları üretir.
7. Klinik yorum veya medikal teşhis üretmez; yalnızca sinyal işleme fonksiyonlarını port eder.

## Kapsam

### Birincil ECG Fonksiyonları

Port kapsamındaki temel fonksiyon aileleri:

```text
ecg_process
ecg_clean
ecg_peaks
ecg_findpeaks
ecg_rate
ecg_quality
ecg_delineate
ecg_phase
ecg_segment
ecg_simulate
```

### Yardımcı Sinyal İşleme Fonksiyonları

Dart tarafında ayrıca şu yardımcı fonksiyonlar gerekir:

```text
signal_filter
signal_sanitize
signal_rate
signal_interpolate
signal_smooth
signal_findpeaks
signal_formatpeaks
signal_fixpeaks
signal_period
```

### Matematik / DSP Katmanı

Python ekosistemindeki `numpy`, `scipy.signal`, `pandas` ve `pywt` kullanımlarının Dart karşılıkları için ayrı bir altyapı gerekir:

```text
array/vector operations
finite checks
NaN handling
moving average
Butterworth filters
FIR/IIR filters
zero-phase filtering approximation
peak detection
wavelet transform support
interpolation
resampling
```

## Kapsam Dışı

Bu agent aşağıdaki işleri yapmaz:

```text
medikal teşhis üretmek
ECG yorum raporu yazmak
aritmi sınıflandırıcı eğitmek
FDA/CE tıbbi cihaz uyumluluğu garanti etmek
hasta güvenliği kararı vermek
NeuroKit lisansını değiştirmek
Python kodunu mekanik olarak birebir çevirmek
```

## Öncelikli Port Stratejisi

Port işlemi üç seviyede yürütülür.

### Seviye 1 — API ve Veri Modeli

Önce Dart tarafında stabil veri modelleri kurulur:

```text
EcgProcessor
EcgProcessResult
EcgSignals
EcgInfo
EcgMethod
EcgPeakDetector
EcgDelineationResult
EcgQualityResult
```

Amaç, Python'daki `DataFrame` ve `dict` çıktılarının Dart'ta tip güvenli sınıflara dönüştürülmesidir.

### Seviye 2 — Minimal Çalışan ECG Pipeline

İlk çalışan sürüm aşağıdaki hattı desteklemelidir:

```text
ecg_clean(method: neurokit)
ecg_peaks(method: neurokit)
ecg_rate()
ecg_process()
```

Bu sürüm, gerçek zamanlı veya mobil kullanım için temel R-peak detection ve heart-rate üretimini sağlar.

### Seviye 3 — Geniş Algoritma Uyumluluğu

Sonraki iterasyonlarda desteklenecek yöntemler:

```text
pantompkins1985
hamilton2002
elgendi2010
engzeemod2012
biosppy
vg
emrich2023
promac
```

Delineation için ayrı yöntemler:

```text
peak
cwt
dwt
prominence
```

## Önerilen Paket Dizin Yapısı

```text
neurokit_ecg/
├── lib/
│   ├── neurokit_ecg.dart
│   └── src/
│       ├── ecg/
│       │   ├── ecg_processor.dart
│       │   ├── ecg_clean.dart
│       │   ├── ecg_peaks.dart
│       │   ├── ecg_rate.dart
│       │   ├── ecg_quality.dart
│       │   ├── ecg_delineate.dart
│       │   ├── ecg_phase.dart
│       │   ├── ecg_segment.dart
│       │   ├── ecg_simulate.dart
│       │   └── models.dart
│       ├── signal/
│       │   ├── signal_filter.dart
│       │   ├── signal_findpeaks.dart
│       │   ├── signal_rate.dart
│       │   ├── signal_interpolate.dart
│       │   ├── signal_smooth.dart
│       │   └── signal_sanitize.dart
│       ├── dsp/
│       │   ├── filters.dart
│       │   ├── convolution.dart
│       │   ├── interpolation.dart
│       │   ├── statistics.dart
│       │   ├── wavelets.dart
│       │   └── resampling.dart
│       └── utils/
│           ├── numeric.dart
│           ├── validation.dart
│           └── exceptions.dart
├── test/
│   ├── ecg/
│   ├── signal/
│   ├── dsp/
│   └── fixtures/
├── benchmark/
├── example/
├── docs/
└── pubspec.yaml
```

## Agent Doküman Seti

Bu dizindeki dosyalar agent davranışını ve üretim çıktısını tanımlar:

```text
README.md
skills.md
production_artifacts.md
handoff.md
workflows.md
rules.md
skill_references.md
```

### Dosya Rolleri

| Dosya | Rol |
|---|---|
| `README.md` | Genel hedef, kapsam, mimari yaklaşım |
| `skills.md` | Agent'ın sahip olması gereken teknik yetkinlikler |
| `production_artifacts.md` | Agent'ın üretmesi gereken somut çıktılar |
| `handoff.md` | İnsan geliştiriciye veya başka agente teslim standardı |
| `workflows.md` | Port, test, doğrulama ve release iş akışları |
| `rules.md` | Zorunlu kurallar, yasaklar, kalite kapıları |
| `skill_references.md` | NeuroKit fonksiyonları ve Dart karşılık referansları |

## Kalite İlkeleri

Agent her çıktıda aşağıdaki ilkeleri korumalıdır:

```text
numerical correctness > API convenience
explicit errors > silent fallback
typed models > dynamic maps
small pure functions > large mutable processors
test fixtures > visual inspection
algorithm notes > opaque translation
reproducibility > approximate behavior
```

## Lisans ve Atıf Notu

NeuroKit2 açık kaynak bir projedir. Dart portu hazırlanırken:

```text
orijinal lisans kontrol edilmeli
kaynak algoritmalara atıf korunmalı
dokümantasyon referansları belirtilmeli
Python kodu doğrudan kopyalanmamalı
algoritmik davranış yeniden uygulanmalı
```

Agent, her port edilen fonksiyon için kaynak referansını ve uyarlama notunu üretim artefaktına eklemelidir.

## Başarı Kriterleri

İlk başarılı port aşağıdaki koşulları sağlamalıdır:

```text
Dart package pub get ile kurulabilir
statik analiz hatasız geçer
ecg_process benzeri tek çağrılı API çalışır
R-peak indexleri fixture verilerde beklenen tolerans içindedir
heart-rate çıktısı Python referansı ile karşılaştırılabilir
NaN/empty/short signal edge-case testleri vardır
algoritma belgeleri geliştiriciye yeterli açıklığı sağlar
```

## Agent Çalışma Modu

Agent her görevde şu sırayı izler:

```text
1. Kaynak NeuroKit fonksiyonunu belirle
2. Python bağımlılıklarını çıkar
3. Algoritmik adımları listele
4. Dart veri modelini seç
5. Saf Dart implementasyon planı yaz
6. Test fixture ihtiyacını tanımla
7. Sayısal toleransları belirle
8. Üretim artefaktını oluştur
9. Handoff notlarını güncelle
```

## Minimum İlk Milestone

İlk milestone için üretilecek Dart fonksiyonları:

```text
EcgProcessor.process()
EcgCleaner.clean()
EcgPeakDetector.detect()
SignalRate.compute()
SignalSanitizer.sanitize()
SignalFilter.butterworth()
```

Minimum testler:

```text
clean signal length preservation
R-peak index detection tolerance
heart-rate interpolation length
invalid sampling-rate validation
empty signal validation
NaN handling
```

## Referans Kaynaklar

- NeuroKit GitHub: <https://github.com/neuropsychology/NeuroKit>
- NeuroKit ECG docs: <https://neuropsychology.github.io/NeuroKit/functions/ecg.html>
- NeuroKit `ecg_process` source docs: <https://neuropsychology.github.io/NeuroKit/_modules/neurokit2/ecg/ecg_process.html>

