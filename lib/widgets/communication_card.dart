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

import 'package:flutter/material.dart' hide Action;
import 'package:html_unescape/html_unescape.dart';
import 'package:klient/util.dart';
import 'package:scolengo_api/scolengo_api.dart';

class CommunicationCard extends StatelessWidget {
  final Communication _communication;

  const CommunicationCard(this._communication, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(0, 3),
          child: Container(
            width: _communication.read! ? 0 : 8,
            height: _communication.read! ? 0 : 8,
            margin: _communication.read!
                ? const EdgeInsets.all(0)
                : const EdgeInsets.fromLTRB(0, 5, 5, 0),
            decoration: BoxDecoration(
                color: _communication.read!
                    ? Colors.transparent
                    : Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      HtmlUnescape().convert(_communication.recipientsSummary ?? '').innerText,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _communication.lastParticipation!.dateTime.format(),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: _communication.read! ? FontWeight.normal : FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
              Row(
                //FIXME replace the commented out code
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      _communication.subject,
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: _communication.read! ? FontWeight.normal : FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                  /*

                  if (_communication.hasAttachment)
                    Transform.scale(
                      scale: .7,
                      child: const Icon(Icons.attach_file),
                    ),
                    */
                ],
              ),
              /* _communication.customPreview ??*/
              Text(
                HtmlUnescape().convert(_communication.lastParticipation!.content).innerText,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.secondary,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
