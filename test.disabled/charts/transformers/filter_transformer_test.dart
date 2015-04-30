library charted.test.filtertransformer;

import 'package:charted/charts/charts.dart';
import 'package:unittest/unittest.dart';

main() {
  List COLUMNS = [
      new ChartColumnSpec(label:'Continent', type:ChartColumnSpec.TYPE_STRING),
      new ChartColumnSpec(label:'Country', type:ChartColumnSpec.TYPE_STRING),
      new ChartColumnSpec(label:'City', type:ChartColumnSpec.TYPE_STRING),
      new ChartColumnSpec(label:'Stats1'),
      new ChartColumnSpec(label:'Stats2'),
      new ChartColumnSpec(label:'Stats3')
    ];

  const List DATA = const [
      const['America', 'USA', 'LA', 4.51,  7,  1000],
      const['America', 'USA', 'SF', 9.50,  50,  2000],
      const['Asia', 'Japan', 'Tokyo', 1.50,  99,  2000],
      const['Asia', 'Japan', 'Kyoto', 5.10,  66,  4000],
      const['Asia', 'Taiwan', 'Taipei', 3.50,  127,  1337],
      const['Asia', 'Japan', 'Osaka', 4.50,  19,  2000],
      const['Asia', 'Taiwan', 'Tainan', 1.50,  10,  100],
      const['Europe', 'France', 'Nice', 2.50,  29,  6000],
      const['Europe', 'France', 'Paris', 6.50,  129,  3000],
      const['Europe', 'Germany', 'Berlin', 10.99,  999,  10000],
      const['Europe', 'England', 'London', 2.50,  10,  3000],
      const['America', 'USA', 'NY', 3.50,  17,  4000],
      const['America', 'Brazil', 'Brasilia', 1.50,  27,  6000],
      const['America', 'Argentina', 'Buenos Aires', 5.50,  37,  2000],
      const['America', 'Brazil', 'Rio de Janeiro', 2.50,  52,  3000],
    ];

  ChartData inputData = new ChartData(COLUMNS, DATA);

  test('Filter out rows whose stats3 is below 4000', () {
    FilterDefinition fd = new FilterDefinition(5, (value) => (value >= 4000));

    FilterTransformer transformer = new FilterTransformer([fd]);
    ChartData result = transformer.transform(inputData);
    // Expected data:
    // ['Asia', 'Japan', 'Kyoto', 5.10,  66,  4000],
    // ['Europe', 'France', 'Nice', 2.50,  29,  6000],
    // ['Europe', 'Germany', 'Berlin', 10.99,  999,  10000],
    // ['America', 'USA', 'NY', 3.50,  17,  4000],
    // ['America', 'Brazil', 'Brasilia', 1.50,  27,  6000],

    // ['Asia', 'Japan', 'Kyoto', 5.10,  66,  4000]
    expect(result.rows.elementAt(0).elementAt(0), equals('Asia'));
    expect(result.rows.elementAt(0).elementAt(1), equals('Japan'));
    expect(result.rows.elementAt(0).elementAt(2), equals('Kyoto'));
    expect(result.rows.elementAt(0).elementAt(3), equals(5.10));
    expect(result.rows.elementAt(0).elementAt(4), equals(66));
    expect(result.rows.elementAt(0).elementAt(5), equals(4000));

    // ['Europe', 'Germany', 'Berlin', 10.99,  999,  10000]
    expect(result.rows.elementAt(2).elementAt(0), equals('Europe'));
    expect(result.rows.elementAt(2).elementAt(1), equals('Germany'));
    expect(result.rows.elementAt(2).elementAt(2), equals('Berlin'));
    expect(result.rows.elementAt(2).elementAt(3), equals(10.99));
    expect(result.rows.elementAt(2).elementAt(4), equals(999));
    expect(result.rows.elementAt(2).elementAt(5), equals(10000));

    // ['America', 'Brazil', 'Brasilia', 1.50,  27,  6000],
    expect(result.rows.elementAt(4).elementAt(0), equals('America'));
    expect(result.rows.elementAt(4).elementAt(1), equals('Brazil'));
    expect(result.rows.elementAt(4).elementAt(2), equals('Brasilia'));
    expect(result.rows.elementAt(4).elementAt(3), equals(1.5));
    expect(result.rows.elementAt(4).elementAt(4), equals(27));
    expect(result.rows.elementAt(4).elementAt(5), equals(6000));
  });

  test('Filter out rows whose stats3 is below 4000 and is not in America', () {
    FilterDefinition fd1 = new FilterDefinition(5, (value) => (value >= 4000));
    FilterDefinition fd2 = new FilterDefinition(0,
        (value) => (value == 'America'));

    FilterTransformer transformer = new FilterTransformer([fd1, fd2]);
    ChartData result = transformer.transform(inputData);
    // Expected data:
    // ['America', 'USA', 'NY', 3.50,  17,  4000],
    // ['America', 'Brazil', 'Brasilia', 1.50,  27,  6000],

    // ['America', 'USA', 'NY', 3.50,  17,  4000],
    expect(result.rows.elementAt(0).elementAt(0), equals('America'));
    expect(result.rows.elementAt(0).elementAt(1), equals('USA'));
    expect(result.rows.elementAt(0).elementAt(2), equals('NY'));
    expect(result.rows.elementAt(0).elementAt(3), equals(3.5));
    expect(result.rows.elementAt(0).elementAt(4), equals(17));
    expect(result.rows.elementAt(0).elementAt(5), equals(4000));

    // ['America', 'Brazil', 'Brasilia', 1.50,  27,  6000],
    expect(result.rows.elementAt(1).elementAt(0), equals('America'));
    expect(result.rows.elementAt(1).elementAt(1), equals('Brazil'));
    expect(result.rows.elementAt(1).elementAt(2), equals('Brasilia'));
    expect(result.rows.elementAt(1).elementAt(3), equals(1.5));
    expect(result.rows.elementAt(1).elementAt(4), equals(27));
    expect(result.rows.elementAt(1).elementAt(5), equals(6000));
  });
}
