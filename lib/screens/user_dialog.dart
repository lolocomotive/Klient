import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:flutter/services.dart';
import 'package:klient/api/client.dart';
import 'package:klient/api/student.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/screens/about.dart';
import 'package:klient/screens/debug.dart';
import 'package:klient/screens/settings.dart';
import 'package:klient/screens/setup.dart';
import 'package:klient/widgets/default_card.dart';
import 'package:klient/widgets/user_avatar.dart';

class UserDialog extends StatefulWidget {
  final void Function()? onUpdate;
  const UserDialog({this.onUpdate, Key? key}) : super(key: key);

  @override
  State<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
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
                                if (widget.onUpdate != null) {
                                  widget.onUpdate!();
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
                          ..push(MaterialPageRoute(builder: (_) => const SettingsPage()))
                              .then((value) {
                            if (widget.onUpdate != null) widget.onUpdate!();
                          });
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
                      onTap: () => Client.disconnect(context),
                    ),
                    Divider(height: 1, color: Theme.of(context).colorScheme.primary.withAlpha(80)),
                    Option(
                      icon: Icons.copy,
                      text: 'Copier le jeton d\'authentification',
                      onTap: () async {
                        Clipboard.setData(ClipboardData(text: Client.getClient().token));
                        //KosmosApp.messengerKey.currentState!
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Copié'),
                        ));
                      },
                    ),
                    if (kDebugMode)
                      Divider(
                          height: 1, color: Theme.of(context).colorScheme.primary.withAlpha(80)),
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
                      Divider(
                          height: 1, color: Theme.of(context).colorScheme.primary.withAlpha(80)),
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
      ),
    );
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
                    color: Theme.of(context).highlightColor,
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
