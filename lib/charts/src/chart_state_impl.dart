//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

///
/// Model that maintains state of each visualization item. Each entry in the
/// legend is considered one visualization item.
/// - In [CartesianArea] it is always a column.
/// - In [LayoutArea] renders choose either columns or rows.
///
class _ChartState extends ChangeNotifier implements ChartState {
  final bool isMultiSelect;

  LinkedHashSet<int> selection = new LinkedHashSet<int>();
  LinkedHashSet<int> hidden = new LinkedHashSet<int>();
  Pair<int,int> _highlighted;
  int _hovered;

  _ChartState({this.isMultiSelect: false}) {}

  set highlighted(Pair<int,int> value) {
    if (value != _highlighted) {
      _highlighted = value;
      notifyChange(new ChartHighlightChangeRecord(_highlighted));
    }
    return value;
  }
  Pair<int,int> get highlighted => _highlighted;

  set preview(int value) {
    if (value != _hovered) {
      _hovered = value;
      notifyChange(new ChartPreviewChangeRecord(_hovered));
    }
    return value;
  }
  int get preview => _hovered;

  bool show(int id) {
    if (hidden.contains(id)) {
      hidden.remove(id);
      notifyChange(new ChartVisibilityChangeRecord(add:id));
    }
    return true;
  }

  bool hide(int id) {
    if (!hidden.contains(id)) {
      hidden.add(id);
      notifyChange(new ChartVisibilityChangeRecord(remove:id));
    }
    return false;
  }

  bool isVisible(int id) => !hidden.contains(id);

  bool select(int id) {
    if (!selection.contains(id)) {
      if (!isMultiSelect) {
        selection.clear();
      }
      selection.add(id);
      notifyChange(new ChartSelectionChangeRecord(add:id));
    }
    return true;
  }

  bool unselect(int id) {
    if (selection.contains(id)) {
      selection.remove(id);
      notifyChange(new ChartSelectionChangeRecord(remove:id));
    }
    return false;
  }

  bool isSelected(int id) => selection.contains(id);
}
