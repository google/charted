library charted.test.chaintransform;

import 'package:charted/charts/charts.dart';
import 'package:charted/core/utils.dart';
import 'package:unittest/unittest.dart';
import 'package:observable/observable.dart';

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

  test('Filter out sum aggregated rows whose stats2 is above 1000', () {
    AggregationTransformer aggrTransformer = new AggregationTransformer(
        [0, 1, 2], [3, 4, 5]);
    FilterDefinition fd = new FilterDefinition(4, (value) => (value <= 1000));
    FilterTransformer filterTransformer = new FilterTransformer([fd]);
    ChartData result = filterTransformer.transform(
        aggrTransformer.transform(inputData));
    // Expected data:
    // [America, , , 27.0, 190.0, 18000.0]
    // [Asia, , , 16.1, 321.0, 9437.0]
    // [Europe, , , 22.49, 1167.0, 22000.0] -- Filtered out

    // [America, , , 27.0, 190.0, 18000.0]
    expect(result.rows.elementAt(0).elementAt(3), closeTo(27.01, EPSILON));
    expect(result.rows.elementAt(0).elementAt(4), equals(190));
    expect(result.rows.elementAt(0).elementAt(5), equals(18000));

    // [Asia, , , 16.1, 321.0, 9437.0]
    expect(result.rows.elementAt(1).elementAt(3), closeTo(16.1, EPSILON));
    expect(result.rows.elementAt(1).elementAt(4), equals(321));
    expect(result.rows.elementAt(1).elementAt(5), equals(9437));

  });

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

  test('Grouping by country-continent-city with less fact columns, the ' +
      'filter out rows whose stats3 (column4) is less than 8000', () {
    AggregationTransformer aggrTransformer = new AggregationTransformer(
        [1, 2, 0], [5, 3]);

    ChartData aggrResult = aggrTransformer.transform(inputData);
    // Result at this point:
    // [Argentina, , , 2000.0, 5.50]
    // [Brazil, , , 9000.0, 4.00]
    // [England, , , 3000.0, 2.50]
    // [France, , , 9000.0, 9.00]
    // ...

    FilterDefinition fd = new FilterDefinition(3, (value) => (value >= 8000));
    FilterTransformer transformer = new FilterTransformer([fd]);
    (aggrResult as Observable).deliverChanges();
    ChartData result = transformer.transform(aggrResult);

    // Result at this point:
    // [Brazil, , , 9000.0, 4.00]
    // [France, , , 9000.0, 9.00]
    // ...

    // Brazil
    expect(result.rows.elementAt(0).elementAt(3), equals(9000));
    expect(result.rows.elementAt(0).elementAt(4), closeTo(4, EPSILON));

    // France
    expect(result.rows.elementAt(1).elementAt(3), equals(9000));
    expect(result.rows.elementAt(1).elementAt(4), closeTo(9, EPSILON));
  });

}
