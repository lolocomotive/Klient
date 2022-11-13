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
import 'package:kosmos_client/api/client.dart';
import 'package:kosmos_client/api/database_manager.dart';
import 'package:kosmos_client/config_provider.dart';
import 'package:kosmos_client/screens/settings.dart';

class SetupPage extends StatefulWidget {
  final Function() _callback;
  static int downloadStep = 0;
  static int progress = 0;
  static int progressOf = 0;
  const SetupPage(this._callback, {Key? key}) : super(key: key);

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  int currentStep = 0;

  void update() {
    try {
      setState(() {});
    } catch (_) {
      return;
    }

    Timer(const Duration(milliseconds: 250), update);
  }

  @override
  Widget build(BuildContext context) {
    ConfigProvider.notifMsgEnabled = ConfigProvider.notifMsgEnabled ?? false;
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
                            value: ConfigProvider.notifMsgEnabled!,
                            onChanged: (value) {
                              ConfigProvider.notifMsgEnabled = !ConfigProvider.notifMsgEnabled!;
                              setState(() {});
                            }),
                        const Padding(padding: EdgeInsets.all(8.0)),
                        Row(
                          children: [
                            TextButton(
                                onPressed: () {
                                  currentStep++;
                                  ConfigProvider.getStorage().write(
                                      key: 'notifications.messages',
                                      value: ConfigProvider.notifMsgEnabled! ? 'true' : 'false');
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
                              Client.retryNetworkRequests = true;
                              DatabaseManager.downloadAll().then((_) {
                                Client.retryNetworkRequests = false;
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
                              const Flexible(child: Text('Téléchargement des dernières notes')),
                              SetupPage.downloadStep >= 1
                                  ? const Icon(Icons.done)
                                  : const CircularProgressIndicator(),
                            ],
                          ),
                        ),
                        if (SetupPage.downloadStep >= 1)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(child: Text('Téléchargement de l\'emploi du temps')),
                                SetupPage.downloadStep >= 2
                                    ? const Icon(Icons.done)
                                    : const CircularProgressIndicator(),
                              ],
                            ),
                          ),
                        if (SetupPage.downloadStep >= 2)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(child: Text('Téléchargement des actualités')),
                                SetupPage.downloadStep >= 3
                                    ? const Icon(Icons.done)
                                    : const CircularProgressIndicator(),
                              ],
                            ),
                          ),
                        if (SetupPage.downloadStep >= 3)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                    child: Text(
                                        'Téléchargement de la liste des messages (peut prendre un certain temps) ')),
                                SetupPage.downloadStep >= 4
                                    ? const Icon(Icons.done)
                                    : const CircularProgressIndicator(),
                              ],
                            ),
                          ),
                        if (SetupPage.downloadStep >= 4)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                    child: Text('Téléchargement du contenu des messages')),
                                SetupPage.downloadStep >= 5 ? const Icon(Icons.done) : Container(),
                              ],
                            ),
                          ),
                        if (SetupPage.progressOf != 0)
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                    'Téléchargement ${SetupPage.progress}/${SetupPage.progressOf}'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: LinearProgressIndicator(
                                  value: SetupPage.progress / SetupPage.progressOf,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  )
                ],
              ),
              if (SetupPage.downloadStep >= 5)
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
