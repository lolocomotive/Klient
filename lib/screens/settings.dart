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
import 'package:kosmos_client/api/lesson.dart';
import 'package:kosmos_client/global.dart';
import 'package:kosmos_client/widgets/lesson_card.dart';
import 'package:restart_app/restart_app.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final boldPrimary = TextStyle(
        fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 14);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SettingsList(
              darkTheme: SettingsThemeData(
                  settingsListBackground: Theme.of(context).colorScheme.background),
              lightTheme: SettingsThemeData(
                  settingsListBackground: Theme.of(context).colorScheme.background),
              sections: [
                SettingsSection(
                    title: Text(
                      'API URL',
                      style: boldPrimary,
                    ),
                    tiles: [
                      SettingsTile(
                        title: DropdownButton(
                            value: Global.apiurl,
                            isExpanded: true,
                            items: Global.dropdownItems,
                            onChanged: (dynamic newValue) async {
                              await Global.storage!.write(key: 'apiurl', value: newValue);
                              Global.apiurl = newValue;
                              setState(() {});
                            }),
                      ),
                    ]),
                SettingsSection(
                  title: Text(
                    'Notifications',
                    style: boldPrimary,
                  ),
                  tiles: <SettingsTile>[
                    SettingsTile.switchTile(
                      initialValue: Global.notifMsgEnabled,
                      onToggle: (_) {
                        Global.notifMsgEnabled = !Global.notifMsgEnabled!;
                        Global.storage!.write(
                            key: 'notifications.messages',
                            value: Global.notifMsgEnabled! ? 'true' : 'false');
                        setState(() {});
                      },
                      leading: const Icon(Icons.message_outlined),
                      title: const Text('Messagerie'),
                      description:
                          const Text('Recevoir une notification quand il y a un nouveau message'),
                    ),
                    SettingsTile.switchTile(
                      initialValue: Global.notifCalEnabled,
                      onToggle: (_) {
                        Global.notifCalEnabled = !Global.notifCalEnabled!;
                        Global.storage!.write(
                            key: 'notifications.calendar',
                            value: Global.notifCalEnabled! ? 'true' : 'false');
                        setState(() {});
                      },
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Emploi du temps'),
                      description:
                          const Text('Recevoir une notification quand une séance est annulée'),
                    ),
                  ],
                ),
                SettingsSection(
                    title: Text(
                      'Affichage',
                      style: boldPrimary,
                    ),
                    tiles: <SettingsTile>[
                      SettingsTile(
                        leading: const Icon(Icons.invert_colors),
                        title: Row(
                          children: [
                            const Text('Thème'),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16.0, 0, 0, 0),
                                child: DropdownButton(
                                  isExpanded: true,
                                  value: Global.enforcedBrightness == null
                                      ? 'default'
                                      : Global.enforcedBrightness == Brightness.light
                                          ? 'light'
                                          : 'dark',
                                  items: const [
                                    DropdownMenuItem(value: 'default', child: Text('Système')),
                                    DropdownMenuItem(value: 'light', child: Text('Clair')),
                                    DropdownMenuItem(value: 'dark', child: Text('Sombre')),
                                  ],
                                  onChanged: (dynamic value) {
                                    Global.storage!
                                        .write(key: 'display.enforcedBrightness', value: value);
                                    Global.enforcedBrightness = value == 'light'
                                        ? Brightness.light
                                        : value == 'dark'
                                            ? Brightness.dark
                                            : null;
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                              'Redémarrer l\'application pour que le changement apparaîsse'),
                                        ),
                                        ElevatedButton(
                                            onPressed: (() {
                                              Restart.restartApp();
                                            }),
                                            child: const Text('Redémarrer maintenant'))
                                      ],
                                    )));
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SettingsTile(
                        title: const CompactSelector(),
                      )
                    ])
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CompactSelector extends StatefulWidget {
  const CompactSelector({Key? key}) : super(key: key);

  @override
  State<CompactSelector> createState() => _CompactSelectorState();
}

class _CompactSelectorState extends State<CompactSelector> {
  @override
  Widget build(BuildContext context) {
    final boldPrimary = TextStyle(
        fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 14);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 0, 16.0),
          child: Text('Style d\'affichage'),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 1,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    Global.storage!.write(key: 'display.compact', value: 'false');
                    Global.compact = false;
                  });
                },
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: Global.compact! ? null : Theme.of(context).highlightColor,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8.0),
                        child: Text(
                          'Normal',
                          style: boldPrimary,
                        ),
                      ),
                      IgnorePointer(
                        child: LessonCard(
                          Lesson(
                            0,
                            DateTime.now(),
                            '13:45',
                            '14:40',
                            '404',
                            'Exemple',
                            [],
                            false,
                            false,
                            false,
                          ),
                          positionned: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 1,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    Global.storage!.write(key: 'display.compact', value: 'true');
                    Global.compact = true;
                  });
                },
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: Global.compact! ? Theme.of(context).highlightColor : null,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8.0),
                        child: Text(
                          'Compact',
                          style: boldPrimary,
                        ),
                      ),
                      IgnorePointer(
                        child: LessonCard(
                          Lesson(
                            0,
                            DateTime.now(),
                            '13:45',
                            '14:40',
                            '404',
                            'Exemple',
                            [],
                            false,
                            false,
                            false,
                          ),
                          positionned: false,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ],
    );
  }
}
