@Tags(['tooling'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asset generator: rasterizes assets/svg/logo_new.svg onto a square
/// transparent canvas and overwrites assets/images/app_logo.png (consumed by
/// flutter_launcher_icons and flutter_native_splash) plus the Play Store
/// listing icon. Gated behind an env var so normal test runs never rewrite
/// assets. Run explicitly with:
///   RENDER_LOGO=1 flutter test test/tooling/render_app_logo_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final enabled = Platform.environment['RENDER_LOGO'] == '1';

  test(
    'render logo_new.svg to app_logo.png',
    skip: enabled ? false : 'Asset generator — run with RENDER_LOGO=1',
    () async {
      const canvasSize = 2048.0;
      // Keep the mark inside ~66% of the canvas so Android adaptive icons
      // (which crop to a circle) never clip it.
      const contentFraction = 0.66;

      // flutter_svg does not support CSS <style> classes, so inline the fills
      // the stylesheet declares before rendering.
      final svgString = File('assets/svg/logo_new.svg')
          .readAsStringSync()
          .replaceAll('class="cls-0"', 'fill="#FBF9F4"')
          .replaceAll('class="cls-1"', 'fill="#DD8C6A"')
          .replaceAll('class="cls-2"', 'fill="#93A57B"');
      final pictureInfo = await vg.loadPicture(
        SvgStringLoader(svgString),
        null,
      );

      final svgSize = pictureInfo.size;
      final scale =
          (canvasSize * contentFraction) /
          (svgSize.width > svgSize.height ? svgSize.width : svgSize.height);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.translate(
        (canvasSize - svgSize.width * scale) / 2,
        (canvasSize - svgSize.height * scale) / 2,
      );
      canvas.scale(scale);
      canvas.drawPicture(pictureInfo.picture);
      pictureInfo.picture.dispose();

      final image = await recorder.endRecording().toImage(
        canvasSize.toInt(),
        canvasSize.toInt(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        'assets/images/app_logo.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());

      expect(bytes.lengthInBytes, greaterThan(0));

      // Play Store listing icon: 512x512, opaque, on the splash background.
      const storeSize = 512.0;
      final storeRecorder = ui.PictureRecorder();
      final storeCanvas = Canvas(storeRecorder);
      storeCanvas.drawRect(
        const Rect.fromLTWH(0, 0, storeSize, storeSize),
        Paint()..color = const Color(0xFFF0EBE5),
      );
      final storeScale = storeSize / canvasSize;
      storeCanvas.scale(storeScale);
      storeCanvas.drawImage(image, Offset.zero, Paint());
      final storeImage = await storeRecorder.endRecording().toImage(
        storeSize.toInt(),
        storeSize.toInt(),
      );
      final storeBytes = await storeImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      File(
        'docs/store-assets/icon-512.png',
      ).writeAsBytesSync(storeBytes!.buffer.asUint8List());

      expect(storeBytes.lengthInBytes, greaterThan(0));
    },
  );
}
