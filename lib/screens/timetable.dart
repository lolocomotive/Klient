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
import 'package:kosmos_client/api/database_manager.dart';
import 'package:kosmos_client/api/lesson.dart';
import 'package:kosmos_client/widgets/day_view.dart';

import '../global.dart';

extension DateOnlyCompare on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

class TimetablePage extends StatefulWidget {
  const TimetablePage({Key? key}) : super(key: key);

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  PageController _pageController = PageController(viewportFraction: 0.8);
  int _page = 0;
  Future<List<List<Lesson>>> _getCalendar() async {
    List<List<Lesson>> r = [];
    var lessons = await Lesson.fetchAll();
    List<Lesson> day = [];
    DateTime lastDate = DateTime.utc(0);
    if (lessons.isNotEmpty) {
      lastDate = lessons[0].date;
    }

    _page = 0;
    for (int i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      if (lesson.date.isSameDay(lastDate)) {
        day.add(lesson);
      } else {
        r.add(day);
        day = [lesson];
        lastDate = lesson.date;
      }
      if ((lesson.date.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch >= 0 &&
              _page == 0) ||
          lesson.date.isSameDay(DateTime.now())) {
        _page = r.length;
      }
    }
    return r;
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
            setState(() {});
          },
          child: SingleChildScrollView(
            child: SizedBox(
              height: (Global.heightPerHour * Global.maxLessonsPerDay * Global.lessonLength + 32),
              child: Stack(
                children: [
                  FutureBuilder<List<List<Lesson>>>(
                      future: _getCalendar()
                        ..then((value) {
                          _pageController =
                              PageController(viewportFraction: .8, initialPage: _page);
                        }),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Column(
                            children: [
                              DefaultCard(
                                child: ExceptionWidget(
                                    e: snapshot.error! as Exception, st: snapshot.stackTrace!),
                              ),
                            ],
                          );
                        }
                        return PageView.builder(
                          controller: _pageController,
                          itemBuilder: (ctx, index) {
                            if (snapshot.data!.isEmpty) {
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'Rien à afficher',
                                      style:
                                          TextStyle(color: Theme.of(context).colorScheme.secondary),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return DayView(snapshot.data![index]);
                          },
                          itemCount: max(snapshot.data!.length, 1),
                        );
                      }),
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
