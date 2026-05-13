# Algorithm Mapping Matrix

Bu tablo, NeuroKit2 kaynak kodundaki ECG fonksiyonlarının Dart hedef projesindeki (`dart_ecg`) eşdeğerlerini göstermektedir.

| NeuroKit2 Function | Python Source | Dart Target | Status | Test Fixture | Notes |
|---|---|---|---|---|---|
| `ecg_process` | `neurokit2/ecg/ecg_process.py` | `ecgProcess()` | ✅ verified | `ecg_process_golden.json` | Pipeline orchestrator. Full parity achieved. |
| `ecg_clean` | `neurokit2/ecg/ecg_clean.py` | `ecgClean()` | ✅ verified | `ecg_process_golden.json` | 7 farklı temizleme metodu destekleniyor. `padlen` mekanizması eklendi. |
| `ecg_findpeaks` | `neurokit2/ecg/ecg_findpeaks.py` | `ecgFindpeaks()` | ✅ verified | `ecg_process_golden.json` | En popüler 5 algoritma port edildi (neurokit, pantompkins, hamilton, elgendi, engzee). |
| `ecg_peaks` | `neurokit2/ecg/ecg_peaks.py` | `ecgPeaks()` | ✅ verified | `ecg_process_golden.json` | R-peak bulma ve düzeltme (fixpeaks). |
| `ecg_simulate` | `neurokit2/ecg/ecg_simulate.py` | `ecgSimulate()` | ✅ ported | (Golden fixture ile dolaylı) | Daubechies ve ECGSYN destekleniyor. ECGSYN için 4th order RK entegre edildi. |
| `ecg_quality` | `neurokit2/ecg/ecg_quality.py` | `ecgQuality()` | ✅ verified | `ecg_process_golden.json` | averageQRS ve Zhao2018 yöntemleri port edildi. |
| `ecg_delineate` | `neurokit2/ecg/ecg_delineate.py` | `ecgDelineate()` | ✅ ported | (Manuel test) | `peak` ve `dwt` yöntemleri eklendi. |
| `ecg_phase` | `neurokit2/ecg/ecg_phase.py` | `ecgPhase()` | ✅ ported | (Dolaylı süreç) | Atrial / Ventricular faz tayini eklendi. |
| `ecg_segment` | `neurokit2/ecg/ecg_segment.py` | `ecgSegment()` | ✅ ported | (Dolaylı süreç) | R-Peak eksenli epoch/beat ayrıştırması. |
| `ecg_invert` | `neurokit2/ecg/ecg_invert.py` | `ecgInvert()` | ✅ ported | (Dolaylı süreç) | Yön tespiti (Inversion detection). |
| `signal_rate` | `neurokit2/signal/signal_rate.py` | `signalRate()` | ✅ verified | `ecg_process_golden.json` | R-R aralıklarından anlık BPM çıkarımı ve linear/cubic/nearest interpolasyon. |

## Durum Tanımları (Status)
- **planned:** Planlandı ancak henüz başlanmadı.
- **in_progress:** Geliştirme aşamasında.
- **ported:** Kodlar Dart'a aktarıldı, syntax hatası yok, temel çalışabilirlik sağlandı.
- **verified:** Dart kodları Python NeuroKit2 ile Golden Reference eşleşme/test aşamasını başarıyla tamamladı.
- **deferred:** Sonraki versiyonlara ertelendi (Örn. `ecg_rsp`, matplotlib çıktıları).
