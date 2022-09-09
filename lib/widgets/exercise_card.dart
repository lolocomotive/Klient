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

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:kosmos_client/api/exercise.dart';
import 'package:kosmos_client/api/lesson.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global.dart';

class ExerciceCard extends StatefulWidget {
  const ExerciceCard(this._exercise, this._lesson,
      {Key? key, this.showDate = false, this.showSubject = false, this.elevation = 3})
      : super(key: key);
  final bool showDate;
  final bool showSubject;
  final Exercise _exercise;
  final Lesson _lesson;
  final double elevation;

  @override
  State<ExerciceCard> createState() => _ExerciceCardState();
}

class _ExerciceCardState extends State<ExerciceCard> {
  final bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showDate)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
            child: Text(
              '${widget.showSubject ? '${widget._lesson.title}: ' : ''}À faire pour le ${DateFormat('dd/MM - HH:mm').format(widget._exercise.dateFor!)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        Card(
          margin: const EdgeInsets.all(8.0),
          clipBehavior: Clip.antiAlias,
          elevation: widget.elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpandableNotifier(
            child: Expandable(
              collapsed: _CardContents(widget: widget),
              expanded: _CardContents(widget: widget, expanded: true),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardContents extends StatelessWidget {
  final bool expanded;
  static const cutLength = 100;
  const _CardContents({
    Key? key,
    required this.widget,
    this.expanded = false,
  }) : super(key: key);

  final ExerciceCard widget;

  @override
  Widget build(BuildContext context) {
    return ExpandableButton(
      theme: const ExpandableThemeData(useInkWell: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: widget._lesson.color,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Flexible(
                        child: Text(
                          widget._exercise.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(widget._exercise.done ? 'Fait' : 'À faire'),
                    ],
                  ),
                ),
                if (widget._exercise.type == ExerciseType.exercise ||
                    widget._exercise.htmlContent.length > cutLength ||
                    widget._exercise.attachments.isNotEmpty)
                  Icon(expanded ? Icons.expand_less : Icons.expand_more)
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                widget._exercise.htmlContent == ''
                    ? Text(
                        'Aucun contenu renseigné',
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                        textAlign: TextAlign.center,
                      )
                    : Html(
                        data: widget._exercise.htmlContent.substringWords(expanded
                                ? widget._exercise.htmlContent.length
                                : min(cutLength, widget._exercise.htmlContent.length)) +
                            (expanded || widget._exercise.htmlContent.length <= cutLength
                                ? ''
                                : '...'),
                        onLinkTap: (url, context, map, element) {
                          launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication);
                        },
                      ),
                if (widget._exercise.attachments.isNotEmpty && expanded)
                  Global.defaultCard(
                    elevation: widget.elevation * 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Flexible(
                          child: Text(
                            'Pièces jointes',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...widget._exercise.attachments.map((attachment) => Row(
                              children: [Text(attachment.name)],
                            ))
                      ],
                    ),
                  ),
                if (!expanded &&
                    (widget._exercise.attachments.isNotEmpty ||
                        widget._exercise.htmlContent.length > cutLength))
                  ExpandableButton(
                    theme: const ExpandableThemeData(useInkWell: false),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Voir plus',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (expanded && widget._exercise.type == ExerciseType.exercise)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          //TODO
                        },
                        child: const Text('Marquer comme fait'),
                      ),
                    ],
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension WordSubstring on String {
  String substringWords(int maxLetters) {
    String r = '';
    int count = 0;
    for (String word in split(' ')) {
      count += word.length;
      if (count > maxLetters) break;
      r += '$word ';
    }
    return r;
  }
}
