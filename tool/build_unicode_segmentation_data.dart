//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

library charted.tool.build_unicode_segmentation_data;

import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:charted/core/text_metrics/segmentation_utils.dart';

/// Unicode version
/// A new version of unicode is available every June.
const VERSION = '7.0.0';

/// URI for downloading the grapheme properties file.
const UCD_PROPERTIES_URL =
    'http://www.unicode.org/Public/${VERSION}/ucd/auxiliary/GraphemeBreakProperty.txt';

const LIBRARY_NAME = 'charted.core.text_metrics.segmentation_data';

/// License header for the generated file.
const HEADER = """
//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//
// This is a generated file.
// Please use tool/build_unicode_segmentation-data.dart to update
//

/// Code ranges by their types for use with grapheme segmentation
/// of text in charts.
library $LIBRARY_NAME;

import "package:charted/core/text_metrics/segmentation_utils.dart";

""";

Future<String> _getPropertiesFile() => http.read(UCD_PROPERTIES_URL);

void _dumpPropertiesData(String data) {
  StringBuffer buffer = new StringBuffer();
  RegExp lineRegExp =
      new RegExp(r'([0-9A-F]{4})..([0-9A-F]{4})?\s+;\s([a-zA-Z]+)\s');

  buffer.write(HEADER);
  buffer.writeln('const CODE_POINT_BLOCKS = const[');

  List<List> items = [];
  data.split('\n').forEach((String line) {
    Match match = lineRegExp.matchAsPrefix(line);
    if (match == null) return;

    int start = int.parse(match.group(1), radix:16);
    int end =
        match.group(2) == null ? start : int.parse(match.group(2), radix:16);

    items.add([start, end, CodeUnitCategory[match.group(3)]]);
    items.sort((a, b) => a.first.compareTo(b.first));
  });

  buffer.write(items.map((List range) => range.join(', ')).join(',\n  '));
  buffer.writeln();
  buffer.writeln('];');
  print(buffer.toString());
}

main() {
  _getPropertiesFile().then((data) => _dumpPropertiesData(data));
}
