/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
library charted.test.aggregationtransformer;

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

  test('Sum aggregation all dimension collapsed', () {
    AggregationTransformer transformer = new AggregationTransformer([0, 1, 2],
        [3, 4, 5]);
    ChartData result = transformer.transform(inputData);
    // Expected data:
    // [America, , , 27.0, 190.0, 18000.0]
    // [Asia, , , 16.1, 321.0, 9437.0]
    // [Europe, , , 22.49, 1167.0, 22000.0]

    // America
    expect(result.rows.elementAt(0).elementAt(3), closeTo(27.01, EPSILON));
    expect(result.rows.elementAt(0).elementAt(4), equals(190));
    expect(result.rows.elementAt(0).elementAt(5), equals(18000));

    // Asia
    expect(result.rows.elementAt(1).elementAt(3), closeTo(16.1, EPSILON));
    expect(result.rows.elementAt(1).elementAt(4), equals(321));
    expect(result.rows.elementAt(1).elementAt(5), equals(9437));

    // Europe
    expect(result.rows.elementAt(2).elementAt(3), closeTo(22.49, EPSILON));
    expect(result.rows.elementAt(2).elementAt(4), equals(1167));
    expect(result.rows.elementAt(2).elementAt(5), equals(22000));
  });

  test('Sum aggregation expanding America in continent dimension', () {
    AggregationTransformer transformer = new AggregationTransformer([0, 1, 2],
        [3, 4, 5]);
    transformer.expand(['America']);
    ChartData result = transformer.transform(inputData);

    // Expected data:
    // [America, Argentina, , 5.5, 37.0, 2000.0]
    // [America, Brazil, , 4.0, 79.0, 9000.0]
    // [America, USA, , 17.51, 74.0, 7000.0]
    // [Asia, , , 16.1, 321.0, 9437.0]
    // [Europe, , , 22.49, 1167.0, 22000.0]

    // America
    expect(result.rows.elementAt(0).elementAt(3), closeTo(5.5, EPSILON));
    expect(result.rows.elementAt(0).elementAt(4), equals(37));
    expect(result.rows.elementAt(0).elementAt(5), equals(2000));
    expect(result.rows.elementAt(1).elementAt(3), closeTo(4, EPSILON));
    expect(result.rows.elementAt(1).elementAt(4), equals(79));
    expect(result.rows.elementAt(1).elementAt(5), equals(9000));
    expect(result.rows.elementAt(2).elementAt(3), closeTo(17.51, EPSILON));
    expect(result.rows.elementAt(2).elementAt(4), equals(74));
    expect(result.rows.elementAt(2).elementAt(5), equals(7000));

    // Asia
    expect(result.rows.elementAt(3).elementAt(3), closeTo(16.1, EPSILON));
    expect(result.rows.elementAt(3).elementAt(4), equals(321));
    expect(result.rows.elementAt(3).elementAt(5), equals(9437));

    // Europe
    expect(result.rows.elementAt(4).elementAt(3), closeTo(22.49, EPSILON));
    expect(result.rows.elementAt(4).elementAt(4), equals(1167));
    expect(result.rows.elementAt(4).elementAt(5), equals(22000));
  });

  test('Sum aggregation expanding [America, Brazil] in continent/country '+
      'dimension', () {
    AggregationTransformer transformer = new AggregationTransformer([0, 1, 2],
        [3, 4, 5]);
    transformer.expand(['America']);
    transformer.expand(['America', 'Brazil']);
    ChartData result = transformer.transform(inputData);

    // Expected data:
    // [America, Argentina, , 5.5, 37.0, 2000.0]
    // [America, Brazil, 'Brasilia, 1.50,  27,  6000]
    // [America, Brazil, 'Rio de Janeiro, 2.50,  52,  3000]
    // [America, USA, , 17.51, 74.0, 7000.0]
    // [Asia, , , 16.1, 321.0, 9437.0]
    // [Europe, , , 22.49, 1167.0, 22000.0]

    // America Argentina
    expect(result.rows.elementAt(0).elementAt(3), closeTo(5.5, EPSILON));
    expect(result.rows.elementAt(0).elementAt(4), equals(37));
    expect(result.rows.elementAt(0).elementAt(5), equals(2000));

    // America Brazil Brasilia
    expect(result.rows.elementAt(1).elementAt(3), closeTo(1.5, EPSILON));
    expect(result.rows.elementAt(1).elementAt(4), equals(27));
    expect(result.rows.elementAt(1).elementAt(5), equals(6000));

    // America Brazil Rio de Janeiro
    expect(result.rows.elementAt(2).elementAt(3), closeTo(2.5, EPSILON));
    expect(result.rows.elementAt(2).elementAt(4), equals(52));
    expect(result.rows.elementAt(2).elementAt(5), equals(3000));

    // America USA
    expect(result.rows.elementAt(3).elementAt(3), closeTo(17.51, EPSILON));
    expect(result.rows.elementAt(3).elementAt(4), equals(74));
    expect(result.rows.elementAt(3).elementAt(5), equals(7000));

    // Asia
    expect(result.rows.elementAt(4).elementAt(3), closeTo(16.1, EPSILON));
    expect(result.rows.elementAt(4).elementAt(4), equals(321));
    expect(result.rows.elementAt(4).elementAt(5), equals(9437));

    // Europe
    expect(result.rows.elementAt(5).elementAt(3), closeTo(22.49, EPSILON));
    expect(result.rows.elementAt(5).elementAt(4), equals(1167));
    expect(result.rows.elementAt(5).elementAt(5), equals(22000));
  });

  test('Collapsing parent of expanded dimension should collapse dimension', () {
    AggregationTransformer transformer = new AggregationTransformer([0, 1, 2],
        [3, 4, 5]);
    transformer.expand(['America']);
    transformer.expand(['America', 'Brazil']);
    transformer.collapse(['America']);
    ChartData result = transformer.transform(inputData);

    // Expected data:
    // [America, , , 27.0, 190.0, 18000.0]
    // [Asia, , , 16.1, 321.0, 9437.0]  -- not tested in this case
    // [Europe, , , 22.49, 1167.0, 22000.0] -- not tested in this case

    // America
    expect(result.rows.elementAt(0).elementAt(3), closeTo(27.01, EPSILON));
    expect(result.rows.elementAt(0).elementAt(4), equals(190));
    expect(result.rows.elementAt(0).elementAt(5), equals(18000));
  });

  test('Expanding the lowest dimension should be ignored', () {
    AggregationTransformer transformer = new AggregationTransformer([0, 1, 2],
        [3, 4, 5]);
    transformer.expand(['America']);
    transformer.expand(['America', 'Brazil']);
    transformer.expand(['America', 'Brazil', 'Brasilia']);
    ChartData result = transformer.transform(inputData);

    // Expected data:
    // [America, Argentina, , 5.5, 37.0, 2000.0]
    // [America, Brazil, 'Brasilia, 1.50,  27,  6000]
    // [America, Brazil, 'Rio de Janeiro, 2.50,  52,  3000]
    // [America, USA, , 17.51, 74.0, 7000.0]
    // [Asia, , , 16.1, 321.0, 9437.0] -- not tested in this case
    // [Europe, , , 22.49, 1167.0, 22000.0] -- not tested in this case

    // America Argentina
    expect(result.rows.elementAt(0).elementAt(3), closeTo(5.5, EPSILON));
    expect(result.rows.elementAt(0).elementAt(4), equals(37));
    expect(result.rows.elementAt(0).elementAt(5), equals(2000));

    // America Brazil Brasilia
    expect(result.rows.elementAt(1).elementAt(3), closeTo(1.5, EPSILON));
    expect(result.rows.elementAt(1).elementAt(4), equals(27));
    expect(result.rows.elementAt(1).elementAt(5), equals(6000));

    // America Brazil Rio de Janeiro
    expect(result.rows.elementAt(2).elementAt(3), closeTo(2.5, EPSILON));
    expect(result.rows.elementAt(2).elementAt(4), equals(52));
    expect(result.rows.elementAt(2).elementAt(5), equals(3000));

    // America USA
    expect(result.rows.elementAt(3).elementAt(3), closeTo(17.51, EPSILON));
    expect(result.rows.elementAt(3).elementAt(4), equals(74));
    expect(result.rows.elementAt(3).elementAt(5), equals(7000));
  });

  test('Expanding the multiple dimension at different level', () {
    AggregationTransformer transformer = new AggregationTransformer([0, 1, 2],
        [3, 4, 5]);
    transformer.expand(['Asia']);
    transformer.expand(['Asia', 'Taiwan']);
    transformer.expand(['Asia', 'Japan', 'Osaka']);
    transformer.expand(['Europe']);
    transformer.collapse(['Asia', 'Japan']);
    ChartData result = transformer.transform(inputData);


    // Expected data:
    // [America, , , 27.0, 190.0, 18000.0]
    // [Asia, Japan, , 10.10, 184.0, 8000.0]
    // [Asia, Taiwan, Tainan, 1.50, 10.0, 100.0]
    // [Asia, Taiwan, Taipei, 3.50, 127.0, 1337.0]
    // [Europe, England, , 2.50, 10.0, 3000.0]
    // [Europe, France, , 9.00, 158.0, 9000.0]
    // [Europe, Germany, , 10.99, 999.0, 10000.0]

    // America
    expect(result.rows.elementAt(0).elementAt(3), closeTo(27.01, EPSILON));
    expect(result.rows.elementAt(0).elementAt(4), equals(190));
    expect(result.rows.elementAt(0).elementAt(5), equals(18000));

    // Asia Japan
    expect(result.rows.elementAt(1).elementAt(3), closeTo(11.1, EPSILON));
    expect(result.rows.elementAt(1).elementAt(4), equals(184));
    expect(result.rows.elementAt(1).elementAt(5), equals(8000));

    // Asia Taiwan Tainan
    expect(result.rows.elementAt(2).elementAt(3), closeTo(1.5, EPSILON));
    expect(result.rows.elementAt(2).elementAt(4), equals(10));
    expect(result.rows.elementAt(2).elementAt(5), equals(100));

    // Asia Taiwan Taipei
    expect(result.rows.elementAt(3).elementAt(3), closeTo(3.5, EPSILON));
    expect(result.rows.elementAt(3).elementAt(4), equals(127));
    expect(result.rows.elementAt(3).elementAt(5), equals(1337));

    // Europe England
    expect(result.rows.elementAt(4).elementAt(3), closeTo(2.5, EPSILON));
    expect(result.rows.elementAt(4).elementAt(4), equals(10));
    expect(result.rows.elementAt(4).elementAt(5), equals(3000));

    // Europe France
    expect(result.rows.elementAt(5).elementAt(3), closeTo(9, EPSILON));
    expect(result.rows.elementAt(5).elementAt(4), equals(158));
    expect(result.rows.elementAt(5).elementAt(5), equals(9000));

    // Europe Germany
    expect(result.rows.elementAt(6).elementAt(3), closeTo(10.99, EPSILON));
    expect(result.rows.elementAt(6).elementAt(4), equals(999));
    expect(result.rows.elementAt(6).elementAt(5), equals(10000));
  });

  test('Expanding the multiple dimension at different level', () {
    AggregationTransformer transformer = new AggregationTransformer([0, 1, 2],
        [3, 4, 5]);
    transformer.expand(['Asia']);
    transformer.expand(['Asia', 'Taiwan']);
    transformer.expand(['Asia', 'Japan', 'Osaka']);
    transformer.expand(['Europe']);
    transformer.collapse(['Asia', 'Japan']);

    ChartData result = transformer.transform(inputData);


    // Expected data:
    // [America, , , 27.0, 190.0, 18000.0]
    // [Asia, Japan, , 10.10, 184.0, 8000.0]
    // [Asia, Taiwan, Tainan, 1.50, 10.0, 100.0]
    // [Asia, Taiwan, Taipei, 3.50, 127.0, 1337.0]
    // [Europe, England, , 2.50, 10.0, 3000.0]
    // [Europe, France, , 9.00, 158.0, 9000.0]
    // [Europe, Germany, , 10.99, 999.0, 10000.0]

    transformer.expandAll();

    // America
    expect(result.rows.elementAt(0).elementAt(3), closeTo(27.01, EPSILON));
    expect(result.rows.elementAt(0).elementAt(4), equals(190));
    expect(result.rows.elementAt(0).elementAt(5), equals(18000));

    // Asia Japan
    expect(result.rows.elementAt(1).elementAt(3), closeTo(11.1, EPSILON));
    expect(result.rows.elementAt(1).elementAt(4), equals(184));
    expect(result.rows.elementAt(1).elementAt(5), equals(8000));

    // Asia Taiwan Tainan
    expect(result.rows.elementAt(2).elementAt(3), closeTo(1.5, EPSILON));
    expect(result.rows.elementAt(2).elementAt(4), equals(10));
    expect(result.rows.elementAt(2).elementAt(5), equals(100));

    // Asia Taiwan Taipei
    expect(result.rows.elementAt(3).elementAt(3), closeTo(3.5, EPSILON));
    expect(result.rows.elementAt(3).elementAt(4), equals(127));
    expect(result.rows.elementAt(3).elementAt(5), equals(1337));

    // Europe England
    expect(result.rows.elementAt(4).elementAt(3), closeTo(2.5, EPSILON));
    expect(result.rows.elementAt(4).elementAt(4), equals(10));
    expect(result.rows.elementAt(4).elementAt(5), equals(3000));

    // Europe France
    expect(result.rows.elementAt(5).elementAt(3), closeTo(9, EPSILON));
    expect(result.rows.elementAt(5).elementAt(4), equals(158));
    expect(result.rows.elementAt(5).elementAt(5), equals(9000));

    // Europe Germany
    expect(result.rows.elementAt(6).elementAt(3), closeTo(10.99, EPSILON));
    expect(result.rows.elementAt(6).elementAt(4), equals(999));
    expect(result.rows.elementAt(6).elementAt(5), equals(10000));
  });

  test('Grouping by country-continent-city with less fact columns', () {
    AggregationTransformer transformer = new AggregationTransformer([1, 2, 0],
        [5, 3]);

    ChartData result = transformer.transform(inputData);

    // Expected data:
    // [Argentina, , , 2000.0, 5.50]
    // [Brazil, , , 9000.0, 4.00]
    // [England, , , 3000.0, 2.50]
    // [France, , , 9000.0, 9.00]
    // more entries not listed/tested..
    // Argentian
    expect(result.rows.elementAt(0).elementAt(3), equals(2000));
    expect(result.rows.elementAt(0).elementAt(4), closeTo(5.5, EPSILON));

    // Brazil
    expect(result.rows.elementAt(1).elementAt(3), equals(9000));
    expect(result.rows.elementAt(1).elementAt(4), closeTo(4, EPSILON));

    // England
    expect(result.rows.elementAt(2).elementAt(3), equals(3000));
    expect(result.rows.elementAt(2).elementAt(4), closeTo(2.5, EPSILON));

    // France
    expect(result.rows.elementAt(3).elementAt(3), equals(9000));
    expect(result.rows.elementAt(3).elementAt(4), closeTo(9, EPSILON));
  });


  test('Modifying data row when it is an ObeservableList should cause ' +
      'transform to be called', () {
    ObservableList observableRows = new ObservableList.from(DATA);
    ChartData observableData = new ChartData(COLUMNS, observableRows);
    AggregationTransformer aggrTransformer = new AggregationTransformer(
        [1, 2, 0], [5, 3]);

    ChartData result = aggrTransformer.transform(observableData);
    // Result at this point:
    // [Argentina, , , 2000.0, 5.50]
    // [Brazil, , , 9000.0, 4.00]
    // [England, , , 3000.0, 2.50]
    // [France, , , 9000.0, 9.00]
    // ...

    // Remove Brazil, Rio de Janeiro from the original data, causing aggregation
    // of stats1 for Brazil to drop from 4 to 1.5 and stats3 from 9000 to 6000.
    observableRows.remove(observableRows.last);
    observableRows.deliverListChanges();
    (observableData as Observable).deliverChanges();

    // [Argentina, , , 2000.0, 5.50]
    // [Brazil, , , 6000.0, 2.50]
    expect(result.rows.elementAt(0).elementAt(3), equals(2000));
    expect(result.rows.elementAt(0).elementAt(4), closeTo(5.5, EPSILON));
    expect(result.rows.elementAt(1).elementAt(3), equals(6000));
    expect(result.rows.elementAt(1).elementAt(4), closeTo(1.5, EPSILON));
  });
}
