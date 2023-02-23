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
import 'package:kosmos_client/api/client.dart';
import 'package:kosmos_client/api/conversation.dart';
import 'package:kosmos_client/api/downloader.dart';
import 'package:kosmos_client/config_provider.dart';
import 'package:kosmos_client/database_provider.dart';
import 'package:kosmos_client/screens/conversation.dart';
import 'package:kosmos_client/screens/message_search.dart';
import 'package:kosmos_client/util.dart';
import 'package:kosmos_client/widgets/default_card.dart';
import 'package:kosmos_client/widgets/default_transition.dart';
import 'package:kosmos_client/widgets/delayed_progress_indicator.dart';
import 'package:kosmos_client/widgets/exception_widget.dart';
import 'package:kosmos_client/widgets/message_card.dart';
import 'package:kosmos_client/widgets/user_avatar_action.dart';
import 'package:morpheus/morpheus.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  State<MessagesPage> createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage> with TickerProviderStateMixin {
  final GlobalKey<MessagesPageState> key = GlobalKey();
  final List<int> _selection = [];
  Exception? _e;
  StackTrace? _st;
  bool _sideBySide = false;
  String? currentSubject;
  int? currentId;
  bool _transitionDone = false;

  void openConversation(
      BuildContext context, GlobalKey? parentKey, int conversationId, String conversationSubject) {
    if (_sideBySide) {
      setState(() {
        currentId = conversationId;
        currentSubject = conversationSubject;
      });
    } else {
      Navigator.of(context).push(
        MorpheusPageRoute(
          //FIXME Builder is called twice
          builder: (_) => ConversationPage(
              onDelete: deleteConversationFromList,
              subject: conversationSubject,
              id: conversationId),
          parentKey: parentKey,
        ),
      );
    }
  }

  reloadFromDB() {
    Conversation.fetchAll().then((conversations) {
      if (!mounted) return;
      _conversations = conversations;
      delayTransitionDone();
    });
  }

  refresh() async {
    await Downloader.fetchMessageData();
    await reloadFromDB();
  }

  delayTransitionDone() {
    setState(() {
      _transitionDone = false;
    });
    Future.delayed(const Duration(milliseconds: 400)).then((_) {
      _transitionDone = true;
    });
  }

  static MessagesPageState? currentState;
  @override
  initState() {
    super.initState();
    currentState = this;
    currentId = null;
    currentSubject = null;
    Conversation.fetchAll().then((conversations) {
      delayTransitionDone();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
      });
    }).onError((e, st) {
      _e = e as Exception;
      _st = st;
      setState(() {});
    });
  }

  List<Conversation> _conversations = [];

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
              constraints: const BoxConstraints(maxWidth: 1400),
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
                                      delegate: MessagesSearchDelegate(),
                                    );
                                  },
                                ),
                              if (!_selection.isNotEmpty) const UserAvatarAction()
                            ],
                            title: Text(
                              _selection.isNotEmpty
                                  ? _selection.length == 1
                                      ? _conversations[_selection[0]].subject
                                      : '${_selection.length} conversations'
                                  : 'Messagerie',
                              style: TextStyle(
                                color: _selection.isNotEmpty
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onBackground,
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
                          onRefresh: () async {
                            await refresh();
                          },
                          child: _e != null
                              ? Column(
                                  children: [
                                    DefaultCard(child: ExceptionWidget(e: _e!, st: _st!)),
                                  ],
                                )
                              : _conversations.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: const [
                                            DelayedProgressIndicator(
                                              delay: Duration(milliseconds: 500),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _conversations.length +
                                          (Downloader.loadingMessages ? 1 : 0),
                                      padding: const EdgeInsets.all(0),
                                      itemBuilder: (BuildContext context, int index) {
                                        final parentKey = GlobalKey();
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
                                                  Card(
                                                    key: parentKey,
                                                    margin: EdgeInsets.fromLTRB(
                                                        14,
                                                        index == 0 ? 16 : 7,
                                                        14,
                                                        index == _conversations.length - 1
                                                            ? 14
                                                            : 7),
                                                    elevation: 1,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    clipBehavior: Clip.antiAlias,
                                                    child: InkWell(
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: MessageCard(_conversations[index]),
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
                                                          openConversation(
                                                              context,
                                                              parentKey,
                                                              _conversations[index].id,
                                                              _conversations[index].subject);
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
                                                  Positioned.fill(
                                                    child: IgnorePointer(
                                                      child: AnimatedOpacity(
                                                        duration: const Duration(milliseconds: 300),
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
                          : ConversationPage(
                              key: Key(currentId.toString()),
                              id: currentId!,
                              subject: currentSubject!,
                              onDelete: deleteConversationFromList,
                            ),
                    )
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  deleteConversationFromList(Conversation conv) async {
    await deleteConversation(conv);
    try {
      _conversations.removeAt(_conversations.indexOf(conv));
    } catch (_) {
      reloadFromDB();
    }
    setState(() {});
  }

  void deleteSelection(List<int> selection) {
    for (var index in selection) {
      deleteConversationFromList(_conversations[index]);
    }
  }
}

class SideConversationView extends StatelessWidget {
  const SideConversationView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Cliquer sur un message pour l\'afficher ici'));
  }
}

deleteConversation(Conversation conv) async {
  final db = await DatabaseProvider.getDB();

  try {
    if (!ConfigProvider.demo) {
      await Client.getClient().request(Action.deleteMessage, params: [conv.id.toString()]);
    }
    db.delete('Conversations', where: 'ID = ?', whereArgs: [conv.id]);
    db.delete('Messages', where: 'ParentID = ?', whereArgs: [conv.id]);
    for (var message in conv.messages) {
      db.delete('MessageAttachments', where: 'ParentID = ?', whereArgs: [message.id]);
    }
  } on Exception catch (e, st) {
    Util.onException(e, st);
  }
}
