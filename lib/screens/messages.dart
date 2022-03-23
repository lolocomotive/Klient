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

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:kosmos_client/kdecole-api/conversation.dart';
import 'package:kosmos_client/kdecole-api/database_manager.dart';
import 'package:morpheus/morpheus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';

class MessagePreview extends StatelessWidget {
  final Conversation _conversation;
  final GlobalKey _parentKey;

  const MessagePreview(this._conversation, this._parentKey, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _conversation.read ? 0 : 8,
          height: _conversation.read ? 0 : 8,
          margin: _conversation.read
              ? const EdgeInsets.all(0)
              : const EdgeInsets.fromLTRB(0, 5, 5, 0),
          decoration: BoxDecoration(
              color: _conversation.read ? Colors.transparent : Colors.blue,
              shape: BoxShape.circle),
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
                              ? ', ' + _conversation.lastAuthor
                              : ''),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _conversation.read
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    Global.dateToString(_conversation.lastDate),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: _conversation.read
                            ? FontWeight.normal
                            : FontWeight.bold,
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
                        fontWeight: _conversation.read
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 14),
                  ),
              _conversation.customPreview ??
                  Text(HtmlUnescape().convert(_conversation.preview),
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black45)),
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

  static void openConversation(BuildContext context, GlobalKey parentKey,
      int conversationId, String conversationSubject) {
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
        headerSliverBuilder: (ctx, innerBoxScrolled) {
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
              forceElevated: innerBoxScrolled,
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
                if (index == 0 && _conversations.isEmpty ||
                    index == _conversations.length) {
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
                final _parentKey = GlobalKey();
                return InkWell(
                  child: Container(
                      margin: EdgeInsets.fromLTRB(14, index == 0 ? 16 : 7, 14,
                          index == _conversations.length - 1 ? 14 : 7),
                      decoration: const BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4))
                          ],
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(8))),
                      padding: const EdgeInsets.all(8.0),
                      child: MessagePreview(_conversations[index], _parentKey)),
                  onTap: () => openConversation(context, _parentKey,
                      _conversations[index].id, _conversations[index].subject),
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
      return const Center(
          child: Text('Entrez au moins 3 caractères',
              style: TextStyle(color: Colors.black45)));
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
            ? const Center(
                child: Text(
                'Aucun résultat trouvé.',
                style: TextStyle(color: Colors.black45),
                textAlign: TextAlign.center,
              ))
            : ListView.separated(
                itemBuilder: (context, index) {
                  final _parentKey = GlobalKey();
                  return InkWell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: MessagePreview(_conversations![index], _parentKey),
                    ),
                    onTap: () => MessagesState.openConversation(
                        context,
                        _parentKey,
                        _conversations![index].id,
                        _conversations![index].subject),
                  );
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
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(_conversation != null
                ? _conversation!.subject
                : Global.currentConversationSubject!),
            floating: true,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final _parentKey = GlobalKey();
                return Container(
                  margin: EdgeInsets.fromLTRB(14, index == 0 ? 16 : 7, 14,
                      index == _conversation!.messages.length - 1 ? 14 : 7),
                  decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4))
                      ],
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    key: _parentKey,
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
                          Text(Global.dateToString(
                              _conversation!.messages[index].date)),
                        ],
                      ),
                      Html(
                        data: HtmlUnescape().convert(
                            _conversation!.messages[index].htmlContent),
                        style: {
                          'blockquote': Style(
                              border: const Border(
                                  left: BorderSide(
                                      color: Colors.black12, width: 2)),
                              padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                              margin: EdgeInsets.zero)
                        },
                        onLinkTap: (url, context, map, element) {
                          launch(url!);
                        },
                      ),
                    ],
                  ),
                );
              },
              childCount:
                  _conversation != null ? _conversation!.messages.length : 0,
            ),
          ),
        ],
      ),
    );
  }
}
