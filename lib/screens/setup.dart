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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kosmos_client/api/database_manager.dart';
import 'package:kosmos_client/global.dart';
import 'package:kosmos_client/screens/settings.dart';

class SetupPage extends StatefulWidget {
  final Function() _callback;

  const SetupPage(this._callback, {Key? key}) : super(key: key);

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  int currentStep = 0;

  bool step1 = false;
  bool step2 = false;
  bool step3 = false;
  bool step4 = false;
  bool step5 = false;
  bool step6 = false;

  int progress = 0;
  int progressOf = 0;

  void update() {
    step1 = Global.step1;
    step2 = Global.step2;
    step3 = Global.step3;
    step4 = Global.step4;
    step5 = Global.step5;
    step6 = Global.step6;

    progress = Global.progress;
    progressOf = Global.progressOf;
    try {
      setState(() {});
    } catch (_) {
      return;
    }

    Timer(const Duration(milliseconds: 250), update);
  }

  @override
  Widget build(BuildContext context) {
    Global.notifMsgEnabled = Global.notifMsgEnabled ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        leadingWidth: 0,
        title: const Text('Premiers pas'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Stepper(
                currentStep: currentStep,
                controlsBuilder: (context, details) {
                  return Container();
                },
                steps: [
                  Step(
                    isActive: currentStep == 0,
                    title: const Text('Notifications'),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(padding: EdgeInsets.all(16.0)),
                        SwitchListTile(
                            title: const Text('Messagerie'),
                            subtitle: const Text(
                                'Recevoir des notifications quand il y a un nouveau message'),
                            value: Global.notifMsgEnabled!,
                            onChanged: (value) {
                              Global.notifMsgEnabled = !Global.notifMsgEnabled!;
                              setState(() {});
                            }),
                        const Padding(padding: EdgeInsets.all(8.0)),
                        Row(
                          children: [
                            TextButton(
                                onPressed: () {
                                  currentStep++;
                                  Global.storage!.write(
                                      key: 'notifications.messages',
                                      value: Global.notifMsgEnabled! ? 'true' : 'false');
                                  setState(() {});
                                },
                                child: const Text(
                                  'CONTINUER',
                                )),
                          ],
                        )
                      ],
                    ),
                  ),
                  Step(
                    title: const Flexible(child: Text('Affichage')),
                    content: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CompactSelector(),
                        TextButton(
                            onPressed: () {
                              currentStep++;
                              Global.retryNetworkRequests = true;
                              DatabaseManager.downloadAll().then((_) {
                                Global.retryNetworkRequests = false;
                              });
                              update();
                              setState(() {});
                            },
                            child: const Text(
                              'CONTINUER',
                            )),
                      ],
                    ),
                    isActive: currentStep == 1,
                  ),
                  Step(
                    isActive: currentStep == 2,
                    title: const Flexible(child: Text('Téléchergement des données')),
                    content: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(child: Text('Téléchargement des donnés de l\'utilisateur')),
                              step1 ? const Icon(Icons.done) : const CircularProgressIndicator(),
                            ],
                          ),
                        ),
                        if (step1)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(child: Text('Téléchargement des dernières notes')),
                                step2 ? const Icon(Icons.done) : const CircularProgressIndicator(),
                              ],
                            ),
                          ),
                        if (step2)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(child: Text('Téléchargement de l\'emploi du temps')),
                                step3 ? const Icon(Icons.done) : const CircularProgressIndicator(),
                              ],
                            ),
                          ),
                        if (step3)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                    child: Text(
                                        'Téléchargement des actualités')),
                                step4 ? const Icon(Icons.done) : const CircularProgressIndicator(),
                              ],
                            ),
                          ),
                        if (step4)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                    child: Text('Téléchargement de la liste des messages (peut prendre un certain temps)')),
                                step5 ? const Icon(Icons.done) : const CircularProgressIndicator(),
                              ],
                            ),
                          ),
                        if (progressOf != 0)
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Téléchargement $progress/$progressOf'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: LinearProgressIndicator(
                                  value: progress / progressOf,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  )
                ],
              ),
              if (step6)
                ElevatedButton(
                  onPressed: () {
                    widget._callback();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Fermer'),
                )
            ],
          ),
        ),
      ),
    );
  }
}
