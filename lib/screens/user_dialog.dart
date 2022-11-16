import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:kosmos_client/api/client.dart';
import 'package:kosmos_client/api/student.dart';
import 'package:kosmos_client/config_provider.dart';
import 'package:kosmos_client/database_provider.dart';
import 'package:kosmos_client/screens/about.dart';
import 'package:kosmos_client/screens/debug.dart';
import 'package:kosmos_client/screens/settings.dart';
import 'package:kosmos_client/screens/setup.dart';
import 'package:kosmos_client/widgets/default_card.dart';
import 'package:kosmos_client/widgets/user_avatar.dart';
import 'package:restart_app/restart_app.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class UserDialog extends StatefulWidget {
  final void Function()? onStudentChange;
  const UserDialog({this.onStudentChange, Key? key}) : super(key: key);

  @override
  State<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                ConfigProvider.username ?? '',
                style: TextStyle(fontSize: MediaQuery.of(context).textScaleFactor * 30),
              ),
            ),
            if (Client.students.length > 1)
              DefaultCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...Client.students
                        .map((student) => UserWidget(student, () {
                              Client.currentlySelected = student;
                              setState(() {});
                              Navigator.of(context).pop();
                              if (widget.onStudentChange != null) {
                                widget.onStudentChange!();
                              }
                            }))
                        .toList(),
                  ],
                ),
              ),
            DefaultCard(
              child: Column(
                children: [
                  Option(
                    icon: Icons.settings_outlined,
                    text: 'Paramètres',
                    onTap: () {
                      Navigator.of(context)
                        ..pop()
                        ..push(MaterialPageRoute(builder: (_) => const SettingsPage()));
                    },
                  ),
                  Divider(height: 1, color: Theme.of(context).colorScheme.primary.withAlpha(80)),
                  Option(
                    icon: Icons.info_outlined,
                    text: 'À propos',
                    onTap: () {
                      Navigator.of(context)
                        ..pop()
                        ..push(MaterialPageRoute(builder: (_) => const AboutPage()));
                    },
                  ),
                  Divider(height: 1, color: Theme.of(context).colorScheme.primary.withAlpha(80)),
                  Option(
                    icon: Icons.logout_outlined,
                    text: 'Se déconnecter',
                    onTap: () => _disconnect(context),
                  ),
                  if (kDebugMode)
                    Divider(height: 1, color: Theme.of(context).colorScheme.primary.withAlpha(80)),
                  if (kDebugMode)
                    Option(
                      text: 'Debug',
                      icon: Icons.bug_report_outlined,
                      onTap: () {
                        Navigator.of(context)
                          ..pop()
                          ..push(MaterialPageRoute(builder: (_) => const DebugScreen()));
                      },
                    ),
                  if (kDebugMode)
                    Divider(height: 1, color: Theme.of(context).colorScheme.primary.withAlpha(80)),
                  if (kDebugMode)
                    Option(
                      text: 'Initial setup',
                      icon: Icons.bug_report_outlined,
                      onTap: () {
                        Navigator.of(context)
                          ..pop()
                          ..push(MaterialPageRoute(builder: (_) => SetupPage(() {})));
                      },
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  _disconnect(BuildContext context) async {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [CircularProgressIndicator()],
        ),
      );
    }));
    Client.getClient().clear();
    try {
      await Client.getClient().request(Action.logout);
    } catch (_) {}
    await (await DatabaseProvider.getDB()).close();
    await deleteDatabase((await DatabaseProvider.getDB()).path);
    await ConfigProvider.getStorage().deleteAll();
    await ConfigProvider.load();
    await DatabaseProvider.initDB();
    await Restart.restartApp();
  }
}

class UserWidget extends StatelessWidget {
  final Student student;
  final void Function() onTap;

  const UserWidget(
    this.student,
    this.onTap, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Row(children: [
              SizedBox(
                  height: MediaQuery.of(context).textScaleFactor * 55,
                  child: UserAvatar(student.name.split(' ').map((e) => e[0]).join())),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(student.name),
              ),
            ]),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: student.uid == Client.currentlySelected!.uid ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    color: Colors.deepPurpleAccent.shade100.withAlpha(80),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Option extends StatelessWidget {
  final IconData icon;
  final String text;
  final void Function()? onTap;

  const Option({
    required this.icon,
    required this.text,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(icon),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(text),
            )
          ],
        ),
      ),
    );
  }
}
