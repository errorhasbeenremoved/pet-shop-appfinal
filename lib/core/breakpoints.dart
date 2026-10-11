import 'package:flutter/material.dart';

enum ScreenSize { compact, medium, expanded }

ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) return ScreenSize.compact;
  if (width < 1200) return ScreenSize.medium;
  return ScreenSize.expanded;
}

T byScreen<T>(BuildContext context,
        {required T compact, T? medium, T? expanded}) =>
    switch (screenSizeOf(context)) {
      ScreenSize.compact => compact,
      ScreenSize.medium => medium ?? compact,
      ScreenSize.expanded => expanded ?? medium ?? compact,
    };

int gridColumnsForWidth(double width) => width < 600
    ? 1
    : width < 1200
        ? 2
        : 4;
