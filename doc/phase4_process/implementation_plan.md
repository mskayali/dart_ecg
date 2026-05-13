# Phase 4: ECG Process Pipeline — Implementation Plan

## Amaç
Tüm ECG modüllerini tek bir pipeline fonksiyonunda birleştirmek. NeuroKit2'nin `ecg_process()` fonksiyonunun 1:1 portu.

## Pipeline Adımları

```
ecgProcess(rawSignal, samplingRate, method)
  ├── 1. ecgClean()         → cleaned signal
  ├── 2. ecgPeaks()         → R-peak indices + binary signal
  ├── 3. signalRate()       → instantaneous BPM
  ├── 4. ecgQuality()       → quality index [0-1]
  ├── 5. ecgDelineate()     → P, Q, S, T wave markers
  └── 6. ecgPhase()         → atrial + ventricular phase
```

## Çıktı: EcgProcessResult

```dart
class EcgProcessResult {
  final List<double> ecgCleaned;
  final List<double>? ecgRaw;
  final List<double> ecgRPeaks;      // binary markers
  final List<int> rpeakIndices;       // sample indices
  final List<double> ecgRate;         // BPM
  final List<double>? ecgQuality;     // quality [0-1]
  final List<double>? ecgPPeaks;      // P-wave markers
  final List<double>? ecgQPeaks;      // Q-wave markers
  final List<double>? ecgSPeaks;      // S-wave markers
  final List<double>? ecgTPeaks;      // T-wave markers
  // ... onsets, offsets, phases
}
```

## toMap() Desteği
Pandas DataFrame karşılığı olarak `Map<String, List<double>>` dönüşümü.
