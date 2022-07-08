import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('À propos'),
              floating: true,
              forceElevated: innerBoxIsScrolled,
            )
          ];
        },
        body: Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Kosmos Client',
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
                Card(
                  margin: const EdgeInsets.all(8.0),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FutureBuilder<AppInfo>(
                      future: getGitInfo(),
                      builder: ((context, snapshot) {
                        if (snapshot.hasError) {
                          print(snapshot.error);
                          return Text('Erreur: "${snapshot.error}"');
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
                                Text(snapshot.data!.commitID.substring(0, 6))
                              ]),
                              TableRow(children: [
                                const Text('Commit origin'),
                                Text(snapshot.data!.originCommitID.substring(0, 6))
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
                ),
                Card(
                  margin: const EdgeInsets.all(8.0),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                            text: TextSpan(children: [
                              const TextSpan(text: 'Code source disponible sur '),
                              TextSpan(
                                text: 'github',
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(
                                        Uri.parse('https://github.com/lolocomotive/kosmos_client'));
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
                            text: TextSpan(children: [
                              const TextSpan(text: 'Codage/design: '),
                              TextSpan(
                                text: 'lolocomotive',
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(Uri.parse('https://github.com/lolocomotive'));
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
                            text: TextSpan(children: [
                              const TextSpan(text: 'Merci à maelgangloff pour '),
                              TextSpan(
                                text: 'kdecole-api',
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(
                                        Uri.parse('https://github.com/maelgangloff/kdecole-api'));
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
                ),
                Card(
                  margin: const EdgeInsets.all(8.0),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
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
                              text: TextSpan(children: [
                                const TextSpan(
                                    text:
                                        'Cette application et son code source sont distribués sous licence '),
                                TextSpan(
                                  text: 'GPL-3.0',
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      launchUrl(
                                          Uri.parse('https://www.gnu.org/licenses/gpl-3.0.html'));
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
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<AppInfo> getGitInfo() async {
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
}
