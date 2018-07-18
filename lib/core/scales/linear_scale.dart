//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//
part of charted.core.scales;

class LinearScale extends BaseLinearScale {
  LinearScale();
  LinearScale._clone(LinearScale source) : super._clone(source);

  @override
  Iterable<num> get ticks => _linearTickRange();

  @override
  LinearScale clone() => new LinearScale._clone(this);
}

abstract class BaseLinearScale implements Scale<num, num> {
  static const List<int> defaultDomain = const [0, 1];
  static const List<int> defaultRange = const [0, 1];

  bool _rounded = false;
  Iterable<num> _domain;
  Iterable<num> _range;

  int _ticksCount = 5;
  int _forcedTicksCount = -1;

  bool _clamp = false;
  bool _nice = false;
  num Function(num) _invert;
  num Function(num) _scale;

  BaseLinearScale()
      : _domain = defaultDomain,
        _range = defaultRange;

  BaseLinearScale._clone(BaseLinearScale source)
      : _domain = new List<num>.from(source._domain),
        _range = new List<num>.from(source._range),
        _ticksCount = source._ticksCount,
        _clamp = source._clamp,
        _nice = source._nice,
        _rounded = source._rounded {
    _reset();
  }

  void _reset({bool nice: false}) {
    if (nice) {
      _domain = ScaleUtils.nice(
          _domain, ScaleUtils.niceStep(_linearTickRange().step));
    } else {
      if (_forcedTicksCount > 0) {
        var tickRange = _linearTickRange();
        _domain = [tickRange.first, tickRange.last];
      }
    }

    num Function(num) Function(List<num>, List<num>,
            InterpolatorGenerator<num, num>, InterpolatorGenerator<num, num>)
        linear = math.min(_domain.length, _range.length) > 2
            ? ScaleUtils.polylinearScale
            : ScaleUtils.bilinearScale;

    InterpolatorGenerator<num, num> uninterpolator =
        clamp ? uninterpolateClamp : uninterpolateNumber;
    InterpolatorGenerator<num, num> interpolator =
        rounded ? createRoundedNumberInterpolator : createNumberInterpolator;

    _invert = linear(_range, _domain, uninterpolator, createNumberInterpolator);
    _scale = linear(_domain, _range, uninterpolator, interpolator);
  }

  @override
  set range(Iterable<num> value) {
    assert(value != null);
    _range = value;
    _reset();
  }

  @override
  Iterable<num> get range => _range;

  @override
  set domain(Iterable<num> value) {
    _domain = value;
    _reset(nice: _nice);
  }

  @override
  Iterable<num> get domain => _domain;

  @override
  set rounded(bool value) {
    assert(value != null);
    if (value != null && _rounded != value) {
      _rounded = value;
      _reset();
    }
  }

  @override
  bool get rounded => _rounded;

  @override
  set ticksCount(int value) {
    assert(value != null);
    if (value != null && _ticksCount != value) {
      _ticksCount = value;
      _reset();
    }
  }

  @override
  int get ticksCount => _ticksCount;

  @override
  set forcedTicksCount(int value) {
    _forcedTicksCount = value;
    _reset(nice: false);
  }

  @override
  int get forcedTicksCount => _forcedTicksCount;

  @override
  set clamp(bool value) {
    assert(value != null);
    if (value != null && _clamp != value) {
      _clamp = value;
      _reset();
    }
  }

  @override
  bool get clamp => _clamp;

  @override
  set nice(bool value) {
    assert(value != null);
    if (value != null && _nice != value) {
      _nice = value;
      _reset(nice: _nice);
    }
  }

  @override
  bool get nice => _nice;

  @override
  Extent<num> get rangeExtent => ScaleUtils.extent(_range);

  @override
  num scale(num value) => _scale(value);

  @override
  num invert(num value) => _invert(value);

  Range _linearTickRange([Extent<num> extent]) {
    extent ??= ScaleUtils.extent(_domain);
    num span = extent.max - extent.min;
    if (span == 0) {
      span = 1.0; // [span / _ticksCount] should never be equal zero.
    }

    num step;
    if (_forcedTicksCount > 0) {
      // Find the factor (in power of 10) for the max and min of the extent and
      // round the max up and min down to make sure the domain of the scale is
      // of nicely rounded number and it contains the original domain.  This way
      // when forcing the ticks count at least the two ends of the scale would
      // look nice and has a high chance of having the intermediate tick values
      // to be nice.
      var maxFactor = extent.max == 0
          ? 1
          : math.pow(
              10,
              (math.log(extent.max.abs() / forcedTicksCount) / math.ln10)
                  .floor());
      num max = (extent.max / maxFactor).ceil() * maxFactor;
      num minFactor = extent.min == 0
          ? 1
          : math.pow(
              10,
              (math.log(extent.min.abs() / forcedTicksCount) / math.ln10)
                  .floor());
      num min = (extent.min / minFactor).floor() * minFactor;
      step = (max - min) / forcedTicksCount;
      return new Range(min, max + step * 0.5, step);
    } else {
      step = math.pow(10, (math.log(span / _ticksCount) / math.ln10).floor());
      var err = _ticksCount / span * step;

      // Filter ticks to get closer to the desired count.
      if (err <= .15) {
        step *= 10;
      } else if (err <= .35) {
        step *= 5;
      } else if (err <= .75) {
        step *= 2;
      }
    }

    return new Range((extent.min / step).ceil() * step,
        (extent.max / step).floor() * step + step * 0.5, step);
  }

  @override
  FormatFunction createTickFormatter([String formatStr]) {
    if (formatStr == null) {
      int precision(num value) {
        return -(math.log(value) / math.ln10 + .01).floor();
      }

      Range tickRange = _linearTickRange();
      formatStr = ".${precision(tickRange.step)}f";
    }
    return Scale.numberFormatter.format(formatStr);
  }
}
