library charted.demo.charts;

import "package:charted/charts/charts.dart";

/// Helper method to create default behaviors for cartesian chart demos.
Iterable<ChartBehavior> createDefaultCartesianBehaviors() =>
    new List.from([new ChartTooltip(), new AxisLabelTooltip()]);

/// Helper method to create default behaviors for layout chart demos.
Iterable<ChartBehavior> createDefaultLayoutBehaviors() =>
    new List.from([new ChartTooltip()]);

/// Sample columns used by demos with quantitative dimension scale
Iterable ORDINAL_SMALL_DATA_COLUMNS = [
    new ChartColumnSpec(label: 'Month', type: ChartColumnSpec.TYPE_STRING),
    new ChartColumnSpec(label: 'Grains'),
    new ChartColumnSpec(label: 'Fruits'),
    new ChartColumnSpec(label: 'Vegetables')
];

/// Sample values used by demos with quantitative dimension scale
Iterable ORDINAL_SMALL_DATA = const [
    const ['January',   4.50,  7,  6],
    const ['February',  5.61, 16,  8],
    const ['March',     8.26, 36,  9],
    const ['April',    15.46, 63, 49],
    const ['May',      18.50, 77, 46],
    const ['June',     14.61, 60,  8],
    const ['July',      3.26,  9,  6],
    const ['August',    1.46,  9,  3],
    const ['September', 1.46, 13,  9],
    const ['October',   2.46, 29,  3],
    const ['November',  4.46, 33,  9],
    const ['December',  8.46, 19,  3]
];

/// Sample values used by RTL demos with quantitative dimension scale
Iterable ORDINAL_SMALL_DATA_RTL = const [
    const ['كانون الثاني',   4.50,  7,  6],
    const ['شباط',  5.61, 16,  8],
    const ['آذار',     8.26, 36,  9],
    const ['نيسان',    15.46, 63, 49],
    const ['أيار',      18.50, 77, 46],
    const ['حزيران',     14.61, 60,  8],
    const ['تموز',      3.26,  9,  6],
    const ['آب',    1.46,  9,  3],
    const ['أيلول', 1.46, 13,  9],
    const ['تشرين الأول',   2.46, 29,  3],
    const ['تشرين الثاني',  4.46, 33,  9],
    const ['كانون الأول',  8.46, 19,  3]
];

