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
import 'package:kosmos_client/kdecole-api/client.dart';
import 'package:kosmos_client/kdecole-api/conversation.dart';
import 'package:kosmos_client/kdecole-api/database_manager.dart';
import 'package:morpheus/morpheus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global.dart';

class MessagePreview extends StatelessWidget {
  final Conversation _conversation;
  final GlobalKey? _parentKey;

  const MessagePreview(this._conversation, this._parentKey, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _conversation.read ? 0 : 8,
          height: _conversation.read ? 0 : 8,
          margin:
              _conversation.read ? const EdgeInsets.all(0) : const EdgeInsets.fromLTRB(0, 5, 5, 0),
          decoration: BoxDecoration(
              color: _conversation.read ? Colors.transparent : Colors.blue, shape: BoxShape.circle),
        ),
        Expanded(
          child: Column(
            key: _parentKey,
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
              _conversation.customSubject ??
                  Text(
                    _conversation.subject,
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: _conversation.read ? FontWeight.normal : FontWeight.bold,
                        fontSize: 14),
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

class Messages extends StatefulWidget {
  const Messages({Key? key}) : super(key: key);

  @override
  State<Messages> createState() => MessagesState();
}

class MessagesState extends State<Messages> {
  final GlobalKey<MessagesState> key = GlobalKey();

  static void openConversation(
      BuildContext context, GlobalKey? parentKey, int conversationId, String conversationSubject) {
    Global.currentConversation = conversationId;
    Global.currentConversationSubject = conversationSubject;
    Navigator.of(context).push(
      MorpheusPageRoute(
        builder: (_) => const ConversationView(),
        parentKey: parentKey,
      ),
    );
  }

  reloadFromDB() {
    Conversation.fetchAll().then((conversations) {
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
      });
    });
  }

  refresh() async {
    await DatabaseManager.fetchMessageData();
    await reloadFromDB();
  }

  MessagesState() {
    Global.messagesState = this;
    Conversation.fetchAll().then((conversations) {
      if (conversations.isEmpty) {
        refresh();
        return;
      }
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
      });
    });
  }

  List<Conversation> _conversations = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      child: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (ctx, innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: MessagesSearchDelegate(),
                    );
                  },
                ),
                Global.popupMenuButton
              ],
              title: const Text('Messagerie'),
              floating: true,
              forceElevated: innerBoxIsScrolled,
            )
          ];
        },
        body: RefreshIndicator(
          onRefresh: () async {
            await refresh();
          },
          child: Scrollbar(
            child: ListView.builder(
              itemCount: _conversations.isEmpty
                  ? 1
                  : _conversations.length + (Global.loadingMessages ? 1 : 0),
              padding: const EdgeInsets.all(0),
              itemBuilder: (BuildContext context, int index) {
                if (index == 0 && _conversations.isEmpty || index == _conversations.length) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(0, index == 0 ? 16 : 0, 0, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(),
                      ],
                    ),
                  );
                }
                final parentKey = GlobalKey();
                return Card(
                  margin: EdgeInsets.fromLTRB(
                      14, index == 0 ? 16 : 7, 14, index == _conversations.length - 1 ? 14 : 7),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: MessagePreview(_conversations[index], parentKey),
                    ),
                    onTap: () => openConversation(context, parentKey, _conversations[index].id,
                        _conversations[index].subject),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class MessagesSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Recherche';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 3) {
      return Center(
          child: Text('Entrez au moins 3 caractères',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary)));
    }
    Global.searchQuery = query;
    if (Global.messageSearchSuggestionState != null) {
      Global.messageSearchSuggestionState!.refresh();
    }
    return const MessageSearchResults();
  }
}

class MessageSearchResults extends StatefulWidget {
  const MessageSearchResults({Key? key}) : super(key: key);

  @override
  State<MessageSearchResults> createState() => MessageSearchResultsState();
}

class MessageSearchResultsState extends State<MessageSearchResults> {
  List<Conversation>? _conversations;

  MessageSearchResultsState() {
    Global.messageSearchSuggestionState = this;
    refresh();
  }

  refresh() {
    Conversation.search(Global.searchQuery!).then((conversations) {
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _conversations == null
        ? const Center(child: CircularProgressIndicator())
        : _conversations!.isEmpty
            ? Center(
                child: Text(
                'Aucun résultat trouvé.',
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                textAlign: TextAlign.center,
              ))
            : ListView.separated(
                itemBuilder: (context, index) {
                  const parentKey = null; //FIXME fix transition //GlobalKey();
                  return InkWell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: MessagePreview(
                          _conversations![index],
                          parentKey,
                        ),
                      ),
                      onTap: () {
                        Global.currentConversation = _conversations![index].id;
                        Global.currentConversationSubject = _conversations![index].subject;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ConversationView(),
                          ),
                        );
                      });
                },
                separatorBuilder: (context, index) {
                  return const Divider();
                },
                itemCount: _conversations!.length);
  }
}

class ConversationView extends StatefulWidget {
  const ConversationView({Key? key}) : super(key: key);

  @override
  State<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<ConversationView> {
  Conversation? _conversation;
  final TextEditingController _textFieldController = TextEditingController();
  bool _busy = false;
  bool _showReply = false;
  _ConversationViewState() {
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
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: OutlinedButton(
                            onPressed: () {
                              _showReply = true;
                              setState(() {});
                            },
                            child: const Text('Répondre à tous')),
                      );
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
                                    border: const Border(
                                        left: BorderSide(color: Colors.black12, width: 2)),
                                    padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                                    margin: EdgeInsets.zero)
                              },
                              onLinkTap: (url, context, map, element) {
                                launchUrl(Uri.parse(url!));
                              },
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
