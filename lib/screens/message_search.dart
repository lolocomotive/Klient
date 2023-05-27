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

import 'package:animations/animations.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:full_text_search/full_text_search.dart';
import 'package:full_text_search/searches.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/screens/communication.dart';
import 'package:klient/util.dart';
import 'package:klient/widgets/communication_card.dart';
import 'package:scolengo_api/scolengo_api.dart';

class MessagesSearchDelegate extends SearchDelegate {
  static MessageSearchResultsState? messageSearchSuggestionState;

  final Function(Communication) onDelete;

  MessagesSearchDelegate(this.onDelete);

  @override
  String get searchFieldLabel => 'Recherche';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        tooltip: 'Vider',
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
      tooltip: 'Retour',
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    MessagesSearchDelegate.messageSearchSuggestionState?.refresh();
    return MessageSearchResults(
      onDelete: onDelete,
      query: query,
    );
  }
}

class MessageSearchResults extends StatefulWidget {
  final Function(Communication) onDelete;
  final String query;

  const MessageSearchResults({
    Key? key,
    required this.onDelete,
    required this.query,
  }) : super(key: key);

  @override
  State<MessageSearchResults> createState() => MessageSearchResultsState();
}

class MessageSearchResultsState extends State<MessageSearchResults> {
  List<Communication>? _communications;
  List<IndexEntry<Communication>>? _index;
  List<Communication>? _fullCommunications;
  String? oldQuery;

  MessageSearchResultsState() {
    MessagesSearchDelegate.messageSearchSuggestionState = this;
    init();
  }

  refresh() {
    if (widget.query.toLowerCase() == oldQuery?.toLowerCase()) return;
    if (_index == null) return;
    FullTextSearch<IndexEntry<Communication>>(
      term: widget.query,
      items: _index!,
      tokenize: (entry) => entry.tokens,
      isStartsWith: false,
    ).findResults().then((results) {
      _communications = results.map((e) => e.item).toList();
      oldQuery = widget.query;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.query.length < 3) {
      return Center(
          child: Text('Entrez au moins 3 caractères',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary)));
    }
    return Center(
      child: _fullCommunications == null
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Téléchargement des messages...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  const LinearProgressIndicator(),
                ],
              ),
            )
          : _communications == null
              ? const CircularProgressIndicator()
              : _communications!.isEmpty
                  ? Text(
                      'Aucun résultat trouvé.',
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                      textAlign: TextAlign.center,
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: ListView.builder(
                        itemBuilder: (context, index) {
                          final parentKey = GlobalKey();
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: OpenContainer(
                              backgroundColor: Colors.black26,
                              closedElevation: 1,
                              closedShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              clipBehavior: Clip.antiAlias,
                              closedColor: ElevationOverlay.applySurfaceTint(
                                  Theme.of(context).colorScheme.surface,
                                  Theme.of(context).colorScheme.primary,
                                  1),
                              openColor: Theme.of(context).colorScheme.background,
                              openBuilder: (context, action) => CommunicationPage(
                                onDelete: widget.onDelete,
                                communication: _communications![index],
                              ),
                              closedBuilder: (context, action) => InkWell(
                                  onTap: action,
                                  child: Padding(
                                    key: parentKey,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                    child: CommunicationCard(
                                      _communications![index],
                                    ),
                                  )),
                            ),
                          );
                        },
                        itemCount: _communications!.length,
                      ),
                    ),
    );
  }

  init() async {
    final settings =
        await ConfigProvider.client!.getUsersMailSettings(await ConfigProvider.currentId!).first;
    _fullCommunications = (await ConfigProvider.client!
            .getCommunicationsFromFolder(
                settings.data.folders
                    .firstWhere((element) => element.folderType == FolderType.INBOX)
                    .id,
                limit: 1 << 32)
            .first)
        .data;
    _index = _fullCommunications!.map((e) => IndexEntry<Communication>(e, e.tokenize)).toList();
    refresh();
  }
}

extension Tokenize on Communication {
  List<String> get tokenize => [
        subject.toLowerCase() + (lastParticipation?.content.innerText.toLowerCase() ?? ''),
        (lastParticipation?.sender?.label?.toLowerCase() ?? ''),
        (recipientsSummary?.innerText.toLowerCase() ?? '')
      ];
}

class IndexEntry<T> {
  final T item;
  final List<String> tokens;

  IndexEntry(this.item, this.tokens);
}
