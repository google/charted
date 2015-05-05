
part of charted.demo;

List SMALL_DATA_COLUMNS = [
    new ChartColumnSpec(label: 'Month', type: ChartColumnSpec.TYPE_STRING),
    new ChartColumnSpec(label: 'Grains'),
    new ChartColumnSpec(label: 'Fruits'),
    new ChartColumnSpec(label: 'Vegetables'),
    new ChartColumnSpec(label: 'City', type: ChartColumnSpec.TYPE_STRING)
];

List SMALL_DATA = const [
    const ['January',   4.50,  7,  6, 'San Francisco'],
    const ['February',  5.61, 16,  8, 'Los Angeles'],
    const ['March',     8.26, 36,  9, 'San Francisco'],
    const ['April',    15.46, 63, 49, 'Los Angeles'],
    const ['May',      18.50, 77, 46, 'Mountain View'],
    const ['June',     14.61, 60,  8, 'San Francisco'],
    const ['July',      3.26,  9,  6, 'Mountain View'],
    const ['August',    1.46,  9,  3, 'San Francisco'],
    const ['September', 1.46, 13,  9, 'Sunnyvale'],
    const ['October',   2.46, 29,  3, 'Mountain View'],
    const ['November',  4.46, 33,  9, 'Los Angeles'],
    const ['December',  8.46, 19,  3, 'San Francisco']
];

List SMALL_DATA_RTL = const [
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
