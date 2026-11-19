import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';

/// Audit automatique des contrastes de l'écran affiché.
///
/// Pour chaque texte visible, la couleur effective du texte est comparée au
/// fond réellement peint dessous (Material, ColoredBox, décorations, Ink,
/// Scaffold ; couches translucides fusionnées). Un dégradé compte par sa
/// teinte la moins favorable. Seuils WCAG AA : 4,5:1, ou 3:1 pour les grands
/// textes (24 px, ou 18,66 px en gras).
///
/// Les textes posés sur une photo (fond inconnu) ou dans un contrôle
/// désactivé (exemptés par le WCAG) sont ignorés.
List<String> auditContrast(WidgetTester tester) {
  final issues = <String>{};
  for (final element in find.byType(RichText).evaluate()) {
    final render = element.renderObject;
    if (render is! RenderParagraph || !render.hasSize || render.size.isEmpty) {
      continue;
    }
    if (!_visible(element)) continue;
    final backgrounds = _backgrounds(element);
    if (backgrounds == null) continue;
    final rich = element.widget as RichText;
    void visit(InlineSpan span, TextStyle? inherited) {
      final style = inherited == null
          ? span.style
          : inherited.merge(span.style);
      if (span is! TextSpan) return;
      final text = span.text?.trim() ?? '';
      final color = style?.color;
      if (text.isNotEmpty && color != null) {
        final size = style?.fontSize ?? 14;
        final bold = (style?.fontWeight?.value ?? 400) >= 700;
        final large = size >= 24 || (size >= 18.66 && bold);
        final minimum = large ? 3.0 : 4.5;
        for (final background in backgrounds) {
          final ink = Color.alphaBlend(color, background);
          final ratio = contrastRatio(ink, background);
          if (ratio < minimum) {
            issues.add(
              '« ${text.length > 40 ? '${text.substring(0, 40)}…' : text} » '
              '${ratio.toStringAsFixed(2)}:1 '
              '(texte ${_hex(ink)} sur ${_hex(background)})',
            );
          }
        }
      }
      for (final child in span.children ?? const <InlineSpan>[]) {
        visit(child, style);
      }
    }

    visit(rich.text, null);
  }
  return issues.toList()..sort();
}

bool _visible(Element element) {
  var visible = true;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if ((widget is Opacity && widget.opacity < 0.99) ||
        (widget is FadeTransition && widget.opacity.value < 0.99) ||
        widget is Offstage && widget.offstage ||
        (widget is Visibility && !widget.visible)) {
      visible = false;
      return false;
    }
    // Icônes (glyphes de police) : pas du texte au sens du WCAG.
    // Contrôles désactivés : exemptés du critère de contraste.
    if (widget is Icon ||
        (widget is ButtonStyleButton && !widget.enabled) ||
        (widget is ListTile && !widget.enabled) ||
        (widget is TextField && !(widget.enabled ?? true)) ||
        (widget is InputDecorator && !widget.decoration.enabled)) {
      visible = false;
      return false;
    }
    return true;
  });
  return visible;
}

/// Fonds candidats sous le texte, ou `null` si inconnus (photo).
List<Color>? _backgrounds(Element element) {
  final layers = <List<Color>>[];
  var unknown = false;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    List<Color>? colors;
    Decoration? decoration;
    if (widget is Material && widget.type != MaterialType.transparency) {
      colors = [widget.color ?? Theme.of(ancestor).canvasColor];
    } else if (widget is ColoredBox) {
      colors = [widget.color];
    } else if (widget is DecoratedBox &&
        widget.position == DecorationPosition.background) {
      decoration = widget.decoration;
    } else if (widget is Ink) {
      decoration = widget.decoration;
    } else if (widget is Scaffold) {
      colors = [
        widget.backgroundColor ?? Theme.of(ancestor).scaffoldBackgroundColor,
      ];
    } else if (widget is Image || (widget is Stack && _hasImage(ancestor))) {
      // Texte sur une photo : fond inconnu (voile de dégradé non mesurable).
      unknown = true;
      return false;
    }
    if (decoration is BoxDecoration) {
      if (decoration.image != null) {
        unknown = true;
        return false;
      }
      colors = decoration.gradient?.colors ?? [?decoration.color];
    } else if (decoration is ShapeDecoration) {
      colors = decoration.gradient?.colors ?? [?decoration.color];
    }
    if (colors == null || colors.isEmpty) return true;
    final painted = [
      for (final color in colors)
        if (color.a > 0.01) color,
    ];
    if (painted.isEmpty) return true;
    layers.add(painted);
    return !painted.every((color) => color.a >= 0.999);
  });
  if (unknown || layers.isEmpty) return null;
  // Fusion du fond le plus profond vers le texte.
  var result = layers.last;
  for (final layer in layers.reversed.skip(1)) {
    result = [
      for (final top in layer)
        for (final below in result) Color.alphaBlend(top, below),
    ];
  }
  return [
    for (final color in result)
      if (color.a >= 0.999) color,
  ];
}

bool _hasImage(Element root) {
  var found = false;
  void visit(Element element) {
    if (found) return;
    final widget = element.widget;
    if (widget is Image ||
        (widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).image != null)) {
      found = true;
      return;
    }
    element.visitChildren(visit);
  }

  root.visitChildren(visit);
  return found;
}

String _hex(Color color) {
  final rgb = (color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  return '#${rgb.toUpperCase()}';
}
