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
import 'package:intl/intl.dart';
import 'package:klient/api/color_provider.dart';
import 'package:klient/util.dart';
import 'package:klient/widgets/default_activity.dart';
import 'package:klient/widgets/default_card.dart';
import 'package:klient/widgets/homework_list.dart';
import 'package:scolengo_api/scolengo_api.dart';

class LessonPage extends StatelessWidget {
  final Lesson _lesson;
  const LessonPage(this._lesson, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = _lesson.subject.id.color;
    return DefaultSliverActivity(
      title: _lesson.title,
      titleColor: Colors.black,
      titleBackground: color.shade200,
      leading: const BackButton(color: Colors.black),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            children: [
              DefaultCard(
                surfaceTintColor: Theme.of(context).brightness == Brightness.light ? color : null,
                shadowColor: Theme.of(context).brightness == Brightness.light ? color : null,
                child: Column(
                  children: [
                    Text(
                      'Séance du ${DateFormat('dd/MM').format(_lesson.startDateTime.date())} de ${_lesson.startDateTime.hm()} à ${_lesson.endDateTime.hm()}',
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Salle ${_lesson.location}',
                      textAlign: TextAlign.center,
                    ),
                    // TODO new API doesn't have this ?
                    //if (_lesson.isModified) Text(_lesson.modificationMessage!)
                  ],
                ),
              ),
              HomeworkList(
                _lesson.toDoForTheLesson ?? [],
                'Travail à faire pour cette séance',
                color,
              ),
              /* TODO implement lessonContent display
              HomeworkList(
                _lesson.exercises.where((e) => e.type == ExerciseType.lessonContent).toList(),
                'Contenu de la séance',
                color,
              ), */
              HomeworkList(
                _lesson.toDoAfterTheLesson ?? [],
                'Travail donné lors de la séance',
                color,
                showDate: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
