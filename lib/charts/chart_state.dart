//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

part of charted.charts;

///
/// Model to provide highlight, selection and visibility in a ChartArea.
/// Selection and visibility
///
abstract class ChartState implements ChangeNotifier {
  static const SELECTED_CLASS = 'item-selected';
  static const UNSELECTED_CLASS = 'item-unselected';
  static const PREVIEW_CLASS = 'item-previewed';
  static const HIDDEN_CLASS = 'item-hidden';

  static const ROW_HIGHLIGHTED_CLASS = 'row-highlighted';
  static const ROW_HOVERED_CLASS = 'row-hovered';

  static const HIGHLIGHTED_CLASS = 'value-highlighted';
  static const HOVERED_CLASS = 'value-hovered';

  static const CLASS_NAMES = const[
    SELECTED_CLASS, UNSELECTED_CLASS, PREVIEW_CLASS, HIDDEN_CLASS,
    ROW_HIGHLIGHTED_CLASS, ROW_HOVERED_CLASS,
    HIGHLIGHTED_CLASS, HOVERED_CLASS ];

  /// List of selected items.
  /// - Contains a column on CartesianArea if useRowColoring is false.
  /// - Row index in all other cases.
  Iterable<int> get selection;

  /// List of visible items.
  /// - Contains a column on CartesianArea if useRowColoring is false.
  /// - Row index in all other cases.
  Iterable<int> get hidden;

  /// Currently highlighted value, if any, represented as column and row.
  /// Highlight is result of a click on certain value.
  Pair<int,int> highlighted;

  /// Currently hovered value, if any, represented as column and row.
  /// Hover is result of mouse moving over a certian value in chart.
  Pair<int,int> hovered;

  /// Currently previewed row or column. Hidden items can be previewed
  /// by hovering on the corresponding label in Legend
  /// - Contains a column on CartesianArea if useRowColoring is false.
  /// - Row index in all other cases.
  int preview;

  /// Ensure that a row or column is visible.
  bool unhide(int id);

  /// Ensure that a row or column is invisible.
  bool hide(int id);

  /// Returns current visibility of a row or column.
  bool isVisible(int id);

  /// Select a row or column.
  bool select(int id);

  /// Unselect a row or column.
  bool unselect(int id);

  /// Returns current selection state of a row or column.
  bool isSelected(int id);

  factory ChartState({bool isMultiSelect: false}) =>
      new _ChartState(isMultiSelect: isMultiSelect);
}

///
/// Implementation of [ChangeRecord], that is used to notify changes to
/// values in [ChartData].
///
class ChartSelectionChangeRecord implements ChangeRecord {
  final int add;
  final int remove;
  const ChartSelectionChangeRecord({this.add, this.remove});
}

///
/// Implementation of [ChangeRecord], that is used to notify changes to
/// values in [ChartData].
///
class ChartVisibilityChangeRecord implements ChangeRecord {
  final int unhide;
  final int hide;
  const ChartVisibilityChangeRecord({this.unhide, this.hide});
}

///
/// Implementation of [ChangeRecord], that is used to notify changes to
/// values in [ChartData].
///
class ChartHighlightChangeRecord implements ChangeRecord {
  final Pair<int,int> highlighted;
  const ChartHighlightChangeRecord(this.highlighted);
}

///
/// Implementation of [ChangeRecord], that is used to notify changes to
/// values in [ChartData].
///
class ChartHoverChangeRecord implements ChangeRecord {
  final Pair<int,int> hovered;
  const ChartHoverChangeRecord(this.hovered);
}

///
/// Implementation of [ChangeRecord], that is used to notify changes to
/// values in [ChartData].
///
class ChartPreviewChangeRecord implements ChangeRecord {
  final int previewed;
  const ChartPreviewChangeRecord(this.previewed);
}
