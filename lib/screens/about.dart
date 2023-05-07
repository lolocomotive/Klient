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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klient/widgets/default_activity.dart';
import 'package:klient/widgets/default_card.dart';
import 'package:klient/widgets/exception_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultSliverActivity(
      title: 'À propos',
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Klient',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Text(
                      'Un client alternatif pour l\'ENT (kdecole/skolengo/kosmos education/mon bureau numérique etc...)'),
                ),
                DefaultCard(
                  child: FutureBuilder<AppInfo>(
                    future: AppInfo.getAppInfo(),
                    builder: ((context, snapshot) {
                      if (snapshot.hasError) {
                        return ExceptionWidget(e: snapshot.error!, st: snapshot.stackTrace!);
                      } else if (snapshot.connectionState == ConnectionState.done) {
                        return Table(
                          children: [
                            TableRow(children: [
                              const Text('Version de l\'application'),
                              Text(snapshot.data!.version)
                            ]),
                            TableRow(
                                children: [const Text('Branche'), Text(snapshot.data!.branch)]),
                            TableRow(children: [
                              const Text('Commit'),
                              Text(snapshot.data!.commitID.substring(0, 7))
                            ]),
                            TableRow(children: [
                              const Text('Commit origin'),
                              Text(snapshot.data!.originCommitID.substring(0, 7))
                            ]),
                          ],
                        );
                      } else if (snapshot.data == null) {
                        return const Center(child: CircularProgressIndicator());
                      } else {
                        return const Text('???');
                      }
                    }),
                  ),
                ),
                DefaultCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Contributeurs',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                        child: RichText(
                          text: TextSpan(
                              style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                              children: [
                                const TextSpan(text: 'Code source disponible sur '),
                                TextSpan(
                                  text: 'github',
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      launchUrl(Uri.parse('https://github.com/lolocomotive/klient'),
                                          mode: LaunchMode.externalApplication);
                                    },
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                        child: RichText(
                          text: TextSpan(
                              style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                              children: [
                                const TextSpan(text: 'Codage/design: '),
                                TextSpan(
                                  text: 'lolocomotive',
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      launchUrl(Uri.parse('https://github.com/lolocomotive'),
                                          mode: LaunchMode.externalApplication);
                                    },
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                        child: RichText(
                          text: TextSpan(
                              style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                              children: [
                                const TextSpan(text: 'Merci à maelgangloff pour '),
                                TextSpan(
                                  text: 'kdecole-api',
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      launchUrl(
                                          Uri.parse('https://github.com/maelgangloff/kdecole-api'),
                                          mode: LaunchMode.externalApplication);
                                    },
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(
                                    text: ' sans quoi ce projet n\'aurait pas été possible.')
                              ]),
                        ),
                      ),
                    ],
                  ),
                ),
                DefaultCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'License',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                        child: RichText(
                          text: TextSpan(
                              style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                              children: [
                                const TextSpan(
                                    text:
                                        'Cette application et son code source sont distribués sous licence '),
                                TextSpan(
                                  text: 'GPL-3.0',
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      launchUrl(
                                          Uri.parse('https://www.gnu.org/licenses/gpl-3.0.html'),
                                          mode: LaunchMode.externalApplication);
                                    },
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppInfo {
  String commitID;
  String originCommitID;
  String branch;
  String version;
  String name;
  String signature;
  String build;
  AppInfo({
    required this.commitID,
    required this.originCommitID,
    required this.branch,
    required this.version,
    required this.name,
    required this.signature,
    required this.build,
  });
  static Future<AppInfo> getAppInfo() async {
    final head = await rootBundle.loadString('.git/HEAD');
    final originCommitId = await rootBundle.loadString('.git/ORIG_HEAD');
    final branch = head.split('/').last.replaceAll('\n', '');
    final commitId = await rootBundle.loadString('.git/refs/heads/$branch');

    final packageInfo = await PackageInfo.fromPlatform();
    return AppInfo(
      commitID: commitId,
      originCommitID: originCommitId,
      branch: branch,
      name: packageInfo.appName,
      signature: packageInfo.buildSignature,
      build: packageInfo.buildNumber,
      version: packageInfo.version,
    );
  }
}
