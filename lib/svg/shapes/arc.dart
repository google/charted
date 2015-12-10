//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.svg.shapes;

///
/// [SvgArc] provides a data-driven way to create path descriptions
/// that can be used to draw arcs - like those used in pie-charts.
///
class SvgArc implements SvgShape {
  static const _OFFSET = -HALF_PI;
  static const _MAX = TAU - EPSILON;

  /// [innerRadiusCallback] is called to get inner radius of the arc.
  /// As with other callbacks, [innerRadiusCallback] is passed data, index
  /// and element in the context.
  final SelectionCallback<num> innerRadiusCallback;

  /// [outerRadiusCallback] is called to get outer radius of the arc.
  /// As with other callbacks, [outerRadiusCallback] is passed data, index
  /// and element in the context.
  final SelectionCallback<num> outerRadiusCallback;

  /// [startAngleCallback] is called to get the start angle of the arc.
  /// As with other callbacks, [startAngleCallback] is passed data, index
  /// and element in the context.
  final SelectionCallback<num> startAngleCallback;

  /// [endAngleCallback] is called to get the start angle of the arc.
  /// As with other callbacks, [endAngleCallback] is passed data, index
  /// and element in the context.
  final SelectionCallback<num> endAngleCallback;

  SvgArc(
      {this.innerRadiusCallback: defaultInnerRadiusCallback,
      this.outerRadiusCallback: defaultOuterRadiusCallback,
      this.startAngleCallback: defaultStartAngleCallback,
      this.endAngleCallback: defaultEndAngleCallback});

  String path(d, int i, Element e) {
    var ir = innerRadiusCallback(d, i, e),
        or = outerRadiusCallback(d, i, e),
        start = startAngleCallback(d, i, e) + _OFFSET,
        end = endAngleCallback(d, i, e) + _OFFSET,
        sa = math.min(start, end),
        ea = math.max(start, end),
        delta = ea - sa;

    if (delta > _MAX) {
      return ir > 0
          ? "M0,$or"
              "A$or,$or 0 1,1 0,-$or"
              "A$or,$or 0 1,1 0,$or"
              "M0,$ir"
              "A$ir,$ir 0 1,0 0,-$ir"
              "A$ir,$ir 0 1,0 0,$ir"
              "Z"
          : "M0,$or" "A$or,$or 0 1,1 0,-$or" "A$or,$or 0 1,1 0,$or" "Z";
    }

    var ss = math.sin(sa),
        se = math.sin(ea),
        cs = math.cos(sa),
        ce = math.cos(ea),
        df = delta < PI ? 0 : 1;

    return ir > 0
        ? "M${or * cs},${or * ss}"
            "A$or,$or 0 $df,1 ${or * ce},${or * se}"
            "L${ir * ce},${ir * se}"
            "A$ir,$ir 0 $df,0 ${ir * cs},${ir * ss}"
            "Z"
        : "M${or * cs},${or * ss}"
        "A$or,$or 0 $df,1 ${or * ce},${or * se}"
        "L0,0"
        "Z";
  }

  List centroid(d, int i, Element e) {
    var r = (innerRadiusCallback(d, i, e) + outerRadiusCallback(d, i, e)) / 2,
        a = (startAngleCallback(d, i, e) + endAngleCallback(d, i, e)) / 2 -
            math.PI / 2;
    return [math.cos(a) * r, math.sin(a) * r];
  }

  /// Default [innerRadiusCallback] returns data.innerRadius
  static num defaultInnerRadiusCallback(d, i, e) =>
      d is! SvgArcData || d.innerRadius == null ? 0 : d.innerRadius;

  /// Default [outerRadiusCallback] returns data.outerRadius
  static num defaultOuterRadiusCallback(d, i, e) =>
      d is! SvgArcData || d.outerRadius == null ? 0 : d.outerRadius;

  /// Default [startAngleCallback] returns data.startAngle
  static num defaultStartAngleCallback(d, i, e) =>
      d is! SvgArcData || d.startAngle == null ? 0 : d.startAngle;

  /// Default [endAngleCallback] that returns data.endAngle
  static num defaultEndAngleCallback(d, i, e) =>
      d is! SvgArcData || d.endAngle == null ? 0 : d.endAngle;
}

/// Value type for SvgArc as used by default property accessors in SvgArc
class SvgArcData {
  dynamic data;
  num value;
  num innerRadius;
  num outerRadius;
  num startAngle;
  num endAngle;

  SvgArcData(this.data, this.value, this.startAngle, this.endAngle,
      [this.innerRadius = 0, this.outerRadius = 100]);
}

/// Returns the interpolator between two [SvgArcData] [a] and [b].
///
/// The interpolator will interpolate the older innerRadius and outerRadius with
/// newer ones, as well as older startAngle and endAngle with newer ones.
Interpolator interpolateSvgArcData(SvgArcData a, SvgArcData b) {
  var ast = a.startAngle,
      aen = a.endAngle,
      ai = a.innerRadius,
      ao = a.outerRadius,
      bst = b.startAngle - ast,
      ben = b.endAngle - aen,
      bi = b.innerRadius - ai,
      bo = b.outerRadius - ao;

  return (t) => new SvgArcData(b.data, b.value, (ast + bst * t),
      (aen + ben * t), (ai + bi * t), (ao + bo * t));
}
