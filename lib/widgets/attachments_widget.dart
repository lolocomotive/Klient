/*
 * This file is part of the Kosmos Client (https://github.com/lolocomotive/kosmos_client)
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
import 'package:kosmos_client/api/attachment.dart';

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
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'À cause de limitations dues à l\'ENT, il est impossible de télécharger les pièces jointes depuis l\'application.'),
            ),
          );
        },
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
            ...attachments
                .map(
                  (attachment) => Row(
                    children: [Flexible(child: Text(attachment.name))],
                  ),
                )
                .toList(),
          ],
        ));
  }
}
