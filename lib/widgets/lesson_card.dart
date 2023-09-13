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

import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:klient/api/color_provider.dart';
import 'package:klient/main.dart';
import 'package:klient/screens/lesson.dart';
import 'package:klient/screens/timetable.dart';
import 'package:klient/util.dart';
import 'package:scolengo_api/scolengo_api.dart';

extension IsLong on Lesson {
  bool get isLong =>
      DateTime.parse(endDateTime).difference(DateTime.parse(startDateTime)).inMinutes > 55;
}

class LessonCard extends StatelessWidget {
  final Lesson _lesson;
  final GlobalKey _key = GlobalKey();

  final bool compact;
  final bool positionned;

  LessonCard(this._lesson, {Key? key, this.compact = false, this.positionned = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasIcons = _lesson.toDoAfterTheLesson != null ||
        _lesson.toDoForTheLesson != null ||
        _lesson.contents != null;
    final iconsRow = Opacity(
      opacity: 0.5,
      child: Row(
        children: [
          if (_lesson.toDoForTheLesson != null)
            const Tooltip(
                message: 'Travail à faire pour cette séance donné',
                child: Icon(Icons.event_outlined)),
          if (_lesson.contents != null)
            const Tooltip(
                message: 'Contenu de séance donné', child: Icon(Icons.event_note_outlined)),
          if (_lesson.toDoAfterTheLesson != null)
            const Tooltip(
              message: 'Travail à faire à l\'issue de la séance donné',
              child: Icon(Icons.update),
            ),
        ],
      ),
    );
    final content = SizedBox(
      height: DateTime.parse(_lesson.endDateTime)
              .difference(DateTime.parse(_lesson.startDateTime))
              .inMinutes *
          (compact ? Values.compactHeightPerMinute : Values.heightPerMinute) *
          MediaQuery.of(context).textScaleFactor,
      child: OpenContainer(
        backgroundColor: Colors.black26,
        closedColor: Colors.transparent,
        openColor: Colors.transparent,
        openElevation: 0,
        closedElevation: 0,
        openBuilder: (context, action) => LessonPage(_lesson),
        closedBuilder: (context, action) => Card(
          surfaceTintColor: _lesson.subject.id.color.tint(context),
          shadowColor: _lesson.subject.id.color.shadow(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _lesson.canceled ? StripesPainter(_lesson.subject.id.color) : null,
            child: InkWell(
              onTap: () {
                if (!positionned) return;
                action();
              },
              key: _key,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!compact)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      color: _lesson.subject.id.color.shade200,
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
                          //FIXME not in new API ?
                          //if (_lesson.modified)
                          //  Text(
                          //    _lesson.modificationMessage!,
                          //    style: const TextStyle(color: Colors.black),
                          //  ),
                        ],
                      ),
                    ),
                  if (compact)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border(
                                left: BorderSide(
                                    color: _lesson.subject.id.color.shade200, width: 6))),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  //FIXME not in new API?
                                  //if (_lesson.isModified)
                                  //  Padding(
                                  //    padding: const EdgeInsets.only(right: 4.0),
                                  //    child: Tooltip(
                                  //        message: _lesson.modificationMessage ?? 'Cours modifié',
                                  //        child: Icon(
                                  //          Icons.info_outline,
                                  //          size: MediaQuery.of(context).textScaleFactor * 18,
                                  //        )),
                                  //  ),
                                  Text(
                                    '${_lesson.title} ',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Flexible(
                                      child: Text(
                                    _lesson.location ?? '',
                                    overflow: TextOverflow.ellipsis,
                                  )),
                                ],
                              ),
                              //if (_lesson.length > 1 && _lesson.isModified)
                              //  Text(_lesson.modificationMessage!),
                              if (_lesson.isLong || !hasIcons)
                                Text(_lesson.teachers?.map((e) => e.fullName).join(', ') ?? ''),
                              if (_lesson.isLong)
                                Text(
                                  '${_lesson.startDateTime.hm()} - ${_lesson.endDateTime.hm()}',
                                ),
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
                                    _lesson.location ?? '',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                                  child: Text(
                                    '${_lesson.startDateTime.hm()} - ${_lesson.endDateTime.hm()}',
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
      ),
    );
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: _lesson.subject.id.color.shade200.withAlpha(80),
        highlightColor: _lesson.subject.id.color.shade200.withAlpha(50),
      ),
      child: positionned
          ? Positioned(
              top: (_lesson.startDateTime.date().hour * 60 +
                      _lesson.startDateTime.date().minute -
                      Values.startTime * 60) *
                  MediaQuery.of(context).textScaleFactor *
                  (compact ? Values.compactHeightPerMinute : Values.heightPerMinute),
              left: 0,
              right: 0,
              child: content,
            )
          : content,
    );
  }
}

class StripesPainter extends CustomPainter {
  final MaterialColor color;

  StripesPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint foreground = Paint();
    foreground.color = KlientApp.theme!.brightness == Brightness.light
        ? color.shade700.withAlpha(20)
        : color.shade100.withAlpha(20);
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
