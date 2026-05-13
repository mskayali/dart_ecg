import 'dart:convert';
import 'dart:io';
import 'package:dart_ecg/dart_ecg.dart';

void main() {
  final file = File('test/golden/ecg_process_golden.json');
  final jsonString = file.readAsStringSync();
  final data = jsonDecode(jsonString) as Map<String, dynamic>;
  final raw = (data['raw'] as List).map((e) => (e as num).toDouble()).toList();
  final samplingRate = (data['sampling_rate'] as num).toDouble();
  final nkRpeaks = (data['rpeaks'] as List).map((e) => (e as num).toInt()).toList();

  final result = ecgProcess(raw, samplingRate: samplingRate, method: 'neurokit');

  print('NK peaks: $nkRpeaks');
  print('Dart peaks: ${result.rpeakIndices}');
  
  if (result.rpeakIndices.length != nkRpeaks.length) {
    print('Length mismatch: Dart=${result.rpeakIndices.length}, NK=${nkRpeaks.length}');
  }
}
