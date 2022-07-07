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
import 'package:kosmos_client/global.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifMsgEnabled = false;
  bool notifCalEnabled = false;
  _SettingsPageState() {
    _readPrefs();
  }
  _readPrefs() async {
    notifMsgEnabled =
        await Global.storage!.read(key: 'notifications.messages') == 'true';
    notifCalEnabled =
        await Global.storage!.read(key: 'notifications.calendar') == 'true';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Global.theme!.colorScheme.background,
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SettingsList(
              sections: [
                SettingsSection(
                    title: Text(
                      'API URL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    tiles: [
                      SettingsTile(
                        title: DropdownButton(
                            value: Global.apiurl,
                            isExpanded: true,
                            items: Global.dropdownItems,
                            onChanged: (dynamic newValue) async {
                              await Global.storage!
                                  .write(key: 'apirul', value: newValue);
                              Global.apiurl = newValue;
                              setState(() {});
                            }),
                      ),
                    ]),
                SettingsSection(
                  title: Text(
                    'Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  tiles: <SettingsTile>[
                    SettingsTile.switchTile(
                      initialValue: notifMsgEnabled,
                      onToggle: (_) {
                        notifMsgEnabled = !notifMsgEnabled;
                        Global.storage!.write(
                            key: 'notifications.messages',
                            value: notifMsgEnabled ? 'true' : 'false');
                        setState(() {});
                      },
                      leading: const Icon(Icons.message_outlined),
                      title: const Text('Messagerie'),
                      description: const Text(
                          'Recevoir une notification quand il y a un nouveau message'),
                    ),
                    SettingsTile.switchTile(
                      initialValue: notifCalEnabled,
                      onToggle: (_) {
                        notifCalEnabled = !notifCalEnabled;
                        Global.storage!.write(
                            key: 'notifications.calendar',
                            value: notifCalEnabled ? 'true' : 'false');
                        setState(() {});
                      },
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Emploi du temps'),
                      description: const Text(
                          'Recevoir une notification quand une séance est annulée'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
