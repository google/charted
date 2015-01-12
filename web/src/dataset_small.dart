
part of charted.demo;

List SMALL_DATA_COLUMNS = [
    new ChartColumnSpec(label: 'Month', type: ChartColumnSpec.TYPE_STRING),
    new ChartColumnSpec(label: 'Precipitation'),
    new ChartColumnSpec(label: 'High Temperature'),
    new ChartColumnSpec(label: 'Low Temperature'),
];

List SMALL_DATA = const [
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

List SMALL_WATERFALL_DATA_COLUMNS = [
    new ChartColumnSpec(label: 'Category', type: ChartColumnSpec.TYPE_STRING),
    new ChartColumnSpec(label: 'Quater 1'),
    new ChartColumnSpec(label: 'Quater 2'),
    new ChartColumnSpec(label: 'Quater 3'),
    new ChartColumnSpec(label: 'Quater 4'),
];

List SMALL_WATERFALL_DATA_WITH_SUM = const [
    const ['Product Revenue',  4200,   6000,  6000,  7000],
    const ['Service Revenue',  2100,   1600,  3000,  4000],
    const ['Revenue Subtotal', 6300,   7600,  9000, 11000],
    const ['Fixed Costs',     -1700,  -1700, -1700, -1700],
    const ['Viriable Costs',  -1000,  -2000, -3000, -4500],
    const ['Gross Earning',    3600,   3900,  4300,  4800],
];
