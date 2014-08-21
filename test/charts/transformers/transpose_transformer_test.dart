library charted.test.transposetransformer;

import 'package:charted/charts/charts.dart';
import 'package:unittest/unittest.dart';

main() {
  List COLUMNS = [
      new ChartColumnSpec(label:'Country', type:ChartColumnSpec.TYPE_STRING),
      new ChartColumnSpec(label:'Stats1'),
      new ChartColumnSpec(label:'Stats2'),
      new ChartColumnSpec(label:'Stats3')
    ];

  const List DATA = const [
      const['USA', 9.50,  50,  2000],
      const['Japan',1.50,  99,  2000],
      const['Taiwan', 3.50,  127,  1337],
      const['France', 2.50,  29,  6000],
      const['Germany', 10.99,  999,  10000],
      const['England', 2.50,  10,  3000],
      const['Brazil', 1.50,  27,  6000],
      const['Argentina', 5.50,  37,  2000],
    ];

  ChartData inputData = new ChartData(COLUMNS, DATA);

  test('Transpose ChartData', () {
    TransposeTransformer transformer = new TransposeTransformer();
    ChartData result = transformer.transform(inputData);
    // Expected data:
    // ['Stats1', 9.50, 1.50, 3.50, 2.50, 10.99, 2.50, 1.50, 5.50]
    // ['Stats2', 50, 99, 127, 29, 999, 10, 27, 37]
    // ['Stats3', 2000, 2000, 1337, 6000, 10000, 3000, 6000, 2000]
    // While The chart column spec should contain new column specs with label
    // equal to the list of country names.

    // Stats1
    expect(result.rows.elementAt(0).elementAt(0), equals('Stats1'));
    expect(result.rows.elementAt(0).elementAt(1), equals(9.50));
    expect(result.rows.elementAt(0).elementAt(2), equals(1.50));
    expect(result.rows.elementAt(0).elementAt(3), equals(3.50));
    expect(result.rows.elementAt(0).elementAt(4), equals(2.50));
    expect(result.rows.elementAt(0).elementAt(5), equals(10.99));

    // Stats2
    expect(result.rows.elementAt(1).elementAt(0), equals('Stats2'));
    expect(result.rows.elementAt(1).elementAt(1), equals(50));
    expect(result.rows.elementAt(1).elementAt(2), equals(99));
    expect(result.rows.elementAt(1).elementAt(3), equals(127));
    expect(result.rows.elementAt(1).elementAt(4), equals(29));
    expect(result.rows.elementAt(1).elementAt(5), equals(999));

    // Stats3
    expect(result.rows.elementAt(2).elementAt(0), equals('Stats3'));
    expect(result.rows.elementAt(2).elementAt(1), equals(2000));
    expect(result.rows.elementAt(2).elementAt(2), equals(2000));
    expect(result.rows.elementAt(2).elementAt(3), equals(1337));
    expect(result.rows.elementAt(2).elementAt(4), equals(6000));
    expect(result.rows.elementAt(2).elementAt(5), equals(10000));

    // ColumnSpecs
    expect(result.columns.elementAt(0).label, equals('Country'));
    expect(result.columns.elementAt(1).label, equals('USA'));
    expect(result.columns.elementAt(2).label, equals('Japan'));
    expect(result.columns.elementAt(3).label, equals('Taiwan'));
    expect(result.columns.elementAt(4).label, equals('France'));
    expect(result.columns.elementAt(5).label, equals('Germany'));
    expect(result.columns.elementAt(6).label, equals('England'));
    expect(result.columns.elementAt(7).label, equals('Brazil'));

  });

  test('Transposing data twice should produce the original data', () {
    TransposeTransformer t1 = new TransposeTransformer();
    TransposeTransformer t2 = new TransposeTransformer();
    ChartData result = t2.transform(t1.transform(inputData));

    // Check all values are the same in the result and original data.
    for (var i = 0; i < result.rows.length; i++) {
      var row = result.rows.elementAt(i);
      for (var j = 0; j < row.length; j++) {
        expect(row.elementAt(j),
            equals((DATA.elementAt(i) as List).elementAt(j)));
      }
    }

    for (var i = 0; i < result.columns.length; i++) {
      expect(result.columns.elementAt(i).label,
          equals((COLUMNS.elementAt(i) as ChartColumnSpec).label));
    }
  });
}
