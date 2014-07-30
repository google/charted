/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.test.event;

class MockFlag {
  static const IDLE = 0;
  static const STARTED = 1;
  static const FINISHED = 2;
  int state = IDLE;
}

testTimer() {
  const TIME_BIAS = 50;

  // Set flag property of a MockFlag to true after a time span.
  timeSpan(t, MockFlag mock) => (elapse) {
    if (mock.state == MockFlag.IDLE) mock.state = MockFlag.STARTED;
    if (elapse < t) return false;
    mock.state = MockFlag.FINISHED;
    return true;
  };

  test('ChartTimer starts a custom animation timer after specific delay', () {
    MockFlag mock1 = new MockFlag(),
             mock2 = new MockFlag(),
             mock3 = new MockFlag();
    // Timer with 200 duration of execution.
    new ChartTimer(timeSpan(200, mock1));
    // Timer with 200 duration of execution and 200 delay.
    new ChartTimer(timeSpan(200, mock2), 200);
    // Timer with 200 duration of execution and 200 delay after 200 from now.
    new ChartTimer(timeSpan(200, mock3), 200,
        new DateTime.now().add(new Duration(milliseconds: 200)));
    new Timer(new Duration(milliseconds:200 - TIME_BIAS), expectAsync(() {
      expect(mock1.state, equals(MockFlag.STARTED));
      expect(mock2.state, equals(MockFlag.IDLE));
      expect(mock3.state, equals(MockFlag.IDLE));
    }));
    new Timer(new Duration(milliseconds:200 + TIME_BIAS), expectAsync(() {
      expect(mock1.state, equals(MockFlag.FINISHED));
      expect(mock2.state, equals(MockFlag.STARTED));
      expect(mock3.state, equals(MockFlag.IDLE));
    }));
    new Timer(new Duration(milliseconds:400 + TIME_BIAS), expectAsync(() {
      expect(mock1.state, equals(MockFlag.FINISHED));
      expect(mock2.state, equals(MockFlag.FINISHED));
      expect(mock3.state, equals(MockFlag.STARTED));
    }));
    new Timer(new Duration(milliseconds:600 + TIME_BIAS), expectAsync(() {
      expect(mock1.state, equals(MockFlag.FINISHED));
      expect(mock2.state, equals(MockFlag.FINISHED));
      expect(mock3.state, equals(MockFlag.FINISHED));
    }));
  });
}