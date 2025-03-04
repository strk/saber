import 'package:flutter/material.dart';
import 'package:saber/components/canvas/_editor_image.dart';
import 'package:saber/components/canvas/_stroke.dart';
import 'package:saber/components/canvas/canvas_preview.dart';
import 'package:saber/data/editor/editor_core_info.dart';

class EditorPageManager extends StatelessWidget {
  const EditorPageManager({
    super.key,
    required this.coreInfo,
    required this.currentPageIndex,
    required this.redrawAndSave,
  });

  final EditorCoreInfo coreInfo;
  final int? currentPageIndex;
  final VoidCallback redrawAndSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: ReorderableListView.builder(
        shrinkWrap: true,
        itemCount: coreInfo.pages.length,
        itemBuilder: (context, pageIndex) {
          return Padding(
            key: ValueKey(pageIndex),
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  "${pageIndex + 1} / ${coreInfo.pages.length}",
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 150,
                    maxHeight: 250,
                  ),
                  child: CanvasPreview(
                    pageIndex: pageIndex,
                    height: null,
                    coreInfo: coreInfo,
                  ),
                ),
              ],
            ),
          );
        },
        onReorder: (oldIndex, newIndex) {
          if (oldIndex == newIndex) return;
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          coreInfo.pages.insert(newIndex, coreInfo.pages.removeAt(oldIndex));

          // reassign pageIndex of pages' strokes and images
          for (int i = 0; i < coreInfo.pages.length; i++) {
            for (Stroke stroke in coreInfo.pages[i].strokes) {
              stroke.pageIndex = i;
            }
            for (EditorImage image in coreInfo.pages[i].images) {
              image.pageIndex = i;
            }
          }

          redrawAndSave();
        },
      ),
    );
  }
}
