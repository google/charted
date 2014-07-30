/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.charts_demo;

import 'dart:html';
import 'dart:collection';
import 'package:observe/observe.dart';
import 'package:charted/charts/charts.dart';

List COLUMNS = [
    new ChartColumnSpec(label:'Month', type:ChartColumnSpec.TYPE_STRING),
    new ChartColumnSpec(label:'Precipitation'),
    new ChartColumnSpec(label:'High Temperature'),
    new ChartColumnSpec(label:'Low Temperature'),
    new ChartColumnSpec(label:'Random Number')
  ];

const List DATA = const [
    const['January',   4.50,  7,  6, 10],
    const['February',  5.61, 16,  8,  5],
    const['March',     8.26, 36,  9, 15],
    const['April',    15.46, 63, 49,  6],
    const['May',      18.50, 77, 46, 16],
    const['June',     14.61, 60,  8,  3],
    const['July',      3.26,  6,  9,  9],
    const['August',    1.46,  3,  9, 30],
    const['September', 1.46, 13,  9, 30],
    const['October',   2.46,  3, 29, 30],
    const['November',  4.46, 33,  9, 35],
    const['December',  8.46,  3, 19, 20],
    const['Next Jan',  4.50,  7,  6, 10],
    const['Next Feb',  5.61, 16,  8,  5],
    const['Next Mar',  8.26, 36,  9, 15],
    const['Next Apr', 15.46, 63, 49,  6],
    const['Next May', 18.50, 77, 46, 16],
    const['Next Jun', 14.61, 60,  8,  3],
    const['Next Jul',  3.26,  6,  9,  9],
    const['Next Aug',  1.46,  3,  9, 30],
    const['Next Sep',  1.46, 13,  9, 30],
    const['Next Oct',  2.46,  3, 29, 30],
    const['Next Nov',  4.46, 33,  9, 35],
    const['Next Dec',  8.46,  3, 19, 20],
  ];

const List DIMENSION_COLUMNS =  const[0];

int customSeriesCounter = 0;

/*
 * TODO(prsd): save config in hash to let users user the browser's
 * forward/back buttons and share the URLs.
 */
List DEMOS = [
  {
    'name': 'One',
    'title': 'One: Use left panel to configure the chart',
    'series': [
      {
        'name': 'Series-01',
        'renderer': 'bar-chart',
        'columns': [ 1, 2, 3 ]
      }
    ]
  },
  {
    'name': 'Two',
    'title': 'Two: Use left panel to configure the chart',
    'series': [
      {
        'name': 'Series-01',
        'renderer': 'line-chart',
        'columns': [ 1, 2, 3 ]
      }
    ]
  },
  {
    'name': 'Three',
    'title': 'Three: Use left panel to configure the chart',
    'series': [
      {
        'name': 'Series-01',
        'renderer': 'stacked-bar-chart',
        'columns': [ 1, 2, 3 ]
      }
    ]
  },
  {
    'name': 'Four',
    'title': 'Four: Use left panel to configure the chart',
    'series': [
      {
        'name': 'Series-01',
        'renderer': 'pie-chart',
        'columns': [ 1, 2, 3 ]
      }
    ],
    'dimensionAxesCount': 0,
  },
];

Map RENDERERS = {
  'bar-chart': 'Bar chart',
  'line-chart': 'Line chart',
  'stacked-bar-chart': 'Stacked bar chart',
  'pie-chart': 'Pie chart',
};

ChartRenderer getRendererForType(String name) {
  if (name == 'bar-chart') return new BarChartRenderer();
  if (name == 'line-chart') return new LineChartRenderer();
  if (name == 'stacked-bar-chart') return new StackedBarChartRenderer();
  if (name == 'pie-chart') return new PieChartRenderer();
  return new BarChartRenderer();
}
String getTypeForRenderer(ChartRenderer renderer) {
  if (renderer is BarChartRenderer) return 'bar-chart';
  if (renderer is LineChartRenderer) return 'line-chart';
  if (renderer is StackedBarChartRenderer) return 'stacked-bar-chart';
  if (renderer is PieChartRenderer) return 'pie-chart';
  return 'bar-chart';
}

class DemoChart {
  String title;

  ObservableList columns;
  ObservableList rows;
  ObservableList series;

  ChartArea area;
  ChartConfig config;
  ChartData data;
  ChartRenderer renderer;
  Element host;
  Element legendHost;
  int dimensionAxesCount;

  DemoChart(Map demoConfig, this.host, this.legendHost) {
    List seriesList = demoConfig['series'];
    title = demoConfig['title'];

    dimensionAxesCount = demoConfig.containsKey('dimensionAxesCount') ?
        demoConfig['dimensionAxesCount'] : 1;
    columns = new ObservableList.from(COLUMNS);
    rows = new ObservableList.from(DATA.sublist(0, 3));
    series = new ObservableList.from(seriesList.map(
        (item) => new ChartSeries(item['name'],
            new ObservableList.from(item['columns']),
            getRendererForType(item['renderer']))));

    data = new ChartData(this.columns, this.rows);
    config = new ChartConfig(series, DIMENSION_COLUMNS);
    area = new ChartArea(host, data, config, autoUpdate:true,
        dimensionAxesCount: dimensionAxesCount);

    config.legend = new ChartLegend(legendHost);
  }

  draw() => area.draw();
}

main() {
  LinkedHashMap<String,DemoChart> charts = new LinkedHashMap();
  DemoChart active;
  ChartSeries activeSeries;

  ButtonElement addRowButton = querySelector('#add-row'),
      removeRowButton = querySelector('#remove-row'),
      addSeriesButton = querySelector('#add-series'),
      removeSeriesButton = querySelector('#remove-series');

  SelectElement chartSelect = querySelector('#select-chart'),
      seriesSelect = querySelector('#select-series'),
      rendererSelect = querySelector('#select-renderer');

  Element columnButtons = querySelector('#column-buttons');



  /*
   * Updating rows
   */

  updateRowButtonStates() {
    addRowButton.disabled = active.rows.length >= DATA.length;
    removeRowButton.disabled = active.rows.length <= 1;
  }

  addRowButton.onClick.listen((_) {
    if (active.rows.length < DATA.length) {
      active.rows.add(DATA.elementAt(active.rows.length));
    }
    updateRowButtonStates();
  });

  removeRowButton.onClick.listen((_) {
    if (active.rows.length > 0) active.rows.removeLast();
    updateRowButtonStates();
  });



 /*
   * Series selection
   */

  selectSeries(ChartSeries series) {
    activeSeries = series;

    List<Element> options = rendererSelect.children.toList();
    String rendererType = getTypeForRenderer(series.renderer);
    for (int i = 0; i < options.length; i++) {
      if ((options[i] as OptionElement).value == rendererType)
        rendererSelect.selectedIndex = i;
    }

    List<InputElement> buttons = querySelectorAll('.column-button');
    Iterable measures = series.measures;
    for (int i = 0; i < buttons.length; i++) {
      buttons[i].checked = measures.contains(i + 1);
    }
  }

  updateSeriesSelector([ChartSeries selected]) {
    seriesSelect.children.clear();
    active.series.forEach((ChartSeries item) {
      var option = new OptionElement()
          ..value = item.name
          ..text = item.name;
      seriesSelect.append(option);
    });
    selectSeries(selected == null ? active.series.first : selected);
  }

  seriesSelect.onChange.listen(
      (_) => selectSeries(active.series.firstWhere(
          (ChartSeries x) => x.name == seriesSelect.value)));

  updateRendererSelector() {
    rendererSelect.children.clear();
    RENDERERS.forEach((name, label) {
      var option = new OptionElement()
          ..value = name
          ..text = label;
      rendererSelect.append(option);
    });
  }

  rendererSelect.onChange.listen(
      (_) => activeSeries.renderer = getRendererForType(rendererSelect.value));

  updateColumns([Event e]) {
    if (activeSeries == null) return;

    List<Element> buttons = querySelectorAll('.column-button');
    InputElement firstChecked;
    for (int i = 0; i < buttons.length && firstChecked == null; i++) {
      if ((buttons[i] as InputElement).checked) firstChecked = buttons[i];
    }

    List measures = activeSeries.measures as List;
    int index = buttons.indexOf(e.target) + 1;
    if ((e.target as InputElement).checked) {
      measures.add(index);
      buttons.forEach((InputElement b) => b.disabled = false);
    } else {
      measures.remove(index);
      if (measures.length <= 1) firstChecked.disabled = true;
    }
  }

  updateColumnsList() {
    columnButtons.children.clear();
    COLUMNS.asMap().forEach((int index, ChartColumnSpec spec) {
      if (index == 0) return;
      var row = new DivElement();
      var button = new InputElement()
          ..className = 'column-button'
          ..type = 'checkbox'
          ..value = spec.label
          ..id = 'column-$index'
          ..onChange.listen((e) => updateColumns(e));
      var label = new LabelElement()
          ..text = spec.label
          ..htmlFor = 'column-$index';
      row.children.addAll([button,label]);
      columnButtons.append(row);
    });
  }



  /*
   * Updates to series
   */

  updateSeriesButtonStates() {
    removeSeriesButton.disabled = active.series.length <= 1;
  }

  addSeriesButton.onClick.listen((_) {
    if (active == null) return;
    var name = 'New Series ${customSeriesCounter}',
        series = new ChartSeries(name, new ObservableList.from([1, 2, 3]),
            new BarChartRenderer());
    active.series.add(series);
    updateSeriesSelector(series);
    seriesSelect.selectedIndex = active.series.length - 1;
    updateSeriesButtonStates();
    customSeriesCounter++;
  });

  removeSeriesButton.onClick.listen((_) {
    if (active.series.length > 0) active.series.removeLast();
    updateSeriesSelector();
    updateSeriesButtonStates();
  });



  /*
   * Chart selection
   */

  selectChart(DemoChart chart) {
    active = chart;
    updateSeriesSelector();
    updateSeriesButtonStates();
    updateRowButtonStates();
  }

  updateChartSelector() {
    chartSelect.children.clear();
    charts.forEach((name, value) {
      var option = new OptionElement()
          ..value = name
          ..text = name;
      chartSelect.append(option);
    });
    selectChart(charts[DEMOS.first['name']]);
  }

  chartSelect.onChange.listen(
      (_) => selectChart(charts[chartSelect.value]));



  /*
   * Create the first few charts
   */

  DemoChart createDemoChart(Map config) {
    var name = config['name'];
    if (charts.containsKey(name)) return charts[name];
    Element host = new DivElement()..className = 'chart',
        legendHost = new DivElement()..className = 'chart-legend';
    return (charts[name] = new DemoChart(config, host, legendHost));
  }

  var container = querySelector('.charts-container');
  DEMOS.forEach((demo) {
    var chart = createDemoChart(demo),
        chartWithLegend = new Element.tag('div');

    container.append(new Element.html('<h2>${demo['title']}</h2>'));
    chartWithLegend.append(chart.host);
    chartWithLegend.append(chart.config.legend.host);
    container.append(chartWithLegend);

    chart.draw();
  });



  /*
   * Update UI
   */

  updateColumnsList();
  updateRendererSelector();
  updateChartSelector();
}
