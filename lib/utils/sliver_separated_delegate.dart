import 'package:flutter/widgets.dart';
import 'dart:math' as math;

SliverChildBuilderDelegate SliverSeparatedDelegate({
  @required IndexedWidgetBuilder itemBuilder,
  @required IndexedWidgetBuilder separatorBuilder,
  @required int itemCount,
  bool addAutomaticKeepAlives = true,
  bool addRepaintBoundaries = true,
  bool addSemanticIndexes = true,
}) {
  return SliverChildBuilderDelegate(
        (BuildContext context, int index) {
      final int itemIndex = index ~/ 2;
      Widget widget;
      if (index.isEven) {
        widget = itemBuilder(context, itemIndex);
      } else {
        widget = separatorBuilder(context, itemIndex);
        assert(() {
          if (widget == null) {
            throw FlutterError('separatorBuilder cannot return null.');
          }
          return true;
        }());
      }
      return widget;
    },
    childCount: math.max(0, itemCount * 2 - 1),
    addAutomaticKeepAlives: addAutomaticKeepAlives,
    addRepaintBoundaries: addRepaintBoundaries,
    addSemanticIndexes: addSemanticIndexes,
    semanticIndexCallback: (Widget _, int index) {
      return index.isEven ? index ~/ 2 : null;
    },
  );
}