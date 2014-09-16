/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class _ChartEvent implements ChartEvent {
  @override
  final _ChartArea area;

  @override
  final ChartSeries series;

  @override
  final MouseEvent source;

  @override
  final int column;

  @override
  final int row;

  @override
  final num value;

  @override
  num scaledX;

  @override
  num scaledY;

  @override
  num chartX;

  @override
  num chartY;

  _ChartEvent(this.source, this.area,
      [this.series, this.row, this.column, this.value]) {
    var host = area.host;
    var rect = getElementPosition(host);
    chartX = source.page.x - (rect.x + _ChartArea.MARGIN);
    chartY = source.page.y - (rect.y + _ChartArea.MARGIN);
  }

  static Rect getElementPosition(Element host) {
    var x = 0,
        y = 0,
        element = host;
    if (element.offsetParent != null) {
      do {
        x += element.offsetLeft;
        y += element.offsetTop;
      } while ((element = element.offsetParent) != null);
    }

    // TODO(psunkari): Look for a better way to compensate scroll.
    element = host;
    if (element.parent != null) {
      do {
        x -= element.scrollLeft;
        y -= element.scrollTop;
      } while ((element = element.parent) != null);
    }

    return new Rect.position(x, y);
  }
}
