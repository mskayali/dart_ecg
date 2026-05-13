/// ECG signal simulation.
///
/// Port of neurokit2.ecg_simulate — generates artificial ECG signals
/// using either a simple Daubechies wavelet model or the ECGSYN
/// dynamical model (McSharry et al., 2003).
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fftea/fftea.dart' as fftea;

import '../dsp/array_ops.dart';
import '../dsp/resample.dart';
import '../dsp/wavelet.dart';

/// Simulate an ECG signal.
///
/// [duration] — recording length in seconds.
/// [samplingRate] — desired sampling rate in Hz.
/// [length] — desired signal length (overrides duration).
/// [noise] — noise amplitude (0 for clean signal).
/// [heartRate] — desired heart rate in BPM.
/// [heartRateStd] — heart rate variability (BPM std).
/// [method] — 'simple'/'daubechies' or 'ecgsyn'.
/// [seed] — random seed for reproducibility.
///
/// Returns simulated ECG signal.
List<double> ecgSimulate({
  double duration = 10,
  double samplingRate = 1000,
  int? length,
  double noise = 0.01,
  double heartRate = 70,
  double heartRateStd = 1,
  String method = 'ecgsyn',
  int? seed,
}) {
  final rng = math.Random(seed);

  // Calculate length if not specified
  final len = length ?? (duration * samplingRate).ceil();
  final dur = length != null ? length / samplingRate : duration;

  List<double> ecg;

  if (['simple', 'daubechies'].contains(method.toLowerCase())) {
    ecg = _ecgSimulateDaubechies(
      duration: dur,
      length: len,
      samplingRate: samplingRate,
      heartRate: heartRate,
    );
  } else {
    // ECGSYN dynamical model
    ecg = _ecgSimulateEcgsyn(
      sfecg: samplingRate,
      numBeats: (dur * heartRate / 60).round(),
      hrmean: heartRate,
      hrstd: heartRateStd,
      sfint: samplingRate,
      rng: rng,
    );
    // Cut to match expected length
    if (ecg.length > len) {
      ecg = ecg.sublist(0, len);
    } else if (ecg.length < len) {
      ecg = [...ecg, ...zeros(len - ecg.length)];
    }
  }

  // Add noise
  if (noise > 0) {
    ecg = _signalDistort(
      ecg,
      samplingRate: samplingRate,
      noiseAmplitude: noise,
      rng: rng,
    );
  }

  return ecg;
}

/// Daubechies wavelet-based ECG simulation.
///
/// Uses db10 wavelet reconstruction coefficients as a rough
/// approximation of a single cardiac cycle.
List<double> _ecgSimulateDaubechies({
  required double duration,
  required int length,
  required double samplingRate,
  required double heartRate,
}) {
  // db10 wavelet ≈ single cardiac cycle
  final cardiac = List<double>.from(db10RecLo);

  // Add resting gap after PQRST
  final cycle = [...cardiac, ...zeros(10)];

  // Number of beats
  final numBeats = (duration * heartRate / 60).round();

  // Tile cycles
  var ecg = tile(cycle, numBeats);

  // Scale amplitude
  ecg = ecg.scale(10);

  // Resample to desired length
  ecg = signalResample(ecg, length);

  return ecg;
}

/// ECGSYN dynamical model simulation.
///
/// Python translation of McSharry & Clifford (2003) ECGSYN model.
/// Uses RR process generation and 4th-order Runge-Kutta ODE solver.
List<double> _ecgSimulateEcgsyn({
  required double sfecg,
  required int numBeats,
  required double hrmean,
  required double hrstd,
  required double sfint,
  required math.Random rng,
  double lfhfratio = 0.5,
  List<double>? ti,
  List<double>? ai,
  List<double>? bi,
}) {
  // Default ECGSYN parameters (P, Q, R, S, T)
  var tiRad = ti ?? [-70, -15, 0, 15, 100];
  var aiVals = ai ?? [1.2, -5, 30, -7.5, 0.75];
  var biVals = bi ?? [0.25, 0.1, 0.1, 0.1, 0.4];

  // Convert angles to radians
  tiRad = tiRad.scale(math.pi / 180);

  // Adjust for heart rate
  final hrfact = math.sqrt(hrmean / 60);
  final hrfact2 = math.sqrt(hrfact);
  biVals = biVals.scale(hrfact);
  final tiFactors = [hrfact2, hrfact, 1.0, hrfact, hrfact2];
  tiRad = List<double>.generate(
      5, (i) => tiFactors[i] * tiRad[i]);

  // RR process parameters
  const flo = 0.1;
  const fhi = 0.25;
  const flostd = 0.01;
  const fhistd = 0.01;
  const sfrr = 1.0;
  final rrmean = 60 / hrmean;
  final n = math.pow(2, (math.log(numBeats * rrmean / (1 / sfrr)) /
      math.log(2)).ceil()).toInt();

  // Generate RR process
  final rr0 = _ecgSimulateRrprocess(
    flo: flo, fhi: fhi,
    flostd: flostd, fhistd: fhistd,
    lfhfratio: lfhfratio,
    hrmean: hrmean, hrstd: hrstd,
    sfrr: sfrr, n: n, rng: rng,
  );

  // Upsample RR from 1 Hz to sfint Hz
  final rrLen = (rr0.length * sfint / sfrr).round();
  final rr = signalResample(rr0, rrLen);

  // Make rrn time series
  final dt = 1.0 / sfint;
  final rrn = List<double>.filled(rr.length, 0.0);
  var tecg = 0.0;
  var i = 0;
  var ip = 0;
  while (i < rr.length) {
    tecg += rr[i];
    ip = (tecg / dt).round();
    ip = math.min(ip, rr.length);
    for (var j = i; j < ip && j < rr.length; j++) {
      rrn[j] = rr[i];
    }
    i = ip;
  }
  final nt = math.min(ip, rr.length);

  // Integrate using RK4
  final tEval = linspace(0, (nt - 1) * dt, nt);
  var state = [1.0, 0.0, 0.04]; // x0, y0, z0

  final zValues = <double>[];

  for (var step = 0; step < tEval.length; step++) {
    final t = tEval[step];
    zValues.add(state[2]);

    if (step < tEval.length - 1) {
      final h = tEval[step + 1] - t;
      state = _rk4Step(t, state, h, rrn, tiRad, sfint, aiVals, biVals);
    }
  }

  // Downsample
  final q = (sfint / sfecg).round();
  final downsampled = <double>[];
  for (var j = 0; j < zValues.length; j += math.max(1, q)) {
    downsampled.add(zValues[j]);
  }

  // Scale signal to lie between -0.4 and 1.2 mV
  if (downsampled.isEmpty) return [];
  final zmin = downsampled.min;
  final zmax = downsampled.max;
  final zrange = zmax - zmin;
  if (zrange == 0) return downsampled;

  return List<double>.generate(
    downsampled.length,
    (k) => (downsampled[k] - zmin) * 1.6 / zrange - 0.4,
  );
}

/// RK4 single step.
List<double> _rk4Step(
  double t,
  List<double> state,
  double h,
  List<double> rrn,
  List<double> ti,
  double sfint,
  List<double> ai,
  List<double> bi,
) {
  final k1 = _ecgsynDerivs(t, state, rrn, ti, sfint, ai, bi);
  final s1 = List<double>.generate(3, (i) => state[i] + 0.5 * h * k1[i]);

  final k2 = _ecgsynDerivs(t + 0.5 * h, s1, rrn, ti, sfint, ai, bi);
  final s2 = List<double>.generate(3, (i) => state[i] + 0.5 * h * k2[i]);

  final k3 = _ecgsynDerivs(t + 0.5 * h, s2, rrn, ti, sfint, ai, bi);
  final s3 = List<double>.generate(3, (i) => state[i] + h * k3[i]);

  final k4 = _ecgsynDerivs(t + h, s3, rrn, ti, sfint, ai, bi);

  return List<double>.generate(3, (i) =>
    state[i] + (h / 6.0) * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]));
}

/// ECGSYN ODE derivatives.
///
/// Port of _ecg_simulate_derivsecgsyn.
List<double> _ecgsynDerivs(
  double t,
  List<double> x,
  List<double> rr,
  List<double> ti,
  double sfint,
  List<double> ai,
  List<double> bi,
) {
  final ta = math.atan2(x[1], x[0]);
  const r0 = 1.0;
  final a0 = 1.0 - math.sqrt(x[0] * x[0] + x[1] * x[1]) / r0;

  final ip = math.min((t * sfint).floor(), rr.length - 1);
  final w0 = 2 * math.pi / rr[math.max(0, ip)];

  const fresp = 0.25;
  final zbase = 0.005 * math.sin(2 * math.pi * fresp * t);

  final dx1dt = a0 * x[0] - w0 * x[1];
  final dx2dt = a0 * x[1] + w0 * x[0];

  // Sum over PQRST components
  var dx3dt = 0.0;
  for (var j = 0; j < 5; j++) {
    var dti = (ta - ti[j]);
    // Matlab-style remainder: dti - round(dti/(2*pi)) * 2*pi
    dti = dti - (dti / (2 * math.pi)).roundToDouble() * 2 * math.pi;
    dx3dt -= ai[j] * dti * math.exp(-0.5 * (dti / bi[j]) * (dti / bi[j]));
  }
  dx3dt -= (x[2] - zbase);

  return [dx1dt, dx2dt, dx3dt];
}

/// Generate RR interval process using spectral method.
///
/// Port of _ecg_simulate_rrprocess.
List<double> _ecgSimulateRrprocess({
  required double flo,
  required double fhi,
  required double flostd,
  required double fhistd,
  required double lfhfratio,
  required double hrmean,
  required double hrstd,
  required double sfrr,
  required int n,
  required math.Random rng,
}) {
  final w1 = 2 * math.pi * flo;
  final w2 = 2 * math.pi * fhi;
  final c1 = 2 * math.pi * flostd;
  final c2 = 2 * math.pi * fhistd;
  const sig2 = 1.0;
  final sig1 = lfhfratio;
  final rrmean = 60.0 / hrmean;
  final rrstd = 60.0 * hrstd / (hrmean * hrmean);

  final df = sfrr / n;
  final w = List<double>.generate(n, (i) => i * 2 * math.pi * df);

  // Power spectrum
  final hw = List<double>.generate(n, (i) {
    final dw1 = w[i] - w1;
    final dw2 = w[i] - w2;
    final hw1 = sig1 * math.exp(-0.5 * (dw1 / c1) * (dw1 / c1)) /
        math.sqrt(2 * math.pi * c1 * c1);
    final hw2 = sig2 * math.exp(-0.5 * (dw2 / c2) * (dw2 / c2)) /
        math.sqrt(2 * math.pi * c2 * c2);
    return hw1 + hw2;
  });

  // Make symmetric
  final half = n ~/ 2;
  final hw0 = List<double>.filled(n, 0.0);
  for (var i = 0; i < half; i++) {
    hw0[i] = hw[i];
  }
  for (var i = 0; i < half; i++) {
    hw0[half + i] = hw[half - 1 - i];
  }

  final sw = List<double>.generate(n, (i) =>
      (sfrr / 2) * math.sqrt(hw0[i]));

  // Random phases
  final ph = List<double>.filled(n, 0.0);
  for (var i = 1; i < half; i++) {
    final p = 2 * math.pi * rng.nextDouble();
    ph[i] = p;
    ph[n - i] = -p;
  }

  // Construct complex spectrum and IFFT
  final reals = List<double>.generate(n, (i) => sw[i] * math.cos(ph[i]));
  final imags = List<double>.generate(n, (i) => sw[i] * math.sin(ph[i]));

  // IFFT using fftea
  final fft = fftea.FFT(n);
  final input = Float64x2List(n);
  for (var i = 0; i < n; i++) {
    input[i] = Float64x2(reals[i], imags[i]);
  }
  fft.inPlaceFft(input);

  // Extract real part and scale
  final x = List<double>.generate(n, (i) => input[i].x / n);

  // Normalize to desired RR statistics
  final xstd = x.std;
  final ratio = xstd > 0 ? rrstd / xstd : 1.0;
  return List<double>.generate(n, (i) => rrmean + x[i] * ratio);
}

/// Add distortion/noise to a signal.
///
/// Simplified port of neurokit2.signal_distort.
List<double> _signalDistort(
  List<double> signal, {
  required double samplingRate,
  required double noiseAmplitude,
  required math.Random rng,
}) {
  final n = signal.length;
  final noise = List<double>.generate(n, (i) {
    // Laplace noise approximation using difference of exponentials
    final u = rng.nextDouble() - 0.5;
    final sign = u >= 0 ? 1.0 : -1.0;
    return -sign * math.log(1 - 2 * u.abs()) * noiseAmplitude;
  });

  return List<double>.generate(n, (i) => signal[i] + noise[i]);
}
