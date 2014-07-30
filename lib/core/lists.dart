/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file or at
 * https://developers.google.com/open-source/licenses/bsd
 */

part of charted.core;

/** Returns a sum of all values in the given list of values */
num sum(List values) =>
    values == null || values.isEmpty ?
        0: values.fold(0.0, (old, next) => old + next);

bool isNullOrEmpty(Iterable val) => val == null || val.isEmpty;
