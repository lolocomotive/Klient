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
import 'package:html_unescape/html_unescape.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/main.dart';
import 'package:klient/util.dart';
import 'package:klient/widgets/attachments_widget.dart';
import 'package:klient/widgets/custom_html.dart';
import 'package:klient/widgets/default_activity.dart';
import 'package:klient/widgets/default_transition.dart';
import 'package:scolengo_api/scolengo_api.dart';

class CommunicationPage extends StatefulWidget {
  const CommunicationPage({Key? key, required this.onDelete, required this.communication})
      : super(key: key);

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();

  final Function onDelete;
  final Communication communication;
}

class _CommunicationPageState extends State<CommunicationPage> {
  final TextEditingController _textFieldController = TextEditingController();
  bool _busy = false;
  bool _showReply = false;
  bool _transitionDone = false;
  List<Participation>? _participations;

  @override
  void initState() {
    super.initState();
    load();
  }

  load() async {
    final response =
        await ConfigProvider.client!.getCommunicationParticipations(widget.communication.id);
    if (!mounted) return;
    setState(() {
      _participations = response.data;
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
                              //TODO fix this
                              //await widget.onDelete(_communication);
                            },
                            icon: const Icon(Icons.delete))
                      ],
                      floating: true,
                    ),
                  ];
                },
                body: Scrollbar(
                  child: RefreshIndicator(
                    onRefresh: refresh,
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: ListView.builder(
                        itemCount: (_participations != null
                            ? _participations!.length +
                                (widget.communication.replyToAllAllowed! && !_showReply ? 2 : 1)
                            : 0),
                        itemBuilder: (BuildContext context, int index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: Text(
                                widget.communication.subject,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            );
                          }
                          index -= 1;
                          if (_participations != null &&
                              index == _participations!.length &&
                              widget.communication.replyToAllAllowed!) {
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
                          final participation = _participations![index];
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
                                            '${participation.sender!.person?.firstName} ${participation.sender!.person?.lastName}',
                                            textAlign: TextAlign.left,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Text(
                                          participation.dateTime.format(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    CustomHtml(
                                      data: HtmlUnescape().convert(participation.content),
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
                                    ),
                                    if (participation.attachments != null)
                                      AttachmentsWidget(
                                        attachments: participation.attachments!,
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
                                            await ConfigProvider.client!
                                                .postCommunicationParticipation(
                                                    widget.communication.id,
                                                    _textFieldController.text
                                                        .replaceAll('\\', '\\\\')
                                                        .replaceAll('"', '\\"')
                                                        .replaceAll('\n', '<br/>'));
                                            _textFieldController.clear();
                                            await refresh();
                                          } on Exception catch (e, st) {
                                            Util.onException(e, st);
                                          } finally {
                                            _busy = false;
                                            setState(() {});
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

  Future<void> refresh() async {
    KlientApp.cache.forceRefresh = true;
    await load();
    KlientApp.cache.forceRefresh = false;
  }
}
