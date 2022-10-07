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
import 'package:flutter/material.dart' hide Action;
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:kosmos_client/api/client.dart';
import 'package:kosmos_client/api/exercise.dart';
import 'package:kosmos_client/api/lesson.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global.dart';

class ExerciseCard extends StatefulWidget {
  final Function? onMarkedDone;

  const ExerciseCard(this._exercise, this._lesson,
      {Key? key,
      this.showDate = false,
      this.showSubject = false,
      this.elevation = 3,
      this.onMarkedDone})
      : super(key: key);
  final bool showDate;
  final bool showSubject;
  final Exercise _exercise;
  final Lesson _lesson;
  final double elevation;

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showDate)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
            child: Text(
              '${widget.showSubject ? '${widget._lesson.title}: ' : ''}'
              'À faire pour ${DateFormat('EEEE${widget._exercise.dateFor!.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch > 604800000 ? ' dd / MM ' : ''}'
                  ' - HH:mm', 'FR_fr').format(widget._exercise.dateFor!)}',
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
              collapsed: _CardContents(
                widget: widget,
                onMarkedDone: onMarkedDone,
              ),
              expanded: _CardContents(
                widget: widget,
                expanded: true,
                onMarkedDone: onMarkedDone,
              ),
            ),
          ),
        ),
      ],
    );
  }

  onMarkedDone(bool done) {
    widget._exercise.done = done;
    setState(() {});
    widget.onMarkedDone?.call(done);
  }
}

class _CardContents extends StatefulWidget {
  final bool expanded;
  //The length of a string after being cut
  static const cutLength = 150;
  //The minimum length starting which strings are going to be cut
  static const cutThreshold = cutLength + 50;

  const _CardContents({
    Key? key,
    required this.widget,
    this.expanded = false,
    required this.onMarkedDone,
  }) : super(key: key);

  final ExerciseCard widget;

  @override
  State<_CardContents> createState() => _CardContentsState();

  final Function onMarkedDone;
}

class _CardContentsState extends State<_CardContents> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return ExpandableButton(
      theme: const ExpandableThemeData(useInkWell: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: widget.widget._lesson.color.shade200,
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
                          widget.widget._exercise.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (widget.widget._exercise.type == ExerciseType.exercise)
                        Text(widget.widget._exercise.done ? 'Fait' : 'À faire',
                            style: const TextStyle(
                              color: Colors.black,
                            )),
                    ],
                  ),
                ),
                if (widget.widget._exercise.type == ExerciseType.exercise ||
                    widget.widget._exercise.htmlContent.length > _CardContents.cutThreshold ||
                    widget.widget._exercise.attachments.isNotEmpty)
                  Icon(
                    widget.expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.black,
                  )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                widget.widget._exercise.htmlContent == ''
                    ? Text(
                        'Aucun contenu renseigné',
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                        textAlign: TextAlign.center,
                      )
                    : Html(
                        data: widget.widget._exercise.htmlContent.substringWords(
                                widget.expanded
                                    ? widget.widget._exercise.htmlContent.length
                                    : min(_CardContents.cutLength,
                                        widget.widget._exercise.htmlContent.length),
                                _CardContents.cutThreshold) +
                            (widget.expanded ||
                                    widget.widget._exercise.htmlContent.length <=
                                        _CardContents.cutThreshold
                                ? ''
                                : '...'),
                        onLinkTap: (url, context, map, element) {
                          launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication);
                        },
                      ),
                if (widget.widget._exercise.attachments.isNotEmpty && widget.expanded)
                  DefaultCard(
                      elevation: widget.widget.elevation * 2,
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
                          ...widget.widget._exercise.attachments.map(
                            (attachment) => Row(
                              children: [Flexible(child: Text(attachment.name))],
                            ),
                          ),
                        ],
                      )),
                if (!widget.expanded &&
                    (widget.widget._exercise.attachments.isNotEmpty ||
                        widget.widget._exercise.htmlContent.length > _CardContents.cutThreshold))
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
                if (widget.expanded && widget.widget._exercise.type == ExerciseType.exercise)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () async {
                                setState(() {
                                  _busy = true;
                                });
                                final response = await Global.client!.request(
                                    Action.markExerciseDone,
                                    body: '{"flagRealise":${!widget.widget._exercise.done}}',
                                    params: [
                                      '0',
                                      widget.widget._lesson.id.toString(),
                                      widget.widget._exercise.uid.toString()
                                    ]);
                                await Global.db!.update(
                                  'Exercises',
                                  {'Done': response['flagRealise'] ? 1 : 0},
                                  where: 'ID = ?',
                                  whereArgs: [widget.widget._exercise.uid],
                                );

                                setState(() {
                                  widget.widget._exercise.done = response['flagRealise'];
                                  widget.onMarkedDone(response['flagRealise']);
                                  _busy = false;
                                });
                              },
                        child: Text(
                            'Marquer comme ${widget.widget._exercise.done ? "à faire" : "fait"}'),
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
  String substringWords(int maxLetters, int threshold) {
    if (length < threshold) return this;
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
