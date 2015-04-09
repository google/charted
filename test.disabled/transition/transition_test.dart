/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

library charted.test.transition;

import 'dart:async';
import 'dart:html' show document, Element;
import 'package:charted/core/utils.dart';
import 'package:charted/interpolators/interpolators.dart';
import 'package:charted/selection/selection.dart';
import 'package:charted/selection/transition.dart';
import 'package:unittest/unittest.dart';

transitionTests() {
  const TIME_BIAS = 50;
  String markup =
      '<div class="transition-container">'
        '<div class="delay-100"></div>'
        '<div class="delay-500"></div>'
        '<div class="delay-callback"></div>'
        '<div class="delay-callback"></div>'
        '<div class="delay-callback"></div>'
        '<div class="duration-100"></div>'
        '<div class="duration-callback"></div>'
        '<div class="duration-callback"></div>'
        '<div class="duration-callback"></div>'
        '<div class="attr-100"></div>'
        '<div class="attr-callback"></div>'
        '<div class="attr-callback"></div>'
        '<div class="attr-callback"></div>'
        '<div class="style-callback"></div>'
        '<div class="style-callback"></div>'
        '<div class="style-callback"></div>'
        '<div class="attr-tween"></div>'
        '<div class="attr-tween"></div>'
        '<div class="attr-tween"></div>'
        '<div class="style-tween"></div>'
        '<div class="style-tween"></div>'
        '<div class="style-tween"></div>'
        '<div class="chained-transition"></div>'
        '<div class="transition-select">'
          '<div class="select-item"></div>'
        '</div>'
        '<div class="transition-select-all">'
          '<div class="select-item"></div>'
          '<div class="select-item"></div>'
          '<div class="select-item"></div>'
        '</div>'
      '</div>';

  Element root;
  SelectionScope scope;

  setup() {
    root = new Element.html(markup);
    document.documentElement.append(root);
    scope = new SelectionScope.selector('.transition-container');
  }

  teardown() {
    root.remove();
  }

  setUp(setup);
  tearDown(teardown);

  void checkColor(e, color, [bool equal = true]) {
    if (color == null) {
      expect(e.attributes['style'], isNull);
    } else if (equal) {
      expect(e.attributes['style'], equals('background-color: ${color};'));
    } else {
      expect(e.attributes['style']
        .compareTo('background-color: ${color};') == 0, isFalse);
    }
  }

  void checkHeight(e, height, [bool equal = true]) {
    if (height == null) {
      expect(e.attributes['height'], isNull);
    } else if (equal) {
      expect(e.attributes['height'], equals('${height}'));
    } else {
      expect(e.attributes['height'].compareTo('${height}') == 0, isFalse);
    }
  }

  test('Transition.delay delays specific time before transition', () {
    Selection transition1 = scope.select('.delay-100');
    transition1.transition()
      ..style('background-color', '#ffffff')
      ..delay(100);
    new Timer(new Duration(milliseconds:100 - TIME_BIAS), expectAsync(() {
      transition1.each((d, i, Element e) {
        checkColor(e, null);
      });
    }));
    new Timer(new Duration(milliseconds:100 + TIME_BIAS), expectAsync(() {
      transition1.each((d, i, Element e) {
        checkColor(e, 'rgb(255, 255, 255)');
      });
    }));
    Selection transition2 = scope.select('.delay-500');
    transition2.transition()
      ..style('background-color', '#ffffff')
      ..delay(500);
    new Timer(new Duration(milliseconds:500 - TIME_BIAS), expectAsync(() {
      transition2.each((d, i, Element e) {
        checkColor(e, null);
      });
    }));
    new Timer(new Duration(milliseconds:500 + TIME_BIAS), expectAsync(() {
      transition2.each((d, i, Element e) {
        checkColor(e, 'rgb(255, 255, 255)');
      });
    }));
  });

  test('Transition.delayWithCallback delays specific time by callback', () {
    Selection transition = scope.selectAll('.delay-callback');
    transition.transition()
      ..style('background-color', '#ffffff')
      ..delayWithCallback((d, i, e) => (i + 1) * 100);
    new Timer(new Duration(milliseconds:100 - TIME_BIAS), expectAsync(() {
      transition.each((d, i, Element e) {
        checkColor(e, null);
      });
    }));
    new Timer(new Duration(milliseconds:100 + TIME_BIAS), expectAsync(() {
      transition.each((d, i, Element e) {
        if (i > 0) checkColor(e, null);
        else checkColor(e, 'rgb(255, 255, 255)');
      });
    }));
    new Timer(new Duration(milliseconds:200 + TIME_BIAS), expectAsync(() {
      transition.each((d, i, Element e) {
        if (i > 1) checkColor(e, null);
        else checkColor(e, 'rgb(255, 255, 255)');
      });
    }));
    new Timer(new Duration(milliseconds:300 + TIME_BIAS), expectAsync(() {
      transition.each((d, i, Element e) {
        checkColor(e, 'rgb(255, 255, 255)');
      });
    }));
  });

  test('Transition.duration sets the duration of transition', () {
    Selection transition = scope.select('.duration-100');
    transition
      .style('background-color', '#000000');
    transition.transition()
      ..style('background-color', '#ffffff')
      ..duration(100);
    transition.each((d, i, Element e) {
      checkColor(e, 'rgb(0, 0, 0)');
    });
    new Timer(new Duration(milliseconds:50), expectAsync(() {
      transition.each((d, i, Element e) {
        checkColor(e, 'rgb(0, 0, 0)', false);
        checkColor(e, 'rgb(255, 255, 255)', false);
      });
    }));
    new Timer(new Duration(milliseconds:100 + TIME_BIAS), expectAsync(() {
      transition.each((d, i, Element e) {
        checkColor(e, 'rgb(255, 255, 255)');
      });
    }));
  });

  test('Transition.durationWithCallback sets duration by callback', () {
    Selection transition = scope.selectAll('.duration-callback');
    transition
      .style('background-color', '#000000');
    transition.transition()
      ..style('background-color', '#ffffff')
      ..durationWithCallback((d, i, e) => (i + 1) * 100);
    transition.each((d, i, Element e) {
      checkColor(e, 'rgb(0, 0, 0)');
    });
    new Timer(new Duration(milliseconds:100 - TIME_BIAS), expectAsync(() {
      transition.each((d, i, Element e) {
        checkColor(e, 'rgb(0, 0, 0)', false);
        checkColor(e, 'rgb(255, 255, 255)', false);
      });
    }));
    new Timer(new Duration(milliseconds:100 + TIME_BIAS), expectAsync(() {
      transition.each((d, i, Element e) {
        if (i < 1) {
          checkColor(e, 'rgb(255, 255, 255)');
        } else {
          checkColor(e, 'rgb(0, 0, 0)', false);
          checkColor(e, 'rgb(255, 255, 255)', false);
        }
      });
    }));
    new Timer(new Duration(milliseconds:200 + TIME_BIAS), expectAsync(() {
      transition.each((d, i, Element e) {
        if (i < 2) {
          checkColor(e, 'rgb(255, 255, 255)');
        } else {
          checkColor(e, 'rgb(0, 0, 0)', false);
          checkColor(e, 'rgb(255, 255, 255)', false);
        }
      });
    }));
    new Timer(new Duration(milliseconds:300 + TIME_BIAS), expectAsync(() {
      transition.each((d, i, Element e) {
        checkColor(e, 'rgb(255, 255, 255)');
      });
    }));
  });

  test('Transition.attr sets the attribute of transition', () {
    Selection transition = scope.select('.attr-100');
    transition.attr('height', '0');
    transition.transition()
      ..attr('height', '100')
      ..duration(100);
    transition.each((d, i, Element e) {
      checkHeight(e, 0);
    });
    new Timer(new Duration(milliseconds:50), expectAsync(() {
      transition.each((d, i, Element e) {
        checkHeight(e, 0, false);
        checkHeight(e, 100, false);
      });
    }));
    new Timer(new Duration(milliseconds:100 + TIME_BIAS), expectAsync(() {
      transition.each((d, i, Element e) {
        checkHeight(e, 100);
      });
    }));
  });

  test('Transition.attrWithCallback sets the attribute by callback', () {
    Selection transition = scope.selectAll('.attr-callback');
    transition.attr('height', '0');
    transition.transition()
      ..attrWithCallback('height', (d, i, e) => (i + 1) * 100)
      ..duration(100);
    transition.each((d, i, Element e) {
      checkHeight(e, 0);
    });
    new Timer(new Duration(milliseconds:50), expectAsync(() {
      transition.each((d, i, Element e) {
        checkHeight(e, 0, false);
        checkHeight(e, (i + 1) * 100, false);
      });
    }));
    new Timer(new Duration(milliseconds:100 + TIME_BIAS), expectAsync(() {
      transition.each((d, i, Element e) {
        checkHeight(e, (i + 1) * 100);
      });
    }));
  });

  test('Transition.styleWithCallback sets the style by callback', () {
    Selection transition = scope.selectAll('.style-callback');
    transition.style('background-color', 'rgb(0, 0, 0)');
    var colors = ['rgb(255, 0, 0);', 'rgb(0, 255, 0);', 'rgb(0, 0, 255);'];
    transition.transition()
      ..styleWithCallback('background-color', (d, i, e) => colors[i])
      ..duration(100);
    transition.each((d, i, Element e) {
      checkColor(e, 'rgb(0, 0, 0)');
    });
    new Timer(new Duration(milliseconds:50), expectAsync(() {
      transition.each((d, i, Element e) {
        checkColor(e, 'rgb(0, 0, 0)', false);
        checkColor(e, colors[i], false);
      });
    }));
    new Timer(new Duration(milliseconds:100 + TIME_BIAS), expectAsync(() {
      transition.each((d, i, Element e) {
        checkColor(e, colors[i], false);
      });
    }));
  });

  test('Transition.attrTween transitions the value of the attribute with '
       'the specified name according to the specified tween function', () {
    Selection transition = scope.selectAll('.attr-tween');
    transition.attr('height', '0px');
    transition.transition()
      ..attrTween('height', (d, i, attr) =>
          interpolateString(attr, ((i + 1) * 100).toString() + 'px'))
      ..duration(100);
    transition.each((d, i, Element e) {
      checkHeight(e, '0px');
    });
    new Timer(new Duration(milliseconds:50), expectAsync(() {
      transition.each((d, i, Element e) {
        checkHeight(e, '0px', false);
        checkHeight(e, '${(i + 1) * 100}.0px', false);
      });
    }));
    new Timer(new Duration(milliseconds:100 + TIME_BIAS), expectAsync(() {
      transition.each((d, i, Element e) {
        checkHeight(e, '${(i + 1) * 100}.0px');
      });
    }));
  });

  test('Transition.styleTween transitions the value of the CSS style property '
       'with the specified name according to the specified tween function', () {
    Selection transition = scope.selectAll('.style-tween');
    transition.style('background-color', 'rgb(0, 0, 0)');
    var colors = ['rgb(255, 0, 0);', 'rgb(0, 255, 0);', 'rgb(0, 0, 255);'];
    transition.transition()
      ..styleTween('background-color', (d, i, style) =>
          interpolateString(style, colors[i]))
      ..duration(100);
    transition.each((d, i, Element e) {
      checkColor(e, 'rgb(0, 0, 0)');
    });
    new Timer(new Duration(milliseconds:50), expectAsync(() {
      transition.each((d, i, Element e) {
        checkColor(e, 'rgb(0, 0, 0)', false);
        checkColor(e, colors[i], false);
      });
    }));
    new Timer(new Duration(milliseconds:100 + TIME_BIAS), expectAsync(() {
      transition.each((d, i, Element e) {
        checkColor(e, colors[i], false);
      });
    }));
  });

  test('Transition.transition implements chained transition', () {
    Selection transition = scope.select('.chained-transition');
    transition.attr('height', '0');
    Transition t = transition.transition();
    t..duration(500)
     ..attr('height', '10000');
    var t2 = t.transition();
    t2.attr('height', '1000');

    new Timer(new Duration(milliseconds:200), expectAsync(() {
      transition.each((d, i, Element e) {
        var height = num.parse(e.attributes['height']);
        expect(height > 0, isTrue);
        expect(height < 7500, isTrue);
      });
    }));
    new Timer(new Duration(milliseconds:500), expectAsync(() {
      transition.each((d, i, Element e) {
        var height = num.parse(e.attributes['height']);
        expect(height > 7500, isTrue);
      });
    }));

    new Timer(new Duration(milliseconds:1000 + TIME_BIAS), expectAsync(() {
      transition.each((d, i, Element e) {
        var height = num.parse(e.attributes['height']);
        expect(height == 1000, isTrue);
      });
    }));
  });

  test('Transition.select selects the first descendant element '
       'that matches the specified selector string', () {
    Selection transition = scope.select('.transition-select');
    transition.select('.select-item')
      ..attr('height', '100');
    transition.select('.select-item').each((d, i, Element e) {
      var height = num.parse(e.attributes['height']);
      expect(height, equals(100));
    });
  });

  test('Transition.selectAll selects all descendant elements '
       'that match the specified selector string', () {
    Selection transition = scope.select('.transition-select-all');
    transition.selectAll('.select-item')
      ..attr('height', '100');
    transition.selectAll('.select-item').each((d, i, Element e) {
      var height = num.parse(e.attributes['height']);
      expect(height, equals(100));
    });
  });
}
