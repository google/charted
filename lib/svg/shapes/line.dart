//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.svg.shapes;

/// Function to convert a list of points to path.
typedef String LineInterpolator(Iterable<math.Point> points, int tension);

///
/// [SvgLine] provides a data-driven way to create path descriptions
/// that can be used to draw lines.
///
class SvgLine implements SvgShape {
  static const LINE_INTERPOLATOR_LINEAR = 'linear';

  static final LINE_INTERPOLATORS = <String, LineInterpolator>{
    LINE_INTERPOLATOR_LINEAR: _linear
  };

  /// Callback to access/convert datum to x coordinate value.
  final SelectionValueAccessor<num> xValueAccessor;

  /// Callback to access/convert datum to y coordinate value.
  final SelectionValueAccessor<num> yValueAccessor;

  /// Callback that is used to determine if a value is considered valid.
  /// If [isDefined] returns false at any time, the value isn't part
  /// of the line - the line would be split.
  final SelectionCallback<bool> isDefined;

  /// Interpolator that is used for creating the path.
  final LineInterpolator interpolator;

  /// Tension of the line, as used by a few interpolators.
  final int tension;

  SvgLine(
      {this.xValueAccessor: defaultDataToX,
      this.yValueAccessor: defaultDataToY,
      this.isDefined: defaultIsDefined,
      this.tension: 0,
      String interpolate: LINE_INTERPOLATOR_LINEAR})
      : interpolator = LINE_INTERPOLATORS[interpolate] {
    assert(interpolator != null);
  }

  /// Generates path for drawing a line based in the selected [interpolator]
  @override
  String path(data, int index, Element e) {
    assert(data is Iterable);
    var segments = new StringBuffer(), points = <math.Point<num>>[];
    for (int i = 0, len = data.length; i < len; ++i) {
      final d = data.elementAt(i);
      if (isDefined(d, i, e)) {
        points.add(new math.Point(xValueAccessor(d, i), yValueAccessor(d, i)));
      } else if (points.isNotEmpty) {
        segments.write('M${interpolator(points, tension)}');
        points.clear();
      }
    }
    if (points.isNotEmpty) {
      segments.write('M${interpolator(points, tension)}');
    }
    return segments.toString();
  }

  /// Default implementation of [xValueAccessor].
  /// Returns the first element if [d] is an iterable, otherwise returns [d].
  static num defaultDataToX(d, i) => d is Iterable ? d.first : d;

  /// Default implementation of [yValueAccessor].
  /// Returns the second element if [d] is an iterable, otherwise returns [d].
  static num defaultDataToY(d, i) => d is Iterable ? d.elementAt(1) : d;

  /// Default implementation of [isDefined].
  /// Returns true for all non-null values of [d].
  static bool defaultIsDefined(d, i, e) => d != null;

  /// Linear interpolator.
  static String _linear(Iterable points, int _) =>
      points.map((pt) => '${pt.x},${pt.y}').join('L');
}
