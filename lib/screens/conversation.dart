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
import 'package:kosmos_client/api/downloader.dart';
import 'package:kosmos_client/database_provider.dart';
import 'package:kosmos_client/screens/messages.dart';
import 'package:kosmos_client/util.dart';
import 'package:kosmos_client/widgets/attachments_widget.dart';
import 'package:kosmos_client/widgets/default_activity.dart';
import 'package:kosmos_client/widgets/default_transition.dart';
import 'package:url_launcher/url_launcher.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage(
      {Key? key, required this.onDelete, required this.id, required this.subject})
      : super(key: key);

  @override
  State<ConversationPage> createState() => _ConversationPageState();

  final Function onDelete;
  final int id;
  final String subject;
}

class _ConversationPageState extends State<ConversationPage> {
  Conversation? _conversation;
  final TextEditingController _textFieldController = TextEditingController();
  bool _busy = false;
  bool _showReply = false;
  bool _transitionDone = false;

  @override
  void initState() {
    super.initState();
    Conversation.byID(widget.id).then((conversation) {
      if (!conversation!.read) {
        Client.getClient().markConversationRead(conversation);
        MessagesPageState.currentState?.reloadFromDB();
      }
      if (!mounted) return;
      _conversation = conversation;
      delayTransitionDone();
    });
  }

  delayTransitionDone() {
    setState(() {
      _transitionDone = false;
    });
    Future.delayed(const Duration(milliseconds: 400)).then((_) {
      _transitionDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultActivity(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            Expanded(
              child: NestedScrollView(
                floatHeaderSlivers: true,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      actions: [
                        IconButton(
                            tooltip: 'Supprimer la conversation',
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await widget.onDelete(_conversation);
                            },
                            icon: const Icon(Icons.delete))
                      ],
                      floating: true,
                    ),
                  ];
                },
                body: Scrollbar(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: ListView.builder(
                      itemCount: (_conversation != null ? _conversation!.messages.length : 0) +
                          (_showReply ? 1 : 2),
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            child: Text(
                              _conversation != null ? _conversation!.subject : widget.subject,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          );
                        }
                        index -= 1;
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
                        return DefaultTransition(
                          key: GlobalKey(),
                          duration:
                              _transitionDone ? Duration.zero : const Duration(milliseconds: 200),
                          delay: Duration(milliseconds: _transitionDone ? 0 : 30 * index),
                          child: Card(
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
                                          _conversation!.messages[index].author,
                                          textAlign: TextAlign.left,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Text(
                                        Util.dateToString(_conversation!.messages[index].date),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Html(
                                    data: HtmlUnescape()
                                        .convert(_conversation!.messages[index].htmlContent),
                                    style: {
                                      'body':
                                          Style(margin: Margins.all(0), padding: EdgeInsets.zero),
                                      'blockquote': Style(
                                        border: Border(
                                            left: BorderSide(
                                                color: Theme.of(context).colorScheme.secondary,
                                                width: 2)),
                                        padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                                        margin: Margins.all(0),
                                        fontStyle: FontStyle.italic,
                                      )
                                    },
                                    onLinkTap: (url, context, map, element) {
                                      launchUrl(Uri.parse(url!),
                                          mode: LaunchMode.externalApplication);
                                    },
                                  ),
                                  if (_conversation!.messages[index].attachments.isNotEmpty)
                                    AttachmentsWidget(
                                      attachments: _conversation!.messages[index].attachments,
                                      elevation: 3,
                                    )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
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
                                            await Client.getClient().request(Action.reply,
                                                params: [_conversation!.id.toString()],
                                                body:
                                                    '{"dateEnvoi":0,"corpsMessage": "${_textFieldController.text.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '<br/>')}"}');
                                            _textFieldController.clear();
                                            final batch = (await DatabaseProvider.getDB()).batch();
                                            await Downloader.clearConversation(_conversation!.id);
                                            await Downloader.fetchSingleConversation(
                                                _conversation!.id, batch);
                                            await Client.getClient().process();
                                            //There is no need to commit the batch since it is already commited in the callback of fetchSingleConversation.
                                            //Committing the batch twice would duplicate all the messages.
                                            await Conversation.byID(_conversation!.id)
                                                .then((conversation) {
                                              if (!mounted) return;
                                              setState(() {
                                                _busy = false;
                                                _showReply = false;
                                                _conversation = conversation;
                                              });
                                            });
                                            MessagesPageState.currentState!.reloadFromDB();
                                          } on Exception catch (e, st) {
                                            setState(() {
                                              _busy = false;
                                            });
                                            Util.onException(e, st);
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
