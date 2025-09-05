import 'package:flutter/widgets.dart';

class ErrorRange {
  final int start;
  final int end;

  /// стиль подчёркивания
  final TextStyle style;

  ErrorRange(
      this.start,
      this.end, {
        TextStyle? style,
      }) : style = style ??
      const TextStyle(
        decoration: TextDecoration.underline,
        decorationColor: Color(0xFFFF0000),
        decorationStyle: TextDecorationStyle.wavy,
      );
}
