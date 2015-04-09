/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.core;

testNamespace() {
  test('Namespace should parse known namespace prefixes', () {
    List namespaces = [
        {'prefix':'svg', 'tag':'g', 'uri':'http://www.w3.org/2000/svg' },
        {'prefix':'xhtml', 'tag':'div', 'uri':'http://www.w3.org/1999/xhtml'}
    ];
    List namespacesWithoutTag = [
        {'prefix':'xlink', 'uri':'http://www.w3.org/1999/xlink' },
        {'prefix':'xml', 'uri':'http://www.w3.org/XML/1998/namespace'},
        {'prefix':'xmlns', 'uri':'http://www.w3.org/2000/xmlns/'}
    ];

    namespaces.forEach((var item) {
      var prefixedTag = '${item['prefix']}:${item['tag']}',
          ns = new Namespace(prefixedTag);
      expect(ns.namespaceUri, equals(item['uri']));
      expect(ns.localName, equals(item['tag']));
    });

    namespacesWithoutTag.forEach((var item) {
      var prefixedTag = '${item['prefix']}',
          ns = new Namespace(prefixedTag);
      expect(ns.namespaceUri, equals(item['uri']));
    });
  });

  test('When namespace is not specified, only localName is set', () {
    var ns = new Namespace('div');
    expect(ns.namespaceUri, isNull);
    expect(ns.localName, equals('div'));
  });

  group('Namespace::createChildElement()', () {
    test('should create elements with '
        'parent\'s namespace when mentioned tag does not have prefix', () {
      Element parent = new Element.tag('div'),
          parent2 = document.createElementNS(
              'http://www.w3.org/2000/svg', 'div'),
          child = Namespace.createChildElement('div', parent),
          child2 = Namespace.createChildElement('div', parent2);

      expect(parent.namespaceUri, equals(child.namespaceUri));
      expect(parent2.namespaceUri, equals(child2.namespaceUri));
    });

    test('should use the right namespace Uri '
        'when tag is prefixed with common namespace prefixes', () {
      Element parent = new Element.tag('div'),
          child = Namespace.createChildElement('xhtml:div', parent),
          child2 = Namespace.createChildElement('svg:div', parent);
      expect(child.namespaceUri, equals('http://www.w3.org/1999/xhtml'));
      expect(child2.namespaceUri, equals('http://www.w3.org/2000/svg'));
    });
  });
}
