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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/file.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/util.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scolengo_api/scolengo_api.dart';
import 'package:share_plus/share_plus.dart';

import 'default_card.dart';

class AttachmentsWidget extends StatelessWidget {
  final bool outlined;

  final Color? outlineColor;

  const AttachmentsWidget({
    Key? key,
    required this.attachments,
    this.elevation,
    this.color,
    this.outlineColor,
    this.outlined = false,
  }) : super(key: key);

  final List<Attachment> attachments;
  final double? elevation;
  final MaterialColor? color;

  @override
  Widget build(BuildContext context) {
    return DefaultCard(
        outlined: outlined,
        outlineColor: outlineColor,
        elevation: elevation,
        surfaceTintColor: color?.tint(context),
        shadowColor: color?.shadow(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pièces jointes',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            ...attachments.asMap().entries.map((entry) {
              return Column(
                children: [
                  AttachmentWidget(
                    attachment: entry.value,
                  ),
                  if (entry.key < attachments.length - 1) const Divider(height: 2),
                ],
              );
            }).toList(),
          ],
        ));
  }
}

class AttachmentWidget extends StatefulWidget {
  const AttachmentWidget({
    Key? key,
    required this.attachment,
  }) : super(key: key);
  final Attachment attachment;

  @override
  State<AttachmentWidget> createState() => _AttachmentWidgetState();
}

class _AttachmentWidgetState extends State<AttachmentWidget> {
  bool _dowloading = false;
  int? _progress;
  int? _total;
  File? _file;
  @override
  void initState() {
    DefaultCacheManager().getFileFromCache(widget.attachment.url).then((value) {
      _file = value?.file;
      setState(() {});
    });
    super.initState();
  }

  copy(File file) async {
    final path = '${(await getExternalCacheDirectories())!.first.path}/attachments/';
    await Directory(path).create(recursive: true);
    final dest = path + widget.attachment.name;
    if (file.path == dest) return;
    _file = await file.copy(dest);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      trailing: _file == null
          ? null
          : IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                await copy(_file!);
                Share.shareXFiles([XFile(_file!.path)]);
              },
            ),
      visualDensity: VisualDensity.compact,
      title: Text(widget.attachment.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.attachment.size.niceSize()}o',
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          if (_dowloading)
            LinearProgressIndicator(
              value: _progress == null ? null : _progress! / _total!,
            )
        ],
      ),
      leading: Icon(widget.attachment.name.icon),
      onTap: () {
        _dowloading = true;
        setState(() {});

        DefaultCacheManager()
            .getFileStream(widget.attachment.url,
                withProgress: true, headers: ConfigProvider.client!.headers)
            .listen((response) async {
          if (response is DownloadProgress) {
            setState(() {
              _progress = response.downloaded;
              _total = response.totalSize;
            });
          }
          if (response is FileInfo) {
            _dowloading = false;
            setState(() {});
            await copy(response.file);
            OpenFile.open(_file!.path).then((value) => print('${value.type} ${value.message}'));
          }
        }).onError((e, st) {
          _dowloading = false;
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erreur de téléchargement'),
          ));
        });
      },
    );
  }
}
