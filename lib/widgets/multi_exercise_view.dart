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
import 'package:kosmos_client/api/exercise.dart';
import 'package:kosmos_client/api/lesson.dart';
import 'package:kosmos_client/widgets/exercise_card.dart';

import '../global.dart';

class MultiExerciseView extends StatelessWidget {
  final List<Exercise> _exercises;
  final String _title;
  final Lesson _lesson;
  final bool showDate;
  final bool showSubject;

  const MultiExerciseView(this._exercises, this._title, this._lesson,
      {Key? key, this.showDate = false, this.showSubject = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Global.defaultCard(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Column(
        children: [
          Text(
            _title,
            style: const TextStyle(fontSize: 16),
          ),
          ..._exercises
              .map((e) => ExerciceCard(
                    e,
                    _lesson,
                    showDate: showDate,
                    showSubject: showSubject,
                  ))
              .toList(),
          if (_exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: Text(
                'Aucun contenu rensiegné',
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
        ],
      ),
    );
  }
}
