/// ECG signal quality assessment.
///
/// Port of neurokit2.ecg_quality — assesses signal quality using
/// the 'averageQRS' correlation method.
import 'dart:math' as math;

import '../dsp/statistics.dart';
import 'ecg_segment.dart';

/// Assess ECG signal quality.
///
/// [ecgCleaned] — cleaned ECG signal.
/// [rpeaks] — R-peak indices.
/// [samplingRate] — sampling frequency in Hz.
/// [method] — quality method: 'averageqrs' (default).
///
/// Returns quality index at each sample (0 = bad, 1 = good).
List<double> ecgQuality(
  List<double> ecgCleaned,
  List<int> rpeaks, {
  double samplingRate = 1000,
  String method = 'averageqrs',
}) {
  if (rpeaks.isEmpty) {
    return List<double>.filled(ecgCleaned.length, 0.0);
  }

  switch (method.toLowerCase()) {
    case 'averageqrs':
    default:
      return _ecgQualityAverageqrs(ecgCleaned, rpeaks, samplingRate);
  }
}

/// Average QRS correlation method.
///
/// Segments heartbeats, computes average template, and measures
/// correlation of each beat to the template.
List<double> _ecgQualityAverageqrs(
  List<double> ecgCleaned,
  List<int> rpeaks,
  double samplingRate,
) {
  // Segment heartbeats
  final segments = ecgSegment(ecgCleaned, rpeaks,
      samplingRate: samplingRate);

  if (segments.isEmpty) {
    return List<double>.filled(ecgCleaned.length, 0.0);
  }

  // Normalize segment lengths to shortest
  final segmentList = segments.values.toList();
  final minLen = segmentList.map((s) => s.length).reduce(math.min);

  final normalized = segmentList.map((s) {
    if (s.length > minLen) return s.sublist(0, minLen);
    return s;
  }).toList();

  // Compute average template
  final template = List<double>.filled(minLen, 0.0);
  for (final seg in normalized) {
    for (var i = 0; i < minLen; i++) {
      template[i] += seg[i];
    }
  }
  for (var i = 0; i < minLen; i++) {
    template[i] /= normalized.length;
  }

  // Compute correlation of each beat with template
  final beatQualities = <double>[];
  for (final seg in normalized) {
    beatQualities.add(correlation(seg, template).abs());
  }

  // Interpolate quality to full signal length
  final quality = List<double>.filled(ecgCleaned.length, 0.0);

  for (var i = 0; i < rpeaks.length && i < beatQualities.length; i++) {
    // Determine region this beat covers
    final start = i == 0
        ? 0
        : (rpeaks[i - 1] + rpeaks[i]) ~/ 2;
    final end = i == rpeaks.length - 1
        ? ecgCleaned.length
        : (rpeaks[i] + rpeaks[i + 1]) ~/ 2;

    for (var j = start; j < end && j < ecgCleaned.length; j++) {
      quality[j] = beatQualities[i];
    }
  }

  return quality;
}
