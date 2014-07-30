/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */
part of charted.time;

abstract class Interval {
  DateTime floor(var date);
  DateTime ceil(var date);
  List range(var t0, var t1, int dt);
}

class TimeInterval extends Interval{
  Function _local;
  Function _step;
  Function _number;

  TimeInterval(this._local, this._step, this._number);

  DateTime floor(var date) {
    if (date is int) date = new DateTime.fromMillisecondsSinceEpoch(date);
    return _local(date);
  }

  DateTime round(var date) {
    if (date is int) date = new DateTime.fromMillisecondsSinceEpoch(date);
    DateTime d0 = _local(date),
             d1 = offset(d0, 1);
    return date.millisecondsSinceEpoch - d0.millisecondsSinceEpoch <
           d1.millisecondsSinceEpoch - date.millisecondsSinceEpoch ? d0 : d1;
  }

  DateTime ceil(var date) {
    if (date is int) date = new DateTime.fromMillisecondsSinceEpoch(date);
    DateTime d0 = _local(date),
             d1 = offset(d0, 1);
    return date.millisecondsSinceEpoch - d0.millisecondsSinceEpoch > 0 ?
           d1 : d0;
  }

  offset(date, num k) {
    date = _step(date, k);
    return date;
  }

  List range(var t0, var t1, int dt) {
    var time = ceil(t0),
        times = [],
        t1SinceEpoch = t1 is DateTime ? t1.millisecondsSinceEpoch : t1,
        timeSinceEpoch = time.millisecondsSinceEpoch;
    if (dt > 1) {
      while (timeSinceEpoch < t1SinceEpoch) {
        if ((_number(time) % dt) == 0) times.add(
            new DateTime.fromMillisecondsSinceEpoch(timeSinceEpoch));
        time = _step(time, 1);
        timeSinceEpoch = time.millisecondsSinceEpoch;
      }
    } else {
      while (timeSinceEpoch < t1SinceEpoch) {
        times.add(new DateTime.fromMillisecondsSinceEpoch(timeSinceEpoch));
        time = _step(time, 1);
        timeSinceEpoch = time.millisecondsSinceEpoch;
      }
    }
    return times;
  }

  // TODO(songrenchu): Implement UTC range
  List rangeUTC(DateTime t0, DateTime t1, int dt) {
    throw new UnimplementedError();
  }
}

// TODO(songrenchu): Implement UTC time interval
class TimeIntervalUTC extends TimeInterval {
  TimeIntervalUTC(local, step, number): super(local, step, number) {
    throw new UnimplementedError();
  }
}