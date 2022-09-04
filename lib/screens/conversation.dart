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
import 'package:flutter_html/flutter_html.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:kosmos_client/api/client.dart';
import 'package:kosmos_client/api/conversation.dart';
import 'package:kosmos_client/api/database_manager.dart';
import 'package:kosmos_client/global.dart';
import 'package:url_launcher/url_launcher.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({Key? key}) : super(key: key);

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  Conversation? _conversation;
  final TextEditingController _textFieldController = TextEditingController();
  bool _busy = false;
  bool _showReply = false;
  _ConversationPageState() {
    Conversation.byID(Global.currentConversation!).then((conversation) {
      if (!conversation!.read) {
        Global.client!.markConversationRead(conversation);
        Global.messagesState!.reloadFromDB();
      }
      if (!mounted) return;
      setState(() {
        _conversation = conversation;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Global.theme!.colorScheme.background,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            Expanded(
              child: NestedScrollView(
                floatHeaderSlivers: true,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      title: Text(_conversation != null
                          ? _conversation!.subject
                          : Global.currentConversationSubject!),
                      floating: true,
                    ),
                  ];
                },
                body: ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    if (_conversation == null || index >= _conversation!.messages.length) {
                      return _conversation != null && _conversation!.canReply
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: OutlinedButton(
                                  onPressed: () {
                                    _showReply = true;
                                    setState(() {});
                                  },
                                  child: const Text('Répondre à tous')),
                            )
                          : const Text('');
                    }
                    final parentKey = GlobalKey();
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          key: parentKey,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _conversation!.messages[index].author,
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Text(Global.dateToString(_conversation!.messages[index].date)),
                              ],
                            ),
                            Html(
                              data: HtmlUnescape()
                                  .convert(_conversation!.messages[index].htmlContent),
                              style: {
                                'blockquote': Style(
                                  border: Border(
                                      left: BorderSide(
                                          color: Theme.of(context).colorScheme.secondary,
                                          width: 2)),
                                  padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                                  margin: EdgeInsets.zero,
                                  fontStyle: FontStyle.italic,
                                )
                              },
                              onLinkTap: (url, context, map, element) {
                                launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication);
                              },
                            ),
                            if (_conversation!.messages[index].attachments.isNotEmpty)
                              Global.defaultCard(
                                elevation: 3,
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
                                    ..._conversation!.messages[index].attachments.map(
                                      (attachment) => Row(
                                        children: [Text(attachment.name)],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  itemCount: (_conversation != null ? _conversation!.messages.length : 0) +
                      (_showReply ? 0 : 1),
                ),
              ),
            ),
            if (_showReply)
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Card(
                    margin: const EdgeInsets.all(8.0),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Répondre à tous',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextField(
                              autofocus: true,
                              maxLines: null,
                              controller: _textFieldController,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    _showReply = false;
                                    setState(() {});
                                  },
                                  child: const Text('Fermer'),
                                ),
                                OutlinedButton(
                                  onPressed: _busy
                                      ? null
                                      : () async {
                                          _busy = true;
                                          setState(() {});
                                          try {
                                            await Global.client!.request(Action.reply,
                                                params: [_conversation!.id.toString()],
                                                body:
                                                    '{"dateEnvoi":0,"corpsMessage": "${_textFieldController.text.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '<br/>')}"}');
                                            _textFieldController.clear();
                                            final batch = Global.db!.batch();
                                            await DatabaseManager.fetchSingleConversation(
                                                _conversation!.id, batch);
                                            await Global.client!.process();
                                            await batch.commit();
                                            await Conversation.byID(_conversation!.id)
                                                .then((conversation) {
                                              if (!mounted) return;
                                              setState(() {
                                                _busy = false;
                                                _showReply = false;
                                                _conversation = conversation;
                                              });
                                            });
                                          } on Exception catch (e, st) {
                                            Global.onException(e, st);
                                          }
                                        },
                                  child: _busy
                                      ? Transform.scale(
                                          scale: .7,
                                          child: const CircularProgressIndicator(),
                                        )
                                      : const Text('Envoyer'),
                                ),
                              ],
                            ),
                          ]),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
