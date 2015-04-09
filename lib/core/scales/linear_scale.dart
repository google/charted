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

  void _reset() {
    if (nice) {
      _domain = ScaleUtils.nice(
          _domain, ScaleUtils.niceStep(_linearTickRange().step));
    }

    Function linear = math.min(_domain.length, _range.length) > 2 ?
        ScaleUtils.polylinearScale : ScaleUtils.bilinearScale;

    Function uninterpolator = clamp ? uninterpolateClamp : uninterpolateNumber;
    InterpolatorGenerator interpolator =
        _rounded ? createRoundedNumberInterpolator : createNumberInterpolator;

    _invert =
        linear(_range, _domain, uninterpolator, createNumberInterpolator);
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
    _reset();
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
      _reset();
    }
  }

  @override
  bool get nice => _nice;

  @override
  Extent get rangeExtent => ScaleUtils.extent(_range);

  @override
  num scale(num value) => _scale(value);

  @override
  num invert(num value) => _invert(value);

  Range _linearTickRange([Extent extent]) {
    if (extent == null) {
      extent = ScaleUtils.extent(_domain);
    }
    var span = extent.max - extent.min,
        step =
            math.pow(10, (math.log(span / _ticksCount) / math.LN10).floor()),
        err = _ticksCount / span * step;

    // Filter ticks to get closer to the desired count.
    if (err <= .15) {
      step *= 10;
    }
    else if (err <= .35) {
      step *= 5;
    }
    else if (err <= .75) {
      step *= 2;
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
