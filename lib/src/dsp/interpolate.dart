/// Signal interpolation utilities.
///
/// Port of scipy.interpolate and neurokit2.signal_interpolate.

/// Interpolate values at new x positions.
///
/// [x] — original x positions (must be sorted ascending).
/// [y] — original y values at each x.
/// [xNew] — new x positions to interpolate at.
/// [method] — interpolation method: 'linear', 'nearest', 'previous', 'cubic'.
List<double> signalInterpolate(
  List<double> x,
  List<double> y,
  List<double> xNew, {
  String method = 'linear',
}) {
  if (x.isEmpty || y.isEmpty) return List<double>.filled(xNew.length, 0.0);

  switch (method) {
    case 'nearest':
      return _interpolateNearest(x, y, xNew);
    case 'previous':
      return _interpolatePrevious(x, y, xNew);
    case 'cubic':
      return _interpolateCubic(x, y, xNew);
    case 'linear':
    default:
      return _interpolateLinear(x, y, xNew);
  }
}

/// Convenience: interpolate peaks to full signal length.
///
/// [peakIndices] — indices of peaks.
/// [peakValues] — values at peak positions.
/// [desiredLength] — target signal length.
/// [method] — interpolation method.
List<double> interpolatePeaks(
  List<int> peakIndices,
  List<double> peakValues,
  int desiredLength, {
  String method = 'linear',
}) {
  final x = peakIndices.map((i) => i.toDouble()).toList();
  final xNew = List<double>.generate(desiredLength, (i) => i.toDouble());
  return signalInterpolate(x, peakValues, xNew, method: method);
}

// --- Private implementations ---

List<double> _interpolateLinear(
    List<double> x, List<double> y, List<double> xNew) {
  final result = List<double>.filled(xNew.length, 0.0);
  for (var i = 0; i < xNew.length; i++) {
    result[i] = _linearInterp(x, y, xNew[i]);
  }
  return result;
}

double _linearInterp(List<double> x, List<double> y, double xVal) {
  if (xVal <= x.first) return y.first;
  if (xVal >= x.last) return y.last;

  // Binary search for interval
  var lo = 0;
  var hi = x.length - 1;
  while (hi - lo > 1) {
    final mid = (lo + hi) ~/ 2;
    if (x[mid] <= xVal) {
      lo = mid;
    } else {
      hi = mid;
    }
  }

  final t = (xVal - x[lo]) / (x[hi] - x[lo]);
  return y[lo] + t * (y[hi] - y[lo]);
}

List<double> _interpolateNearest(
    List<double> x, List<double> y, List<double> xNew) {
  final result = List<double>.filled(xNew.length, 0.0);
  for (var i = 0; i < xNew.length; i++) {
    var minDist = double.infinity;
    var bestIdx = 0;
    for (var j = 0; j < x.length; j++) {
      final dist = (xNew[i] - x[j]).abs();
      if (dist < minDist) {
        minDist = dist;
        bestIdx = j;
      }
    }
    result[i] = y[bestIdx];
  }
  return result;
}

List<double> _interpolatePrevious(
    List<double> x, List<double> y, List<double> xNew) {
  final result = List<double>.filled(xNew.length, 0.0);
  for (var i = 0; i < xNew.length; i++) {
    var idx = 0;
    for (var j = 0; j < x.length; j++) {
      if (x[j] <= xNew[i]) {
        idx = j;
      } else {
        break;
      }
    }
    result[i] = y[idx];
  }
  return result;
}

List<double> _interpolateCubic(
    List<double> x, List<double> y, List<double> xNew) {
  // Natural cubic spline interpolation
  final n = x.length;
  if (n < 3) return _interpolateLinear(x, y, xNew);

  // Compute spline coefficients
  final h = List<double>.filled(n - 1, 0.0);
  for (var i = 0; i < n - 1; i++) {
    h[i] = x[i + 1] - x[i];
  }

  // Tridiagonal system for second derivatives
  final alpha = List<double>.filled(n, 0.0);
  for (var i = 1; i < n - 1; i++) {
    alpha[i] = 3.0 / h[i] * (y[i + 1] - y[i]) -
        3.0 / h[i - 1] * (y[i] - y[i - 1]);
  }

  final l = List<double>.filled(n, 1.0);
  final mu = List<double>.filled(n, 0.0);
  final z = List<double>.filled(n, 0.0);

  for (var i = 1; i < n - 1; i++) {
    l[i] = 2.0 * (x[i + 1] - x[i - 1]) - h[i - 1] * mu[i - 1];
    mu[i] = h[i] / l[i];
    z[i] = (alpha[i] - h[i - 1] * z[i - 1]) / l[i];
  }

  final c = List<double>.filled(n, 0.0);
  final b = List<double>.filled(n - 1, 0.0);
  final d = List<double>.filled(n - 1, 0.0);

  for (var j = n - 2; j >= 0; j--) {
    c[j] = z[j] - mu[j] * c[j + 1];
    b[j] = (y[j + 1] - y[j]) / h[j] - h[j] * (c[j + 1] + 2.0 * c[j]) / 3.0;
    d[j] = (c[j + 1] - c[j]) / (3.0 * h[j]);
  }

  // Evaluate spline at xNew
  final result = List<double>.filled(xNew.length, 0.0);
  for (var i = 0; i < xNew.length; i++) {
    final xv = xNew[i];
    if (xv <= x.first) {
      result[i] = y.first;
      continue;
    }
    if (xv >= x.last) {
      result[i] = y.last;
      continue;
    }

    // Find interval
    var j = 0;
    for (var k = 0; k < n - 1; k++) {
      if (xv >= x[k] && xv < x[k + 1]) {
        j = k;
        break;
      }
    }

    final dx = xv - x[j];
    result[i] = y[j] + b[j] * dx + c[j] * dx * dx + d[j] * dx * dx * dx;
  }

  return result;
}
