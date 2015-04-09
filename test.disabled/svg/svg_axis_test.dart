/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.svg;

testSvgAxis() {
  String markup = '<div class="charts-axis-container">'
                     '<div class="charts-axis"></div>'
                     '<div class="charts-axis-async1"></div>'
                     '<div class="charts-axis-async2"></div>'
                     '<div class="charts-axis-async3"></div>'
                     '<div class="charts-axis-async4"></div>'
                  '</div>';

  Element root;
  SelectionScope scope;
  Selection axis, ticks, text;

  setup() {
    root = new Element.html(markup);
    document.documentElement.append(root);
    scope = new SelectionScope.selector('.charts-axis-container');
    axis = scope.select('.charts-axis');
  }

  teardown() {
    root.remove();
  }

  group('SvgAxis.axis', () {
    setUp(setup);
    tearDown(teardown);
    SvgAxis svgAxis = new SvgAxis();
    svgAxis.scale.domain = [1, 10];

    test('generates an axis with default tickFormat and scale', () {
      svgAxis.axis(axis);
      ticks = axis.selectAll('.tick');
      text = ticks.select('text');
      text.each((d, i, Element e) {
        //Exactly 10 ticks steped 1 from 1 to 10 according to domain
        expect(e.text, equals((i + 1).toString()));
      });
    });

    test('generates an axis with manaully set tickFormat', () {
      svgAxis.tickFormat = (x) => x.toString() + 'px';
      svgAxis.axis(axis);
      ticks = axis.selectAll('.tick');
      text = ticks.select('text');
      text.each((d, i, Element e) {
        //Exactly 10 ticks steped 1 from 1 to 10 according to domain
        expect(e.text, equals((i + 1).toString() + '.0px'));
      });
      svgAxis.tickFormat = null;
    });

    test('generates an axis with manaully set tickValues', () {
      svgAxis.tickValues = [2, 4, 6, 8];
      svgAxis.axis(axis);
      ticks = axis.selectAll('.tick');
      text = ticks.select('text');
      text.each((d, i, Element e) {
        //Exactly 10 ticks steped 1 from 1 to 10 according to domain
        expect(e.text, equals((i * 2 + 2).toString()));
      });
    });

    test('transforms linear scale axis ticks to right positions', () {
      Selection axis = scope.select('.charts-axis-async1');
      SvgAxis svgAxis = new SvgAxis();
      svgAxis.scale.domain = [1, 10];
      svgAxis.scale.range = [10, 100];
      svgAxis.axis(axis);
      Selection ticks = axis.selectAll('.tick');
      new Timer(new Duration(milliseconds:200), expectAsync(() {
        ticks.each((d, i, Element e) {
          int pos = e.attributes['transform'].indexOf(',');
          expect(num.parse(e.attributes['transform'].substring(10, pos)),
              closeTo((i + 1) * 10, EPSILON));
        });
      }));
      Selection axis2 = scope.select('.charts-axis-async2');
      SvgAxis svgAxis2 = new SvgAxis();
      svgAxis2.orientation = ORIENTATION_LEFT;
      svgAxis2.scale.domain = [1, 10];
      svgAxis2.scale.range = [10, 100];
      svgAxis2.axis(axis2);
      Selection ticks2 = axis2.selectAll('.tick');
      new Timer(new Duration(milliseconds:200), expectAsync(() {
        ticks2.each((d, i, Element e) {
          int pos1 = e.attributes['transform'].indexOf(',');
          int pos2 = e.attributes['transform'].indexOf(')');
          expect(num.parse(e.attributes['transform'].substring(pos1 + 1, pos2)),
              closeTo((i + 1) * 10, EPSILON));
        });
      }));
    });

    test('generates an axis with ordinal scale defined tickValues '
        'and transforms ordinal scale axis ticks to right positions', () {
      Selection axis = scope.select('.charts-axis-async3');
      SvgAxis svgAxis = new SvgAxis();
      svgAxis.orientation = ORIENTATION_TOP;
      svgAxis.scale = new OrdinalScale();
      svgAxis.scale.domain = ['Jan', 'Feb', 'Mar'];
      svgAxis.scale.range = [0, 45, 90];
      svgAxis.scale.rangeBand = 10;
      svgAxis.axis(axis);
      Selection ticks = axis.selectAll('.tick');
      text = ticks.select('text');
      text.each((d, i, Element e) {
        expect(e.text, equals(svgAxis.scale.domain[i]));
      });
      new Timer(new Duration(milliseconds:200), expectAsync(() {
        ticks.each((d, i, Element e) {
          int pos = e.attributes['transform'].indexOf(',');
          expect(num.parse(e.attributes['transform'].substring(10, pos)),
              closeTo(i * 45 + 5, EPSILON));
        });
      }));
      Selection axis2 = scope.select('.charts-axis-async4');
      SvgAxis svgAxis2 = new SvgAxis();
      svgAxis2.orientation = ORIENTATION_RIGHT;
      svgAxis2.scale = new OrdinalScale();
      svgAxis2.scale.domain = ['Jan', 'Feb', 'Mar'];
      svgAxis2.scale.range = [0, 45, 90];
      svgAxis2.scale.rangeBand = 10;
      svgAxis2.axis(axis2);
      text = ticks.select('text');
      text.each((d, i, Element e) {
        expect(e.text, equals(svgAxis2.scale.domain[i]));
      });
      Selection ticks2 = axis2.selectAll('.tick');
      new Timer(new Duration(milliseconds:200), expectAsync(() {
        ticks2.each((d, i, Element e) {
          int pos1 = e.attributes['transform'].indexOf(',');
          int pos2 = e.attributes['transform'].indexOf(')');
          expect(num.parse(e.attributes['transform'].substring(pos1 + 1, pos2)),
              closeTo(i * 45 + 5, EPSILON));
        });
      }));
    });
  });
}