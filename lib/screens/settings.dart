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
import 'package:klient/config_provider.dart';
import 'package:klient/main.dart';
import 'package:klient/screens/export.dart';
import 'package:klient/widgets/color_picker.dart';
import 'package:klient/widgets/default_activity.dart';
import 'package:klient/widgets/lesson_card.dart';
import 'package:scolengo_api/scolengo_api.dart';
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
    return DefaultActivity(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      child: Column(
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
                    'Notifications',
                    style: boldPrimary,
                  ),
                  tiles: <SettingsTile>[
                    SettingsTile.switchTile(
                      initialValue: ConfigProvider.notificationSettings![NotificationType.messages],
                      onToggle: (value) {
                        ConfigProvider.setNotifications(value, () {
                          setState(() {});
                        }, NotificationType.messages);
                      },
                      leading: const Icon(Icons.message_outlined),
                      title: const Text('Messagerie'),
                      description:
                          const Text('Recevoir une notification quand il y a un nouveau message'),
                    ),
                    SettingsTile.switchTile(
                      initialValue:
                          ConfigProvider.notificationSettings![NotificationType.evaluations],
                      onToggle: (value) {
                        ConfigProvider.setNotifications(value, () {
                          setState(() {});
                        }, NotificationType.evaluations);
                      },
                      leading: const Icon(Icons.auto_graph_outlined),
                      title: const Text('Dernières notes'),
                      description:
                          const Text('Recevoir une notification quand il y a une nouvelle note'),
                    ),
                    SettingsTile.switchTile(
                      initialValue: ConfigProvider.notificationSettings![NotificationType.homework],
                      onToggle: (value) {
                        ConfigProvider.setNotifications(value, () {
                          setState(() {});
                        }, NotificationType.homework);
                      },
                      leading: const Icon(Icons.today_outlined),
                      title: const Text('Travail à faire'),
                      description: const Text(
                          'Recevoir une notification quand un travail à faire est ajouté'),
                    ),
                    SettingsTile.switchTile(
                      initialValue: ConfigProvider.notificationSettings![NotificationType.info],
                      onToggle: (value) {
                        ConfigProvider.setNotifications(value, () {
                          setState(() {});
                        }, NotificationType.info);
                      },
                      leading: const Icon(Icons.newspaper),
                      title: const Text('Actualités'),
                      description:
                          const Text('Recevoir une notification quand une actualité est publiée'),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Thème'),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.only(left: 16, right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: ElevationOverlay.applySurfaceTint(
                                  Theme.of(context).colorScheme.surface,
                                  Theme.of(context).colorScheme.primary,
                                  2,
                                ),
                              ),
                              child: DropdownButton(
                                borderRadius: BorderRadius.circular(16),
                                dropdownColor: ElevationOverlay.applySurfaceTint(
                                  Theme.of(context).colorScheme.surface,
                                  Theme.of(context).colorScheme.primary,
                                  4,
                                ),
                                underline: Container(),
                                value: ConfigProvider.enforcedBrightness == null
                                    ? 'default'
                                    : ConfigProvider.enforcedBrightness == Brightness.light
                                        ? 'light'
                                        : 'dark',
                                items: const [
                                  DropdownMenuItem(
                                      value: 'default',
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                        child: Text('Système'),
                                      )),
                                  DropdownMenuItem(
                                      value: 'light',
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                        child: Text('Clair'),
                                      )),
                                  DropdownMenuItem(
                                      value: 'dark',
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                        child: Text('Sombre'),
                                      )),
                                ],
                                onChanged: (dynamic value) {
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
                                ConfigProvider.enforcedColor = color;
                                KlientState.currentState!.setState(() {});
                              },
                            )
                          ],
                        )),
                    SettingsTile(
                      title: const CompactSelector(),
                    )
                  ],
                ),
                SettingsSection(
                    title: Text(
                      'Données personnelles',
                      style: boldPrimary,
                    ),
                    tiles: <SettingsTile>[
                      SettingsTile(
                        title: const Text('Exporter les données'),
                        leading: const Icon(Icons.import_export),
                        onPressed: (context) => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (context) => const ExportPage())),
                      )
                    ]),
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
  final demoLesson = Lesson(
      canceled: false,
      startDateTime: DateTime.now().toIso8601String(),
      endDateTime: DateTime.now().add(const Duration(minutes: 55)).toIso8601String(),
      id: '',
      location: '404',
      title: 'Exemple',
      locationComplement: null,
      subject: Subject(
        id: '',
        label: 'Exemple',
        color: 'null',
        type: 'subject',
      ),
      type: 'lesson');
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
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
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
                          demoLesson,
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
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
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
                          demoLesson,
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
