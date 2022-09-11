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
import 'package:kosmos_client/screens/lesson.dart';
import 'package:morpheus/morpheus.dart';

import '../global.dart';

class LessonCard extends StatelessWidget {
  final Lesson _lesson;
  final GlobalKey _key = GlobalKey();

  LessonCard(this._lesson, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: (_lesson.startDouble - Global.startTime) * Global.heightPerHour,
      left: 0,
      right: 0,
      child: SizedBox(
        height: _lesson.length * Global.heightPerHour,
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          color: _lesson.isModified
              ? Global.theme!.brightness == Brightness.dark
                  ? const Color.fromARGB(255, 90, 77, 0)
                  : Colors.yellow.shade100
              : null,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MorpheusPageRoute(
                  builder: (_) => LessonPage(_lesson),
                  parentKey: _key,
                ),
              );
            },
            key: _key,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: _lesson.color.shade200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        _lesson.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      if (_lesson.isModified) Text(_lesson.modificationMessage!),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
                              child: Text(
                                _lesson.room,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                              child: Text(
                                '${_lesson.startTime} - ${_lesson.endTime}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Opacity(
                        opacity: .5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  if (_lesson.exercises
                                      .where((e) => e.lessonFor == _lesson.id)
                                      .isNotEmpty)
                                    const Icon(Icons.event_outlined),
                                  if (_lesson.exercises
                                      .where((e) => e.type == ExerciseType.lessonContent)
                                      .isNotEmpty)
                                    const Icon(Icons.event_note_outlined),
                                  if (_lesson.exercises
                                      .where((e) =>
                                              e.type == ExerciseType.exercise &&
                                              e.parentLesson == _lesson.id &&
                                              e.parentLesson !=
                                                  e.lessonFor // don't display those twice
                                          )
                                      .isNotEmpty)
                                    const Icon(Icons.update)
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
