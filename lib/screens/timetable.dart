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

import 'package:flutter/material.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/util.dart';
import 'package:klient/widgets/day_view.dart';
import 'package:klient/widgets/default_activity.dart';
import 'package:klient/widgets/default_card.dart';
import 'package:klient/widgets/default_transition.dart';
import 'package:klient/widgets/delayed_progress_indicator.dart';
import 'package:klient/widgets/exception_widget.dart';
import 'package:klient/widgets/user_avatar_action.dart';
import 'package:scolengo_api/scolengo_api.dart';

extension DateOnlyCompare on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

class Values {
  static const timeWidth = 32.0;
  static const heightPerMinute = 2.0;
  static const compactHeightPerMinute = 1.2;
  static const lessonLength = 55.0 / 55.0;
  static const maxMinutesPerDay = 11 * 60;
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
    final response = await ConfigProvider.client!.getAgendas(
      ConfigProvider.credentials!.idToken.claims.subject,
      startDate: DateTime.now().add(const Duration(days: -14)),
      endDate: DateTime.now().add(
        const Duration(days: 14),
      ),
    );
    final days = response.data
        .where((element) => element.lessons != null)
        .map((element) => element.lessons!)
        .toList();

    //Set _page to current or next day
    for (var i = 0; i < days.length; i++) {
      if (days[i][0].startDateTime.date().isSameDay(DateTime.now())) {
        _page = i;
        break;
      } else if (days[i].last.startDateTime.date().isBefore(DateTime.now())) {
        _page = i + 1;
      } else {
        break;
      }
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultSliverActivity(
      title: 'Emploi du temps',
      actions: [
        UserAvatarAction(
          onUpdate: () {
            setState(() {
              compact = ConfigProvider.compact!;
            });
          },
        )
      ],
      child: RefreshIndicator(
        onRefresh: () async {
          /* TODO rewrite this
          Client.getClient().clear();
          await Downloader.fetchTimetable();
          setState(() {}); */
        },
        child: SingleChildScrollView(
          child: SizedBox(
            height: (compact ? Values.compactHeightPerMinute : Values.heightPerMinute) *
                    MediaQuery.of(context).textScaleFactor *
                    Values.maxMinutesPerDay *
                    Values.lessonLength +
                32,
            child: Stack(
              children: [
                FutureBuilder<List<List<Lesson>>>(
                    future: _getCalendar()
                      ..then((value) {
                        _pageController = PageController(viewportFraction: .8, initialPage: _page);
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
                                (compact ? Values.compactHeightPerMinute : Values.heightPerMinute) *
                                    60 *
                                    MediaQuery.of(context).textScaleFactor,
                            child: Text(
                              '${index + Values.startTime}h',
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                        itemCount: (Values.maxMinutesPerDay / 60).round(),
                      ),
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

int getWeekCount(List<List<Lesson>> data) {
  var weeks = 1;
  for (final day in data) {
    if (day[0].startDateTime.date().weekday == DateTime.monday) {
      weeks++;
    }
  }
  return weeks;
}

int dayToWeek(int d, List<List<Lesson>> data) {
  var week = 1;
  int i = 0;
  for (final day in data) {
    if (day[0].startDateTime.date().weekday == DateTime.monday) {
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
      if (day[0].startDateTime.date().weekday == DateTime.monday) {
        currentWeek++;
      }
      if (currentWeek == index) {
        if (_week.isEmpty && day[0].startDateTime.date().weekday > 1) {
          for (var i = 1; i < day[0].startDateTime.date().weekday; i++) {
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
