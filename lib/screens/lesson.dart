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
import 'package:klient/api/exercise.dart';
import 'package:klient/api/lesson.dart';
import 'package:klient/widgets/default_activity.dart';
import 'package:klient/widgets/default_card.dart';
import 'package:klient/widgets/multi_exercise_view.dart';

class LessonPage extends StatelessWidget {
  final Lesson _lesson;
  const LessonPage(this._lesson, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultSliverActivity(
      title: _lesson.title,
      titleColor: Colors.black,
      titleBackground: _lesson.color.shade200,
      leading: const BackButton(color: Colors.black),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            children: [
              DefaultCard(
                surfaceTintColor:
                    Theme.of(context).brightness == Brightness.light ? _lesson.color : null,
                shadowColor:
                    Theme.of(context).brightness == Brightness.light ? _lesson.color : null,
                child: Column(
                  children: [
                    Text(
                      'Séance du ${DateFormat('dd/MM').format(_lesson.date)} de ${_lesson.startTime} à ${_lesson.endTime}',
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Salle ${_lesson.room}',
                      textAlign: TextAlign.center,
                    ),
                    if (_lesson.isModified) Text(_lesson.modificationMessage!)
                  ],
                ),
              ),
              MultiExerciseView(
                _lesson.exercises.where((e) => e.lessonFor == _lesson.id).toList(),
                'Travail à faire pour cette séance',
                _lesson.color,
              ),
              MultiExerciseView(
                _lesson.exercises.where((e) => e.type == ExerciseType.lessonContent).toList(),
                'Contenu de la séance',
                _lesson.color,
              ),
              MultiExerciseView(
                _lesson.exercises
                    .where((e) =>
                            e.type == ExerciseType.exercise &&
                            e.parentLesson == _lesson.id &&
                            e.parentLesson != e.lessonFor // don't display those twice
                        )
                    .toList(),
                'Travail donné lors de la séance',
                _lesson.color,
                showDate: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
