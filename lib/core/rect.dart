/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.core;

/** Interface representing size and position of an element */
class Rect {
  final num x;
  final num y;
  final num width;
  final num height;

  const Rect([this.x = 0, this.y = 0, this.width = 0, this.height = 0]);
  const Rect.size(this.width, this.height) : x = 0, y = 0;
  const Rect.position(this.x, this.y) : width = 0, height = 0;

  bool operator==(other) =>
      other is Rect && isSameSizeAs(other) && isSamePositionAs(other);

  bool isSameSizeAs(Rect other) =>
      other != null && width == other.width && height == other.height;

  bool isSamePositionAs(Rect other) =>
      other != null && x == other.x && y == other.y;

  bool contains(num otherX, num otherY) =>
      otherX >= x && otherX <= x + width &&
      otherY >= y && otherY <= y + height;

  String toString() => '$x, $y, $width, $height';
}

/**
 * Editable Rect
 * TODO(prsd): Can we avoid duplication here?
 */
class EditableRect implements Rect {
  num x;
  num y;
  num width;
  num height;

  EditableRect(this.x, this.y, this.width, this.height);
  EditableRect.size(this.width, this.height);
  EditableRect.position(this.x, this.y);

  bool operator==(other) =>
      other is Rect && isSameSizeAs(other) && isSamePositionAs(other);

  bool isSameSizeAs(Rect other) =>
      other != null && width == other.width && height == other.height;

  bool isSamePositionAs(Rect other) =>
      other != null && x == other.x && y == other.y;

  bool contains(num otherX, num otherY) =>
      otherX >= x && otherX <= x + width &&
      otherY >= y && otherY <= y + height;
}
