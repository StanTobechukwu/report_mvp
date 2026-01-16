import 'package:flutter/foundation.dart';

enum TitleAlign { left, center, right }
enum HeadingLevel { h1, h2, h3 }

@immutable
class TitleStyle {
  final HeadingLevel level;
  final bool bold;
  final TitleAlign align;

  const TitleStyle({
    this.level = HeadingLevel.h2,
    this.bold = true,
    this.align = TitleAlign.left,
  });

  TitleStyle copyWith({HeadingLevel? level, bool? bold, TitleAlign? align}) {
    return TitleStyle(
      level: level ?? this.level,
      bold: bold ?? this.bold,
      align: align ?? this.align,
    );
  }
}

sealed class Node {
  final String id;
  const Node({required this.id});
}

@immutable
class SectionNode extends Node {
  final String title;
  final bool collapsed;
  final TitleStyle style;
  final List<Node> children;

  const SectionNode({
    required super.id,
    required this.title,
    this.collapsed = false,
    this.style = const TitleStyle(),
    this.children = const [],
  });

  SectionNode copyWith({
    String? title,
    bool? collapsed,
    TitleStyle? style,
    List<Node>? children,
  }) {
    return SectionNode(
      id: id,
      title: title ?? this.title,
      collapsed: collapsed ?? this.collapsed,
      style: style ?? this.style,
      children: children ?? this.children,
    );
  }
}

@immutable
class ContentNode extends Node {
  final String text;
  const ContentNode({required super.id, this.text = ''});

  ContentNode copyWith({String? text}) => ContentNode(id: id, text: text ?? this.text);
}
