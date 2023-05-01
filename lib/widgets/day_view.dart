/*
 * This file is part of the Klient (https://github.com/lolocomotive/klient)
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
import 'package:klient/config_provider.dart';
import 'package:klient/screens/timetable.dart';
import 'package:klient/widgets/lesson_card.dart';
import 'package:scolengo_api/scolengo_api.dart';

class DayView extends StatelessWidget {
  final List<Lesson> _lessons;

  const DayView(this._lessons, {Key? key}) : super(key: key);

  static const _days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
  @override
  Widget build(BuildContext context) {
    final date0 = DateTime.parse(_lessons[0].startDateTime);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '${_days[date0.weekday - 1]} ${date0.day}/${date0.month}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height:
              (ConfigProvider.compact! ? Values.compactHeightPerMinute : Values.heightPerMinute) *
                      MediaQuery.of(context).textScaleFactor *
                      Values.maxMinutesPerDay *
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
