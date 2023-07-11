import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/widgets/default_activity.dart';
import 'package:klient/widgets/default_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scolengo_api/scolengo_api.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  int currentStep = 0;
  bool communications = false;

  bool communicationAttachments = false;
  Map<String, bool> folders = {};

  Future<SkolengoResponse<UsersMailSettings>>? settings;
  Stream<DownloadStatus>? status;
  String ziplog = '';
  late String dir;

  final ScrollController _logController = ScrollController();

  double? zipProgress;
  @override
  void initState() {
    settings = ConfigProvider.client!
        .getUsersMailSettings(ConfigProvider.client!.credentials!.idToken.claims.subject)
        .first;
    getApplicationDocumentsDirectory().then((value) {
      dir = '${value.path}/klient/backup-${DateTime.now().millisecondsSinceEpoch}/';
      cleanup();
    });
    super.initState();
  }

  void cleanup() {
    for (final entry in Directory(dir).parent.listSync()) {
      if (entry.path.split('/').last.startsWith('backup')) {
        entry.delete(recursive: true);
        print('Deleting ${entry.path}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultSliverActivity(
        title: 'Exporter les données',
        child: Stepper(
          onStepContinue: () {
            setState(() => currentStep++);
            if (currentStep == 1) {
              status ??= download().asBroadcastStream();
              status!.last.then((value) {
                setState(() => currentStep++);
                compress();
              });
            }
          },
          currentStep: currentStep,
          controlsBuilder: (context, details) => Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                if (currentStep == 0)
                  TextButton(
                    onPressed: communications ? details.onStepContinue : null,
                    child: const Text('Continuer'),
                  )
              ],
            ),
          ),
          steps: [
            Step(
              title: const Text('Choix des données à exporter'),
              content: Column(
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: DefaultCard(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            value: communications,
                            onChanged: (value) => setState(() => communications = value ?? false),
                            title: const Text('Messagerie'),
                          ),
                          if (communications)
                            FutureBuilder<SkolengoResponse<UsersMailSettings>>(
                                future: settings,
                                builder: (context, snapshot) {
                                  final data = snapshot.data?.data;
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: Column(
                                      children: [
                                        ...(data?.folders.map(
                                              (folder) => CheckboxListTile(
                                                value: folders[folder.id] ?? false,
                                                onChanged: (value) {
                                                  setState(() {
                                                    folders[folder.id] = value ?? false;
                                                  });
                                                },
                                                title: Text(folder.name),
                                                subtitle: Text(
                                                  folder.folderType.name,
                                                  style: TextStyle(
                                                      color:
                                                          Theme.of(context).colorScheme.secondary),
                                                ),
                                              ),
                                            ) ??
                                            []),
                                        const Divider(),
                                        CheckboxListTile(
                                          value: communicationAttachments,
                                          onChanged: (value) {
                                            setState(() {
                                              communicationAttachments = value ?? false;
                                            });
                                          },
                                          title: const Text('Télécharger les pièces jointes'),
                                        ),
                                      ],
                                    ),
                                  );
                                })
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            Step(
              title: const Text('Téléchargement'),
              content: StreamBuilder<DownloadStatus>(
                  stream: status,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final status = snapshot.data!;
                    final data = <Widget>[];
                    for (int i = 0; i < status.steps.length; i++) {
                      final children = <Widget>[];
                      if (i < status.step) {
                        children.add(const Icon(Icons.check));
                      }
                      data.add(ListTile(
                        title: Text(status.steps[i]),
                        leading: i < status.step ? const Icon(Icons.check) : null,
                        subtitle: i == status.step
                            ? Column(
                                children: [
                                  if (status.progress != null)
                                    Text('${status.progress} / ${status.progressOf}'),
                                  LinearProgressIndicator(
                                      value: status.progress == null
                                          ? null
                                          : status.progress! / status.progressOf!),
                                ],
                              )
                            : null,
                      ));
                    }
                    return Column(
                      children: [
                        ...data,
                      ],
                    );
                  }),
            ),
            Step(
              title: const Text('Compression'),
              content: Column(
                children: [
                  const Text('Compression en cours'),
                  LinearProgressIndicator(value: zipProgress),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: SingleChildScrollView(
                      controller: _logController,
                      child: Text(
                        ziplog,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Step(
                title: const Text('Exporter'),
                content: Row(
                  children: [
                    ElevatedButton(
                      child: const Text('Partager'),
                      onPressed: () {
                        Share.shareXFiles([XFile('${dir}backup.zip')]);
                      },
                    ),
                    TextButton(
                        onPressed: () {
                          cleanup();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Fermer et nettoyer')),
                  ],
                ))
          ],
        ));
  }

  Stream<DownloadStatus> download() async* {
    Map<String, dynamic> meta = {};
    meta['communications'] = communications;
    meta['communicationAttachments'] = communicationAttachments;

    DownloadStatus status = (progress: null, progressOf: null, steps: [], step: 0);
    print('Exporting to $dir');
    File('${dir}index.json')
      ..createSync(recursive: true)
      ..writeAsString(jsonEncode(meta));

    if (communications) {
      status.steps.add('Paramètres de la messagerie');
    }
    yield status;

    if (communications) {
      final updatedSettings = await ConfigProvider.client!
          .getUsersMailSettings(ConfigProvider.client!.credentials!.idToken.claims.subject)
          .first;
      File('${dir}usermailsettings.json')
        ..createSync(recursive: true)
        ..writeAsString(updatedSettings.json);

      status.steps.addAll(
          updatedSettings.data.folders.where((folder) => folders[folder.id] ?? false).map<String>(
                (folder) => 'Liste ${folder.name}',
              ));
      status.steps.add('Contenu des messages');
      if (communicationAttachments) status.steps.add('Pièces jointes');
      yield status = (progress: null, progressOf: null, steps: status.steps, step: status.step + 1);
      Set<Communication> communications = {};

      for (final folderId in folders.keys.where((f) => folders[f] ?? false)) {
        final response = await ConfigProvider.client!
            .getCommunicationsFromFolder(folderId, offset: 0, limit: 1 << 32)
            .first;
        communications
            .addAll(response.data.where((a) => communications.where((b) => a.id == b.id).isEmpty));
        File('${dir}communications/$folderId.json')
          ..createSync(recursive: true)
          ..writeAsString(response.json);

        yield status =
            (progress: null, progressOf: null, steps: status.steps, step: status.step + 1);
      }
      Map<String, List<Participation>> participations = {};
      int i = 0;
      for (final communication in communications) {
        final response =
            await ConfigProvider.client!.getCommunicationParticipations(communication.id).first;
        participations[communication.id] = response.data;
        File('${dir}participations/${communication.id}.json')
          ..createSync(recursive: true)
          ..writeAsString(response.json);
        i++;
        yield status = (
          progress: i,
          progressOf: communications.length,
          steps: status.steps,
          step: status.step
        );
      }
      if (communicationAttachments) {
        yield status = (progress: 0, progressOf: 1, steps: status.steps, step: status.step + 1);

        i = 0;
        final attachments = participations.values
            .expand((e) => e)
            .where((participation) => participation.attachments != null)
            .expand((e) => e.attachments!);
        if (Platform.isLinux || Platform.isWindows) {
          databaseFactory = databaseFactoryFfi;
        }
        final path = dir.split('/')
          ..removeLast()
          ..removeLast();
        final cache = CacheManager(Config('backup',
            maxNrOfCacheObjects: 8192,
            repo: CacheObjectProvider(databaseName: 'backup', path: '${path.join('/')}/cache.db')));
        for (final attachment in attachments) {
          final file = File('${dir}attachments/${attachment.id}${attachment.name}');
          Directory('${dir}attachments/').createSync(recursive: true);
          if (!file.existsSync()) {
            try {
              final download = await cache.getSingleFile(attachment.url,
                  headers: ConfigProvider.client!.headers, key: attachment.id);
              download.copy(
                file.path,
              );
            } catch (e, st) {
              print(e);
              print(st);
            }
          }
          i++;
          yield status =
              (progress: i, progressOf: attachments.length, steps: status.steps, step: status.step);
        }
      }
      yield status = (progress: 0, progressOf: 1, steps: status.steps, step: status.step + 1);
    }
  }

  compress() async {
    final files = [
      'index.json',
      if (communications) 'usermailsettings.json',
    ];
    final directories = [
      if (communications) ...['communications', 'participations'],
      if (communicationAttachments) 'attachments',
    ];
    try {
      final result = await Process.start(
        'zip',
        [
          '-r',
          'backup.zip',
          ...files,
          ...directories,
        ],
        workingDirectory: dir,
      );
      result.stdout.listen((event) {
        setState(() {
          ziplog += const Utf8Decoder().convert(event);
          _logController.jumpTo(_logController.position.maxScrollExtent);
        });
      });
      result.exitCode.then((value) {
        setState(() {
          currentStep++;
        });
      });
    } catch (_) {
      try {
        ziplog = 'Tentative de compression avec flutter_archive';
        setState(() {});
        final zipfile = File('${dir}backup.zip');
        await ZipFile.createFromDirectory(
          sourceDir: Directory(dir),
          zipFile: zipfile,
          recurseSubDirs: true,
          onZipping: (filePath, isDirectory, progress) {
            print('ZIP progress:$progress');
            setState(() {
              zipProgress = progress / 100;
              ziplog += '\n$filePath';
              _logController.jumpTo(_logController.position.maxScrollExtent);
            });
            if (filePath == 'backup.zip') return ZipFileOperation.skipItem;
            return ZipFileOperation.includeItem;
          },
        );
        print('Done!');
        setState(() {
          currentStep++;
        });
      } catch (e, st) {
        ziplog += '\nUne erreur a eu lieu';
        ziplog += '\n$e';
        ziplog += '\n$st';
        _logController.jumpTo(_logController.position.maxScrollExtent);
        setState(() {});
      }
    }
  }
}

typedef DownloadStatus = ({
  int? progress,
  int? progressOf,
  List<String> steps,
  int step,
});
