/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.svg;

/**
 * Implementations of line interpolators are given a list of
 * points and they must return Svg path description to draw
 * a line connecting these points
 */
typedef String LineInterpolator(List<math.Point> points);

/**
 * [SvgLine] provides a data-driven way to create Svg path descriptions
 * that can be used to draw lines.  It internally has support for a few
 * interpolations and can easily be extended to add support for more.
 */
class SvgLine implements SvgPathGenerator {
  // TODO(prsd): Implement more interpolators

  /** Linear interpolator */
  static const String LINEAR = "linear";

  /** Default interpolator */
  static LineInterpolator DEFAULT_INTERPOLATOR = _linear;

  /** Map of interpolator names to implementations */
  static Map<String, LineInterpolator> interpolators = {};

  /**
   * [xAccessor] is used to access/convert datum to x coordinate value.
   * If not specified, [defaultDataToX] is used.
   */
  SelectionValueAccessor<num> xAccessor = defaultDataToX;

  /**
   * [yAccessor] is used to access/convert datum to y coordinate value.
   * If not specified, [defaultDataToY] is used.
   */
  SelectionValueAccessor<num> yAccessor = defaultDataToY;

  /**
   * [defined] is used to determine if a value is considered valid.
   * If this function returns false for any value, that value isn't
   * included in the line and the line gets split.
   */
  SelectionCallback<bool> defined = (d, i, e) => true;

  LineInterpolator _interpolate = DEFAULT_INTERPOLATOR;

  /**
   * Set line interpolation to one of the known/registered
   * interpolation types.  Defaults to [SvgLine.LINEAR]
   */
  set interpolation(String value) {
    if (!interpolators.containsKey(value)) {
      throw new ArgumentError('Unregistered line interpolator.');
    }
    _interpolate = DEFAULT_INTERPOLATOR;
  }

  /** Set a constant value as the x-value on all points in the line */
  set x(num value) => xAccessor = toValueAccessor(value);

  /** Set a constant value as the x-value on all points in the line */
  set y(num value) => yAccessor = toValueAccessor(value);

  /**
   * Get Svg path description for the given [data], element index [index]
   * and element [e] to which the data is associated.
   */
  String path(List data, int index, Element e) {
    var segments = [],
        points = [];

    data.asMap().forEach((int i, d) {
      if (defined(d, i, e)) {
        points.add(new math.Point(xAccessor(d, i), yAccessor(d, i)));
      } else if (points.isNotEmpty) {
        segments.add('M${_interpolate(points)}');
        points = [];
      }
    });

    if (points.isNotEmpty) segments.add('M${_interpolate(points)}');

    return segments.join();
  }

  /**
   * Default implementation of a callback to extract X coordinate
   * value for a given datum.  Assumes that datam is a non-empty
   * array.
   */
  static num defaultDataToX(d, i) => d[0];

  /**
   * Default implementation of a callback to extract Y coordinate
   * value for a given datum.  Assumes that datam is an array of
   * atleast two elements.
   */
  static num defaultDataToY(d, i) => d[1];

  /* Implementation of the linear interpolator */
  static String _linear(List points) =>
      points.map((pt) => '${pt.x},${pt.y}').join('L');
}
