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

import 'dart:convert';

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
  static Map<String, MaterialColor> _lessonColors = {};
  static bool canSave = true;

  static MaterialColor getColor(String subject) {
    String sanitized = subject.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
    sanitized = sanitized.replaceAll(RegExp(r'^_+|_+$'), '');
    if (sanitized.isEmpty) {
      sanitized = 'unnamed';
    }
    sanitized = '${sanitized.toLowerCase()}cs';
    MaterialColor? color = _lessonColors[sanitized];
    if (color == null) {
      color = colors[_lessonColors.length % colors.length];
      _lessonColors[sanitized] = color;
      if (canSave) {
        canSave = false;
        //Save after a slight delay because this method is often called multiple times in a row
        Future.delayed(const Duration(milliseconds: 200)).then((_) {
          canSave = true;
          save();
        });
      }
    }
    return color;
  }

  static save() async {
    await ConfigProvider.getStorage().write(
      key: 'lessonColors',
      value: jsonEncode(_lessonColors.map((key, value) => MapEntry(key, colors.indexOf(value)))),
    );
  }

  static init(String json) {
    _lessonColors = (jsonDecode(json) as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, colors[value]));
  }
}
