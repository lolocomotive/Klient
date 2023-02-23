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
import 'package:kosmos_client/config_provider.dart';
import 'package:kosmos_client/database_provider.dart';
import 'package:kosmos_client/widgets/attachments_widget.dart';
import 'package:kosmos_client/widgets/default_card.dart';
import 'package:url_launcher/url_launcher.dart';

class ExerciseCard extends StatefulWidget {
  final Function? onMarkedDone;

  const ExerciseCard(this._exercise,
      {Key? key,
      this.showDate = false,
      this.compact = false,
      this.showSubject = false,
      this.elevation = 3,
      this.onMarkedDone})
      : super(key: key);
  final bool showDate;
  final bool showSubject;
  final bool compact;
  final Exercise _exercise;
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
              '${widget.showSubject ? '${widget._exercise.subject}: ' : ''}'
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
    required this.onMarkedDone,
    this.expanded = false,
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
    final bool online =
        RegExp('<p.*#FFB622.*Ce travail à faire est à remettre directement en ligne.*<\\/p>')
            .hasMatch(widget.widget._exercise.htmlContent);
    return ExpandableButton(
      theme: const ExpandableThemeData(useInkWell: false),
      child: Container(
        decoration: widget.widget.compact
            ? BoxDecoration(
                border: Border(
                  left: BorderSide(color: widget.widget._exercise.color.shade200, width: 6),
                ),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: widget.widget.compact ? null : widget.widget._exercise.color.shade200,
              padding: widget.widget.compact
                  ? const EdgeInsets.fromLTRB(8, 4, 8, 0)
                  : const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: widget.widget.compact
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.spaceAround,
                      children: [
                        Flexible(
                          child: Text(
                            widget.widget._exercise.title +
                                (widget.widget.compact &&
                                        widget.widget._exercise.type == ExerciseType.exercise
                                    ? ' - '
                                    : ''),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.widget.compact ? null : Colors.black,
                            ),
                          ),
                        ),
                        if (widget.widget._exercise.type == ExerciseType.exercise)
                          Text(widget.widget._exercise.done ? 'Fait' : 'À faire',
                              style: TextStyle(
                                color: widget.widget.compact ? null : Colors.black,
                              )),
                      ],
                    ),
                  ),
                  if (!online &&
                      (widget.widget._exercise.type == ExerciseType.exercise ||
                          widget.widget._exercise.htmlContent.length > _CardContents.cutThreshold ||
                          widget.widget._exercise.attachments.isNotEmpty))
                    Icon(
                      widget.expanded ? Icons.expand_less : Icons.expand_more,
                      color: widget.widget.compact ? null : Colors.black,
                    )
                ],
              ),
            ),
            Padding(
              padding: widget.widget.compact ? EdgeInsets.zero : const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  online
                      ? const OnlineWarning()
                      : widget.widget._exercise.htmlContent == ''
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8.0),
                              child: Text(
                                'Aucun contenu renseigné',
                                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                                textAlign: TextAlign.center,
                              ),
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
                    AttachmentsWidget(
                      attachments: widget.widget._exercise.attachments,
                      elevation: widget.widget.elevation * 2,
                    ),
                  if (!online &&
                      !widget.expanded &&
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
                  if (!online &&
                      widget.expanded &&
                      widget.widget._exercise.type == ExerciseType.exercise)
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
                                  if (ConfigProvider.demo) {
                                    await (await DatabaseProvider.getDB()).update(
                                      'Exercises',
                                      {'Done': !widget.widget._exercise.done ? 1 : 0},
                                      where: 'ID = ?',
                                      whereArgs: [widget.widget._exercise.uid],
                                    );

                                    setState(() {
                                      widget.widget._exercise.done = !widget.widget._exercise.done;
                                      widget.onMarkedDone(widget.widget._exercise.done);
                                      _busy = false;
                                    });
                                  } else {
                                    final response = await Client.getClient().request(
                                        Action.markExerciseDone,
                                        body: '{"flagRealise":${!widget.widget._exercise.done}}',
                                        params: [
                                          '0',
                                          widget.widget._exercise.parentLesson.toString(),
                                          widget.widget._exercise.uid.toString()
                                        ]);
                                    await (await DatabaseProvider.getDB()).update(
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
                                  }
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
      ),
    );
  }
}

class OnlineWarning extends StatelessWidget {
  const OnlineWarning({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const DefaultCard(
      elevation: 4,
      child: Text(
          'Ce travail à faire est à remettre directement en ligne. Le statut se mettra à jour automatiquement dès que vous aurez déposé ou retiré le fichier sur l\'ENT.'),
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
