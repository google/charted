/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.test.selection;

import 'dart:html' show document, Element;
import 'package:unittest/unittest.dart';
import 'package:charted/selection/selection.dart';

part 'selection_scope_test.dart';

selectionTests() {
  testSelectionScope();
  testSelections();
}

testSelections() {
  String markup = '<div class="charted-scope-root">'
            '<div class="charted-scope-inner">'
              '<div class="charted-scope-leaf"></div>'
              '<div class="charted-scope-leaf"></div>'
            '</div>'
          '</div>';

  Element root;
  SelectionScope scope;
  Selection empty, single, multiple;

  setup() {
    root = new Element.html(markup);
    document.documentElement.append(root);
    scope = new SelectionScope.selector('.charted-scope-root');

    empty = scope.selectAll('.node');
    single = scope.select('.charted-scope-inner');
    multiple = scope.selectAll('.charted-scope-leaf');
  }

  teardown() {
    root.remove();
  }

  test('toCallback() creates a callback to return the given value', () {
    num value = 100;
    SelectionCallback<num> cb = toCallback(value);
    expect(cb(null, null, null), equals(value));
  });

  test('toValueAccessor() creates an accessor to return the given value', () {
    num value = 100;
    SelectionValueAccessor<num> cb = toValueAccessor(value);
    expect(cb(null, null), equals(value));
  });

  group('Selection created from scope', () {
    setUp(setup);
    tearDown(teardown);

    test('has isEmpty=true when the selection is empty', () {
      expect(empty.isEmpty, equals(true));
      expect(single.isEmpty, equals(false));
      expect(multiple.isEmpty, equals(false));
    });

    test('has length set to number of non-null elements', () {
      expect(empty.length, equals(0));
      expect(single.length, equals(1));
      expect(multiple.length, equals(2));
    });

    test('has first=null when there selection is empty', () {
      expect(empty.first, equals(null));
    });

    test('has first set to first non-null element in selection', () {
      expect(single.first.className, equals('charted-scope-inner'));
      expect(multiple.first.className, equals('charted-scope-leaf'));
    });

    test('has exactly one group', () {
      expect(empty.groups.length, equals(1));
      expect(single.groups.length, equals(1));
      expect(multiple.groups.length, equals(1));
    });
  });

  group('Selection created from another selection', () {
    Selection selection1, selection2, selection3;

    setUp(() {
      setup();
      selection1 = empty.selectAll('.child-nodes');
      selection2 = single.selectAll('.child-nodes');
      selection3 = multiple.selectAll('.child-nodes');
    });
    tearDown(teardown);

    test('has length set to number of non-null elements', () {
      expect(selection1.length, equals(0));
      expect(selection2.length, equals(0));
      expect(selection3.length, equals(0));
    });

    test('has first=null when there selection is empty', () {
      expect(selection1.first, equals(null));
      expect(selection2.first, equals(null));
      expect(selection3.first, equals(null));
    });

    test('has same number of groups as number of non-null elements '
        'in source selection', () {
      expect(selection1.groups.length, equals(empty.length));
      expect(selection2.groups.length, equals(single.length));
      expect(selection3.groups.length, equals(multiple.length));
    });
  });

  group('Selection', () {
    setUp(setup);
    tearDown(teardown);

    test('attr sets attribute to the specified value on selected', () {
      multiple.each((d, i, e) {
        expect(e.attributes['height'], isNull);
      });
      multiple.attr('height', '10');
      multiple.each((d, i, e) {
        expect(e.attributes['height'], equals('10'));
      });
    });

    test('attrWithCallBack sets attribute to the specified value '
         'on selected elements with callback', () {
      multiple.each((d, i, e) {
        expect(e.attributes['height'], isNull);
      });
      multiple.attrWithCallback('height', (d, i, e) => '${i * 10}');
      multiple.each((d, i, e) {
        expect(e.attributes['height'], equals('${i * 10}'));
      });
    });


    test('classed sets class to the specified value on selected', () {
      multiple.classed('new-class');
      multiple.each((d, i, e) {
        expect(e.attributes['class'], equals('charted-scope-leaf new-class'));
      });
      multiple.classed('new-class', false);
      multiple.each((d, i, e) {
        expect(e.attributes['class'], equals('charted-scope-leaf'));
      });
    });

    test('classedWithCallBack sets class to the specified value '
         'on selected elements with callback', () {
      multiple.classedWithCallback('new-class', (d, i, e) => i % 2 > 0);
      multiple.each((d, i, e) {
        if (i % 2 > 0) {
          expect(e.attributes['class'], equals('charted-scope-leaf new-class'));
        } else {
          expect(e.attributes['class'], equals('charted-scope-leaf'));
        }
      });
      multiple.classedWithCallback('new-class', (d, i, e) => i % 2 == 0);
      multiple.each((d, i, e) {
        if (i % 2 == 0) {
          expect(e.attributes['class'], equals('charted-scope-leaf new-class'));
        } else {
          expect(e.attributes['class'], equals('charted-scope-leaf'));
        }
      });
    });

    test('style sets CSS style to specified value on selected', () {
      multiple.each((d, i, e) {
        expect(e.attributes['style'], isNull);
      });
      multiple.style('height', '10px');
      multiple.each((d, i, e) {
        expect(e.attributes['style'], equals('height: 10px;'));
      });
    });

    test('attrWithCallBack sets CSS style to the specified value '
         'on selected elements with callback', () {
      multiple.each((d, i, e) {
        expect(e.attributes['style'], isNull);
      });
      multiple.styleWithCallback('height', (d, i, e) => '${i * 10}px');
      multiple.each((d, i, e) {
        expect(e.attributes['style'], equals('height: ${i * 10}px;'));
      });
    });

    test('text sets text to specified value on selected', () {
      multiple.each((d, i, e) {
        expect(e.text, '');
      });
      multiple.text('some text');
      multiple.each((d, i, e) {
        expect(e.text, equals('some text'));
      });
    });

    test('textWithCallBack sets text to the specified value '
         'on selected elements with callback', () {
      multiple.each((d, i, e) {
        expect(e.text, '');
      });
      multiple.textWithCallback((d, i, e) => 'text-${i}');
      multiple.each((d, i, e) {
        expect(e.text, equals('text-${i}'));
      });
    });

    test('html sets inner html to specified value on selected', () {
      multiple.each((d, i, e) {
        expect(e.innerHtml, '');
      });
      multiple.text('some html');
      multiple.each((d, i, e) {
        expect(e.innerHtml, equals('some html'));
      });
    });

    test('htmlWithCallBack sets inner html to the specified value '
         'on selected elements with callback', () {
      multiple.each((d, i, e) {
        expect(e.innerHtml, '');
      });
      multiple.htmlWithCallback((d, i, e) => 'html-${i}');
      multiple.each((d, i, e) {
        expect(e.innerHtml, equals('html-${i}'));
      });
    });

    test('append appends new child elements to selection', () {
      expect(multiple.selectAll('.appended').length, equals(0));
      multiple.append('div')..classed('appended');
      expect(multiple.selectAll('.appended').length, equals(multiple.length));
      multiple.append('div')..classed('appended');
      expect(multiple.selectAll('.appended').length,
          equals(multiple.length * 2));
    });

    test('appendWithCallback appends new child elements '
         'to selection with callback', () {
      for (var i = 0; i < multiple.length; i++) {
        expect(multiple.selectAll('.appended-${i}').length, equals(0));
      }
      multiple.appendWithCallback((d, i, e) {
        Element newItem = new Element.tag('div')
                        ..className = 'appended-${i}';
        return newItem;
      });
      for (var i = 0; i < multiple.length; i++) {
        expect(multiple.selectAll('.appended-${i}').length, equals(1));
      }
    });

    test('insert inserts new child elements to selection', () {
      expect(multiple.selectAll('.appended').length, equals(0));
      multiple.insert('div', before: '.appended')..classed('appended');
      expect(multiple.selectAll('.appended').length, equals(multiple.length));
      multiple.insert('div', before: '.appended')..classed('appended');
      expect(multiple.selectAll('.appended').length,
          equals(multiple.length * 2));
    });

    test('insertWithCallback inserts new child elements '
         'to selection with callback', () {
      for (var i = 0; i < multiple.length; i++) {
        expect(multiple.selectAll('.appended-${i}').length, equals(0));
      }
      multiple.insertWithCallback((d, i, e) {
        Element newItem = new Element.tag('div')
                        ..className = 'appended-${i}';
        return newItem;
      }, beforeFn: (d, i, e) => multiple.selectAll('.appended-${i}').first);
      for (var i = 0; i < multiple.length; i++) {
        expect(multiple.selectAll('.appended-${i}').length, equals(1));
      }
    });

    test('remove removes selected elements', () {
      Selection remove = scope.selectAll('.charted-scope-leaf');
      expect(remove.length, equals(2));
      remove.remove();
      remove = scope.selectAll('.charted-scope-leaf');
      expect(remove.length, equals(0));
    });

    test('each visits each selected element in order', () {
      multiple.attrWithCallback('height', (d, i, e) => i * 10);
      int count = 0;
      multiple.each((d, i, e) {
        expect(e.attributes['height'], equals('${i * 10}'));
        count++;
      });
      expect(count, equals(multiple.length));
    });

    test('data binds data to selected elements', () {
      List dataList = [1, 2];
      multiple.data(dataList);
      multiple.each((d, i, e) => expect(d, dataList[i]));
    });

    test('dataWithCallback binds data to elements with callback', () {
      List dataList = [1, 2];
      multiple.dataWithCallback((d, i, e) => dataList);
      multiple.each((d, i, e) => expect(d, dataList[i]));
    });
  });
}
