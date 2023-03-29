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

import 'package:flutter/material.dart';
import 'package:klient/api/client.dart';
import 'package:klient/api/lesson.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/main.dart';
import 'package:klient/widgets/color_picker.dart';
import 'package:klient/widgets/lesson_card.dart';
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
                            value: Client.apiurl,
                            isExpanded: true,
                            items: KlientApp.dropdownItems,
                            onChanged: (dynamic newValue) async {
                              await ConfigProvider.getStorage()
                                  .write(key: 'apiurl', value: newValue);
                              Client.apiurl = newValue;
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
                      initialValue: ConfigProvider.notifMsgEnabled,
                      onToggle: (value) {
                        ConfigProvider.setMessageNotifications(value, () {
                          setState(() {});
                        });
                      },
                      leading: const Icon(Icons.message_outlined),
                      title: const Text('Messagerie'),
                      description:
                          const Text('Recevoir une notification quand il y a un nouveau message'),
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
                                  value: ConfigProvider.enforcedBrightness == null
                                      ? 'default'
                                      : ConfigProvider.enforcedBrightness == Brightness.light
                                          ? 'light'
                                          : 'dark',
                                  items: const [
                                    DropdownMenuItem(value: 'default', child: Text('Système')),
                                    DropdownMenuItem(value: 'light', child: Text('Clair')),
                                    DropdownMenuItem(value: 'dark', child: Text('Sombre')),
                                  ],
                                  onChanged: (dynamic value) {
                                    ConfigProvider.getStorage()
                                        .write(key: 'display.enforcedBrightness', value: value);
                                    ConfigProvider.enforcedBrightness = value == 'light'
                                        ? Brightness.light
                                        : value == 'dark'
                                            ? Brightness.dark
                                            : null;
                                    // If we don't setState here the value does not update when the setting does not change what is displayed.
                                    setState(() {});
                                    KlientState.currentState!.setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SettingsTile(
                          leading: const Icon(Icons.color_lens),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Couleur principale'),
                              ColorPicker(
                                color: ConfigProvider.enforcedColor,
                                onChange: (color) {
                                  ConfigProvider.setColor(color);
                                  KlientState.currentState!.setState(() {});
                                },
                              )
                            ],
                          )),
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
    bool icon = false;
    try {
      SettingsTheme.of(context);
      icon = true;
    } catch (_) {}
    final boldPrimary = TextStyle(
        fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 14);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0, top: 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon)
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Icon(Icons.display_settings,
                      color: SettingsTheme.of(context).themeData.leadingIconsColor),
                ),
              const Text('Style d\'affichage'),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    ConfigProvider.getStorage().write(key: 'display.compact', value: 'false');
                    ConfigProvider.compact = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: ConfigProvider.compact! ? null : Theme.of(context).highlightColor,
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
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    ConfigProvider.getStorage().write(key: 'display.compact', value: 'true');
                    ConfigProvider.compact = true;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: ConfigProvider.compact! ? Theme.of(context).highlightColor : null,
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
