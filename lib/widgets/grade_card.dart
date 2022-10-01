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

import '../global.dart';

class GradeCard extends StatelessWidget {
  final Grade _grade;

  const GradeCard(this._grade, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                color: ColorProvider.getColor(_grade.subject).shade200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      _grade.subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      Global.dateToString(_grade.date),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: SizedBox(
                      width: 50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _grade.grade.toString().replaceAll('.', ','),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const Divider(height: 10),
                          Text(_grade.of.toInt().toString())
                        ],
                      ),
                    ),
                  )),
            ],
          )),
    );
  }
}
