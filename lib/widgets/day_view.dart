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
import 'package:kosmos_client/api/lesson.dart';
import 'package:kosmos_client/config_provider.dart';
import 'package:kosmos_client/screens/timetable.dart';
import 'package:kosmos_client/widgets/lesson_card.dart';

class DayView extends StatelessWidget {
  final List<Lesson> _lessons;

  const DayView(this._lessons, {Key? key}) : super(key: key);

  static const _days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '${_days[_lessons[0].date.weekday - 1]} ${_lessons[0].date.day}/${_lessons[0].date.month}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: (ConfigProvider.compact! ? Values.compactHeightPerHour : Values.heightPerHour) *
                  MediaQuery.of(context).textScaleFactor *
                  Values.maxLessonsPerDay *
                  Values.lessonLength -
              4,
          child: Stack(
            children: _lessons
                .map((lesson) => LessonCard(lesson, compact: ConfigProvider.compact!))
                .toList(),
          ),
        ),
      ],
    );
  }
}
