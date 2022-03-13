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
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:kosmos_client/kdecole-api/exercise.dart';

import '../main.dart';

class Lesson {
  int id;
  DateTime date;

  /// Start time of the lesson formatted  HH:MM
  String startTime;

  /// End time of the lesson formatted HH:MM
  String endTime;

  /// Contains the room and also the group (304 - 1ALLG1 for example)
  String room;
  String title;
  List<Exercise> exercises;
  bool isModified;
  String? modificationMessage;

  ///1 = 1 hour
  late double length;
  late double startDouble;
  late Color color;

  Lesson(this.id, this.date, this.startTime, this.endTime, this.room,
      this.title, this.exercises, this.isModified,
      [this.modificationMessage]) {
    startDouble = int.parse(startTime.substring(0, 2)) +
        int.parse(startTime.substring(3)) / 60;
    final e = int.parse(endTime.substring(0, 2)) +
        int.parse(endTime.substring(3)) / 60;

    length = e - startDouble;
    int seed = 0;
    List<int> encoded = utf8.encode(title);
    for (int i = 0; i < encoded.length; i++) {
      seed += encoded[i] * i * 256;
    }
    color = HSLColor.fromAHSL(
      1,
      Random(seed).nextDouble() * 360,
      .7,
      .8,
    ).toColor();
  }

  static Future<List<Lesson>> fetchAll() async {
    final List<Lesson> lessons = [];
    final results = await Global.db!.query('Lessons', orderBy: 'LessonDate');
    for (final result in results) {
      lessons.add(Lesson(
          result['ID'] as int,
          DateTime.fromMillisecondsSinceEpoch((result['LessonDate'] as int)),
          result['StartTime'] as String,
          result['EndTime'] as String,
          result['Room'] as String,
          result['Subject'] as String,
          await Exercise.fromParentLesson(result['ID'] as int, Global.db!),
          result['IsModified'] as int == 1,
          result['ModificationMessage'] as String?));
    }
    return lessons;
  }
}
