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
import 'package:flutter_html/flutter_html.dart';
import 'package:klient/widgets/default_activity.dart';
import 'package:klient/widgets/default_transition.dart';
import 'package:scolengo_api/scolengo_api.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunicationPage extends StatefulWidget {
  const CommunicationPage(
      {Key? key, required this.onDelete, required this.id, required this.subject})
      : super(key: key);

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();

  final Function onDelete;
  final String id;
  final String subject;
}

class _CommunicationPageState extends State<CommunicationPage> {
  Communication? _communication;
  final TextEditingController _textFieldController = TextEditingController();
  final bool _busy = false;
  bool _showReply = false;
  bool _transitionDone = false;

  @override
  void initState() {
    super.initState();

/* TODO rewrite this
    Conversation.byID(widget.id).then((conversation) {
      if (!conversation!.read) {
        Client.getClient().markConversationRead(conversation);
        MessagesPageState.currentState?.reloadFromDB();
      }
      if (!mounted) return;
      _communication = conversation;
      delayTransitionDone();
    }); */
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
                              await widget.onDelete(_communication);
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
                      itemCount: (_communication != null
                              ? (_communication!.participationsNumber ?? 0).toInt()
                              : 0) +
                          (_showReply ? 1 : 2),
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            child: Text(
                              _communication != null ? _communication!.subject : widget.subject,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          );
                        }
                        index -= 1;
                        if (_communication == null ||
                            index >= _communication!.participationsNumber!) {
                          return _communication != null && _communication!.replyToAllAllowed!
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
                                          /*_communication!.messages[index].author*/ 'Unimplemented', //FIXME
                                          textAlign: TextAlign.left,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Text(
                                        /*Util.dateToString(_communication!.messages[index].date)*/ 'Unimplemented', //FIXME
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Html(
                                    data: /* HtmlUnescape()
                                        .convert(_communication!.messages[index].htmlContent)*/
                                        'Unimplemented', //FIXME
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
                                  /* FIXME
                                 if (_communication!.messages[index].attachments.isNotEmpty)
                                    AttachmentsWidget(
                                      attachments: _communication!.messages[index].attachments,
                                      elevation: 3,
                                    )*/
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
                                          /* TODO rewrite this
                                          _busy = true;
                                          setState(() {});
                                          try {
                                            await Client.getClient().request(Action.reply,
                                                params: [_communication!.id.toString()],
                                                body:
                                                    '{"dateEnvoi":0,"corpsMessage": "${_textFieldController.text.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '<br/>')}"}');
                                            _textFieldController.clear();
                                            final batch = (await DatabaseProvider.getDB()).batch();
                                            await Downloader.clearConversation(_communication!.id);
                                            await Downloader.fetchSingleConversation(
                                                _communication!.id, batch);
                                            await Client.getClient().process();
                                            //There is no need to commit the batch since it is already commited in the callback of fetchSingleConversation.
                                            //Committing the batch twice would duplicate all the messages.
                                            await Conversation.byID(_communication!.id)
                                                .then((conversation) {
                                              if (!mounted) return;
                                              setState(() {
                                                _busy = false;
                                                _showReply = false;
                                                _communication = conversation;
                                              });
                                            });
                                            MessagesPageState.currentState!.reloadFromDB();
                                          } on Exception catch (e, st) {
                                            setState(() {
                                              _busy = false;
                                            });
                                            Util.onException(e, st);
                                          }*/
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
