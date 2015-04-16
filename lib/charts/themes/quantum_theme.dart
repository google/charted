/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.charts;

class QuantumChartTheme extends ChartTheme {
  static const List OTHER_COLORS =
      const['#EEEEEE', '#BDBDBD', '#9E9E9E'];

  static const List<List<String>> COLORS = const[
    const [ '#C5D9FB', '#4184F3', '#2955C5' ],
    const [ '#F3C6C2', '#DB4437', '#A52714' ],
    const [ '#FBE7B1', '#F4B400', '#EF9200' ],
    const [ '#B6E0CC', '#0F9D58', '#0A7F42' ],
    const [ '#E0BDE6', '#AA46BB', '#691A99' ],
    const [ '#B1EAF1', '#00ABC0', '#00828E' ],
    const [ '#FFCBBB', '#FF6F42', '#E54918' ],
    const [ '#EFF3C2', '#9D9C23', '#817616' ],
    const [ '#C4C9E8', '#5B6ABF', '#3848AA' ],
    const [ '#F7BACF', '#EF6191', '#E81D62' ],
    const [ '#B1DEDA', '#00786A', '#004C3F' ],
    const [ '#F38EB0', '#C1175A', '#870D4E' ],
  ];

  static const List<List<String>> COLORS_ASSIST = const[
    const [ '#C5D9FB', '#4184F3', '#2955C5' ],
    const [ '#F3C6C2', '#DB4437', '#A52714' ],
    const [ '#FBE7B1', '#F4B400', '#EF9200' ],
    const [ '#B6E0CC', '#0F9D58', '#0A7F42' ],
    const [ '#E0BDE6', '#AA46BB', '#691A99' ],
    const [ '#B1EAF1', '#00ABC0', '#00828E' ],
    const [ '#FFCBBB', '#FF6F42', '#E54918' ],
    const [ '#EFF3C2', '#9D9C23', '#817616' ]
  ];

  final OrdinalScale _scale = new OrdinalScale()..range = COLORS;

  /* Implementation of ChartTheme */
  String getColorForKey(key, [int state = ChartTheme.STATE_NORMAL]) {
    var result = _scale.scale(key);
    return (result is List && result.length > state)
        ? result.elementAt(state)
        : result;
  }

  String getOtherColor([int state = ChartTheme.STATE_NORMAL]) =>
      OTHER_COLORS is List && OTHER_COLORS.length > state
          ? OTHER_COLORS.elementAt(state)
          : OTHER_COLORS;

  ChartAxisTheme get measureAxisTheme =>
      const _QuantumChartAxisTheme(ChartAxisTheme.FILL_RENDER_AREA, 5);
  ChartAxisTheme get dimensionAxisTheme =>
      const _QuantumChartAxisTheme(0, 10);

  AbsoluteRect get padding => const AbsoluteRect(10, 10, 0, 0);

  String get defaultFont => '14px Roboto';

  String get filters => '''
    <filter id="active-shadow" x="-50%" y="-25%" width="200%" height="200%">
      <feOffset result="offOut" in="SourceGraphic" dx="0" dy="0" />
      <feColorMatrix result="matrixOut" in="offOut"
          type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.5 0"/>
      <feGaussianBlur result="blurOut" in="matrixOut" stdDeviation="2" />
      <feBlend in="SourceGraphic" in2="blurOut" mode="normal" />
    </filter>
''';

  String getFilterForKey(key, [int state = ChartTheme.STATE_NORMAL]) =>
      state == ChartTheme.STATE_ACTIVE ? 'url(#active-shadow)' : null;
}

class _QuantumChartAxisTheme implements ChartAxisTheme {
  final axisOuterPadding = 0.1;
  final axisBandInnerPadding = 0.35;
  final axisBandOuterPadding = 0.175;
  final axisTickPadding = 6;
  final axisTickSize;
  final axisTickCount;
  final verticalAxisAutoResize = true;
  final verticalAxisWidth = 75;
  final horizontalAxisAutoResize = false;
  final horizontalAxisHeight = 50;
  final ticksFont = '14px Roboto';
  const _QuantumChartAxisTheme(this.axisTickSize, this.axisTickCount);
}
