/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.core;

/**
 * Basic namespace handing for Charted - includes utilities to
 * parse the namespace prefixes and to create DOM elements using a
 * namespace.
 */
class Namespace {
  /** Support namespace prefixes mapped to their URIs. */
  static const Map<String,String> NS_PREFIXES = const {
    "svg": "http://www.w3.org/2000/svg",
    "xhtml": "http://www.w3.org/1999/xhtml",
    "xlink": "http://www.w3.org/1999/xlink",
    "xml": "http://www.w3.org/XML/1998/namespace",
    "xmlns": "http://www.w3.org/2000/xmlns/"
  };

  /**
   * Create an element from [tag]. If tag is prefixed with a
   * supported namespace prefix, the created element will
   * have the namespaceUri set to the correct URI.
   */
  static Element createChildElement(String tag, Element parent) {
    Namespace parsed = new Namespace(tag);
    return parsed.namespaceUri == null ?
        parent.ownerDocument.createElementNS(parent.namespaceUri, tag) :
        parent.ownerDocument.createElementNS(parsed.namespaceUri,
            parsed.localName);
  }

  String localName;
  String namespaceUri;

  /**
   * Parses a tag for namespace prefix and local name.
   * If a known namespace prefix is found, sets the namespaceUri property
   * to the URI of the namespace.
   */
  Namespace(String tagName) {
    int separatorIdx = tagName.indexOf(':');
    String prefix = tagName;
    if (separatorIdx >= 0) {
      prefix = tagName.substring(0, separatorIdx);
      localName = tagName.substring(separatorIdx + 1);
    }

    if (NS_PREFIXES.containsKey(prefix)) {
      namespaceUri = NS_PREFIXES[prefix];
    } else {
      localName = tagName;
    }
  }
}
