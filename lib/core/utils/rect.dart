//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.core.utils;

/// Interface representing size and position of an element
class Rect {
  final num _x;
  final num _y;
  final num _width;
  final num _height;

  num get x => _x;
  num get y => _y;
  num get width => _width;
  num get height => _height;

  const Rect([this._x = 0, this._y = 0, this._width = 0, this._height = 0]);
  const Rect.size(this._width, this._height)
      : _x = 0,
        _y = 0;
  const Rect.position(this._x, this._y)
      : _width = 0,
        _height = 0;

  bool isSameSizeAs(Rect other) =>
      other != null && width == other.width && height == other.height;

  bool isSamePositionAs(Rect other) =>
      other != null && x == other.x && y == other.y;

  bool contains(num otherX, num otherY) =>
      otherX >= x && otherX <= x + width && otherY >= y && otherY <= y + height;

  String toString() => '$x, $y, $width, $height';

  @override
  bool operator ==(other) =>
      other is Rect && isSameSizeAs(other) && isSamePositionAs(other);

  @override
  int get hashCode => hash4(x, y, width, height);
}

/// Mutable version of [Rect] class.
class MutableRect extends Rect {
  num x;
  num y;
  num width;
  num height;

  MutableRect(this.x, this.y, this.width, this.height);
  MutableRect.size(this.width, this.height);
  MutableRect.position(this.x, this.y);
}

class AbsoluteRect {
  final num start;
  final num end;
  final num top;
  final num bottom;

  const AbsoluteRect(this.top, this.end, this.bottom, this.start);

  @override
  bool operator ==(other) => other is AbsoluteRect &&
      start == other.start &&
      end == other.end &&
      top == other.top &&
      bottom == other.bottom;

  @override
  int get hashCode => hash4(start, end, top, bottom);
}
