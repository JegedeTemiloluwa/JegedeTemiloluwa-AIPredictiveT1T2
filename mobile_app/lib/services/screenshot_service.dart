import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

class ScreenshotService {
  /// Captures the widget subtree wrapped in a RepaintBoundary using its GlobalKey.
  static Future<Uint8List?> capture(GlobalKey key) async {
    try {
      final RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        debugPrint("ScreenshotService: Could not find RenderRepaintBoundary.");
        return null;
      }
      
      // Capture image with 3.0 pixel ratio for high definition
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        debugPrint("ScreenshotService: ByteData is null.");
        return null;
      }
      
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint("ScreenshotService Capture Error: $e");
      return null;
    }
  }

  /// Resolves the save path and writes the image bytes to a PNG file.
  /// On Android, it attempts to save to the public Downloads folder.
  /// Otherwise, it saves in the standard Application Documents directory.
  static Future<File?> saveScreenshot(Uint8List bytes, String prefix) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${prefix}_$timestamp.png';
      
      String? targetDirPath;
      
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          // On Android, save directly to the public Downloads folder for user accessibility
          final publicDownloadDir = Directory('/storage/emulated/0/Download');
          if (await publicDownloadDir.exists()) {
            targetDirPath = publicDownloadDir.path;
          } else {
            // Fallback to external storage
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              targetDirPath = externalDir.path;
            }
          }
        }
      }
      
      // Fallback for desktop, iOS, or other platforms: application documents folder
      if (targetDirPath == null) {
        final appDocDir = await getApplicationDocumentsDirectory();
        targetDirPath = appDocDir.path;
      }
      
      final filePath = '$targetDirPath/$filename';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      debugPrint("ScreenshotService: Saved successfully to $filePath");
      return file;
    } catch (e) {
      debugPrint("ScreenshotService Save Error: $e");
      // Double fallback to temporary directory in case of permission issues
      try {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = '${tempDir.path}/${prefix}_$timestamp.png';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        debugPrint("ScreenshotService: Saved successfully to fallback temp path: $filePath");
        return file;
      } catch (innerError) {
        debugPrint("ScreenshotService Double Fallback Save Error: $innerError");
        return null;
      }
    }
  }
}
