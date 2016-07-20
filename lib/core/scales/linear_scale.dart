//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//
part of charted.core.scales;

class LinearScale implements Scale {
  static const defaultDomain = const [0, 1];
  static const defaultRange = const [0, 1];

  bool _rounded = false;
  Iterable _domain = defaultDomain;
  Iterable _range = defaultRange;

  int _ticksCount = 5;
  int _forcedTicksCount = -1;

  bool _clamp = false;
  bool _nice = false;
  Function _invert;
  Function _scale;

  LinearScale();

  LinearScale._clone(LinearScale source)
      : _domain = source._domain.toList(),
        _range = source._range.toList(),
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

    Function linear = math.min(_domain.length, _range.length) > 2
        ? ScaleUtils.polylinearScale
        : ScaleUtils.bilinearScale;

    Function uninterpolator = clamp ? uninterpolateClamp : uninterpolateNumber;
    InterpolatorGenerator interpolator;
    if (rounded) {
      interpolator = createRoundedNumberInterpolator;
    } else {
      interpolator = createNumberInterpolator;
    }

    _invert = linear(_range, _domain, uninterpolator, createNumberInterpolator);
    _scale = linear(_domain, _range, uninterpolator, interpolator);
  }

  @override
  set range(Iterable value) {
    assert(value != null);
    _range = value;
    _reset();
  }

  @override
  Iterable get range => _range;

  @override
  set domain(Iterable value) {
    _domain = value;
    _reset(nice: _nice);
  }

  @override
  Iterable get domain => _domain;

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

  set forcedTicksCount(int value) {
    _forcedTicksCount = value;
    _reset(nice: false);
  }

  get forcedTicksCount => _forcedTicksCount;

  @override
  Iterable get ticks => _linearTickRange();

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
  Extent get rangeExtent => ScaleUtils.extent(_range);

  @override
  scale(value) => _scale(value);

  @override
  invert(value) => _invert(value);

  Range _linearTickRange([Extent extent]) {
    if (extent == null) {
      extent = ScaleUtils.extent(_domain);
    }
    var span = extent.max - extent.min;
    if (span == 0) {
      span = 1.0; // [span / _ticksCount] should never be equal zero.
    }

    var step;
    if (_forcedTicksCount > 0) {
      // Find the factor (in power of 10) for the max and min of the extent and
      // round the max up and min down to make sure the domain of the scale is
      // of nicely rounded number and it contains the original domain.  This way
      // when forcing the ticks count at least the two ends of the scale would
      // look nice and has a high chance of having the intermediate tick values
      // to be nice.
      var maxFactor = extent.max == 0 ? 1
          : math.pow(10, (math.log((extent.max as num).abs() / forcedTicksCount)
              / math.LN10).floor());
      var max = (extent.max / maxFactor).ceil() * maxFactor;
      var minFactor = extent.min == 0 ? 1
          : math.pow(10, (math.log((extent.min as num).abs() / forcedTicksCount)
              / math.LN10).floor());
      var min = (extent.min / minFactor).floor() * minFactor;
      step = (max - min) / forcedTicksCount;
      return new Range(min, max + step * 0.5, step);
    } else {

      step = math.pow(10, (math.log(span / _ticksCount) / math.LN10).floor());
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
    int precision(value) {
      return -(math.log(value) / math.LN10 + .01).floor();
    }
    Range tickRange = _linearTickRange();
    if (formatStr == null) {
      formatStr = ".${precision(tickRange.step)}f";
    }
    NumberFormat formatter = new NumberFormat(new EnUsLocale());
    return formatter.format(formatStr);
  }

  @override
  LinearScale clone() => new LinearScale._clone(this);
}
