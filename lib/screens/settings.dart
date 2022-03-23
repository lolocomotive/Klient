import 'package:flutter/material.dart';
import 'package:kosmos_client/main.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Global.theme!.colorScheme.background,
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: Column(
        children: const [Text('Dinkdonk')],
      ),
    );
  }
}
