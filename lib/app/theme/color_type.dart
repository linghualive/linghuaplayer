import 'package:flutter/material.dart';

class ColorType {
  final String label;
  final Color color;

  const ColorType(this.label, this.color);
}

const List<ColorType> colorThemeTypes = [
  // -- 特殊 --
  ColorType('动态取色', Colors.transparent),

  // -- 粉色系 --
  ColorType('樱花粉', Color(0xFFF8A4B8)),
  ColorType('蜜桃', Color(0xFFFA8072)),
  ColorType('玫瑰', Color(0xFFD4808F)),
  ColorType('珊瑚', Color(0xFFF08080)),
  ColorType('草莓奶昔', Color(0xFFE8879C)),
  ColorType('腮红', Color(0xFFDC8B8B)),

  // -- 紫色系 --
  ColorType('薰衣草', Color(0xFFB39DDB)),
  ColorType('丁香', Color(0xFFC8A2C8)),
  ColorType('紫藤', Color(0xFFA78BCC)),
  ColorType('葡萄冰沙', Color(0xFF9B7DC5)),
  ColorType('香芋', Color(0xFFB8A0D2)),

  // -- 蓝色系 --
  ColorType('天空蓝', Color(0xFF87CEEB)),
  ColorType('雾霾蓝', Color(0xFF8EAEC0)),
  ColorType('婴儿蓝', Color(0xFF89CFF0)),
  ColorType('冰川', Color(0xFF95C8D8)),

  // -- 绿色系 --
  ColorType('薄荷', Color(0xFF98D8C8)),
  ColorType('抹茶', Color(0xFFA8C97F)),
  ColorType('豆沙绿', Color(0xFF8FBC8F)),
  ColorType('牛油果', Color(0xFFB5CC78)),

  // -- 暖色系 --
  ColorType('奶茶', Color(0xFFC9A96E)),
  ColorType('焦糖', Color(0xFFCDA776)),
  ColorType('杏仁', Color(0xFFD4A98C)),
  ColorType('奶油橘', Color(0xFFE8A87C)),
  ColorType('柠檬', Color(0xFFE8D77E)),

  // -- 经典 --
  ColorType('经典红', Color(0xFFE57373)),
  ColorType('经典蓝', Color(0xFF64B5F6)),
  ColorType('经典紫', Color(0xFFAB7DBA)),
  ColorType('经典绿', Color(0xFF81C784)),
];
