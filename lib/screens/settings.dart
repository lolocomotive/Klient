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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Global.theme!.colorScheme.background,
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Les paramètres ne font rien pour l'instant",
              style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          Expanded(
            child: SettingsList(
              sections: [
                SettingsSection(
                  title: Text(
                    'Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    ),
                  ),
                  tiles: <SettingsTile>[
                    SettingsTile.switchTile(
                      initialValue: notifMsgEnabled,
                      onToggle: (_) {
                        notifMsgEnabled = !notifMsgEnabled;
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
