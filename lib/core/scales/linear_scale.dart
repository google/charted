//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//
part of charted.core.scales;

class LinearScale implements QuantitativeScale {
  static const defaultDomain = const [0, 1];
  static const defaultRange = const [0, 1];

  bool _rounded = false;
  Iterable _domain = defaultDomain;
  Iterable _range = defaultRange;

  int _ticksCount = 10;
  bool _clamp = true;
  bool _nice = true;

  Function _invert;
  Function _scale;

  LinearScale();

  LinearScale._clone(LinearScale source)
      : _domain = source._domain.toList(),
        _range = source._range.toList(),
        _ticksCount = source._ticksCount,
        _clamp = source._clamp,
        _nice = source._nice,
        _rounded = source._rounded;

  void _reset() {
    if (nice) {
      _domain = ScaleUtil.nice(
          domain, ScaleUtil.niceStep(_linearTickRange().step));
    }

    Function linear = math.min(_domain.length, _range.length) > 2 ?
        ScaleUtil.polylinearScale : ScaleUtil.bilinearScale;

    Function uninterpolator = clamp ? uninterpolateClamp : uninterpolateNumber;
    InterpolatorGenerator interpolator =
        _rounded ? createRoundedNumberInterpolator : createNumberInterpolator;

    _invert =
        linear(_range, _domain, uninterpolator, createNumberInterpolator);
    _scale = linear(_domain, _range, uninterpolator, interpolator);
  }

  @override
  set range(Iterable value) {
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
  Extent get rangeExtent => QuantitativeScale.extent(_range);

  @override
  set rounded(bool value) {
    if (_rounded != value) {
      _reset();
    }
  }

  @override
  bool get rounded => _rounded;

  @override
  Iterable ticks([int count=10]) {
    if (count != _ticksCount) {
      _ticksCount = count;
      _reset();
    }
    return _linearTickRange();
  }

  @override
  set clamp(bool value) {
    if (_clamp != value) {
      _clamp = value;
      _reset();
    }
  }

  @override
  bool get clamp => _clamp;

  @override
  set nice(bool value) {
    if (_nice != value) {
      _nice = value;
      _reset();
    }
  }

  @override
  bool get nice => _nice;

  @override
  num scale(num value) => _scale(value);

  @override
  num invert(num value) => _invert(value);

  Range _linearTickRange() {
    var extent = QuantitativeScale.extent(_domain),
        span = extent.max - extent.min,
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
  FormatFunction tickFormatter([String format = null]) {
    int precision(value) => -(math.log(value) / math.LN10 + .01).floor();
    Range tickRange = _linearTickRange();
    // TODO(prsd): Revisit use of EnusLocale()
    return new EnusLocale().numberFormat.format((format != null) ?
        format : ",." + precision(tickRange.step).toString() + "f");
  }

  @override
  LinearScale clone() => new LinearScale._clone(this);
}
