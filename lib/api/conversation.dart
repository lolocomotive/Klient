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

import 'package:flutter/material.dart';
import 'package:kosmos_client/api/message_attachment.dart';
import 'package:kosmos_client/database_provider.dart';
import 'package:kosmos_client/main.dart';

import 'message.dart';

class Conversation {
  int id;
  String subject;
  String preview;
  bool hasAttachment;
  DateTime lastDate;
  List<Message> messages;
  String lastAuthor;
  String firstAuthor;
  bool read;
  bool canReply;
  bool notificationShown;
  Widget? customPreview;
  Widget? customSubject;

  Conversation(
    this.id,
    this.subject,
    this.preview,
    this.hasAttachment,
    this.lastDate,
    this.messages,
    this.read,
    this.notificationShown,
    this.lastAuthor,
    this.firstAuthor,
    this.canReply, [
    this.customPreview,
    this.customSubject,
  ]);

  /// DOES NOT return messages
  static Future<List<Conversation>> fetchAll({int? offset, int? limit}) async {
    final List<Conversation> conversations = [];
    final results = await (await DatabaseProvider.getDB()).query(
      'Conversations',
      limit: limit,
      offset: offset,
      orderBy: 'LastDate DESC',
    );

    for (final result in results) {
      List<Message> messages = [];
      conversations.add(
        Conversation(
          result['ID'] as int,
          result['Subject'] as String,
          result['Preview'] as String,
          result['HasAttachment'] as int == 1,
          DateTime.fromMillisecondsSinceEpoch((result['LastDate'] as int)),
          messages,
          result['Read'] as int == 1,
          result['NotificationShown'] as int == 1,
          result['LastAuthor'] as String,
          result['FirstAuthor'] as String,
          result['CanReply'] as int == 1,
        ),
      );
    }

    return conversations;
  }

  static Widget highlight(String query, String content,
      {Color? color, Color? background, double? fontSize}) {
    //Using regex te replace all matches with a marker and split by a marker
    //because dart doesn't allow to split ignoring case
    //Using <!-- REPLACE ME --> because all HTML has been removed
    const String magic = '<!-- REPLACE ME -->';
    List<String> split =
        content.replaceAll(RegExp(RegExp.escape(query), caseSensitive: false), magic).split(magic);

    //Can't use query here because we want to keep the original case
    List<String> replaceWith = RegExp(RegExp.escape(query), caseSensitive: false)
        .allMatches(content)
        .map((e) => e.group(0)!)
        .toList();
    List<InlineSpan> children = [];
    for (int i = 0; i < split.length; i++) {
      if (i == split.length - 1) break;
      children.add(TextSpan(
          text: split[i].length > 75
              ? '...${split[i].substring(max(split[i].length - 75, 0))}'
              : i == 0
                  ? split[i]
                  : ''));
      children.add(TextSpan(
          text: replaceWith[i],
          style: TextStyle(backgroundColor: background ?? KosmosApp.theme!.highlightColor)));
      children.add(TextSpan(
          text: split[i + 1].substring(0, min(75, split[i + 1].length)) +
              (split[i + 1].length > 75 ? '...\n' : '')));
    }
    return RichText(
      text: TextSpan(
        children: children,
        style: TextStyle(color: color ?? Colors.black45, fontSize: fontSize),
      ),
    );
  }

  static Future<List<Conversation>> search(String query, {int? offset, int? limit}) async {
    final List<Conversation> conversations = [];
    String likeClause =
        "(upper(Subject) like upper('%$query%')) or (FullMessageContents like upper('%$query%'))";
    String orderClause = 'LastDate desc';
    final results = await (await DatabaseProvider.getDB()).query('Conversations',
        where: likeClause, orderBy: orderClause, limit: limit, offset: offset);

    for (final result in results) {
      List<Message> messages = [];
      String fullMessageContents = result['FullMessageContents'] as String;

      //TODO separate individual messages from each other

      conversations.add(
        Conversation(
          result['ID'] as int,
          result['Subject'] as String,
          result['Preview'] as String,
          result['HasAttachment'] as int == 1,
          DateTime.fromMillisecondsSinceEpoch((result['LastDate'] as int)),
          messages,
          result['Read'] as int == 1,
          result['NotificationShown'] as int == 1,
          result['LastAuthor'] as String,
          result['FirstAuthor'] as String,
          result['CanReply'] as int == 1,
          fullMessageContents.toUpperCase().contains(query.toUpperCase())
              ? highlight(query, fullMessageContents, color: KosmosApp.theme!.colorScheme.secondary)
              : null,
          (result['Subject'] as String).toUpperCase().contains(query.toUpperCase())
              ? highlight(query, result['Subject'] as String,
                  color: KosmosApp.theme!.colorScheme.secondary, fontSize: 14)
              : null,
        ),
      );
    }
    return conversations;
  }

  static Future<Conversation?> byID(int id) async {
    try {
      final results = (await (await DatabaseProvider.getDB()).rawQuery('''SELECT 
          Conversations.ID as ConversationID,
          Messages.ID as MessageID,
          MessageAttachments.ID AS MessageAttachmentID,
          Messages.ParentID as MessageParentID,
          MessageAttachments.ParentID as MessageAttachmentParentID,
          * FROM Conversations
          LEFT JOIN Messages ON Conversations.ID = Messages.ParentID
          LEFT JOIN MessageAttachments ON Messages.ID = MessageAttachments.ParentID
          WHERE Conversations.ID = $id 
          ORDER BY Messages.DateSent;'''
          'Conversations'));
      List<Message> messages = [];
      Message? message;
      for (final result in results) {
        if (message == null || result['MessageID'] != message.id) {
          message = Message.parse(result);
        }
        if (result['MessageAttachmentID'] != null) {
          message.attachments.add(MessageAttachment.parse(result));
        }
        messages.add(message);
      }

      final result = results[0];
      return Conversation(
        result['ConversationID'] as int,
        result['Subject'] as String,
        result['Preview'] as String,
        result['HasAttachment'] as int == 1,
        DateTime.fromMillisecondsSinceEpoch((result['LastDate'] as int)),
        messages,
        result['Read'] as int == 1,
        result['NotificationShown'] as int == 1,
        result['LastAuthor'] as String,
        result['FirstAuthor'] as String,
        result['CanReply'] as int == 1,
      );
    } catch (e, st) {
      print(e);
      print(st);
      return null;
    }
  }

  static Future<int> unreadCount() async {
    final results =
        await (await DatabaseProvider.getDB()).query('Conversations', where: 'Read = 0');
    return results.length;
  }
}
