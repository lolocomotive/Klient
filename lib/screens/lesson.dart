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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klient/api/color_provider.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/util.dart';
import 'package:klient/widgets/attachments_widget.dart';
import 'package:klient/widgets/custom_html.dart';
import 'package:klient/widgets/default_activity.dart';
import 'package:klient/widgets/default_card.dart';
import 'package:klient/widgets/default_transition.dart';
import 'package:klient/widgets/delayed_progress_indicator.dart';
import 'package:klient/widgets/exception_widget.dart';
import 'package:klient/widgets/homework_list.dart';
import 'package:scolengo_api/scolengo_api.dart';

class LessonPage extends StatefulWidget {
  final Lesson _lesson;
  const LessonPage(this._lesson, {Key? key}) : super(key: key);

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  Future<SkolengoResponse<Lesson>>? _data;
  @override
  void initState() {
    _data = ConfigProvider.client!
        .getLesson(ConfigProvider.credentials!.idToken.claims.subject, widget._lesson.id);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget._lesson.subject.id.color;
    return DefaultSliverActivity(
      background: ElevationOverlay.applySurfaceTint(
        Theme.of(context).colorScheme.surface,
        color.shade200,
        .5,
      ),
      title: widget._lesson.title,
      titleColor: Colors.black,
      titleBackground: color.shade200,
      leading: const BackButton(color: Colors.black),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            children: [
              DefaultCard(
                surfaceTintColor: color.tint(context),
                shadowColor: color.shadow(context),
                child: Column(
                  children: [
                    Text(
                      'Séance du ${DateFormat('dd/MM').format(widget._lesson.startDateTime.date())} de ${widget._lesson.startDateTime.hm()} à ${widget._lesson.endDateTime.hm()}',
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Salle ${widget._lesson.location}',
                      textAlign: TextAlign.center,
                    ),
                    // TODO new API doesn't have this ?
                    //if (_lesson.isModified) Text(_lesson.modificationMessage!)
                  ],
                ),
              ),
              /* TODO implement lessonContent display
              HomeworkList(
                _lesson.exercises.where((e) => e.type == ExerciseType.lessonContent).toList(),
                'Contenu de la séance',
                color,
              ), */
              FutureBuilder<SkolengoResponse<Lesson>>(
                  future: _data,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return ExceptionWidget(e: snapshot.error!, st: snapshot.stackTrace!);
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                          child: DelayedProgressIndicator(
                        delay: Duration(milliseconds: 300),
                      ));
                    }
                    return DefaultTransition(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HomeworkList(
                            snapshot.data?.data.toDoForTheLesson ?? [],
                            'Travail à faire pour cette séance',
                            color,
                          ),
                          DefaultCard(
                            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                            surfaceTintColor: color.tint(context),
                            shadowColor: color.shadow(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Contenu de la séance',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 16 * MediaQuery.of(context).textScaleFactor),
                                ),
                                ...snapshot.data!.data.contents?.map(
                                      (e) => Card(
                                        elevation: 4,
                                        margin: const EdgeInsets.all(8.0),
                                        clipBehavior: Clip.antiAlias,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        surfaceTintColor: color.tint(context),
                                        shadowColor: color.shadow(context),
                                        child: Container(
                                          decoration: ConfigProvider.compact!
                                              ? BoxDecoration(
                                                  border: Border(
                                                    left: BorderSide(
                                                        color: widget
                                                            ._lesson.subject.id.color.shade200,
                                                        width: 6),
                                                  ),
                                                )
                                              : null,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                color:
                                                    ConfigProvider.compact! ? null : color.shade200,
                                                child: Text(
                                                  e.title,
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: ConfigProvider.compact!
                                                          ? null
                                                          : Colors.black),
                                                ),
                                              ),
                                              CustomHtml(data: e.html),
                                              if (e.attachments != null)
                                                AttachmentsWidget(
                                                  attachments: e.attachments!,
                                                  color: color,
                                                  outlineColor: color.shade200,
                                                  outlined: true,
                                                  elevation: 4,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ) ??
                                    [
                                      Text(
                                        'Aucun contenu renseigné',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      )
                                    ],
                              ],
                            ),
                          ),
                          HomeworkList(
                            snapshot.data?.data.toDoAfterTheLesson ?? [],
                            'Travail donné lors de la séance',
                            color,
                          ),
                        ],
                      ),
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
