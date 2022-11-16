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
import 'package:kosmos_client/api/database_manager.dart';
import 'package:kosmos_client/api/exercise.dart';
import 'package:kosmos_client/api/grade.dart';
import 'package:kosmos_client/api/lesson.dart';
import 'package:kosmos_client/api/news_article.dart';
import 'package:kosmos_client/config_provider.dart';
import 'package:kosmos_client/util.dart';
import 'package:kosmos_client/widgets/article_card.dart';
import 'package:kosmos_client/widgets/default_card.dart';
import 'package:kosmos_client/widgets/exception_widget.dart';
import 'package:kosmos_client/widgets/exercise_card.dart';
import 'package:kosmos_client/widgets/grade_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<_HomeworkListWrapperState> _hKey = GlobalKey();
  final GlobalKey<_GradeListState> _gKey = GlobalKey();
  final GlobalKey<_ArticleListState> _aKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              actions: [Util.popupMenuButton],
              title: const Text('Accueil'),
              floating: true,
              forceElevated: innerBoxIsScrolled,
            )
          ];
        },
        body: RefreshIndicator(
          onRefresh: (() async {
          await Future.wait(<Future>[
            DatabaseManager.fetchGradesData().then((_) => _gKey.currentState!.setState(() {})),
            DatabaseManager.fetchNewsData().then((_) => _aKey.currentState!.setState(() {})),
            DatabaseManager.fetchTimetable().then((_) => _hKey.currentState!.setState(() {})),
          ]);
          }),
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: LayoutBuilder(builder: (context, constraints) {
                    if (constraints.maxWidth > 1200) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SectionTitle('Travail à faire'),
                              HomeworkListWrapper(key: _hKey),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SectionTitle('Dernières notes'),
                              GradeList(key: _gKey),
                              ],
                            ),
                          ),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SectionTitle('Actualités'),
                            ArticleList(key: _aKey),
                            ],
                          ))
                        ],
                      );
                    }
                    if (constraints.maxWidth < 700) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionTitle('Travail à faire'),
                        HomeworkListWrapper(key: _hKey),
                        const SectionTitle('Dernières notes'),
                        GradeList(key: _gKey),
                        const SectionTitle('Actualités'),
                        ArticleList(key: _aKey),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SectionTitle('Travail à faire'),
                            HomeworkListWrapper(key: _hKey),
                            const SectionTitle('Dernières notes'),
                            GradeList(key: _gKey),
                            ],
                          ),
                        ),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionTitle('Actualités'),
                          ArticleList(key: _aKey),
                          ],
                        ))
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
      ),
    );
  }
}

class HomeworkListWrapper extends StatefulWidget {
  const HomeworkListWrapper({
    Key? key,
  }) : super(key: key);

  @override
  State<HomeworkListWrapper> createState() => _HomeworkListWrapperState();
}

class _HomeworkListWrapperState extends State<HomeworkListWrapper> {
  Future<List<MapEntry<Exercise, Lesson>>> _fetchHomework() async {
    final exercises = await Exercise.fetchAll();
    List<MapEntry<Exercise, Lesson>> r = [];
    for (final exercise in exercises) {
      if (exercise.lessonFor == null) continue;
      if (exercise.dateFor!.isBefore(DateTime.now())) continue;
      r.add(MapEntry(exercise, (await Lesson.byID(exercise.lessonFor!))!));
    }
    r.sort(
      (a, b) => a.key.dateFor!.millisecondsSinceEpoch - b.key.dateFor!.millisecondsSinceEpoch,
    );

    return r;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MapEntry<Exercise, Lesson>>>(
        future: _fetchHomework(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            return DefaultCard(
                child: ExceptionWidget(e: snapshot.error! as Exception, st: snapshot.stackTrace!));
          }

          return snapshot.data!.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                      child: Text(
                    'Rien à afficher',
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  )),
                )
              : HomeworkList(data: snapshot.data!);
        });
  }
}

class GradeList extends StatefulWidget {
  const GradeList({
    Key? key,
  }) : super(key: key);

  @override
  State<GradeList> createState() => _GradeListState();
}

class _GradeListState extends State<GradeList> {
  Future<List<List<Grade>>> _fetchGrades() async {
    final grades = await Grade.fetchAll();
    List<List<Grade>> r = [];
    for (int i = 0; i < grades.length; i++) {
      if (i % 2 == 0) {
        r.add([grades[i]]);
      } else {
        r[(i / 2).floor()].add(grades[i]);
      }
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<List<Grade>>>(
        future: _fetchGrades(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            return DefaultCard(
                child: ExceptionWidget(e: snapshot.error! as Exception, st: snapshot.stackTrace!));
          }
          return snapshot.data!.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                      child: Text(
                    'Rien à afficher',
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  )),
                )
              : SizedBox(
                  child: Column(
                    children: snapshot.data!
                        .map(
                          (twoGrades) => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GradeCard(
                                twoGrades[0],
                                compact: ConfigProvider.compact!,
                              ),
                              if (twoGrades.length > 1)
                                GradeCard(
                                  twoGrades[1],
                                  compact: ConfigProvider.compact!,
                                )
                            ],
                          ),
                        )
                        .toList(),
                  ),
                );
        });
  }
}

class ArticleList extends StatefulWidget {
  const ArticleList({
    Key? key,
  }) : super(key: key);

  @override
  State<ArticleList> createState() => _ArticleListState();
}

class _ArticleListState extends State<ArticleList> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NewsArticle>>(
        future: NewsArticle.fetchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: DefaultCard(
                  child: ExceptionWidget(e: snapshot.error! as Exception, st: snapshot.stackTrace!),
                ),
              ),
            );
          }
          return snapshot.data!.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'Rien à afficher',
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: snapshot.data!.map((article) => ArticleCard(article)).toList(),
                );
        });
  }
}

class SectionTitle extends StatelessWidget {
  final String _title;
  const SectionTitle(
    this._title, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16, 16, 8),
      child: Text(
        _title,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }
}

class HomeworkList extends StatefulWidget {
  const HomeworkList({
    Key? key,
    required List<MapEntry<Exercise, Lesson>> data,
  })  : _data = data,
        super(key: key);

  final List<MapEntry<Exercise, Lesson>> _data;

  @override
  State<HomeworkList> createState() => _HomeworkListState();
}

class _HomeworkListState extends State<HomeworkList> {
  bool _showDone = false;

  List<MapEntry<Exercise, Lesson>>? mutableData;
  @override
  Widget build(BuildContext context) {
    mutableData ??= widget._data;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        child: InkWell(
          onTap: () {
            setState(() {
              _showDone = !_showDone;
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
            child: Semantics(
              checked: _showDone,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Afficher le travail fait'),
                  Switch(
                      value: _showDone,
                      onChanged: (value) {
                        setState(() {
                          _showDone = value;
                        });
                      }),
                ],
              ),
            ),
          ),
        ),
      ),
      if (widget._data.where((element) => element.key.done == false).isEmpty && !_showDone)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
              child: Text(
            'Tout a été fait :)',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          )),
        )
      else
        ...mutableData!.map((homework) {
          if (!_showDone && homework.key.done) {
            return Container();
          }
          return Opacity(
            opacity: homework.key.done ? .6 : 1,
            child: ExerciseCard(
              homework.key,
              homework.value,
              compact: ConfigProvider.compact!,
              elevation: 1,
              showDate: true,
              showSubject: true,
              onMarkedDone: (bool done) {
                mutableData!.remove(homework);
                MapEntry<Exercise, Lesson> modified =
                    MapEntry(homework.key..done = done, homework.value);
                mutableData!.add(modified);
                mutableData!.sort(
                  (a, b) =>
                      a.key.dateFor!.millisecondsSinceEpoch - b.key.dateFor!.millisecondsSinceEpoch,
                );
                setState(() {});
              },
            ),
          );
        }).toList(),
    ]);
  }
}
