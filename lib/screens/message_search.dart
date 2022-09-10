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
import 'package:kosmos_client/api/conversation.dart';
import 'package:kosmos_client/screens/conversation.dart';
import 'package:kosmos_client/screens/messages.dart';
import 'package:kosmos_client/widgets/message_card.dart';

import '../global.dart';

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
                        child: MessageCard(
                          _conversations![index],
                          parentKey,
                        ),
                      ),
                      onTap: () {
                        Global.currentConversation = _conversations![index].id;
                        Global.currentConversationSubject = _conversations![index].subject;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ConversationPage(
                              onDelete: deleteConversation,
                            ),
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
