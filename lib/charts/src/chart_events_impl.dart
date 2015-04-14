//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

class _ChartEvent implements ChartEvent {
  @override
  final ChartArea area;

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
    var hostRect = area.host.getBoundingClientRect(),
        left = area.config.isRTL
            ? area.theme.padding.end
            : area.theme.padding.start;
    chartX = source.client.x - hostRect.left - left;
    chartY = source.client.y - hostRect.top - area.theme.padding.top;
  }
}
