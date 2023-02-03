/*
 * This file is part of the Kosmos Client (https://github.com/lolocomotive/kosmos_client)
 *
 * Copyright (C) 2022 lolocomotive
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:kosmos_client/config_provider.dart';

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
    Colors.purple,
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
      ConfigProvider.getStorage()
          .write(key: 'colors.$subject', value: colors.indexOf(color).toString());
    });
  }

  ///Used when loading from shared preferences, therefore save is not called here.
  ///do not use to add a color since it will not be saved. Use getColor.
  static addColor(String subject, int colorID) {
    _lessonColors[subject] = colors[colorID];
  }
}
