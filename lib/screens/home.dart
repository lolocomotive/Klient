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
import 'package:flutter_html/flutter_html.dart';
import 'package:kosmos_client/kdecole-api/database_manager.dart';
import 'package:kosmos_client/kdecole-api/exercise.dart';
import 'package:kosmos_client/kdecole-api/grade.dart';
import 'package:kosmos_client/kdecole-api/lesson.dart';
import 'package:kosmos_client/kdecole-api/news_article.dart';
import 'package:kosmos_client/screens/timetable.dart';
import 'package:morpheus/morpheus.dart';

import '../global.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<List<Grade>> _grades = [];
  List<MapEntry<Exercise, Lesson>> _homework = [];

  List<NewsArticle> _news = [];
  _HomeState() {
    _reload();
  }
  _reload() {
    _grades = [];
    _homework = [];
    _news = [];
    Grade.fetchAll().then((grades) => setState(() {
          for (int i = 0; i < grades.length; i++) {
            if (i % 2 == 0) {
              _grades.add([grades[i]]);
            } else {
              _grades[(i / 2).floor()].add(grades[i]);
            }
          }
        }));
    Exercise.fetchAll().then((exercises) async {
      for (final exercise in exercises) {
        if (exercise.lessonFor == null) continue;
        if (exercise.dateFor!.isBefore(DateTime.now())) continue;
        _homework
            .add(MapEntry(exercise, (await Lesson.byID(exercise.lessonFor!))!));
      }
      _homework.sort(
        (a, b) =>
            a.key.dateFor!.millisecondsSinceEpoch -
            b.key.dateFor!.millisecondsSinceEpoch,
      );
      setState(() {});
    });
    NewsArticle.fetchAll().then((news) {
      _news = news;
      setState(() {});
    });
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
            _reload();
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
                  _grades.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : SizedBox(
                          child: Column(
                            children: _grades
                                .map((twoGrades) => Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SingleGradeView(twoGrades[0]),
                                        if (twoGrades.length > 1)
                                          SingleGradeView(twoGrades[1])
                                      ],
                                    ))
                                .toList(),
                          ),
                        ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16.0, 16, 16, 20),
                    child: Text(
                      'Travail à faire',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  _homework.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Column(
                          children: _homework
                              .map(
                                (homework) => ExerciceView(
                                  homework.key,
                                  homework.value,
                                  showDate: true,
                                  showSubject: true,
                                ),
                              )
                              .toList(),
                        ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Actualités',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  _news.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _news
                              .map((article) => ArticlePreview(article))
                              .toList(),
                        ),
                ],
              ),
            ),
          ),
        ));
  }
}

class ArticleView extends StatelessWidget {
  const ArticleView(this._article, {Key? key}) : super(key: key);
  final NewsArticle _article;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: Text(_article.title),
              floating: true,
              forceElevated: innerBoxIsScrolled,
            )
          ];
        },
        body: Scrollbar(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Html(data: _article.htmlContent),
            ),
          ),
        ),
      ),
    );
  }
}

class ArticlePreview extends StatelessWidget {
  final NewsArticle _article;
  final GlobalKey _key = GlobalKey();
  ArticlePreview(this._article, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      key: _key,
      margin: const EdgeInsets.all(8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: (() {
          Navigator.of(context).push(MorpheusPageRoute(
              builder: (_) => ArticleView(_article), parentKey: _key));
        }),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _article.author,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(Global.dateToString(_article.date))
                ],
              ),
              Text(
                _article.title,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SingleGradeView extends StatelessWidget {
  final Grade _grade;

  const SingleGradeView(this._grade, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Lesson.fromSubject(_grade.subject),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      _grade.subject,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      Global.dateToString(_grade.date),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: SizedBox(
                      width: 50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _grade.grade.toString().replaceAll('.', ','),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const Divider(height: 10),
                          Text(_grade.of.toInt().toString())
                        ],
                      ),
                    ),
                  )),
            ],
          )),
    );
  }
}
