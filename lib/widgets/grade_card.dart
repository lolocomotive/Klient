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
import 'package:kosmos_client/api/color_provider.dart';
import 'package:kosmos_client/api/grade.dart';
import 'package:kosmos_client/util.dart';

class GradeCard extends StatelessWidget {
  final Grade _grade;
  final bool compact;

  const GradeCard(this._grade, {Key? key, this.compact = true}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final titleRow = Row(
      mainAxisAlignment: compact ? MainAxisAlignment.start : MainAxisAlignment.spaceAround,
      children: [
        Flexible(
          child: Text(
            '${_grade.subject} ',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: compact ? null : Colors.black,
            ),
          ),
        ),
        Text(
          Util.dateToString(_grade.date),
          textAlign: TextAlign.center,
          style: TextStyle(color: compact ? null : Colors.black),
        ),
      ],
    );
    return Flexible(
      child: Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: compact
                ? BoxDecoration(
                    border: Border(
                      left: BorderSide(
                          color: ColorProvider.getColor(_grade.subject).shade200, width: 6),
                    ),
                  )
                : null,
            padding: EdgeInsets.all(compact ? 8 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact)
                  titleRow
                else
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    color: ColorProvider.getColor(_grade.subject).shade200,
                    child: titleRow,
                  ),
                if (compact)
                  Row(
                    children: [
                      Text(
                        _grade.grade == -1
                            ? _grade.gradeText!
                            : _grade.grade.toString().replaceAll('.', ','),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (_grade.of != 20) Text('/${_grade.of}')
                    ],
                  )
                else
                  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: SizedBox(
                          width: 50,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _grade.grade == -1
                                    ? _grade.gradeText!
                                    : _grade.grade.toString().replaceAll('.', ','),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const Divider(height: 10),
                              Text(_grade.of.toInt().toString())
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          )),
    );
  }
}
