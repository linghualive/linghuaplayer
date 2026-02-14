import 'package:flutter/material.dart';

class ColorType {
  final String label;
  final Color color;

  const ColorType(this.label, this.color);
}

const List<ColorType> colorThemeTypes = [
  ColorType('动态取色', Colors.transparent),
  ColorType('默认', Color(0xFFFB7299)),
  ColorType('红色', Color(0xFFF44336)),
  ColorType('粉色', Color(0xFFE91E63)),
  ColorType('紫色', Color(0xFF9C27B0)),
  ColorType('深紫', Color(0xFF673AB7)),
  ColorType('靛蓝', Color(0xFF3F51B5)),
  ColorType('蓝色', Color(0xFF2196F3)),
  ColorType('浅蓝', Color(0xFF03A9F4)),
  ColorType('青色', Color(0xFF00BCD4)),
  ColorType('青绿', Color(0xFF009688)),
  ColorType('绿色', Color(0xFF4CAF50)),
  ColorType('浅绿', Color(0xFF8BC34A)),
  ColorType('黄绿', Color(0xFFCDDC39)),
  ColorType('黄色', Color(0xFFFFEB3B)),
  ColorType('琥珀', Color(0xFFFFC107)),
  ColorType('橙色', Color(0xFFFF9800)),
  ColorType('深橙', Color(0xFFFF5722)),
  ColorType('棕色', Color(0xFF795548)),
  ColorType('蓝灰', Color(0xFF607D8B)),
];
