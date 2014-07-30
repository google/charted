/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.selection;

testSelectionScope() {
  String markup = '<div class="charted-scope-root">'
             '<div class="charted-scope-inner">'
               '<div class="charted-scope-leaf"></div>'
               '<div class="charted-scope-leaf"></div>'
             '</div>'
          '</div>';
  Element root, inner;
  SelectionScope scope1, scope2, scope3;

  _setup() {
    root = new Element.html(markup);
    inner = root.querySelector('.charted-scope-inner');

    document.documentElement.append(root);

    scope1 = new SelectionScope.selector('.charted-scope-root');
    scope2 = new SelectionScope.element(root);
    scope3 = new SelectionScope();
  };

  _teardown() {
    root.remove();
  }

  group('Creating SelectionScope', () {
    setUp(_setup);
    tearDown(_teardown);

    test('by selector and element should have the same root', () {
      expect(scope1.root, equals(scope2.root));
    });

    test('should use documentElement as root when nothing is specified', () {
      expect(scope3.root, equals(document.documentElement));
    });
  });

  group('SelectionScope.associate', () {
    setUp(_setup);
    tearDown(_teardown);

    test('should associate data to an element', () {
      scope1.associate(inner, 10);
      expect(scope1.datum(inner), equals(10));
    });

    test('should store the associations on scope', () {
      scope1.associate(inner, 10);
      scope2.associate(inner, 20);
      expect(scope1.datum(inner), equals(10));
      expect(scope2.datum(inner), equals(20));
    });
  });

  group('SelectionScope.select', () {
    setUp(_setup);
    tearDown(_teardown);

    test('must create a selection containing atmost one element', () {
      var selection1 = scope1.select('.charted-scope-inner'),
          selection2 = scope1.select('.charted-scope-leaf');
      expect(selection1.length, equals(1));
      expect(selection2.length, equals(1));
    });

    test('must create a empty selection when nothing matches', () {
      var selection = scope1.select('.charted-scope-invalid');
      expect(selection.length, equals(0));
    });
  });

  group('SelectionScope.selectAll', () {
    setUp(_setup);
    tearDown(_teardown);

    test('must create a selection containing all matching elements', () {
      var selection1 = scope1.selectAll('.charted-scope-inner'),
          selection2 = scope1.selectAll('.charted-scope-leaf'),
          selection3 = scope1.selectAll('.charted-scope-invalid');

      expect(selection1.length, equals(1));
      expect(selection1.first.className, equals('charted-scope-inner'));
      expect(selection2.length, equals(2));
      expect(selection2.first.className, equals('charted-scope-leaf'));
      expect(selection3.length, equals(0));
    });
  });

  group('SelectionScope.selectElements', () {
    setUp(_setup);
    tearDown(_teardown);

    test('must create a selection containing passed elements', () {
      var elements = scope1.root.querySelectorAll('.charted-scope-leaf'),
          selection = scope1.selectElements(elements.toList());
      expect(selection.length, equals(elements.toList().length));

      var selected = [];
      selection.each((d,i,e) => selected.add(e));
      expect(selected, unorderedEquals(elements.toList()));
    });
  });

  group('SelectionScope.append', () {
    setUp(_setup);
    tearDown(_teardown);

    test('must append and element and create a selection', () {
      var selection1 = scope1.append('charted-test-dummy');
      expect(selection1.length, equals(1));
      expect(selection1.first.tagName,
          equalsIgnoringCase('charted-test-dummy'));
      expect(scope1.root.querySelector('charted-test-dummy'),
          isNot(equals(null)));
    });
  });
}
