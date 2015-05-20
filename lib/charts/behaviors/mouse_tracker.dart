//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

/// A behavior that tracks mouse pointer and paints a dashed line to
/// the axes from the current pointer location.
class MouseTracker implements ChartBehavior {
  ChartArea _area;
  Rect _rect;

  Element _markerX;
  Element _markerY;

  bool _showMarkerX = true;
  bool _showMarkerY = true;
  bool _showing;

  Element _lower;

  StreamSubscription _mouseMoveSubscription;
  StreamSubscription _mouseInSubscription;
  StreamSubscription _mouseOutSubscription;

  void init(ChartArea area, Selection upper, Selection lower) {
    _area = area;
    _lower = lower.first;

    if (area is CartesianArea) {
      _mouseInSubscription = _area.onMouseOver.listen(_show);
      _mouseOutSubscription = _area.onMouseOut.listen(_hide);
    }
  }

  void dispose() {
    if (_mouseInSubscription != null) _mouseInSubscription.cancel();
    if (_mouseOutSubscription != null) _mouseOutSubscription.cancel();
    if (_mouseMoveSubscription != null) _mouseOutSubscription.cancel();
    if (_markerX != null) _markerX.remove();
    if (_markerY != null) _markerY.remove();
  }

  void _show(ChartEvent e) {
    if (_mouseMoveSubscription != null) return;
    _create();
    _visibility(true);
    _mouseMoveSubscription = _area.onMouseMove.listen(_update);
  }

  void _hide(ChartEvent e) {
    if (_showing != true) return;
    _visibility(false);
    _mouseMoveSubscription.cancel();
    _mouseMoveSubscription = null;
  }

  void _visibility(bool show) {
    if (_showing == show) return;
    var value = show ? 'visible' : 'hidden';
    if (_markerX != null) {
      _markerX.style.visibility = value;
    }
    if (_markerY != null) {
      _markerY.style.visibility = value;
    }
  }

  bool _isRenderArea(ChartEvent e) =>
      _rect != null && _rect.contains(e.chartX, e.chartY);

  void _create() {
    if (_rect == null) {
      var renderArea = _area.layout.renderArea;
      _rect = new Rect(
          renderArea.x, renderArea.y, renderArea.width, renderArea.height);
    }
    if (_showMarkerX && _markerX == null) {
      _markerX = new LineElement();
      _markerX.attributes
        ..['x1'] = '0'
        ..['y1'] = _rect.y.toString()
        ..['x2'] = '0'
        ..['y2'] = (_rect.y + _rect.height).toString()
        ..['class'] = 'axis-marker axis-marker-x';
      _lower.append(_markerX);
    }
    if (_showMarkerY && _markerY == null) {
      _markerY = new LineElement();
      _markerY.attributes
        ..['x1'] = _rect.x.toString()
        ..['y1'] = '0'
        ..['x2'] = (_rect.x + _rect.width).toString()
        ..['y2'] = '0'
        ..['class'] = 'axis-marker axis-marker-y';
      _lower.append(_markerY);
    }
    _visibility(false);
  }

  void _update(ChartEvent e) {
    if (!_isRenderArea(e)) {
      _visibility(false);
    } else {
      _visibility(true);
      window.requestAnimationFrame((_) {
        if (_showMarkerX) {
          _markerX.attributes['transform'] = 'translate(${e.chartX},0)';
        }
        if (_showMarkerY) {
          _markerY.attributes['transform'] = 'translate(0,${e.chartY})';
        }
      });
    }
  }
}
