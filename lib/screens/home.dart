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
import 'package:kosmos_client/kdecole-api/exercise.dart';
import 'package:kosmos_client/kdecole-api/grade.dart';
import 'package:kosmos_client/kdecole-api/lesson.dart';
import 'package:kosmos_client/kdecole-api/news_article.dart';
import 'package:kosmos_client/screens/timetable.dart';

import '../main.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Grade> _grades = [];
  final List<MapEntry<Exercise, Lesson>> _homework = [];
  List<NewsArticle> _news = [];
  _HomeState() {
    Grade.fetchAll().then((grades) => setState(() {
          _grades = grades;
        }));
    Exercise.fetchAll().then((exercises) async {
      for (final exercise in exercises) {
        if (exercise.lessonFor == null) continue;
        if (exercise.dateFor!.isBefore(DateTime.now())) continue;
        _homework
            .add(MapEntry(exercise, (await Lesson.byID(exercise.lessonFor!))!));
      }
      setState(() {});
    });
    NewsArticle.fetchAll().then((news) {
      _news = news;
      setState(() {});
    });
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          AppBar(
            title: const Text('Accueil'),
            actions: [Global.popupMenuButton],
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 24, 16, 8),
            child: Text(
              "Dernières notes",
              style: TextStyle(fontSize: 20),
            ),
          ),
          _grades.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                )
              : SizedBox(
                  height: 100,
                  child: GridView.count(
                    crossAxisCount: 2,
                    children:
                        _grades.map((grade) => SingleGradeView(grade)).toList(),
                  ),
                ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16, 16, 20),
            child: Text(
              "Travail à faire",
              style: TextStyle(fontSize: 20),
            ),
          ),
          _homework.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                )
              : Column(
                  children: _homework
                      .map((homework) => ExerciceView(
                            homework.key,
                            homework.value,
                            showDate: true,
                            showSubject: true,
                          ))
                      .toList(),
                ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Actualités",
              style: TextStyle(fontSize: 20),
            ),
          ),
          _news.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children:
                      _news.map((article) => ArticlePreview(article)).toList(),
                ),
        ],
      ),
    );
  }
}

class ArticlePreview extends StatelessWidget {
  final NewsArticle _article;
  const ArticlePreview(this._article, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(8.0),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          boxShadow: Global.standardShadow,
          color: Colors.white,
        ),
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
    );
  }
}

class SingleGradeView extends StatelessWidget {
  final Grade _grade;

  const SingleGradeView(this._grade, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16, 16, 8),
      child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            boxShadow: Global.standardShadow,
          ),
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
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      Global.dateToString(_grade.date),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child:
                    Text(_grade.grade.toString() + '/' + _grade.of.toString()),
              ),
            ],
          )),
    );
  }
}
