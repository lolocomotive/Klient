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
import 'package:intl/intl.dart';
import 'package:kosmos_client/api/exercise.dart';
import 'package:kosmos_client/api/lesson.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global.dart';

class ExerciceCard extends StatelessWidget {
  const ExerciceCard(this._exercise, this._lesson,
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
          elevation: 3,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _exercise.htmlContent == ''
                        ? Text(
                            'Aucun contenu renseigné',
                            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                            textAlign: TextAlign.center,
                          )
                        : Html(
                            data: _exercise.htmlContent,
                            onLinkTap: (url, context, map, element) {
                              launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication);
                            },
                          ),
                    if (_exercise.attachments.isNotEmpty)
                      Global.defaultCard(
                        elevation: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Pièces jointes',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ..._exercise.attachments.map((attachment) => Row(
                                  children: [Text(attachment.name)],
                                ))
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
