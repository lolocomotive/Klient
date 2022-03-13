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

import 'package:flutter/material.dart';
import 'package:kosmos_client/kdecole-api/lesson.dart';

import '../main.dart';

extension DateOnlyCompare on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

class Timetable extends StatefulWidget {
  const Timetable({Key? key}) : super(key: key);

  @override
  State<Timetable> createState() => _TimetableState();
}

class _TimetableState extends State<Timetable> {
  List<List<Lesson>> _calendar = [];
  final _pageController = PageController(viewportFraction: 0.8);
  _TimetableState() {
    Lesson.fetchAll().then((lessons) {
      List<Lesson> day = [];
      if (lessons.isEmpty) {
        //TODO handle Error
        throw UnimplementedError();
      }
      DateTime lastDate = lessons[0].date;
      var page = 0;
      for (int i = 0; i < lessons.length; i++) {
        final lesson = lessons[i];
        if (lesson.date.isSameDay(lastDate)) {
          day.add(lesson);
        } else {
          _calendar.add(day);
          day = [lesson];
          lastDate = lesson.date;
        }
        if ((lesson.date.millisecondsSinceEpoch -
                        DateTime.now().millisecondsSinceEpoch >=
                    0 &&
                page == 0) ||
            lesson.date.isSameDay(DateTime.now())) {
          page = _calendar.length;
        }
      }
      setState(() {});
      _pageController.jumpToPage(page);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text("Emploi du temps"),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: Global.heightPerHour *
                      Global.maxLessonsPerDay *
                      Global.lessonLength +
                  32, //TODO compute maximum height.
              child: Container(
                color: const Color.fromARGB(255, 240, 240, 240),
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemBuilder: (ctx, index) {
                        return SingleDayCalendarView(_calendar[index]);
                      },
                      itemCount: _calendar.length,
                    ),
                    Container(
                      color: Colors.white60,
                      width: Global.timeWidth,
                      child: MediaQuery.removePadding(
                        removeTop: true,
                        context: context,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 32, 0, 0),
                          child: ListView.builder(
                            itemBuilder: (ctx, index) {
                              return SizedBox(
                                height: Global.heightPerHour,
                                child: Text(
                                  (index + Global.startTime).toString() + 'h',
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                            itemCount: Global.maxLessonsPerDay,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}

class SingleDayCalendarView extends StatelessWidget {
  final List<Lesson> _lessons;

  const SingleDayCalendarView(this._lessons, {Key? key}) : super(key: key);

  static const _days = [
    "Lundi",
    "Mardi",
    "Mercredi",
    "Jeudi",
    "Vendredi",
    "Samedi",
    "Dimanche"
  ];
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            _days[_lessons[0].date.weekday - 1] +
                ' ' +
                _lessons[0].date.day.toString() +
                '/' +
                _lessons[0].date.month.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: Global.heightPerHour *
              Global.maxLessonsPerDay *
              Global.lessonLength,
          child: Stack(
            children:
                _lessons.map((lesson) => SingleLessonView(lesson)).toList(),
          ),
        ),
      ],
    );
  }
}

class SingleLessonView extends StatelessWidget {
  final Lesson _lesson;

  const SingleLessonView(this._lesson, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const boxShadow = [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 8,
        offset: Offset(0, 4),
      )
    ];
    return Positioned(
      top: (_lesson.startDouble - Global.startTime) * Global.heightPerHour,
      left: 0,
      right: 0,
      child: Container(
        height: _lesson.length * Global.heightPerHour,
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: boxShadow,
            color: _lesson.isModified ? Colors.yellow.shade200 : Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                color: _lesson.color,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      _lesson.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_lesson.isModified) Text(_lesson.modificationMessage!)
                  ],
                ),
              ),
              Expanded(
                child: Center(
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
                          _lesson.startTime + ' - ' + _lesson.endTime,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
