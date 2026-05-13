# dart_ecg

A Pure Dart port of the popular **NeuroKit2** ECG processing module. This library provides a robust, zero-dependency (native Dart) toolkit for Electrocardiogram (ECG) signal processing, including cleaning, R-peak detection, delineation, quality assessment, heart rate calculation, and respiratory rate extraction (EDR).

## Features

- **ECG Simulation**: Generate synthetic ECG signals (`ecgsyn` method) for testing and development.
- **Signal Cleaning**: High-performance Butterworth filtering, detrending, and powerline noise removal.
- **R-Peak Detection**: Robust algorithms (e.g., `neurokit`) for finding R-peaks even in noisy signals.
- **Wave Delineation**: Delineate P, Q, S, and T waves using DWT (Discrete Wavelet Transform), CWT (Continuous Wavelet Transform), or Peak methods.
- **ECG Quality**: Estimate signal quality to reject noisy epochs.
- **ECG-Derived Respiration (EDR)**: Extract respiratory rates from ECG using methods like `vangent2019`, `charlton2016`, `soni2019`, and `sarkar2015`.
- **100% NeuroKit2 Parity**: Numerically validated against the Python NeuroKit2 reference.

## Usage

A simple usage example:

```dart
import 'package:dart_ecg/dart_ecg.dart';

void main() {
  // 1. Simulate an ECG signal
  final ecg = ecgSimulate(duration: 10, samplingRate: 250, heartRate: 70);

  // 2. Process the signal
  final result = ecgProcess(ecg, samplingRate: 250);

  print('Detected R-Peaks: \${result.rpeakIndices.length}');
  print('Average Heart Rate: \${result.ecgRate.nanmean.toStringAsFixed(1)} BPM');
  
  // 3. Get EDR (ECG-Derived Respiration)
  final edr = ecgRsp(result.ecgRate, samplingRate: 250);
}
```

## Algorithms

This package implements the following algorithms directly in Dart:
* **Cleaning**: Neurokit, Biosppy, Pantompkins1985, Hamilton2002, Elgendi2010, Engzeemod2012.
* **Peak Detection**: Neurokit, Pantompkins1985.
* **Delineation**: DWT (Discrete Wavelet Transform), CWT (Continuous Wavelet Transform), Peak method.
* **EDR**: Vangent2019, Charlton2016, Soni2019, Sarkar2015.

## License

This project is licensed under the MIT License - see the LICENSE file for details. This library is a Dart port of the NeuroKit2 library, which is also licensed under the MIT License.
