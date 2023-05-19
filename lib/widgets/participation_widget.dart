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
import 'package:flutter_html/flutter_html.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:klient/api/color_provider.dart';
import 'package:klient/util.dart';
import 'package:klient/widgets/attachments_widget.dart';
import 'package:klient/widgets/custom_html.dart';
import 'package:klient/widgets/default_transition.dart';
import 'package:scolengo_api/scolengo_api.dart';

class ParticipationCard extends StatelessWidget {
  const ParticipationCard({
    super.key,
    required bool transitionDone,
    required this.parentKey,
    required this.participation,
    required this.index,
  }) : _transitionDone = transitionDone;

  final bool _transitionDone;
  final GlobalKey<State<StatefulWidget>> parentKey;
  final Participation participation;
  final int index;

  @override
  Widget build(BuildContext context) {
    final MaterialColor? color =
        participation.sender?.person?.id.color ?? participation.sender?.technicalUser?.id.color;
    return DefaultTransition(
      key: GlobalKey(),
      duration: _transitionDone ? Duration.zero : const Duration(milliseconds: 200),
      delay: Duration(milliseconds: _transitionDone ? 0 : 30 * index),
      child: Card(
        //surfaceTintColor: color,
        //shadowColor: color,
        margin: const EdgeInsets.all(8.0),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            key: parentKey,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      participation.sender!.name,
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.light
                              ? color
                              : color?.shade200,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    participation.dateTime.format(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.light
                          ? color
                          : color?.shade200,
                    ),
                  ),
                ],
              ),
              CustomHtml(
                data: HtmlUnescape().convert(participation.content),
                style: {
                  'body': Style(margin: Margins.all(0), padding: EdgeInsets.zero),
                  'blockquote': Style(
                    border: Border(
                        left: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2)),
                    padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                    margin: Margins.all(0),
                    fontStyle: FontStyle.italic,
                  )
                },
              ),
              if (participation.attachments != null)
                AttachmentsWidget(
                  attachments: participation.attachments!,
                  elevation: 3,
                  //color: color,
                )
            ],
          ),
        ),
      ),
    );
  }
}
