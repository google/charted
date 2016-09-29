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
class DefaultChartStateImpl extends Observable implements ChartState {
  final bool isMultiSelect;
  final bool isMultiHighlight;
  final bool isSelectOrHighlight;
  final bool supportColumnSelection;
  final bool supportColumnPreview;
  final bool supportValueHighlight;
  final bool supportValueHover;

  LinkedHashSet<int> hidden = new LinkedHashSet<int>();

  LinkedHashSet<int> selection = new LinkedHashSet<int>();
  LinkedHashSet<Pair<int, int>> highlights = new LinkedHashSet<Pair<int, int>>();

  Pair<int, int> _hovered;
  int _preview;

  DefaultChartStateImpl(
      {this.supportColumnSelection: true,
      this.supportColumnPreview: true,
      this.supportValueHighlight: true,
      this.supportValueHover: true,
      this.isMultiSelect: false,
      this.isMultiHighlight: false,
      this.isSelectOrHighlight: true});

  set hovered(Pair<int, int> value) {
    if (!this.supportValueHover) return null;
    if (value != _hovered) {
      _hovered = value;
      notifyChange(new ChartHoverChangeRecord(_hovered));
    }
  }

  Pair<int, int> get hovered => _hovered;

  set preview(int value) {
    if (!this.supportColumnPreview) return null;
    if (value != _preview) {
      _preview = value;
      notifyChange(new ChartPreviewChangeRecord(_preview));
    }
  }

  int get preview => _preview;

  bool unhide(int id) {
    if (hidden.contains(id)) {
      hidden.remove(id);
      notifyChange(new ChartVisibilityChangeRecord(unhide: id));
    }
    return true;
  }

  bool hide(int id) {
    if (!hidden.contains(id)) {
      hidden.add(id);
      notifyChange(new ChartVisibilityChangeRecord(hide: id));
    }
    return false;
  }

  bool isVisible(int id) => !hidden.contains(id);

  bool select(int id) {
    if (!this.supportColumnSelection) return false;
    if (!selection.contains(id)) {
      if (!isMultiSelect) {
        selection.clear();
      }
      if (isSelectOrHighlight) {
        highlights.clear();
      }
      selection.add(id);
      notifyChange(new ChartSelectionChangeRecord(add: id));
    }
    return true;
  }

  bool unselect(int id) {
    if (selection.contains(id)) {
      selection.remove(id);
      notifyChange(new ChartSelectionChangeRecord(remove: id));
    }
    return false;
  }

  bool isSelected(int id) => selection.contains(id);

  bool highlight(int column, int row) {
    if (!this.supportValueHighlight) return false;
    if (!isHighlighted(column, row)) {
      if (!isMultiHighlight) {
        highlights.clear();
      }
      if (isSelectOrHighlight) {
        selection.clear();
      }
      var item = new Pair<int, int>(column, row);
      highlights.add(item);
      notifyChange(new ChartHighlightChangeRecord(add: item));
    }
    return true;
  }

  bool unhighlight(int column, int row) {
    if (isHighlighted(column, row)) {
      var item = new Pair<int, int>(column, row);
      highlights.remove(item);
      notifyChange(new ChartHighlightChangeRecord(remove: item));
    }
    return false;
  }

  bool isHighlighted(int column, int row) =>
      highlights.any((x) => x.first == column && x.last == row);
}
