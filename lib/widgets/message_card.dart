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

import 'package:flutter/material.dart' hide Action;
import 'package:html_unescape/html_unescape.dart';
import 'package:kosmos_client/api/conversation.dart';

import '../global.dart';

class MessageCard extends StatelessWidget {
  final Conversation _conversation;

  const MessageCard(this._conversation, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(0, 3),
          child: Container(
            width: _conversation.read ? 0 : 8,
            height: _conversation.read ? 0 : 8,
            margin: _conversation.read
                ? const EdgeInsets.all(0)
                : const EdgeInsets.fromLTRB(0, 5, 5, 0),
            decoration: BoxDecoration(
                color:
                    _conversation.read ? Colors.transparent : Theme.of(context).colorScheme.primary,
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
                      _conversation.firstAuthor +
                          (_conversation.lastAuthor != _conversation.firstAuthor
                              ? ', ${_conversation.lastAuthor}'
                              : ''),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _conversation.read ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    Global.dateToString(_conversation.lastDate),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: _conversation.read ? FontWeight.normal : FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: _conversation.customSubject ??
                        Text(
                          _conversation.subject,
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: _conversation.read ? FontWeight.normal : FontWeight.bold,
                              fontSize: 14),
                        ),
                  ),
                  if (_conversation.hasAttachment)
                    Transform.scale(
                      scale: .7,
                      child: const Icon(Icons.attach_file),
                    ),
                ],
              ),
              _conversation.customPreview ??
                  Text(
                    HtmlUnescape().convert(_conversation.preview),
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.secondary),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
