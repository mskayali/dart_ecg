import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:test/test.dart';
import 'package:dart_ecg/dart_ecg.dart';

void main() {
  group('ECG Process Golden Tests', () {
    late Map<String, dynamic> data;
    late List<double> raw;
    late double samplingRate;

    setUpAll(() {
      final file = File('test/golden/ecg_process_golden.json');
      final jsonString = file.readAsStringSync();
      data = jsonDecode(jsonString) as Map<String, dynamic>;
      raw = (data['raw'] as List).map((e) => (e as num).toDouble()).toList();
      samplingRate = (data['sampling_rate'] as num).toDouble();
    });

    test('ecg_process matches neurokit2 output', () {
      final result = ecgProcess(raw, samplingRate: samplingRate, method: 'neurokit');

      final nkClean = (data['clean'] as List).map((e) => (e as num).toDouble()).toList();
      final nkRpeaks = (data['rpeaks'] as List).map((e) => (e as num).toInt()).toList();
      // Remove unused local variables
      // final nkRpeaksSignal = (data['rpeaks_signal'] as List).map((e) => (e as num).toDouble()).toList();
      // final nkRate = (data['rate'] as List).map((e) => (e as num).toDouble()).toList();
      // final nkQuality = (data['quality'] as List).map((e) => (e as num).toDouble()).toList();

      // Check lengths
      expect(result.ecgCleaned.length, equals(raw.length));
      
      // 1. Check clean signal (correlation should be > 0.99)
      // With the extended padLen, transients are absorbed and morphology matches Python's scipy.signal.filtfilt
      // very closely (> 0.995).
      final cleanCorr = correlation(result.ecgCleaned, nkClean);
      expect(cleanCorr, greaterThan(0.99), reason: 'Clean signals are not highly correlated');

      // 2. Check R-peaks (should be exact or within a few samples)
      // The number of peaks should be exactly the same
      expect(result.rpeakIndices.length, equals(nkRpeaks.length), reason: 'Different number of R-peaks detected');
      for (var i = 0; i < nkRpeaks.length; i++) {
        expect((result.rpeakIndices[i] - nkRpeaks[i]).abs(), lessThanOrEqualTo(2), reason: 'R-peak mismatch at peak $i');
      }

      // 3. Check rate
      // Rate is computed from RR intervals. We just check if it's within sensible bounds [30 - 200]
      for (var i = 0; i < raw.length; i++) {
        if (!result.ecgRate[i].isNaN) {
            expect(result.ecgRate[i], greaterThan(30.0));
            expect(result.ecgRate[i], lessThan(200.0));
        }
      }

      // 4. Check quality
      // Quality should be between 0 and 1
      for (var i = 0; i < raw.length; i++) {
        if (!result.ecgQuality![i].isNaN) {
            expect(result.ecgQuality![i], greaterThanOrEqualTo(0.0));
            expect(result.ecgQuality![i], lessThanOrEqualTo(1.0));
        }
      }
    });

    test('ecgRsp (EDR) matches neurokit2 output', () {
      final rate = (data['rate'] as List).map((e) => (e as num).toDouble()).toList();
      final nkEdrVangent = (data['edr_vangent'] as List).map((e) => (e as num).toDouble()).toList();
      
      final edrVangent = ecgRsp(rate, samplingRate: samplingRate, method: 'vangent2019');
      
      // Replace NaNs with 0 for correlation
      final edrVangentClean = edrVangent.map((e) => e.isNaN ? 0.0 : e).toList();
      final nkEdrVangentClean = nkEdrVangent.map((e) => e.isNaN ? 0.0 : e).toList();
      
      final corrVangent = correlation(edrVangentClean, nkEdrVangentClean);
      expect(corrVangent.abs(), greaterThan(0.95), reason: 'vangent2019 EDR signals are not highly correlated (absolute)');
    });

    test('ecg_delineate with cwt method matches neurokit2 output', () {
      final nkRpeaks = (data['rpeaks'] as List).map((e) => (e as num).toInt()).toList();
      final nkCwtPPeaks = (data['cwt_p_peaks'] as List).map((e) => e == null ? double.nan : (e as num).toDouble()).toList();
      final nkCwtTPeaks = (data['cwt_t_peaks'] as List).map((e) => e == null ? double.nan : (e as num).toDouble()).toList();
      
      final cwtWaves = ecgDelineate(raw, nkRpeaks, samplingRate: samplingRate, method: 'cwt');
      
      // Compare P peaks
      int matchCountP = 0;
      int validCountP = 0;
      for (var i = 0; i < nkCwtPPeaks.length; i++) {
        final nkP = nkCwtPPeaks[i];
        if (!nkP.isNaN) {
          validCountP++;
          // Find if there's a P peak in cwtWaves nearby
          final idx = nkP.toInt();
          bool found = false;
          for (var j = math.max(0, idx - 5); j <= math.min(raw.length - 1, idx + 5); j++) {
            if (cwtWaves['ECG_P_Peaks']![j] == 1.0) {
              found = true;
              break;
            }
          }
          if (found) matchCountP++;
        }
      }
      expect(matchCountP / validCountP, greaterThan(0.8), reason: 'CWT P peaks do not match well');
      
      // Compare T peaks
      int matchCountT = 0;
      int validCountT = 0;
      for (var i = 0; i < nkCwtTPeaks.length; i++) {
        final nkT = nkCwtTPeaks[i];
        if (!nkT.isNaN) {
          validCountT++;
          final idx = nkT.toInt();
          bool found = false;
          for (var j = math.max(0, idx - 5); j <= math.min(raw.length - 1, idx + 5); j++) {
            if (cwtWaves['ECG_T_Peaks']![j] == 1.0) {
              found = true;
              break;
            }
          }
          if (found) matchCountT++;
        }
      }
      expect(matchCountT / validCountT, greaterThan(0.8), reason: 'CWT T peaks do not match well');
    });
  });
}
