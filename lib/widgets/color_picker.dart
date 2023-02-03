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

class ColorPicker extends StatefulWidget {
  const ColorPicker({Key? key, required this.onChange, this.color}) : super(key: key);
  final Function(Color? color) onChange;
  final Color? color;

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      child: CircleAvatar(
        backgroundColor: widget.color,
      ),
      onTap: () {
        showDialog(
            builder: (_) => ColorPickerPage(
                  color: widget.color,
                  onChange: (color) {
                    widget.onChange(color);
                  },
                ),
            context: context);
      },
    );
  }
}

class ColorPickerPage extends StatefulWidget {
  const ColorPickerPage({Key? key, required this.onChange, this.color}) : super(key: key);
  final Function(Color? color) onChange;
  final Color? color;
  @override
  State<ColorPickerPage> createState() => ColorPickerPageState();
}

class ColorPickerPageState extends State<ColorPickerPage> {
  static const colors = <Color>[
    Colors.red,
    Colors.deepOrange,
    Colors.orange,
    Colors.amber,
    Colors.pink,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.purple,
    Colors.green,
    Colors.teal,
    Colors.cyan,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
  ];
  bool initialized = false;
  Color? _color;

  _setColor(Color? color) {
    _color = color;
    widget.onChange(color);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      _color = widget.color;
      initialized = true;
    }
    final List<Row> rows = [];
    List<Widget> children = [];
    final size = 50 * MediaQuery.of(context).textScaleFactor;
    for (int i = 0; i < colors.length; i++) {
      children.add(InkWell(
        borderRadius: BorderRadius.circular(100),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(
                  color: _color == colors[i]
                      ? Theme.of(context).colorScheme.onBackground
                      : Colors.transparent,
                  width: 2),
              borderRadius: BorderRadius.circular(100),
              color: colors[i],
            ),
          ),
        ),
        onTap: () {
          _setColor(colors[i]);
        },
      ));
      if (i.remainder(4) == 3) {
        rows.add(Row(
          children: children,
        ));
        children = [];
      }
    }

    return AlertDialog(
      title: const Text('Sélectionnez une couleur'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _color == null
                      ? Theme.of(context).colorScheme.onBackground
                      : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
              child: TextButton(
                onPressed: () {
                  _setColor(null);
                },
                child: const Text('Couleurs du système'),
              ),
            ),
          ),
          ...rows,
        ],
      ),
      actions: [
        ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Appliquer')),
      ],
    );
  }
}
