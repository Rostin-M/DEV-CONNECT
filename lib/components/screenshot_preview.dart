import 'dart:io';
import 'package:flutter/material.dart';

class ScreenshotData {
  File imageFile;
  String caption;
  ScreenshotData({required this.imageFile, this.caption = ''});
}

class ScreenshotPreview extends StatelessWidget {
  final List<ScreenshotData> screenshots;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onEditCaption;

  const ScreenshotPreview({
    super.key,
    required this.screenshots,
    required this.onRemove,
    required this.onEditCaption,
  });

  @override
  Widget build(BuildContext context) {
    if (screenshots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: screenshots.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.file(
                      data.imageFile,
                      fit: BoxFit.cover,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded || frame != null) {
                              return child;
                            }
                            return Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.5),
                                ),
                              ),
                            );
                          },
                    ),
                  ),

                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () => onRemove(index),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      data.caption.isNotEmpty
                          ? data.caption
                          : 'Sin descripción',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: data.caption.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: data.caption.isEmpty
                            ? Theme.of(context).hintColor
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => onEditCaption(index),
                    child: Icon(
                      Icons.edit,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const Divider(height: 30, thickness: 1),
            ],
          ),
        );
      }).toList(),
    );
  }
}
