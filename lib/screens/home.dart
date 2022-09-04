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
import 'package:kosmos_client/widgets/article_card.dart';
import 'package:kosmos_client/widgets/exercise_card.dart';
import 'package:kosmos_client/widgets/grade_card.dart';

import '../global.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    return NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              actions: [Global.popupMenuButton],
              title: const Text('Accueil'),
              floating: true,
              forceElevated: innerBoxIsScrolled,
            )
          ];
        },
        body: RefreshIndicator(
          onRefresh: (() async {
            await DatabaseManager.fetchGradesData();
            await DatabaseManager.fetchNewsData();
            await DatabaseManager.fetchTimetable();
            setState(() {});
          }),
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16.0, 24, 16, 8),
                    child: Text(
                      'Dernières notes',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  FutureBuilder<List<List<Grade>>>(
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
                          return Global.defaultCard(
                              child: Global.exceptionWidget(
                                  snapshot.error! as Exception, snapshot.stackTrace!));
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
                                            GradeCard(twoGrades[0]),
                                            if (twoGrades.length > 1) GradeCard(twoGrades[1])
                                          ],
                                        ),
                                      )
                                      .toList(),
                                ),
                              );
                      }),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16.0, 16, 16, 20),
                    child: Text(
                      'Travail à faire',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  FutureBuilder<List<MapEntry<Exercise, Lesson>>>(
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
                          return Global.defaultCard(
                              child: Global.exceptionWidget(
                                  snapshot.error! as Exception, snapshot.stackTrace!));
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
                            : Column(
                                children: snapshot.data!
                                    .map(
                                      (homework) => ExerciceCard(
                                        homework.key,
                                        homework.value,
                                        showDate: true,
                                        showSubject: true,
                                      ),
                                    )
                                    .toList(),
                              );
                      }),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Actualités',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  FutureBuilder<List<NewsArticle>>(
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
                              child: Global.defaultCard(
                                child: Global.exceptionWidget(
                                    snapshot.error! as Exception, snapshot.stackTrace!),
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
                                    style:
                                        TextStyle(color: Theme.of(context).colorScheme.secondary),
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children:
                                    snapshot.data!.map((article) => ArticleCard(article)).toList(),
                              );
                      }),
                ],
              ),
            ),
          ),
        ));
  }
}
