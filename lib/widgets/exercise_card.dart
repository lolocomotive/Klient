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

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:intl/intl.dart';
import 'package:klient/api/color_provider.dart';
import 'package:klient/util.dart';
import 'package:klient/widgets/attachments_widget.dart';
import 'package:klient/widgets/custom_html.dart';
import 'package:klient/widgets/default_card.dart';
import 'package:scolengo_api/scolengo_api.dart';

class HomeworkCard extends StatefulWidget {
  final Function? onMarkedDone;

  const HomeworkCard(this._hw,
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
  final HomeworkAssignment _hw;
  final double elevation;

  @override
  State<HomeworkCard> createState() => _HomeworkCardState();
}

class _HomeworkCardState extends State<HomeworkCard> {
  @override
  Widget build(BuildContext context) {
    final tint = Theme.of(context).brightness == Brightness.light
        ? widget._hw.subject!.id.color
        : widget._hw.subject!.id.color.shade100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showDate)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
            child: Text(
              '${widget.showSubject ? '${widget._hw.subject?.label}: ' : ''}'
              'À faire pour ${DateFormat('EEEE${widget._hw.dueDateTime.date().millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch > 604800000 ? ' dd / MM ' : ''}'
                  ' - HH:mm', 'FR_fr').format(widget._hw.dueDateTime.date())}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        Card(
          surfaceTintColor: tint,
          shadowColor: Theme.of(context).brightness == Brightness.light
              ? widget._hw.subject!.id.color
              : widget._hw.subject!.id.color.shade200.withAlpha(100),
          margin: const EdgeInsets.all(8.0),
          clipBehavior: Clip.antiAlias,
          elevation: widget.elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            decoration: widget.compact
                ? BoxDecoration(
                    border: Border(
                      left: BorderSide(color: widget._hw.subject!.id.color.shade200, width: 6),
                    ),
                  )
                : null,
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: widget._hw.subject!.id.color.shade200.withAlpha(50),
              ),
              // The whole container is colored and the content overrides the color.
              // This is a workaround because expandable doesn't allow to set the header/icon background color
              child: Container(
                color: widget.compact ? null : widget._hw.subject!.id.color.shade200,
                child: ExpandablePanel(
                  theme: ExpandableThemeData(
                    crossFadePoint: .3,
                    iconPadding: widget.compact ? const EdgeInsets.only(right: 4, top: 2) : null,
                    iconColor:
                        widget.compact ? widget._hw.subject!.id.color.shade200 : Colors.black,
                    headerAlignment: ExpandablePanelHeaderAlignment.center,
                  ),
                  builder: (context, collapsed, expanded) {
                    return Container(
                      color: ElevationOverlay.applySurfaceTint(
                          Theme.of(context).colorScheme.surface, tint, widget.elevation),
                      child: Expandable(
                        collapsed: collapsed,
                        expanded: expanded,
                        theme: const ExpandableThemeData(
                          useInkWell: false,
                        ),
                      ),
                    );
                  },
                  header: Container(
                    padding: widget.compact
                        ? const EdgeInsets.fromLTRB(8, 4, 8, 0)
                        : const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: widget.compact
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.spaceAround,
                            children: [
                              Flexible(
                                child: Text(
                                  widget._hw.title + (widget.compact ? ' - ' : ''),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: widget.compact ? null : Colors.black,
                                    fontSize: MediaQuery.of(context).textScaleFactor * 12,
                                  ),
                                ),
                              ),
                              Text(widget._hw.done ? 'Fait' : 'À faire',
                                  style: TextStyle(
                                    color: widget.compact ? null : Colors.black,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  collapsed: _CardContents(
                    widget: widget,
                    onMarkedDone: onMarkedDone,
                    tint: tint,
                  ),
                  expanded: _CardContents(
                    widget: widget,
                    expanded: true,
                    onMarkedDone: onMarkedDone,
                    tint: tint,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  onMarkedDone(bool done) {
    widget._hw.done = done;
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

  final Color tint;

  const _CardContents({
    Key? key,
    required this.widget,
    required this.onMarkedDone,
    this.expanded = false,
    required this.tint,
  }) : super(key: key);

  final HomeworkCard widget;

  @override
  State<_CardContents> createState() => _CardContentsState();

  final Function onMarkedDone;
}

class _CardContentsState extends State<_CardContents> {
  final bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final bool online =
        RegExp('<p.*?#FFB622.*?Ce travail à faire est à remettre directement en ligne.*<\\/p>')
            .hasMatch(widget.widget._hw.html);
    return ExpandableButton(
      theme: const ExpandableThemeData(useInkWell: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: widget.widget.compact ? EdgeInsets.zero : const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                online
                    ? const OnlineWarning()
                    : widget.widget._hw.html == ''
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8.0),
                            child: Text(
                              'Aucun contenu renseigné',
                              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : CustomHtml(
                            data: widget.widget._hw.html.substringWords(
                                    widget.expanded
                                        ? widget.widget._hw.html.length
                                        : min(
                                            _CardContents.cutLength, widget.widget._hw.html.length),
                                    _CardContents.cutThreshold) +
                                (widget.expanded ||
                                        widget.widget._hw.html.length <= _CardContents.cutThreshold
                                    ? ''
                                    : '...'),
                          ),
                if (widget.widget._hw.attachments != null && widget.expanded)
                  AttachmentsWidget(
                    attachments: widget.widget._hw.attachments!,
                    elevation: widget.widget.elevation * 2,
                  ),
                if (!online &&
                    !widget.expanded &&
                    (widget.widget._hw.attachments != null ||
                        widget.widget._hw.html.length > _CardContents.cutThreshold))
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
                if (!online && widget.expanded)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () async {
                                //TODO implement with new API
                                /*
                                setState(() {
                                  _busy = true;
                                });
                                if (ConfigProvider.demo) {
                                  await (await DatabaseProvider.getDB()).update(
                                    'Exercises',
                                    {'Done': !widget.widget._hw.done ? 1 : 0},
                                    where: 'ID = ?',
                                    whereArgs: [widget.widget._hw.uid],
                                  );
      
                                  setState(() {
                                    widget.widget._hw.done = !widget.widget._hw.done;
                                    widget.onMarkedDone(widget.widget._hw.done);
                                    _busy = false;
                                  });
                                } else {
                                  final response = await Client.getClient().request(
                                      Action.markExerciseDone,
                                      body: '{"flagRealise":${!widget.widget._hw.done}}',
                                      params: [
                                        '0',
                                        (widget.widget._hw.parentLesson ??
                                                widget.widget._hw.lessonFor)
                                            .toString(),
                                        widget.widget._hw.uid.toString()
                                      ]);
                                  await (await DatabaseProvider.getDB()).update(
                                    'Exercises',
                                    {'Done': response['flagRealise'] ? 1 : 0},
                                    where: 'ID = ?',
                                    whereArgs: [widget.widget._hw.uid],
                                  );
      
                                  setState(() {
                                    widget.widget._hw.done = response['flagRealise'];
                                    widget.onMarkedDone(response['flagRealise']);
                                    _busy = false;
                                  });  
                                }
                                */
                              },
                        child: Text('Marquer comme ${widget.widget._hw.done ? "à faire" : "fait"}'),
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
