import 'package:flutter/material.dart';
import 'package:kosmos_client/global.dart';

class ColorProvider {
  static List<MaterialColor> colors = [
    Colors.pink,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.blue,
    Colors.indigo,
    Colors.deepPurple,
    Colors.red,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.deepOrange,
    Colors.yellow,
    Colors.cyan,
    Colors.lime,
  ];
  static final Map<String, MaterialColor> _lessonColors = {};

  static MaterialColor getColor(String subject) {
    MaterialColor? color = _lessonColors[subject];
    if (color == null) {
      color = colors[_lessonColors.length % colors.length];
      _lessonColors[subject] = color;
      save();
    }
    return color;
  }

  static save() async {
    _lessonColors.forEach((subject, color) {
      Global.storage!.write(key: 'colors.$subject', value: colors.indexOf(color).toString());
    });
  }

  ///Used when loading from shared preferences, therefore save is not called here.
  ///do not use to add a color since it will not be saved. Use getColor.
  static addColor(String subject, int colorID) {
    _lessonColors[subject] = colors[colorID];
  }
}
