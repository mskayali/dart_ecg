/// NumPy-equivalent array operations for signal processing.
///
/// Provides extension methods on `List<double>` mirroring common
/// numpy functions used throughout NeuroKit2.
import 'dart:math' as math;
import 'dart:typed_data';

/// Generate evenly spaced values over [start, stop] (inclusive).
/// Equivalent to numpy.linspace.
List<double> linspace(double start, double stop, int num) {
  if (num <= 0) return [];
  if (num == 1) return [start];
  final step = (stop - start) / (num - 1);
  return List<double>.generate(num, (i) => start + i * step);
}

/// Generate evenly spaced values in [start, stop) with given step.
/// Equivalent to numpy.arange.
List<double> arange(double start, double stop, [double step = 1.0]) {
  final result = <double>[];
  if (step > 0) {
    for (var v = start; v < stop; v += step) {
      result.add(v);
    }
  } else if (step < 0) {
    for (var v = start; v > stop; v += step) {
      result.add(v);
    }
  }
  return result;
}

/// Generate integer range [0, n).
List<int> arangeInt(int n) => List<int>.generate(n, (i) => i);

/// Create a list of zeros.
List<double> zeros(int n) => List<double>.filled(n, 0.0);

/// Create a list of ones.
List<double> ones(int n) => List<double>.filled(n, 1.0);

/// Create a Float64List of zeros.
Float64List zerosF64(int n) => Float64List(n);

/// Discrete difference: out[i] = a[i+1] - a[i].
/// Equivalent to numpy.diff(a, n=1).
List<double> diff(List<double> a, [int n = 1]) {
  var result = a;
  for (var iter = 0; iter < n; iter++) {
    final tmp = <double>[];
    for (var i = 0; i < result.length - 1; i++) {
      tmp.add(result[i + 1] - result[i]);
    }
    result = tmp;
  }
  return result;
}

/// Numerical gradient (central differences, forward/backward at edges).
/// Equivalent to numpy.gradient.
List<double> gradient(List<double> a) {
  final n = a.length;
  if (n < 2) return List.from(a);
  final result = List<double>.filled(n, 0.0);
  // Forward difference at start
  result[0] = a[1] - a[0];
  // Central differences
  for (var i = 1; i < n - 1; i++) {
    result[i] = (a[i + 1] - a[i - 1]) / 2.0;
  }
  // Backward difference at end
  result[n - 1] = a[n - 1] - a[n - 2];
  return result;
}

/// Cumulative sum.
/// Equivalent to numpy.cumsum.
List<double> cumsum(List<double> a) {
  final result = List<double>.filled(a.length, 0.0);
  if (a.isEmpty) return result;
  result[0] = a[0];
  for (var i = 1; i < a.length; i++) {
    result[i] = result[i - 1] + a[i];
  }
  return result;
}

/// 1D convolution (full mode).
/// Equivalent to numpy.convolve(a, v, mode='full').
List<double> convolve(List<double> a, List<double> v,
    {String mode = 'full'}) {
  final n = a.length;
  final m = v.length;
  final fullLen = n + m - 1;
  final result = List<double>.filled(fullLen, 0.0);

  for (var i = 0; i < fullLen; i++) {
    var sum = 0.0;
    final jMin = math.max(0, i - n + 1);
    final jMax = math.min(i, m - 1);
    for (var j = jMin; j <= jMax; j++) {
      sum += v[j] * a[i - j];
    }
    result[i] = sum;
  }

  if (mode == 'same') {
    final start = (m - 1) ~/ 2;
    return result.sublist(start, start + n);
  } else if (mode == 'valid') {
    final validLen = (n - m + 1).abs() + 1;
    final start = math.min(n, m) - 1;
    return result.sublist(start, start + validLen);
  }
  return result; // 'full'
}

/// Tile (repeat) array n times.
List<double> tile(List<double> a, int reps) {
  final result = <double>[];
  for (var i = 0; i < reps; i++) {
    result.addAll(a);
  }
  return result;
}

/// Extension methods on List<double> for common numpy operations.
extension ArrayOps on List<double> {
  /// Element-wise absolute value.
  List<double> get abs =>
      List<double>.generate(length, (i) => this[i].abs());

  /// Sum of all elements.
  double get sum {
    var s = 0.0;
    for (final v in this) {
      s += v;
    }
    return s;
  }

  /// Mean of all elements.
  double get mean => isEmpty ? 0.0 : sum / length;

  /// Standard deviation (population).
  double get std {
    if (isEmpty) return 0.0;
    final m = mean;
    var s = 0.0;
    for (final v in this) {
      s += (v - m) * (v - m);
    }
    return math.sqrt(s / length);
  }

  /// Variance (population).
  double get variance {
    if (isEmpty) return 0.0;
    final m = mean;
    var s = 0.0;
    for (final v in this) {
      s += (v - m) * (v - m);
    }
    return s / length;
  }

  /// Maximum value.
  double get max {
    var m = this[0];
    for (var i = 1; i < length; i++) {
      if (this[i] > m) m = this[i];
    }
    return m;
  }

  /// Minimum value.
  double get min {
    var m = this[0];
    for (var i = 1; i < length; i++) {
      if (this[i] < m) m = this[i];
    }
    return m;
  }

  /// Index of maximum value.
  int get argmax {
    var idx = 0;
    for (var i = 1; i < length; i++) {
      if (this[i] > this[idx]) idx = i;
    }
    return idx;
  }

  /// Index of minimum value.
  int get argmin {
    var idx = 0;
    for (var i = 1; i < length; i++) {
      if (this[i] < this[idx]) idx = i;
    }
    return idx;
  }

  /// Indices where condition is true.
  List<int> where_(bool Function(double) test) {
    final result = <int>[];
    for (var i = 0; i < length; i++) {
      if (test(this[i])) result.add(i);
    }
    return result;
  }

  /// Element-wise addition.
  List<double> operator +(List<double> other) =>
      List<double>.generate(length, (i) => this[i] + other[i]);

  /// Element-wise subtraction.
  List<double> operator -(List<double> other) =>
      List<double>.generate(length, (i) => this[i] - other[i]);

  /// Element-wise multiplication.
  List<double> elemMul(List<double> other) =>
      List<double>.generate(length, (i) => this[i] * other[i]);

  /// Scalar multiplication.
  List<double> scale(double s) =>
      List<double>.generate(length, (i) => this[i] * s);

  /// Scalar addition.
  List<double> add(double s) =>
      List<double>.generate(length, (i) => this[i] + s);

  /// Element-wise power.
  List<double> pow(double p) =>
      List<double>.generate(length, (i) => math.pow(this[i], p).toDouble());

  /// Element-wise square.
  List<double> get square =>
      List<double>.generate(length, (i) => this[i] * this[i]);

  /// Element-wise square root.
  List<double> get sqrt =>
      List<double>.generate(length, (i) => math.sqrt(this[i]));

  /// Reverse a copy.
  List<double> get reversed_ => List<double>.from(reversed);

  /// Median.
  double get median {
    final sorted = List<double>.from(this)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }

  /// Clip values to [low, high].
  List<double> clip(double low, double high) =>
      List<double>.generate(
          length, (i) => this[i].clamp(low, high).toDouble());

  /// Pad with value at start and end.
  List<double> pad(int before, int after, {double value = 0.0}) {
    return [
      ...List<double>.filled(before, value),
      ...this,
      ...List<double>.filled(after, value),
    ];
  }

  /// Convert to Float64List for performance.
  Float64List toFloat64List() => Float64List.fromList(this);

  /// Nanmean — mean ignoring NaN values.
  double get nanmean {
    var s = 0.0;
    var count = 0;
    for (final v in this) {
      if (!v.isNaN) {
        s += v;
        count++;
      }
    }
    return count == 0 ? 0.0 : s / count;
  }

  /// Nanmedian — median ignoring NaN values.
  double get nanmedian {
    final clean = this.where((v) => !v.isNaN).toList()..sort();
    if (clean.isEmpty) return double.nan;
    final mid = clean.length ~/ 2;
    if (clean.length.isOdd) return clean[mid];
    return (clean[mid - 1] + clean[mid]) / 2.0;
  }
}

/// Extension on List<int> for convenience.
extension IntArrayOps on List<int> {
  /// Convert to List<double>.
  List<double> toDoubles() =>
      List<double>.generate(length, (i) => this[i].toDouble());

  /// Differences.
  List<int> get diffs {
    final result = <int>[];
    for (var i = 0; i < length - 1; i++) {
      result.add(this[i + 1] - this[i]);
    }
    return result;
  }
}
