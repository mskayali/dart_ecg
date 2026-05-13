import 'dart:convert';
import 'dart:io';

import 'package:dart_ecg/dart_ecg.dart';

void main() {
  final file = File('test/golden/ecg_process_golden.json');
  final jsonString = file.readAsStringSync();
  final data = jsonDecode(jsonString) as Map<String, dynamic>;
  final raw = (data['raw'] as List).map((e) => (e as num).toDouble()).toList();
  final samplingRate = (data['sampling_rate'] as num).toDouble();
  final nkClean = (data['clean'] as List).map((e) => (e as num).toDouble()).toList();

  final result = ecgProcess(raw, samplingRate: samplingRate, method: 'neurokit');

  for (var i = 0; i < 10; i++) {
    print('idx $i | nk: ${nkClean[i].toStringAsFixed(4)} | dart: ${result.ecgCleaned[i].toStringAsFixed(4)}');
  }
  
  print('...');
  
  for (var i = raw.length ~/ 2; i < raw.length ~/ 2 + 10; i++) {
    print('idx $i | nk: ${nkClean[i].toStringAsFixed(4)} | dart: ${result.ecgCleaned[i].toStringAsFixed(4)}');
  }
}
