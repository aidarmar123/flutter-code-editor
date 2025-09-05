import 'package:flutter/widgets.dart';
import 'package:highlight/highlight_core.dart';

import '../code/code.dart';
import '../code/text_style.dart';
import '../code_theme/code_theme_data.dart';
import '../highlight/node.dart';
import 'error_range.dart';



class SpanBuilder {
  final Code code;
  final CodeThemeData? theme;
  final TextStyle? rootStyle;

  final List<ErrorRange> errorRanges;

  int _visibleLineIndex = 0;
  int _globalOffset = 0;
  SpanBuilder({
    required this.code,
    required this.theme,
    this.rootStyle,
    this.errorRanges = const []
  });

  TextSpan build() {
    _visibleLineIndex = 0;
    return TextSpan(
      style: rootStyle,
      children: _buildList(
        nodes: code.visibleHighlighted?.nodes ?? [],
        theme: theme,
        ancestorStyle: rootStyle,
      ),
    );
  }

  List<TextSpan>? _buildList({
    required List<Node>? nodes,
    required CodeThemeData? theme,
    TextStyle? ancestorStyle,
  }) {
    if (nodes == null) {
      return null;
    }

    return nodes
        .map(
          (node) => _buildNode(
            node: node,
            theme: theme,
            ancestorStyle: ancestorStyle,
          ),
        )
        .toList(growable: false);
  }

  TextSpan _buildNode({
    required Node node,
    required CodeThemeData? theme,
    TextStyle? ancestorStyle,
  }) {
    final style = theme?.styles[node.className] ?? ancestorStyle;
    final processedStyle = _paleIfRequired(style);

    _updateLineIndex(node);
    final text = node.value ?? '';
    final spans = <TextSpan>[];

    if (text.isNotEmpty) {
      int localStart = 0;
      int localEnd = text.length;

      // Проверяем на попадание в errorRanges
      for (final range in errorRanges) {
        final overlapStart = range.start.clamp(_globalOffset, _globalOffset + text.length);
        final overlapEnd = range.end.clamp(_globalOffset, _globalOffset + text.length);

        if (overlapStart < overlapEnd) {
          // Часть до ошибки
          if (overlapStart > _globalOffset) {
            spans.add(TextSpan(
              text: text.substring(0, overlapStart - _globalOffset),
              style: processedStyle,
            ));
          }
          // Ошибка
          spans.add(TextSpan(
            text: text.substring(overlapStart - _globalOffset, overlapEnd - _globalOffset),
            style: processedStyle?.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFFFF0000),
              decorationStyle: TextDecorationStyle.wavy,
            ),
          ));
          // Часть после
          if (overlapEnd < _globalOffset + text.length) {
            spans.add(TextSpan(
              text: text.substring(overlapEnd - _globalOffset),
              style: processedStyle,
            ));
          }
          _globalOffset += text.length;
          return TextSpan(children: spans);
        }
      }
    }

    _globalOffset += text.length;
    return TextSpan(
      text: node.value,
      children: _buildList(
        nodes: node.children,
        theme: theme,
        ancestorStyle: style,
      ),
      style: processedStyle,
    );
  }

  void _updateLineIndex(Node node) {
    _visibleLineIndex += node.getValueNewlineCount();

    if (_visibleLineIndex >= code.lines.length) {
      _visibleLineIndex = code.lines.length - 1;
    }
  }

  TextStyle? _paleIfRequired(TextStyle? style) {
    if (code.visibleSectionNames.isNotEmpty) {
      return style;
    }

    final fullLineIndex =
        code.hiddenLineRanges.recoverLineIndex(_visibleLineIndex);
    if (code.lines[fullLineIndex].isReadOnly) {
      return style?.paled();
    }
    return style;
  }
}
