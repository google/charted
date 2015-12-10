/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class QuantumChartTheme extends ChartTheme {
  static const List OTHER_COLORS = const ['#EEEEEE', '#BDBDBD', '#9E9E9E'];

  static const List<List<String>> COLORS = const [
    const ['#C5D9FB', '#4184F3', '#2955C5'],
    const ['#F3C6C2', '#DB4437', '#A52714'],
    const ['#FBE7B1', '#F4B400', '#EF9200'],
    const ['#B6E0CC', '#0F9D58', '#0A7F42'],
    const ['#E0BDE6', '#AA46BB', '#691A99'],
    const ['#B1EAF1', '#00ABC0', '#00828E'],
    const ['#FFCBBB', '#FF6F42', '#E54918'],
    const ['#EFF3C2', '#9D9C23', '#817616'],
    const ['#C4C9E8', '#5B6ABF', '#3848AA'],
    const ['#F7BACF', '#EF6191', '#E81D62'],
    const ['#B1DEDA', '#00786A', '#004C3F'],
    const ['#F38EB0', '#C1175A', '#870D4E'],
  ];

  static const List<List<String>> COLORS_ASSIST = const [
    const ['#C5D9FB', '#4184F3', '#2955C5'],
    const ['#F3C6C2', '#DB4437', '#A52714'],
    const ['#FBE7B1', '#F4B400', '#EF9200'],
    const ['#B6E0CC', '#0F9D58', '#0A7F42'],
    const ['#E0BDE6', '#AA46BB', '#691A99'],
    const ['#B1EAF1', '#00ABC0', '#00828E'],
    const ['#FFCBBB', '#FF6F42', '#E54918'],
    const ['#EFF3C2', '#9D9C23', '#817616']
  ];

  final OrdinalScale _scale = new OrdinalScale()..range = COLORS;

  @override
  String getColorForKey(key, [int state = 0]) {
    var result = _scale.scale(key);
    return result is Iterable ? colorForState(result, state) : result;
  }

  colorForState(Iterable colors, int state) {
    // Inactive color when another key is active or selected.
    if (state & ChartState.COL_UNSELECTED != 0 ||
        state & ChartState.VAL_UNHIGHLIGHTED != 0) {
      return colors.elementAt(0);
    }

    // Active color when this key is being hovered upon
    if (state & ChartState.COL_PREVIEW != 0 ||
        state & ChartState.VAL_HOVERED != 0) {
      return colors.elementAt(2);
    }

    // All others are normal.
    return colors.elementAt(1);
  }

  @override
  String getFilterForState(int state) => state & ChartState.COL_PREVIEW != 0 ||
      state & ChartState.VAL_HOVERED != 0 ||
      state & ChartState.COL_SELECTED != 0 ||
      state & ChartState.VAL_HIGHLIGHTED != 0 ? 'url(#drop-shadow)' : '';

  @override
  String getOtherColor([int state = 0]) => OTHER_COLORS is Iterable
      ? colorForState(OTHER_COLORS, state)
      : OTHER_COLORS;

  @override
  ChartAxisTheme getMeasureAxisTheme([Scale _]) =>
      const QuantumChartAxisTheme(ChartAxisTheme.FILL_RENDER_AREA, 5);

  @override
  ChartAxisTheme getDimensionAxisTheme([Scale scale]) =>
      scale == null || scale is OrdinalScale
          ? const QuantumChartAxisTheme(0, 10)
          : const QuantumChartAxisTheme(4, 10);

  @override
  AbsoluteRect get padding => const AbsoluteRect(10, 40, 0, 0);

  @override
  String get filters => '''
    <filter id="drop-shadow" height="300%" width="300%" y="-100%" x="-100%">
      <feGaussianBlur stdDeviation="2" in="SourceAlpha"></feGaussianBlur>
      <feOffset dy="1" dx="0"></feOffset>
      <feComponentTransfer>
        <feFuncA slope="0.4" type="linear"></feFuncA>
      </feComponentTransfer>
      <feMerge>
        <feMergeNode></feMergeNode>
        <feMergeNode in="SourceGraphic"></feMergeNode>
      </feMerge>
    </filter>
''';

  @override
  String get defaultFont => '14px Roboto';
}

class QuantumChartAxisTheme implements ChartAxisTheme {
  @override
  final axisOuterPadding = 0.1;

  @override
  final axisBandInnerPadding = 0.35;

  @override
  final axisBandOuterPadding = 0.175;

  @override
  final axisTickPadding = 6;

  @override
  final axisTickSize;

  @override
  final axisTickCount;

  @override
  final verticalAxisAutoResize = true;

  @override
  final verticalAxisWidth = 75;

  @override
  final horizontalAxisAutoResize = false;

  @override
  final horizontalAxisHeight = 50;

  @override
  final ticksFont = '12px Roboto';

  const QuantumChartAxisTheme(this.axisTickSize, this.axisTickCount);
}
