@Tags(['tooling'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asset generator: rasterizes assets/svg/logo_new.svg into every logo PNG
/// the build consumes. Gated behind an env var so normal test runs never
/// rewrite assets. Run explicitly with:
///   RENDER_LOGO=1 flutter test test/tooling/render_app_logo_test.dart
/// then regenerate the derived artifacts:
///   dart run flutter_launcher_icons && dart run flutter_native_splash:create
///
/// Outputs:
/// - app_logo.png            transparent, mark at 66% — splash screens
/// - app_icon.png            opaque cream tile, mark at 58% — legacy Android,
///                           iOS, web, desktop launcher icons
/// - app_icon_foreground.png transparent, mark at 50% — Android adaptive
///                           foreground (safe zone is 66/108 ≈ 61%, so 50%
///                           leaves comfortable margins)
/// - docs/store-assets/icon-512.png  opaque 512px Play Store listing icon
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final enabled = Platform.environment['RENDER_LOGO'] == '1';
  const background = Color(0xFFF0EBE5);

  test(
    'render logo_new.svg into logo/icon PNGs',
    skip: enabled ? false : 'Asset generator — run with RENDER_LOGO=1',
    () async {
      // flutter_svg does not support CSS <style> classes, so inline the
      // fills the stylesheet declares before rendering.
      final svgString = File('assets/svg/logo_new.svg')
          .readAsStringSync()
          .replaceAll('class="cls-0"', 'fill="#FBF9F4"')
          .replaceAll('class="cls-1"', 'fill="#DD8C6A"')
          .replaceAll('class="cls-2"', 'fill="#93A57B"');
      final pictureInfo = await vg.loadPicture(
        SvgStringLoader(svgString),
        null,
      );

      Future<void> render({
        required String path,
        required int size,
        required double contentFraction,
        Color? fill,
      }) async {
        final canvasSize = size.toDouble();
        final svgSize = pictureInfo.size;
        final scale =
            (canvasSize * contentFraction) /
            (svgSize.width > svgSize.height ? svgSize.width : svgSize.height);

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        if (fill != null) {
          canvas.drawRect(
            Rect.fromLTWH(0, 0, canvasSize, canvasSize),
            Paint()..color = fill,
          );
        }
        canvas.translate(
          (canvasSize - svgSize.width * scale) / 2,
          (canvasSize - svgSize.height * scale) / 2,
        );
        canvas.scale(scale);
        canvas.drawPicture(pictureInfo.picture);

        final image = await recorder.endRecording().toImage(size, size);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
        expect(bytes.lengthInBytes, greaterThan(0), reason: path);
      }

      await render(
        path: 'assets/images/app_logo.png',
        size: 2048,
        contentFraction: 0.66,
      );
      await render(
        path: 'assets/images/app_icon.png',
        size: 1024,
        contentFraction: 0.58,
        fill: background,
      );
      await render(
        path: 'assets/images/app_icon_foreground.png',
        size: 1024,
        contentFraction: 0.50,
      );
      await render(
        path: 'docs/store-assets/icon-512.png',
        size: 512,
        contentFraction: 0.58,
        fill: background,
      );

      pictureInfo.picture.dispose();
    },
  );
}
