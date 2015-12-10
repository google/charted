//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.svg.shapes;

/// Draw a rectangle at [x], [y] which is [width] pixels wide and
/// [height] pixels height.  [topLeft], [topRight], [bottomRight] and
/// [bottomLeft] are the corner radius at each of the four corners.
String roundedRect(int x, int y, int width, int height, int topLeft,
        int topRight, int bottomRight, int bottomLeft) =>
    'M${x+topLeft},${y} '
    'L${x+width-topRight},${y} '
    'Q${x+width},${y} ${x+width},${y+topRight}'
    'L${x+width},${y+height-bottomRight} '
    'Q${x+width},${y+height} ${x+width-bottomRight},${y+height}'
    'L${x+bottomLeft},${y+height} '
    'Q${x},${y+height} ${x},${y+height-bottomLeft}'
    'L${x},${y+topLeft} '
    'Q${x},${y} ${x+topLeft},${y} Z';

/// Draw a rectangle with rounded corners on both corners on the right.
String rightRoundedRect(int x, int y, int width, int height, int radius) {
  if (width < radius) radius = width;
  if (height < radius * 2) radius = height ~/ 2;
  return roundedRect(x, y, width, height, 0, radius, radius, 0);
}

/// Draw a rectangle with rounded corners on both corners on the top.
String topRoundedRect(int x, int y, int width, int height, int radius) {
  if (height < radius) radius = height;
  if (width < radius * 2) radius = width ~/ 2;
  return roundedRect(x, y, width, height, radius, radius, 0, 0);
}

/// Draw a rectangle with rounded corners on both corners on the right.
String leftRoundedRect(int x, int y, int width, int height, int radius) {
  if (width < radius) radius = width;
  if (height < radius * 2) radius = height ~/ 2;
  return roundedRect(x, y, width, height, radius, 0, 0, radius);
}

/// Draw a rectangle with rounded corners on both corners on the top.
String bottomRoundedRect(int x, int y, int width, int height, int radius) {
  if (height < radius) radius = height;
  if (width < radius * 2) radius = width ~/ 2;
  return roundedRect(x, y, width, height, 0, 0, radius, radius);
}
