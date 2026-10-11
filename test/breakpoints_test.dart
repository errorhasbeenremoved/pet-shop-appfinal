import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_shop_app/core/breakpoints.dart';

void main() {
  test('grid adapts to phone, tablet and desktop widths', () {
    expect(gridColumnsForWidth(360), 1);
    expect(gridColumnsForWidth(768), 2);
    expect(gridColumnsForWidth(1280), 4);
    expect(gridColumnsForWidth(1920), 4);
  });

  for (final width in [360.0, 768.0, 1280.0, 1920.0]) {
    testWidgets('breakpoint is resolved at $width px', (tester) async {
      late ScreenSize size;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 900)),
          child: Builder(builder: (context) {
            size = screenSizeOf(context);
            return const SizedBox.shrink();
          }),
        ),
      ));
      expect(
          size,
          width < 600
              ? ScreenSize.compact
              : width < 1200
                  ? ScreenSize.medium
                  : ScreenSize.expanded);
    });
  }
}
