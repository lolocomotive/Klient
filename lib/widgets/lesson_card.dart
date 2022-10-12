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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kosmos_client/api/exercise.dart';
import 'package:kosmos_client/api/lesson.dart';
import 'package:kosmos_client/screens/lesson.dart';
import 'package:morpheus/morpheus.dart';

import '../global.dart';

class LessonCard extends StatelessWidget {
  final Lesson _lesson;
  final GlobalKey _key = GlobalKey();

  final bool compact;
  final bool positionned;

  LessonCard(this._lesson, {Key? key, this.compact = false, this.positionned = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconsRow = Opacity(
      opacity: 0.5,
      child: Row(
        children: [
          if (_lesson.exercises.where((e) => e.lessonFor == _lesson.id).isNotEmpty)
            const Tooltip(
                message: 'Travail à faire pour cette séance donné',
                child: Icon(Icons.event_outlined)),
          if (_lesson.exercises.where((e) => e.type == ExerciseType.lessonContent).isNotEmpty)
            const Tooltip(
                message: 'Contenu de séance donné', child: Icon(Icons.event_note_outlined)),
          if (_lesson.exercises
              .where((e) =>
                      e.type == ExerciseType.exercise &&
                      e.parentLesson == _lesson.id &&
                      e.parentLesson != e.lessonFor // don't display those twice
                  )
              .isNotEmpty)
            const Tooltip(
                message: 'Travail à faire à l\'issue de la séance donné', child: Icon(Icons.update))
        ],
      ),
    );
    final content = SizedBox(
      height: _lesson.length *
          (compact ? Global.compactHeightPerHour : Global.heightPerHour) *
          MediaQuery.of(context).textScaleFactor,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: _lesson.isModified ? StripesPainter() : null,
          child: InkWell(
            onTap: () {
              if (!positionned) return;
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
                if (!compact)
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    color: _lesson.color.shade200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Flexible(
                          child: Text(
                            _lesson.title,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (_lesson.isModified)
                          Text(
                            _lesson.modificationMessage!,
                            style: const TextStyle(color: Colors.black),
                          ),
                      ],
                    ),
                  ),
                if (compact)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          border:
                              Border(left: BorderSide(color: _lesson.color.shade200, width: 6))),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${_lesson.title} ',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (_lesson.length <= 1 && _lesson.exercises.isNotEmpty)
                                  Flexible(
                                      child: Text(
                                    _lesson.room,
                                    overflow: TextOverflow.ellipsis,
                                  )),
                              ],
                            ),
                            if (_lesson.length > 1 || _lesson.exercises.isEmpty) Text(_lesson.room),
                            Flexible(child: iconsRow)
                          ],
                        ),
                      ),
                    ),
                  )
                else
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
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: iconsRow,
                            ),
                          ],
                        )
                      ],
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
    return positionned
        ? Positioned(
            top: (_lesson.startDouble - Global.startTime) *
                MediaQuery.of(context).textScaleFactor *
                (compact ? Global.compactHeightPerHour : Global.heightPerHour),
            left: 0,
            right: 0,
            child: content,
          )
        : content;
  }
}

class StripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint foreground = Paint();
    foreground.color =
        Global.theme!.brightness == Brightness.light ? Colors.black12 : Colors.white10;
    foreground.strokeWidth = 15;
    const step = 45.0;

    for (var i = 0; i < max(size.width, size.height) / (step / 2); i++) {
      canvas.drawLine(Offset(-foreground.strokeWidth, step * i),
          Offset(step * i, -foreground.strokeWidth), foreground);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
