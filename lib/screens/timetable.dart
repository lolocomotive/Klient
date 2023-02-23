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
import 'package:kosmos_client/api/downloader.dart';
import 'package:kosmos_client/api/lesson.dart';
import 'package:kosmos_client/config_provider.dart';
import 'package:kosmos_client/widgets/day_view.dart';
import 'package:kosmos_client/widgets/default_card.dart';
import 'package:kosmos_client/widgets/default_transition.dart';
import 'package:kosmos_client/widgets/delayed_progress_indicator.dart';
import 'package:kosmos_client/widgets/exception_widget.dart';
import 'package:kosmos_client/widgets/user_avatar_action.dart';

extension DateOnlyCompare on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

class Values {
  static const timeWidth = 32.0;
  static const heightPerHour = 120.0;
  static const compactHeightPerHour = 70.0;
  static const lessonLength = 55.0 / 55.0;
  static const maxLessonsPerDay = 11;
  static const startTime = 8;
}

class TimetablePage extends StatefulWidget {
  const TimetablePage({Key? key}) : super(key: key);

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> with TickerProviderStateMixin {
  PageController _pageController = PageController();
  int _page = 0;

  bool compact = ConfigProvider.compact!;
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
            actions: [
              UserAvatarAction(
                onUpdate: () {
                  setState(() {
                    compact = ConfigProvider.compact!;
                  });
                },
              )
            ],
          )
        ];
      },
      body: Scrollbar(
        child: RefreshIndicator(
          onRefresh: () async {
            await Downloader.fetchTimetable();
            setState(() {});
          },
          child: SingleChildScrollView(
            child: SizedBox(
              height: (compact ? Values.compactHeightPerHour : Values.heightPerHour) *
                      MediaQuery.of(context).textScaleFactor *
                      Values.maxLessonsPerDay *
                      Values.lessonLength +
                  32,
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
                              child: DelayedProgressIndicator(
                                delay: Duration(milliseconds: 500),
                              ),
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
                        return DefaultTransition(
                          child: LayoutBuilder(builder: (context, constraints) {
                            var fraction = 0.8;
                            if (constraints.maxWidth > 700) {
                              fraction = 0.4;
                            }
                            if (constraints.maxWidth > 1200) {
                              fraction = 0.9;
                            }
                            _pageController = PageController(
                                viewportFraction: fraction,
                                initialPage: constraints.maxWidth > 1200
                                    ? dayToWeek(_pageController.initialPage, snapshot.data!)
                                    : _pageController.initialPage);
                            return PageView.builder(
                              pageSnapping: fraction != 0.4,
                              controller: _pageController,
                              itemBuilder: (ctx, index) {
                                if (snapshot.data!.isEmpty) {
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          'Rien à afficher',
                                          style: TextStyle(
                                              color: Theme.of(context).colorScheme.secondary),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return constraints.maxWidth > 1200
                                    ? WeekView(snapshot.data!, index)
                                    : DayView(snapshot.data![index]);
                              },
                              itemCount: max(
                                  constraints.maxWidth > 1200
                                      ? getWeekCount(snapshot.data!)
                                      : snapshot.data!.length,
                                  1),
                            );
                          }),
                        );
                      }),
                  Container(
                    color: Theme.of(context).colorScheme.background.withAlpha(150),
                    width: Values.timeWidth,
                    child: MediaQuery.removePadding(
                      removeTop: true,
                      context: context,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 32, 0, 0),
                        child: ListView.builder(
                          itemBuilder: (ctx, index) {
                            return SizedBox(
                              height:
                                  (compact ? Values.compactHeightPerHour : Values.heightPerHour) *
                                      MediaQuery.of(context).textScaleFactor,
                              child: Text(
                                '${index + Values.startTime}h',
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                          itemCount: Values.maxLessonsPerDay,
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

int getWeekCount(List<List<Lesson>> data) {
  var weeks = 1;
  for (final day in data) {
    if (day[0].date.weekday == DateTime.monday) {
      weeks++;
    }
  }
  return weeks;
}

int dayToWeek(int d, List<List<Lesson>> data) {
  var week = 1;
  int i = 0;
  for (final day in data) {
    if (day[0].date.weekday == DateTime.monday) {
      week++;
    }
    i++;
    if (d == i) return week;
  }
  return 0;
}

class WeekView extends StatelessWidget {
  WeekView(List<List<Lesson>> data, index, {Key? key}) : super(key: key) {
    _week = [];
    var currentWeek = 0;
    for (final day in data) {
      if (day[0].date.weekday == DateTime.monday) {
        currentWeek++;
      }
      if (currentWeek == index) {
        if (_week.isEmpty && day[0].date.weekday > 1) {
          for (var i = 1; i < day[0].date.weekday; i++) {
            _week.add([]);
          }
        }
        _week.add(day);
      }
    }
    while (_week.length < 5) {
      _week.add([]);
    }
  }
  late final List<List<Lesson>> _week;

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Row(
      children: [
        ..._week.map((e) {
          if (e.isEmpty) {
            return Expanded(
                child: Container(
              color: Theme.of(context).colorScheme.onBackground.withAlpha(30),
              child: const Center(
                child: Text('Journée vide'),
              ),
            ));
          }
          return Expanded(child: DayView(e));
        }).toList()
      ],
    ));
  }
}
