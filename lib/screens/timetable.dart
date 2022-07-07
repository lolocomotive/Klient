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
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:kosmos_client/kdecole-api/database_manager.dart';
import 'package:kosmos_client/kdecole-api/exercise.dart';
import 'package:kosmos_client/kdecole-api/lesson.dart';
import 'package:morpheus/morpheus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global.dart';

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
  final List<List<Lesson>> _calendar = [];
  final _pageController = PageController(viewportFraction: 0.8);
  _TimetableState() {
    _reload();
  }
  void _reload() {
    Lesson.fetchAll().then((lessons) {
      List<Lesson> day = [];
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
        if ((lesson.date.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch >= 0 &&
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
    return NestedScrollView(
      floatHeaderSlivers: true,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return [
          SliverAppBar(
            floating: true,
            forceElevated: innerBoxIsScrolled,
            title: const Text('Emploi du temps'),
            actions: [Global.popupMenuButton],
          )
        ];
      },
      body: Scrollbar(
        child: RefreshIndicator(
          onRefresh: () async {
            await DatabaseManager.fetchTimetable();
            _reload();
            setState(() {});
          },
          child: SingleChildScrollView(
            child: SizedBox(
              height: (Global.heightPerHour * Global.maxLessonsPerDay * Global.lessonLength + 32),
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemBuilder: (ctx, index) {
                      if (_calendar.isEmpty) {
                        return Column(
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          ],
                        );
                      }
                      return SingleDayCalendarView(_calendar[index]);
                    },
                    itemCount: max(_calendar.length, 1),
                  ),
                  Container(
                    color: Global.theme!.colorScheme.brightness == Brightness.dark
                        ? Colors.black38
                        : Colors.white60,
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
                                '${index + Global.startTime}h',
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
      ),
    );
  }
}

class SingleDayCalendarView extends StatelessWidget {
  final List<Lesson> _lessons;

  const SingleDayCalendarView(this._lessons, {Key? key}) : super(key: key);

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
          height: Global.heightPerHour * Global.maxLessonsPerDay * Global.lessonLength,
          child: Stack(
            children: _lessons.map((lesson) => SingleLessonView(lesson)).toList(),
          ),
        ),
      ],
    );
  }
}

class SingleLessonView extends StatelessWidget {
  final Lesson _lesson;
  final GlobalKey _key = GlobalKey();

  SingleLessonView(this._lesson, {Key? key}) : super(key: key);

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
                  builder: (_) => DetailedLessonView(_lesson),
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
                      if (_lesson.isModified) Text(_lesson.modificationMessage!),
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
                            '${_lesson.startTime} - ${_lesson.endTime}',
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
      ),
    );
  }
}

class DetailedLessonView extends StatelessWidget {
  final Lesson _lesson;
  const DetailedLessonView(this._lesson, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Global.theme!.colorScheme.background,
      appBar: AppBar(
        title: Text(
          _lesson.title,
        ),
        backgroundColor: _lesson.color,
      ),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.all(8),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
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
                ],
              ),
            ),
          ),
          MultiExerciseView(
            _lesson.exercises.where((e) => e.lessonFor == _lesson.id).toList(),
            'Travail à faire pour cette séance',
            _lesson,
          ),
          MultiExerciseView(
            _lesson.exercises.where((e) => e.type == ExerciseType.lessonContent).toList(),
            'Contenu de la séance',
            _lesson,
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
            _lesson,
          ),
        ],
      ),
    );
  }
}

class MultiExerciseView extends StatelessWidget {
  final List<Exercise> _exercises;
  final String _title;
  final Lesson _lesson;

  const MultiExerciseView(this._exercises, this._title, this._lesson, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              _title,
              style: const TextStyle(fontSize: 16),
            ),
            ..._exercises.map((e) => ExerciceView(e, _lesson)).toList(),
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
      ),
    );
  }
}

class ExerciceView extends StatelessWidget {
  const ExerciceView(this._exercise, this._lesson,
      {Key? key, this.showDate = false, this.showSubject = false})
      : super(key: key);
  final bool showDate;
  final bool showSubject;
  final Exercise _exercise;
  final Lesson _lesson;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDate)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
            child: Text(
              '${showSubject ? '${_lesson.title}: ' : ''}À faire pour le ${DateFormat('dd/MM - HH:mm').format(_exercise.dateFor!)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        Card(
          margin: const EdgeInsets.all(8.0),
          clipBehavior: Clip.antiAlias,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: _lesson.color,
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _exercise.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _exercise.htmlContent == ''
                    ? Text(
                        'Aucun contenu renseigné',
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                        textAlign: TextAlign.center,
                      )
                    : Html(
                        data: _exercise.htmlContent,
                        onLinkTap: (url, context, map, element) {
                          launchUrl(Uri.parse(url!));
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
