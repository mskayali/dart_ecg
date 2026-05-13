/// ECG signal cleaning.
///
/// Port of neurokit2.ecg_clean — removes noise and improves
/// peak-detection accuracy using various filtering methods.
///
/// Supported methods:
/// * `neurokit` (default): 0.5 Hz HP butterworth (order 5) + powerline filter
/// * `biosppy`: FIR bandpass [0.67, 45] Hz
/// * `pantompkins1985`: Butterworth BP [5, 15] Hz (order 1)
/// * `hamilton2002`: Butterworth BP [8, 16] Hz (order 1)
/// * `elgendi2010`: Butterworth BP [8, 20] Hz (order 2)
/// * `engzeemod2012`: Butterworth BP [52, 48] Hz (order 4)
/// * `vg`: Butterworth HP 4 Hz (order 2)

import '../dsp/array_ops.dart';
import '../dsp/filter.dart';
import '../signal/signal_fillmissing.dart';

/// Clean an ECG signal to remove noise.
///
/// [ecgSignal] — raw ECG signal.
/// [samplingRate] — sampling frequency in Hz.
/// [method] — cleaning method name.
/// [powerline] — powerline frequency for neurokit method (default: 50 Hz).
///
/// Returns cleaned ECG signal.
List<double> ecgClean(
  List<double> ecgSignal, {
  double samplingRate = 1000,
  String method = 'neurokit',
  double powerline = 50,
}) {
  // Handle missing data (NaN)
  var signal = List<double>.from(ecgSignal);
  final nMissing = signal.where((v) => v.isNaN).length;
  if (nMissing > 0) {
    signal = signalFillmissing(signal, method: 'linear');
  }

  final m = method.toLowerCase();

  if (['nk', 'nk2', 'neurokit', 'neurokit2'].contains(m)) {
    return _ecgCleanNk(signal, samplingRate, powerline: powerline);
  } else if (['biosppy', 'gamboa2008'].contains(m)) {
    return _ecgCleanBiosppy(signal, samplingRate);
  } else if (['pantompkins', 'pantompkins1985'].contains(m)) {
    return _ecgCleanPantompkins(signal, samplingRate);
  } else if (['hamilton', 'hamilton2002'].contains(m)) {
    return _ecgCleanHamilton(signal, samplingRate);
  } else if (['elgendi', 'elgendi2010'].contains(m)) {
    return _ecgCleanElgendi(signal, samplingRate);
  } else if (['engzee', 'engzee2012', 'engzeemod', 'engzeemod2012']
      .contains(m)) {
    return _ecgCleanEngzee(signal, samplingRate);
  } else if (['vg', 'vgraph', 'fastnvg', 'emrich', 'emrich2023'].contains(m)) {
    return _ecgCleanVgraph(signal, samplingRate);
  } else if ([
    'christov', 'christov2004', 'ssf', 'slopesumfunction',
    'zong', 'zong2003', 'kalidas2017', 'swt', 'kalidas',
    'kalidastamil', 'kalidastamil2017',
  ].contains(m)) {
    // These methods don't clean — return as-is
    return signal;
  } else {
    throw ArgumentError(
      "ecgClean: 'method' should be one of 'neurokit', 'biosppy', "
      "'pantompkins1985', 'hamilton2002', 'elgendi2010', "
      "'engzeemod2012', 'vg'.",
    );
  }
}

/// NeuroKit default: HP 0.5Hz (order 5) + powerline filter.
List<double> _ecgCleanNk(
  List<double> signal,
  double samplingRate, {
  double powerline = 50,
}) {
  // 0.5 Hz high-pass butterworth filter (order 5)
  var clean = butterworthHighpass(
    signal: signal,
    order: 5,
    samplingRate: samplingRate,
    cutoff: 0.5,
  );

  // Powerline filter (notch at 50 Hz and harmonics)
  clean = powerlineFilter(
    signal: clean,
    samplingRate: samplingRate,
    powerline: powerline,
  );

  return clean;
}

/// BioSPPy method: FIR bandpass [0.67, 45] Hz.
///
/// Adapted from BioSPPy/biosppy/signals/ecg.py
List<double> _ecgCleanBiosppy(List<double> signal, double samplingRate) {
  // FIR order = 1.5 * sampling_rate (odd)
  var order = (1.5 * samplingRate).round();
  if (order % 2 == 0) order += 1;

  // FIR bandpass [0.67, 45] Hz
  final filtered = firFilter(
    signal: signal,
    numtaps: order,
    samplingRate: samplingRate,
    filterType: FilterType.bandpass,
    lowcut: 0.67,
    highcut: 45,
  );

  // Remove DC offset
  final m = filtered.mean;
  return List<double>.generate(filtered.length, (i) => filtered[i] - m);
}

/// Pan-Tompkins (1985): Butterworth BP [5, 15] Hz (order 1).
List<double> _ecgCleanPantompkins(List<double> signal, double samplingRate) {
  return butterworthBandpass(
    signal: signal,
    order: 1,
    samplingRate: samplingRate,
    lowcut: 5,
    highcut: 15,
  );
}

/// Hamilton (2002): Butterworth BP [8, 16] Hz (order 1).
List<double> _ecgCleanHamilton(List<double> signal, double samplingRate) {
  return butterworthBandpass(
    signal: signal,
    order: 1,
    samplingRate: samplingRate,
    lowcut: 8,
    highcut: 16,
  );
}

/// Elgendi (2010): Butterworth BP [8, 20] Hz (order 2).
List<double> _ecgCleanElgendi(List<double> signal, double samplingRate) {
  return butterworthBandpass(
    signal: signal,
    order: 2,
    samplingRate: samplingRate,
    lowcut: 8,
    highcut: 20,
  );
}

/// Engelse-Zeelenberg: Butterworth BP (order 4).
///
/// Note: Original uses lowcut=52, highcut=48 which is a bandstop.
/// This is consistent with the original NeuroKit2 source.
List<double> _ecgCleanEngzee(List<double> signal, double samplingRate) {
  // The original source uses lowcut=52, highcut=48
  // In signal_filter, when lowcut > highcut, it becomes a bandstop
  return butterworthBandstop(
    signal: signal,
    order: 4,
    samplingRate: samplingRate,
    centerFreq: 50,
    width: 4, // 48-52 Hz range
  );
}

/// Visibility Graph: Butterworth HP 4 Hz (order 2).
List<double> _ecgCleanVgraph(List<double> signal, double samplingRate) {
  return butterworthHighpass(
    signal: signal,
    order: 2,
    samplingRate: samplingRate,
    cutoff: 4,
  );
}
