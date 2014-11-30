/**
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class BaseRenderer implements ChartRenderer {
  ChartArea area;
  ChartSeries series;
  ChartTheme theme;
  Rect rect;

  Element host;
  Selection root;
  SelectionScope scope;

  StreamController<ChartEvent> mouseOverController;
  StreamController<ChartEvent> mouseOutController;
  StreamController<ChartEvent> mouseClickController;

  void _ensureAreaAndSeries(ChartArea area, ChartSeries series) {
    assert(area != null && series != null);
    this.area = area;
    this.series = series;
  }

  void _ensureReadyToDraw(Element element) {
    assert(series != null && area != null);
    assert(element != null && element is GElement);

    if (scope == null) {
      host = element;
      scope = new SelectionScope.element(element);
      root = scope.selectElements([host]);
    }

    theme = area.theme;
    rect = area.layout.renderArea;
  }

  @override
  void dispose() {
    if (root == null) return;
    root.selectAll('.row-group').remove();
  }

  @override
  Extent get extent {
    assert(series != null && area != null);
    var rows = area.data.rows,
    max = rows[0][series.measures.first],
    min = max;

    rows.forEach((row) {
      series.measures.forEach((idx) {
        if (row[idx] > max) max = row[idx];
        if (row[idx] < min) min = row[idx];
      });
    });
    return new Extent(min, max);
  }

  @override
  Stream<ChartEvent> get onValueMouseOver {
    if (mouseOverController == null) {
      mouseOverController = new StreamController.broadcast(sync: true);
    }
    return mouseOverController.stream;
  }

  @override
  Stream<ChartEvent> get onValueMouseOut {
    if (mouseOutController == null) {
      mouseOutController = new StreamController.broadcast(sync: true);
    }
    return mouseOutController.stream;
  }

  @override
  Stream<ChartEvent> get onValueMouseClick {
    if (mouseClickController == null) {
      mouseClickController = new StreamController.broadcast(sync: true);
    }
    return mouseClickController.stream;
  }

  double get bandInnerPadding => 1.0;
  double get bandOuterPadding => area.theme.dimensionAxisTheme.axisOuterPadding;

  /** Get a color using the theme's ordinal scale of colors */
  String colorForKey(i) =>
      area.theme.getColorForKey(series.measures.elementAt(i));

  /** List of measure values as rows containing only measure columns */
  Iterable<Iterable> get asRowValues => [];

  /** List of measure values as columns */
  Iterable<Iterable> get asColumnValues => [];
}