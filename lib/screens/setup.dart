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
import 'package:kosmos_client/global.dart';
import 'package:kosmos_client/kdecole-api/database_manager.dart';

class SetupPage extends StatefulWidget {
  final Function() _callback;

  const SetupPage(this._callback, {Key? key}) : super(key: key);

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  int currentStep = 0;

  bool notifMsgEnabled = false;
  bool notifCalEnabled = false;

  bool step1 = false;
  bool step2 = false;
  bool step3 = false;
  bool step4 = false;
  bool step5 = false;

  int progress = 0;
  int progressOf = 0;

  void update() {
    step1 = Global.step1;
    step2 = Global.step2;
    step3 = Global.step3;
    step4 = Global.step4;
    step5 = Global.step5;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premiers pas'),
      ),
      body: Column(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme:
                  Theme.of(context).colorScheme.copyWith(primary: Colors.teal),
            ),
            child: Stepper(
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
                      const Text('Sélectionner quelle notifications activer'),
                      Text(
                        'Télécharger tous les messages risque de prendre un certain temps selon la quantité de messages dans votre boite de réception',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onTertiary),
                      ),
                      const Padding(padding: EdgeInsets.all(16.0)),
                      SwitchListTile(
                          title: const Text('Messagerie'),
                          subtitle: const Text(
                              'Recevoir des notifications quand il y a un nouveau message'),
                          activeColor: Colors.teal,
                          value: notifMsgEnabled,
                          onChanged: (value) {
                            notifMsgEnabled = !notifMsgEnabled;
                            setState(() {});
                          }),
                      SwitchListTile(
                          title: const Text('Emploi du temps'),
                          subtitle: const Text(
                              'Recevoir des notifications quand un cours est annulé'),
                          activeColor: Colors.teal,
                          value: notifCalEnabled,
                          onChanged: (value) {
                            notifCalEnabled = !notifCalEnabled;
                            setState(() {});
                          }),
                      const Padding(padding: EdgeInsets.all(8.0)),
                      Row(
                        children: [
                          TextButton(
                              onPressed: () {
                                currentStep++;
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
                  isActive: currentStep == 1,
                  title: const Text('Messagerie'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                          'Sélectionner combien de messages télécharger.'),
                      Text(
                        'Télécharger tous les messages risque de prendre un certain temps selon la quantité de messages dans votre boite de réception',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onTertiary),
                      ),
                      Row(
                        children: [
                          TextButton(
                              onPressed: () {
                                currentStep++;
                                update();
                                DatabaseManager.downloadAll();
                                setState(() {});
                              },
                              child: const Text(
                                'TOUS',
                              )),
                          TextButton(
                              onPressed: () {
                                currentStep++;
                                update();
                                DatabaseManager.downloadAll();
                                setState(() {});
                              },
                              child: const Text(
                                'LES 20 PREMIERS',
                              )),
                        ],
                      )
                    ],
                  ),
                ),
                Step(
                  isActive: currentStep == 2,
                  title: const Text('Téléchergement des données'),
                  content: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Téléchargement des dernières notes'),
                            step1
                                ? const Icon(Icons.done)
                                : const CircularProgressIndicator(),
                          ],
                        ),
                      ),
                      if (step1)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                  'Téléchargement de l\'emploi du temps'),
                              step2
                                  ? const Icon(Icons.done)
                                  : const CircularProgressIndicator(),
                            ],
                          ),
                        ),
                      if (step2)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Téléchargement des actualités'),
                              step3
                                  ? const Icon(Icons.done)
                                  : const CircularProgressIndicator(),
                            ],
                          ),
                        ),
                      if (step3)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                  'Téléchargement de la liste des messages'),
                              step4
                                  ? const Icon(Icons.done)
                                  : const CircularProgressIndicator(),
                            ],
                          ),
                        ),
                      if (step4)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                  'Téléchargement du contenu des messages'),
                              step5 ? const Icon(Icons.done) : Container(),
                            ],
                          ),
                        ),
                      if (progressOf != 0)
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child:
                                  Text("Téléchargement $progress/$progressOf"),
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
          ),
          if (step5)
            ElevatedButton(
              onPressed: () {
                widget._callback();
                Navigator.of(context).pop();
              },
              child: const Text('Fermer'),
            )
        ],
      ),
    );
  }
}
