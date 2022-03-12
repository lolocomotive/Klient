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
import 'package:kosmos_client/kdecole-api/lesson.dart';

extension DateOnlyCompare on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

class Timetable extends StatefulWidget {
  @override
  State<Timetable> createState() => _TimetableState();
}

class _TimetableState extends State<Timetable> {
  List<List<Lesson>> _calendar = [];

  _TimetableState() {
    Lesson.fetchAll().then((lessons) {
      List<Lesson> day = [];
      if (lessons.isEmpty) {
        //TODO handle Error
        throw UnimplementedError();
      }
      DateTime lastDate = lessons[0].date;
      for (final lesson in lessons) {
        if (lesson.date.isSameDay(lastDate)) {
          day.add(lesson);
        } else {
          _calendar.add(day);
          day = [lesson];
          lastDate = lesson.date;
        }
      }
      setState(() {});
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
          child: Container(
            color: const Color.fromARGB(255, 240, 240, 240),
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.8),
              itemBuilder: (ctx, index) {
                return SingleDayCalendarView(_calendar[index]);
              },
              itemCount: _calendar.length,
            ),
          ),
        )
      ],
    );
  }
}

class SingleDayCalendarView extends StatelessWidget {
  final List<Lesson> _lessons;

  const SingleDayCalendarView(this._lessons);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView.builder(
        itemBuilder: (ctx, index) {
          return SingleLessonView(_lessons[index]);
        },
        itemCount: _lessons.length,
      ),
    );
  }
}

class SingleLessonView extends StatelessWidget {
  final Lesson _lesson;

  const SingleLessonView(this._lesson);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4))
            ],
            color: _lesson.isModified ? Colors.redAccent : Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8))),
        child: Column(
          children: [
            Text(_lesson.title),
            Text(_lesson.room),
            Text(_lesson.startTime + '-' + _lesson.endTime)
          ],
        ),
      ),
    );
  }
}
