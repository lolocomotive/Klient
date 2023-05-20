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
import 'package:klient/config_provider.dart';
import 'package:klient/main.dart';
import 'package:klient/screens/communication.dart';
import 'package:klient/screens/message_search.dart';
import 'package:klient/util.dart';
import 'package:klient/widgets/communication_card.dart';
import 'package:klient/widgets/default_card.dart';
import 'package:klient/widgets/default_transition.dart';
import 'package:klient/widgets/delayed_progress_indicator.dart';
import 'package:klient/widgets/exception_widget.dart';
import 'package:klient/widgets/user_avatar_action.dart';
import 'package:scolengo_api/scolengo_api.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  State<MessagesPage> createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage> with TickerProviderStateMixin {
  final GlobalKey<MessagesPageState> key = GlobalKey();
  final List<int> _selection = [];
  Folder? _folder;
  Exception? _e;
  StackTrace? _st;
  bool _sideBySide = false;
  String? currentSubject;
  String? currentId;
  int? _size;
  int _page = 0;
  final int _pageSize = 20;
  bool _transitionDone = false;

  void openConversation(BuildContext context, GlobalKey? parentKey, Communication communication) {
    if (_sideBySide) {
      setState(() {
        currentId = communication.id;
        currentSubject = communication.subject;
      });
    } else {
      //Navigator.of(context).push(
      //  MorpheusPageRoute(
      //    //FIXME Builder is called twice
      //    builder: (_) => CommunicationPage(
      //      onDelete: (communication) {
      //        Navigator.of(context).pop();
      //        deleteSingleCommunication(communication);
      //      },
      //      communication: communication,
      //    ),
      //    parentKey: parentKey,
      //  ),
      //);
    }
  }

  Future<void> load([bool transitionned = false]) async {
    final responses = ConfigProvider.client!.getCommunicationsFromFolder(
      _folder!.id,
      offset: _pageSize * _page,
      limit: _pageSize,
    );

    bool isFirst = true;
    await for (final response in responses) {
      _size = response.meta?['totalResourceCount'];
      if (!mounted) return;

      for (final comm in response.data) {
        //Remove duplicate entries
        _communications.removeWhere((element) => element.id == comm.id);
        _communications.add(comm);
      }
      if (!isFirst) {
        // Sort if it's not the first response in the stream
        // because there could have been other responses in between
        _communications.sort((a, b) =>
            b.lastParticipation!.dateTime.date().compareTo(a.lastParticipation!.dateTime.date()));
      } else if (!transitionned) {
        transitionned = true;
        delayTransitionDone();
      }
      setState(() {});
      _loaded = true;
      isFirst = false;
    }
  }

  Future<void> refresh() async {
    KlientApp.cache.forceRefresh = true;
    _settings =
        (await ConfigProvider.client!.getUsersMailSettings(await ConfigProvider.currentId!).last)
            .data;
    await load();
    KlientApp.cache.forceRefresh = false;
  }

  delayTransitionDone() {
    if (!mounted) return;
    setState(() {
      _transitionDone = false;
    });
    Future.delayed(const Duration(milliseconds: 400)).then((_) => _transitionDone = true);
  }

  static MessagesPageState? currentState;
  @override
  initState() {
    super.initState();
    currentState = this;
    currentId = null;
    currentSubject = null;
    ConfigProvider.client!
        .getUsersMailSettings(ConfigProvider.credentials!.idToken.claims.subject)
        .first
        .then((response) {
      _settings = response.data;
      _settings!.folders.sort(
        (a, b) => a.position.compareTo(b.position),
      );
      _folder = _settings!.folders.firstWhere((element) => element.folderType == FolderType.INBOX);
      setState(() {});
      load();
    });
  }

  bool _loaded = false;
  List<Communication> _communications = [];
  UsersMailSettings? _settings;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selection.isNotEmpty) {
          setState(() {
            while (_selection.isNotEmpty) {
              _selection.removeLast();
            }
          });
          return false;
        }
        return true;
      },
      child: Container(
        key: key,
        child: LayoutBuilder(builder: (context, constraints) {
          _sideBySide = constraints.maxWidth > 1200;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1600),
              child: Container(
                color: Theme.of(context).colorScheme.background,
                child: Row(
                  children: [
                    Flexible(
                      flex: 1,
                      child: NestedScrollView(
                        floatHeaderSlivers: true,
                        headerSliverBuilder: (ctx, innerBoxIsScrolled) {
                          return <Widget>[
                            SliverAppBar(
                              leading: _selection.isNotEmpty
                                  ? IconButton(
                                      tooltip: 'Désactiver la sélection',
                                      onPressed: () {
                                        setState(() {
                                          while (_selection.isNotEmpty) {
                                            _selection.removeLast();
                                          }
                                        });
                                      },
                                      icon: Icon(
                                        Icons.arrow_back,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ))
                                  : null,
                              backgroundColor: _selection.isNotEmpty
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.background,
                              actions: [
                                if (_selection.isNotEmpty)
                                  IconButton(
                                    tooltip: 'Supprimer les messages sélectionnés',
                                    onPressed: () async {
                                      //TODO show that progress is being made

                                      deleteSelection(_selection);
                                      while (_selection.isNotEmpty) {
                                        _selection.removeLast();
                                      }
                                      setState(() {});
                                    },
                                    icon: Icon(
                                      Icons.delete,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                if (!_selection.isNotEmpty)
                                  IconButton(
                                    tooltip: 'Rechercher dans les messages',
                                    icon: const Icon(Icons.search),
                                    onPressed: () {
                                      showSearch(
                                        context: context,
                                        delegate: MessagesSearchDelegate(deleteCommunication),
                                      );
                                    },
                                  ),
                                if (!_selection.isNotEmpty) const UserAvatarAction()
                              ],
                              title: _selection.isNotEmpty
                                  ? Text(
                                      _selection.length == 1
                                          ? _communications[_selection[0]].subject
                                          : '${_selection.length} conversations',
                                      style:
                                          TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: ElevationOverlay.applySurfaceTint(
                                          Theme.of(context).colorScheme.surface,
                                          Theme.of(context).colorScheme.primary,
                                          innerBoxIsScrolled ? 12 : 2,
                                        ),
                                      ),
                                      child: DropdownButton<String>(
                                        borderRadius: BorderRadius.circular(16),
                                        dropdownColor: ElevationOverlay.applySurfaceTint(
                                          Theme.of(context).colorScheme.surface,
                                          Theme.of(context).colorScheme.primary,
                                          4,
                                        ),
                                        isExpanded: true,
                                        underline: Container(),
                                        items: _settings?.folders
                                                .where((folder) =>
                                                    folder.folderType != FolderType.DRAFTS &&
                                                    folder.folderType != FolderType.MODERATION)
                                                .map<DropdownMenuItem<String>>(
                                              (folder) {
                                                final IconData icon;
                                                if (folder.folderType == FolderType.INBOX) {
                                                  icon = Icons.inbox;
                                                } else if (folder.folderType == FolderType.SENT) {
                                                  icon = Icons.send;
                                                } else if (folder.folderType == FolderType.TRASH) {
                                                  icon = Icons.delete;
                                                } else if (folder.folderType == FolderType.DRAFTS) {
                                                  icon = Icons.drafts;
                                                } else if (folder.folderType ==
                                                    FolderType.MODERATION) {
                                                  icon = Icons.report;
                                                } else {
                                                  icon = Icons.folder;
                                                }
                                                return DropdownMenuItem(
                                                  value: folder.id,
                                                  child: Row(
                                                    children: [
                                                      Padding(
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: Icon(icon),
                                                      ),
                                                      Flexible(
                                                        child: Text(
                                                          folder.name,
                                                          overflow: TextOverflow.fade,
                                                          softWrap: false,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ).toList() ??
                                            [
                                              const DropdownMenuItem(
                                                child: Row(
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.all(8.0),
                                                      child: Icon(Icons.inbox),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        'Chargement...',
                                                        overflow: TextOverflow.fade,
                                                        softWrap: false,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                        onChanged: (folder) {
                                          _folder = _settings?.folders
                                              .firstWhere((element) => element.id == folder);
                                          _loaded = false;
                                          _page = 0;
                                          _communications = [];
                                          currentId = null;
                                          currentSubject = null;
                                          setState(() {});
                                          load();
                                        },
                                        value: _folder?.id,
                                      ),
                                    ),
                              floating: false,
                              forceElevated: innerBoxIsScrolled,
                              pinned: _selection.isNotEmpty,
                            )
                          ];
                        },
                        body: Scrollbar(
                          child: RefreshIndicator(
                            onRefresh: refresh,
                            child: _e != null
                                ? Column(
                                    children: [
                                      DefaultCard(child: ExceptionWidget(e: _e!, st: _st!)),
                                    ],
                                  )
                                : _communications.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              _loaded
                                                  ? DefaultTransition(
                                                      child: Text(
                                                        'Aucun message à afficher',
                                                        style: TextStyle(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .secondary,
                                                        ),
                                                      ),
                                                    )
                                                  : const DelayedProgressIndicator(
                                                      delay: Duration(milliseconds: 500),
                                                    ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        cacheExtent: 1000,
                                        itemCount: _communications.length +
                                            (_communications.length < _size! ? 1 : 0),
                                        padding: const EdgeInsets.all(0),
                                        itemBuilder: (BuildContext context, int index) {
                                          final parentKey = GlobalKey();
                                          if (index == _communications.length) {
                                            if ((_page + 1) * _pageSize >= index) {
                                              _page++;
                                              load(true);
                                            }
                                            return const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: CircularProgressIndicator(),
                                              ),
                                            );
                                          }
                                          return DefaultTransition(
                                            duration: _transitionDone
                                                ? Duration.zero
                                                : const Duration(milliseconds: 200),
                                            delay: Duration(
                                                milliseconds: _transitionDone ? 0 : 30 * index),
                                            child: Column(
                                              children: [
                                                Stack(
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.fromLTRB(
                                                          14,
                                                          index == 0 ? 16 : 7,
                                                          14,
                                                          index == _communications.length - 1
                                                              ? 14
                                                              : 7),
                                                      child: OpenContainer(
                                                        transitionType:
                                                            ContainerTransitionType.fadeThrough,
                                                        backgroundColor: Colors.black26,
                                                        closedElevation: 1,
                                                        closedShape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                        clipBehavior: Clip.antiAlias,
                                                        closedColor:
                                                            ElevationOverlay.applySurfaceTint(
                                                                Theme.of(context)
                                                                    .colorScheme
                                                                    .surface,
                                                                Theme.of(context)
                                                                    .colorScheme
                                                                    .primary,
                                                                1),
                                                        openColor: Theme.of(context)
                                                            .colorScheme
                                                            .background,
                                                        openBuilder: (context, action) =>
                                                            CommunicationPage(
                                                          onDelete: deleteSingleCommunication,
                                                          communication: _communications[index],
                                                        ),
                                                        closedBuilder: (context, action) => InkWell(
                                                          child: Padding(
                                                            padding: const EdgeInsets.symmetric(
                                                                vertical: 10, horizontal: 14),
                                                            child: CommunicationCard(
                                                                _communications[index]),
                                                          ),
                                                          onTap: () {
                                                            if (_selection.isNotEmpty) {
                                                              if (_selection.contains(index)) {
                                                                setState(() {
                                                                  _selection.remove(index);
                                                                });
                                                                return;
                                                              }
                                                              _selection.add(index);
                                                              setState(() {});
                                                            } else {
                                                              action();
                                                              openConversation(context, parentKey,
                                                                  _communications[index]);
                                                            }
                                                          },
                                                          onLongPress: () {
                                                            if (_selection.contains(index)) {
                                                              setState(() {
                                                                _selection.remove(index);
                                                              });
                                                              return;
                                                            }
                                                            _selection.add(index);
                                                            setState(() {});
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned.fill(
                                                      child: IgnorePointer(
                                                        child: AnimatedOpacity(
                                                          duration:
                                                              const Duration(milliseconds: 300),
                                                          opacity:
                                                              (_selection.contains(index)) ? 1 : 0,
                                                          child: Container(
                                                            color: Theme.of(context).highlightColor,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                          ),
                        ),
                      ),
                    ),
                    if (_sideBySide)
                      Flexible(
                        flex: 2,
                        child: currentId == null
                            ? const Center(
                                child: Text('Cliquer sur une conversation pour l\'afficher ici'))
                            : CommunicationPage(
                                key: Key(currentId.toString()),
                                communication: _communications.firstWhere(
                                  (element) => element.id == currentId,
                                ),
                                onDelete: (comm) {
                                  currentId = null;
                                  currentSubject = null;
                                  deleteSingleCommunication(comm);
                                },
                              ),
                      )
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  deleteCommunication(Communication comm) async {
    if (_folder!.folderType == FolderType.TRASH) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Le message est déjà dans la corbeille.')));

      return;
    }
    try {
      await ConfigProvider.client!.patchCommunicationFolders(
        comm.id,
        [_settings!.folders.firstWhere((element) => element.folderType == FolderType.TRASH)],
        await ConfigProvider.currentId!,
      );
      _communications.remove(comm);
    } catch (_) {}
    setState(() {});
  }

  deleteSingleCommunication(Communication comm) async {
    await deleteCommunication(comm);
    refreshCache();
  }

  refreshCache() async {
    //We have to wait because the API doesn't update immediately.
    await Future.delayed(const Duration(milliseconds: 500));
    KlientApp.cache.forceRefresh = true;
    ConfigProvider.client!.getCommunicationsFromFolder(
      _settings!.folders.firstWhere((element) => element.folderType == FolderType.INBOX).id,
      limit: 20,
    );
    KlientApp.cache.forceRefresh = false;
  }

  void deleteSelection(List<int> selection) {
    for (var index in selection) {
      deleteCommunication(_communications[index]);
    }
    refreshCache();
  }
}
