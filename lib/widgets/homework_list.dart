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
import 'package:klient/config_provider.dart';
import 'package:klient/widgets/default_card.dart';
import 'package:klient/widgets/exercise_card.dart';
import 'package:scolengo_api/scolengo_api.dart';

class HomeworkList extends StatelessWidget {
  final List<HomeworkAssignment> _hws;
  final String _title;
  final bool showDate;
  final bool showSubject;
  final Color color;

  const HomeworkList(this._hws, this._title, this.color,
      {Key? key, this.showDate = false, this.showSubject = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultCard(
      surfaceTintColor: Theme.of(context).brightness == Brightness.light ? color : null,
      shadowColor: Theme.of(context).brightness == Brightness.light ? color : null,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Column(
        children: [
          Text(
            _title,
            style: const TextStyle(fontSize: 16),
          ),
          ..._hws
              .map((e) => HomeworkCard(
                    e,
                    compact: ConfigProvider.compact!,
                    showDate: showDate,
                    showSubject: showSubject,
                  ))
              .toList(),
          if (_hws.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: Text(
                'Aucun contenu rensiegné',
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
        ],
      ),
    );
  }
}
