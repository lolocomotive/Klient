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
import 'package:kosmos_client/api/database_manager.dart';
import 'package:kosmos_client/screens/conversation.dart';
import 'package:kosmos_client/screens/message_search.dart';
import 'package:kosmos_client/widgets/message_card.dart';
import 'package:morpheus/morpheus.dart';

import '../global.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  State<MessagesPage> createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage> {
  final GlobalKey<MessagesPageState> key = GlobalKey();
  final List<int> _selection = [];
  Exception? _e;
  StackTrace? _st;

  void openConversation(
      BuildContext context, GlobalKey? parentKey, int conversationId, String conversationSubject) {
    Global.currentConversation = conversationId;
    Global.currentConversationSubject = conversationSubject;
    Navigator.of(context).push(
      MorpheusPageRoute(
        builder: (_) => ConversationPage(
          onDelete: deleteConversationFromList,
        ),
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

  MessagesPageState() {
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
        child: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (ctx, innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                leading: _selection.isNotEmpty
                    ? IconButton(
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
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        showSearch(
                          context: context,
                          delegate: MessagesSearchDelegate(),
                        );
                      },
                    ),
                  if (!_selection.isNotEmpty) Global.popupMenuButton
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
          body: RefreshIndicator(
            onRefresh: () async {
              await refresh();
            },
            child: Scrollbar(
              child: _e != null
                  ? Column(
                      children: [
                        Global.defaultCard(child: Global.exceptionWidget(_e!, _st!)),
                      ],
                    )
                  : ListView.builder(
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
                        final parentKey = GlobalKey();
                        return Column(
                          children: [
                            Stack(
                              children: [
                                Card(
                                  margin: EdgeInsets.fromLTRB(14, index == 0 ? 16 : 7, 14,
                                      index == _conversations.length - 1 ? 14 : 7),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: InkWell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: MessageCard(_conversations[index], parentKey),
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
                                      opacity: (_selection.contains(index)) ? .3 : 0,
                                      child: Container(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ),
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

deleteConversation(Conversation conv) async {
  try {
    await Global.client!.request(Action.deleteMessage, params: [conv.id.toString()]);
    Global.db!.delete('Conversations', where: 'ID = ?', whereArgs: [conv.id]);
    Global.db!.delete('Messages', where: 'ParentID = ?', whereArgs: [conv.id]);
    for (var message in conv.messages) {
      Global.db!.delete('MessageAttachments', where: 'ParentID = ?', whereArgs: [message.id]);
    }
  } on Exception catch (e, st) {
    Global.onException(e, st);
  }
}
