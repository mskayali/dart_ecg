# skill_references.md

## Amaç

Bu dosya, NeuroKit2 ECG işleme katmanını Dart kütüphanesine port edecek agent için kaynak referansları, algoritma referans haritasını, doğrulama metriklerini ve öğrenme/uygulama notlarını tanımlar.

Bu dosya doğrudan implementasyon talimatı değildir. Agent'ın hangi kaynağı hangi amaçla okuyacağını, hangi bilgiyi hangi port kararına bağlayacağını ve hangi doğrulama kanıtlarını üretmesi gerektiğini tarif eder.

---

## Kullanım Şekli

Agent her ECG port görevinde bu dosyayı aşağıdaki amaçlarla kullanır:

1. NeuroKit2 kaynak fonksiyonunu bulmak.
2. Fonksiyonun dokümantasyon davranışını doğrulamak.
3. Algoritmanın akademik veya teknik referansını tespit etmek.
4. Python bağımlılıklarını Dart karşılıklarına map etmek.
5. Test fixture ve tolerans gereksinimlerini belirlemek.
6. Handoff sırasında kullanılan referansları açıkça raporlamak.

Bu dosya tek başına yeterli değildir. Port kararı verirken şu dosyalarla birlikte okunmalıdır:

```text
agent.md
rules.md
skills.md
workflows.md
production_artifacts.md
```

---

## Öncelikli Kaynaklar

### 1. NeuroKit2 Resmi Repository

```text
https://github.com/neuropsychology/NeuroKit
```

Kullanım amacı:

- Kaynak kod davranışını incelemek.
- ECG fonksiyonlarının gerçek implementasyonunu okumak.
- Import bağımlılıklarını çıkarmak.
- Test/golden fixture üretiminde referans davranış almak.
- Versiyon farklarını kontrol etmek.

Agent kuralı:

```text
Dokümantasyon ile kaynak kod çelişirse, port davranışı için kaynak kod esas alınır; ancak çelişki handoff notuna yazılır.
```

---

### 2. NeuroKit2 ECG API Dokümantasyonu

```text
https://neuropsychology.github.io/NeuroKit/functions/ecg.html
```

Kullanım amacı:

- Public API davranışını anlamak.
- Fonksiyonların kullanıcıya vaat ettiği input/output yapısını görmek.
- Örnek kullanım akışlarını referans almak.
- Parametre varsayılanlarını dokümantasyon seviyesinde doğrulamak.

Özellikle okunacak başlıklar:

```text
ecg_process
ecg_clean
ecg_peaks
ecg_rate
ecg_quality
ecg_delineate
ecg_phase
ecg_segment
ecg_plot
ecg_simulate
```

---

### 3. NeuroKit2 Modül Kaynakları

Agent ECG portu sırasında aşağıdaki kaynak dosya ailelerini incelemelidir.

```text
neurokit2/ecg/
neurokit2/signal/
neurokit2/misc/
neurokit2/stats/
```

Öncelikli ECG dosyaları:

```text
neurokit2/ecg/ecg_process.py
neurokit2/ecg/ecg_clean.py
neurokit2/ecg/ecg_peaks.py
neurokit2/ecg/ecg_findpeaks.py
neurokit2/ecg/ecg_rate.py
neurokit2/ecg/ecg_quality.py
neurokit2/ecg/ecg_delineate.py
neurokit2/ecg/ecg_phase.py
neurokit2/ecg/ecg_segment.py
neurokit2/ecg/ecg_simulate.py
```

Sinyal yardımcıları:

```text
neurokit2/signal/signal_filter.py
neurokit2/signal/signal_rate.py
neurokit2/signal/signal_smooth.py
neurokit2/signal/signal_findpeaks.py
neurokit2/signal/signal_fixpeaks.py
neurokit2/signal/signal_formatpeaks.py
neurokit2/signal/signal_interpolate.py
neurokit2/signal/signal_period.py
neurokit2/signal/signal_resample.py
neurokit2/signal/signal_sanitize.py
```

---

## ECG Pipeline Referans Haritası

### Ana Akış

NeuroKit2 ECG pipeline aşağıdaki mantıksal sırayla ele alınmalıdır:

```text
raw_ecg
  -> signal_sanitize
  -> ecg_clean
  -> ecg_peaks / ecg_findpeaks
  -> signal_rate / ecg_rate
  -> ecg_quality
  -> ecg_delineate
  -> ecg_phase
  -> ecg_segment
  -> result model
```

Dart portunda bu akış tek bir monolitik fonksiyona gömülmemelidir. Her aşama bağımsız test edilebilir modül olmalıdır.

Önerilen Dart modül eşlemesi:

```text
lib/src/ecg/ecg_process.dart
lib/src/ecg/ecg_clean.dart
lib/src/ecg/ecg_peaks.dart
lib/src/ecg/ecg_findpeaks.dart
lib/src/ecg/ecg_rate.dart
lib/src/ecg/ecg_quality.dart
lib/src/ecg/ecg_delineate.dart
lib/src/ecg/ecg_phase.dart
lib/src/ecg/ecg_segment.dart
lib/src/signal/signal_filter.dart
lib/src/signal/signal_rate.dart
lib/src/signal/signal_smooth.dart
lib/src/signal/signal_interpolate.dart
lib/src/signal/signal_findpeaks.dart
```

---

## Fonksiyon Bazlı Referanslar

### 1. `ecg_process`

Kaynak amaç:

- ECG preprocessing için üst seviye convenience pipeline.
- Cleaning, R-peak detection, rate, quality, delineation ve phase adımlarını birleştirir.

Port önceliği:

```text
Yüksek
```

Dart hedefi:

```dart
EcgProcessResult ecgProcess(
  List<double> ecgSignal, {
  int samplingRate = 1000,
  EcgMethod method = EcgMethod.neurokit,
  bool correctArtifacts = false,
})
```

Doğrulama noktaları:

- Output uzunluğu input uzunluğuyla uyumlu olmalı.
- R-peak indexleri referans NeuroKit2 çıktısıyla tolerans dahilinde eşleşmeli.
- Rate sinyali input timeline ile aynı sample eksenine map edilmeli.
- Missing/NaN davranışı açıkça tanımlanmalı.

---

### 2. `ecg_clean`

Kaynak amaç:

- Ham ECG sinyalini R-peak detection ve delineation için daha uygun hale getirmek.
- Farklı temizleme yöntemlerini desteklemek.

Port önceliği:

```text
Çok yüksek
```

Desteklenecek yöntemler:

```text
neurokit
biosppy
pantompkins1985
hamilton2002
elgendi2010
engzeemod2012
vg
```

Dart port stratejisi:

- Önce `neurokit` yöntemi.
- Sonra R-peak detector ile sık kullanılan yöntemler.
- Daha sonra compatibility yöntemleri.

Doğrulama noktaları:

- Filtre katsayıları.
- Baseline wander azaltma etkisi.
- Sinyal uzunluğu korunumu.
- Edge padding davranışı.
- Çok kısa sinyal davranışı.
- `samplingRate` değiştiğinde cutoff normalizasyonu.

---

### 3. `ecg_peaks`

Kaynak amaç:

- Temizlenmiş ECG sinyalinde R-peak indexlerini bulmak.
- İsteğe bağlı artifact correction uygulamak.

Port önceliği:

```text
Çok yüksek
```

Desteklenecek yöntemler:

```text
neurokit
pantompkins1985
hamilton2002
elgendi2010
engzeemod2012
nabian2018
kalidas2017
martinez2004
rodrigues2021
promac
```

Not:

Tüm yöntemlerin ilk sürümde zorunlu olması gerekmez. İlk production milestone için minimum hedef:

```text
neurokit
pantompkins1985
hamilton2002
elgendi2010
```

Doğrulama noktaları:

- R-peak sample index listesi.
- Minimum distance constraint.
- Refractory period.
- Threshold adaptasyonu.
- Noise burst davranışı.
- False positive / false negative analizi.

---

### 4. `ecg_findpeaks`

Kaynak amaç:

- Farklı R-peak detection algoritmalarını dispatch eden alt seviye fonksiyon.

Dart port stratejisi:

```dart
abstract interface class EcgPeakDetector {
  EcgPeakDetectionResult detect(
    Float64List signal, {
    required int samplingRate,
  });
}
```

Her yöntem ayrı class olarak tasarlanmalıdır:

```text
NeurokitPeakDetector
PanTompkins1985PeakDetector
Hamilton2002PeakDetector
Elgendi2010PeakDetector
EngzeeMod2012PeakDetector
```

Doğrulama noktaları:

- Detector bağımsız unit test.
- Aynı input için deterministik output.
- Method enum ile class mapping.
- Hatalı method için açık exception.

---

### 5. `ecg_rate` / `signal_rate`

Kaynak amaç:

- R-peak indexlerinden anlık heart rate serisi üretmek.

Port önceliği:

```text
Yüksek
```

Dart port stratejisi:

- RR interval hesapla.
- BPM dönüşümü yap.
- İstenen uzunluğa interpolasyon uygula.
- Baş/son sınır davranışını açıkça tanımla.

Temel formül:

```text
BPM = 60 / RR_seconds
RR_seconds = diff(rpeaks) / samplingRate
```

Doğrulama noktaları:

- Tek veya sıfır R-peak davranışı.
- Düzensiz RR interval davranışı.
- Interpolasyon yöntemi.
- Output uzunluğu.

---

### 6. `ecg_quality`

Kaynak amaç:

- ECG sinyal kalitesini ölçmek.
- R-peak ve template tabanlı kalite yaklaşımlarını desteklemek.

Port önceliği:

```text
Orta-yüksek
```

Dart port stratejisi:

- İlk sürümde template/correlation tabanlı kalite indeksi uygulanabilir.
- İleri sürümde yöntem çeşitliliği artırılır.

Doğrulama noktaları:

- Clean ECG için yüksek kalite skoru.
- Gürültülü ECG için düşük kalite skoru.
- Saturation veya flatline davranışı.
- Peak eksikliği durumunda hata/boş sonuç stratejisi.

---

### 7. `ecg_delineate`

Kaynak amaç:

- P, Q, R, S, T dalgalarının onset, peak ve offset noktalarını bulmak.

Port önceliği:

```text
Orta
```

Desteklenecek yaklaşımlar:

```text
peak
cwt
dwt
prominence
```

İlk Dart milestone önerisi:

```text
prominence veya peak tabanlı sınırlı delineation
```

DWT/CWT tabanlı yöntemler için ekstra matematiksel altyapı gerekir.

Doğrulama noktaları:

- R-peak çevresinde Q/S sınırları.
- T dalgası peak/offset.
- P dalgası peak/onset.
- Missing dalga durumlarında nullable index davranışı.
- Indexlerin sinyal sınırlarını aşmaması.

---

### 8. `ecg_phase`

Kaynak amaç:

- Cardiac phase ve atrial/ventricular phase sinyalleri üretmek.

Port önceliği:

```text
Orta
```

Dart port stratejisi:

- R-peak ve delineation çıktısına bağımlı olacak şekilde tasarla.
- Phase output sinyallerini integer veya enum-backed model olarak üret.

Doğrulama noktaları:

- Systole/diastole geçişleri.
- Missing delineation durumları.
- Output uzunluğu.
- Phase completion oranı.

---

### 9. `ecg_segment`

Kaynak amaç:

- ECG sinyalini beat bazlı segmentlere ayırmak.

Port önceliği:

```text
Orta
```

Dart port stratejisi:

```dart
List<EcgBeatSegment> ecgSegment(
  List<double> ecgSignal,
  List<int> rPeaks, {
  required int samplingRate,
  double before = 0.35,
  double after = 0.45,
})
```

Doğrulama noktaları:

- Segment başlangıç/bitiş indexleri.
- Sinyal başı/sonu taşma davranışı.
- Beat metadata.
- Segment length tutarlılığı.

---

### 10. `ecg_simulate`

Kaynak amaç:

- Test ve örnekler için sentetik ECG üretmek.

Port önceliği:

```text
Düşük-orta
```

Dart port stratejisi:

- İlk sürümde basit sentetik fixture üretimi yeterli olabilir.
- Tam NeuroKit2 simülasyon uyumluluğu ayrı milestone olarak ele alınmalıdır.

Doğrulama noktaları:

- Seed ile deterministik üretim.
- Belirlenen duration ve sampling rate uzunluğu.
- Heart rate parametresinin R-peak aralıklarına etkisi.

---

## Python/Dart Teknik Eşleme Referansı

| Python / NeuroKit2 | Dart karşılığı | Not |
|---|---|---|
| `np.ndarray` | `Float64List` | Core numeric buffer |
| `list` | `List<double>` | Public input kabul edilebilir |
| `pd.DataFrame` | Typed result model | Map tabanlı gevşek yapıdan kaçın |
| `pd.Series` | `Float64List` veya named signal | Timeline metadata ayrıca tutulmalı |
| `np.nan` | `double.nan` | Karşılaştırma özel yapılmalı |
| `np.inf` | `double.infinity` | Validation aşamasında ele alınmalı |
| `scipy.signal.butter` | Dart coefficient generator | Test ile doğrula |
| `scipy.signal.filtfilt` | Forward-backward IIR | Padding davranışı kritik |
| `scipy.signal.find_peaks` | Custom peak finder | Prominence/distance/height desteklenmeli |
| `np.diff` | Manual loop | Allocation azaltılmalı |
| `np.where` | Manual index collection | Boolean mask yerine typed index list |
| `np.interp` | Custom linear interpolation | Boundary davranışı test edilmeli |
| `signal_rate` | `SignalRate.compute` | ECG dışı reusable modül |

---

## Algoritma Referansları

Agent port sırasında yöntem isimlerinin tarihsel kaynaklarını ve teknik niyetlerini korumalıdır.

### R-Peak Detection

| Method | Teknik kategori | Port notu |
|---|---|---|
| `neurokit` | Gradient / adaptive threshold yaklaşımı | Ana varsayılan hedef |
| `pantompkins1985` | Bandpass + derivative + squaring + moving window | İlk portlanacak klasik yöntemlerden biri |
| `hamilton2002` | Adaptive threshold QRS detector | Refractory ve threshold davranışı önemli |
| `elgendi2010` | Moving average blocks | Window süreleri sampling rate'e bağlı |
| `engzeemod2012` | Engelse-Zeelenberg modifikasyonu | Threshold ve search-back dikkatli incelenmeli |
| `nabian2018` | ECG detector variant | İleri milestone |
| `kalidas2017` | SWT/wavelet tabanlı yaklaşım | Wavelet altyapısı gerekebilir |
| `martinez2004` | Wavelet delineation/detection | İleri milestone |
| `rodrigues2021` | Visibility graph | Graph tabanlı bağımlılık tasarımı gerekir |
| `promac` | Probabilistic method agreement | Çoklu detector çıktısı gerektirir |

### Cleaning

| Method | Teknik kategori | Port notu |
|---|---|---|
| `neurokit` | ECG odaklı bandpass/highpass filtering | Varsayılan cleaning hedefi |
| `biosppy` | FIR/bandpass yaklaşımı | FIR coefficient ve group delay dikkatli ele alınmalı |
| `pantompkins1985` | QRS detection ön hazırlık filtresi | Detector ile beraber doğrulanmalı |
| `hamilton2002` | QRS detection ön hazırlık filtresi | Detector ile beraber doğrulanmalı |
| `elgendi2010` | Moving average tabanlı işleme | Window sample hesapları önemli |
| `engzeemod2012` | Detector uyumlu preprocessing | Detector pipeline ile birlikte test edilmeli |
| `vg` | Visibility graph preprocessing | İleri milestone |

### Delineation

| Method | Teknik kategori | Port notu |
|---|---|---|
| `peak` | Local extrema | İlk basit milestone için uygun |
| `prominence` | Prominence tabanlı feature çıkarımı | Custom find_peaks gerekir |
| `cwt` | Continuous wavelet transform | Ek matematik modülü gerekir |
| `dwt` | Discrete wavelet transform | Ek wavelet altyapısı gerekir |

---

## Dart Paket Referansları

Agent Dart portunda gereksiz runtime bağımlılıktan kaçınmalıdır. Ancak aşağıdaki alanlarda bağımlılık veya internal implementation kararı verilebilir.

### Core

```text
Dart SDK typed_data
Dart SDK math
package:test
package:lints veya very_good_analysis
```

### Opsiyonel

```text
package:fftea      -> FFT gerekiyorsa
package:ml_linalg  -> Ağır matris işlemleri gerekiyorsa, dikkatli değerlendir
package:csv        -> Fixture okuma/yazma için test/dev dependency
```

Kural:

```text
Core ECG pipeline, Flutter'a ve native FFI'a bağımlı olmamalıdır.
```

---

## Fixture ve Test Referansları

### Golden Fixture Kaynağı

Agent aşağıdaki yöntemi kullanarak fixture üretmelidir:

```text
1. Sabit NeuroKit2 versiyonu seç.
2. Python script ile input ECG, cleaned ECG, rpeaks, rate, quality, delineation çıktıları üret.
3. Çıktıları JSON/CSV olarak kaydet.
4. Dart testlerinde aynı fixture'ları oku.
5. Toleranslı karşılaştırma yap.
```

Önerilen fixture dizini:

```text
test/fixtures/ecg/
├── nk_version.txt
├── synthetic_1000hz_input.csv
├── synthetic_1000hz_cleaned_neurokit.csv
├── synthetic_1000hz_rpeaks_neurokit.json
├── synthetic_1000hz_rate_neurokit.csv
├── noisy_250hz_input.csv
├── noisy_250hz_cleaned_neurokit.csv
├── noisy_250hz_rpeaks_neurokit.json
└── fixture_manifest.json
```

### Fixture Manifest Alanları

```json
{
  "neurokit_version": "0.2.13",
  "python_version": "3.x",
  "sampling_rate": 1000,
  "duration_seconds": 10,
  "method": "neurokit",
  "seed": 42,
  "source_script": "tools/generate_neurokit_fixtures.py",
  "created_at": "YYYY-MM-DD"
}
```

---

## Sayısal Doğrulama Referansları

### Genel Toleranslar

```text
absoluteTolerance = 1e-8
relativeTolerance = 1e-6
```

### Fonksiyon Bazlı Tolerans Önerileri

| Fonksiyon | Karşılaştırma tipi | Başlangıç toleransı |
|---|---|---|
| `ecg_clean` | sample-wise float | abs 1e-6, rel 1e-4 |
| `ecg_peaks` | index exact/near | ±1-3 sample |
| `ecg_rate` | sample-wise float | abs 1e-5, rel 1e-3 |
| `ecg_quality` | sample-wise/summary | abs 1e-4, rel 1e-3 |
| `ecg_delineate` | index near | ±3-10 sample |
| `ecg_phase` | categorical match | exact after boundary tolerance |
| `ecg_segment` | index/window match | exact or documented padding difference |

Tolerans artırma kuralı:

```text
Tolerans yalnızca teknik gerekçeyle artırılabilir. Gerekçe handoff ve test açıklamasına yazılmalıdır.
```

---

## Edge Case Referans Listesi

Her port edilen fonksiyon aşağıdaki durumlara göre test edilmelidir:

```text
empty signal
single sample signal
two sample signal
very short signal shorter than filter order
constant flatline signal
all zeros
all NaN
mixed NaN values
positive infinity
negative infinity
very high amplitude outlier
low sampling rate
high sampling rate
non-integer-like sampling rate rejection
negative sampling rate
zero sampling rate
R-peaks empty
R-peaks unsorted
R-peaks duplicated
R-peaks outside signal bounds
```

---

## Klinik ve Regülasyon Referansı

Agent aşağıdaki sınırı korumalıdır:

```text
Bu port biyomedikal sinyal işleme kütüphanesidir; klinik tanı, hasta izleme alarmı veya tıbbi cihaz fonksiyonu olarak sunulmamalıdır.
```

README, API docs ve public examples içinde aşağıdaki tür ifadelerden kaçınılmalıdır:

```text
arrhythmia diagnosis
medical diagnosis
patient safety alarm
certified ECG interpretation
clinical decision support
```

Kabul edilebilir ifade:

```text
ECG preprocessing, R-peak detection, signal quality estimation, waveform delineation, and research-oriented feature extraction utilities.
```

---

## Agent Referans Okuma Sırası

### Yeni Fonksiyon Portu

```text
1. agent.md
2. rules.md
3. skills.md
4. skill_references.md
5. NeuroKit2 source file
6. NeuroKit2 API docs
7. production_artifacts.md
8. workflows.md
9. handoff.md
```

### Hata Düzeltme

```text
1. Bug report / failing test
2. rules.md
3. ilgili Dart source
4. ilgili NeuroKit2 source
5. fixture manifest
6. skill_references.md
7. handoff.md
```

### Release Hazırlığı

```text
1. production_artifacts.md
2. rules.md
3. workflows.md
4. test reports
5. benchmark reports
6. README.md
7. handoff.md
```

---

## Kaynak Güvenilirlik Sırası

Çelişkili bilgi durumunda öncelik sırası:

```text
1. Sabit commit hash'e bağlı NeuroKit2 kaynak kodu
2. Aynı commit için üretilmiş golden fixture
3. Resmi NeuroKit2 dokümantasyonu
4. NeuroKit2 paper / akademik yayın
5. Algoritmanın orijinal paper'ı
6. Üçüncü parti blog/tutorial
7. LLM yorumu
```

Kural:

```text
LLM yorumu hiçbir zaman tek başına algoritmik doğruluk kanıtı sayılmaz.
```

---

## Handoff İçin Referans Rapor Formatı

Her tamamlanan port görevi sonunda aşağıdaki blok doldurulmalıdır:

```markdown
## Reference Summary

- NeuroKit2 source file:
- NeuroKit2 commit/tag:
- Documentation page:
- Related signal helpers:
- Implemented Dart files:
- Fixture files:
- Test files:
- Known deviations:
- Numeric tolerances:
- Open questions:
```

Örnek:

```markdown
## Reference Summary

- NeuroKit2 source file: neurokit2/ecg/ecg_clean.py
- NeuroKit2 commit/tag: v0.2.13 or pinned commit
- Documentation page: https://neuropsychology.github.io/NeuroKit/functions/ecg.html#ecg-clean
- Related signal helpers: signal_filter.py, signal_sanitize.py
- Implemented Dart files: lib/src/ecg/ecg_clean.dart
- Fixture files: test/fixtures/ecg/synthetic_1000hz_cleaned_neurokit.csv
- Test files: test/ecg/ecg_clean_test.dart
- Known deviations: filtfilt edge padding approximated; max abs diff documented
- Numeric tolerances: abs=1e-6, rel=1e-4
- Open questions: exact SciPy padlen equivalence for short signals
```

---

## Minimum Kabul Kriterleri

Bir referans veya beceri port için tamamlanmış sayılmadan önce şu şartlar sağlanmalıdır:

```text
source behavior reviewed
input/output documented
Dart API designed
deterministic implementation available
unit tests written
golden fixture comparison available
edge cases tested
numeric tolerance justified
performance sanity check completed
handoff reference summary written
```

---

## Sürümleme Referansı

Agent her NeuroKit2 karşılaştırmasında versiyon veya commit bilgisi kullanmalıdır.

Kabul edilebilir referans formatları:

```text
NeuroKit2 tag: v0.2.13
NeuroKit2 commit: <full_commit_hash>
NeuroKit2 docs build: 0.2.13.dev214
```

Kural:

```text
Floating-point golden fixture üretilirken kaynak NeuroKit2 versiyonu sabitlenmeden test sonucu kabul edilmez.
```

---

## Agent İçin Kısa Kontrol Listesi

```text
[ ] İlgili NeuroKit2 kaynak dosyasını okudum.
[ ] İlgili helper fonksiyonları belirledim.
[ ] Public dokümantasyonu kontrol ettim.
[ ] Python bağımlılıklarını Dart karşılıklarına map ettim.
[ ] Edge case davranışını belirledim.
[ ] Fixture gereksinimini yazdım.
[ ] Numeric tolerans önerdim.
[ ] Dart API etkisini değerlendirdim.
[ ] Klinik iddia riski olmadığını kontrol ettim.
[ ] Handoff reference summary hazırladım.
```

---

## Son Not

Bu dosya canlı referans dokümanıdır. NeuroKit2 kaynak kodu, Dart paket mimarisi veya üretim hedefleri değiştiğinde güncellenmelidir. Her güncellemede değişen referanslar, fixture versiyonları ve tolerans kararları açıkça belirtilmelidir.
