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
import 'package:klient/util.dart';
import 'package:scolengo_api/scolengo_api.dart';

import 'default_card.dart';

class AttachmentsWidget extends StatelessWidget {
  const AttachmentsWidget({
    Key? key,
    required this.attachments,
    this.elevation,
  }) : super(key: key);

  final List<Attachment> attachments;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    return DefaultCard(
        elevation: elevation,
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
                  ListTile(
                    title: Text(entry.value.name),
                    subtitle: Text('${entry.value.size.niceSize()}o'),
                    leading: const Icon(Icons.audio_file),
                    onTap: () => print('download'),
                  ),
                  if (entry.key < attachments.length - 1) const Divider(),
                ],
              );
            }).toList(),
          ],
        ));
  }
}
