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
import 'package:klient/api/color_provider.dart';
import 'package:klient/util.dart';
import 'package:scolengo_api/scolengo_api.dart';

class EvaluationCard extends StatelessWidget {
  final Evaluation _evaluation;
  final bool compact;

  const EvaluationCard(this._evaluation, {Key? key, this.compact = true}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final MaterialColor color = ColorProvider.getColor(_evaluation.subject.id);
    final titleRow = Row(
      mainAxisAlignment: compact ? MainAxisAlignment.start : MainAxisAlignment.spaceAround,
      children: [
        Flexible(
          child: Text(
            '${_evaluation.subject.label} ',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: compact ? null : Colors.black,
            ),
          ),
        ),
        Text(
          _evaluation.date.format(),
          textAlign: TextAlign.center,
          style: TextStyle(color: compact ? null : Colors.black),
        ),
      ],
    );
    return Flexible(
      child: Card(
          surfaceTintColor:
              Theme.of(context).brightness == Brightness.light ? color : color.shade100,
          shadowColor: Theme.of(context).brightness == Brightness.light
              ? color
              : color.shade200.withAlpha(100),
          margin: const EdgeInsets.all(8.0),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: compact
                ? BoxDecoration(
                    border: Border(
                      left: BorderSide(color: color.shade200, width: 6),
                    ),
                  )
                : null,
            padding: EdgeInsets.all(compact ? 8 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact)
                  titleRow
                else
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    color: ColorProvider.getColor(_evaluation.subject.id).shade200,
                    child: titleRow,
                  ),
                if (compact)
                  Row(
                    children: [
                      Text(
                        _evaluation.result.mark?.toString().replaceAll('.', ',') ??
                            _evaluation.result.nonEvaluationReason!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (_evaluation.scale != 20) Text('/${_evaluation.scale}')
                    ],
                  )
                else
                  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: SizedBox(
                          width: 50,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _evaluation.result.mark?.toString().replaceAll('.', ',') ??
                                    _evaluation.result.nonEvaluationReason!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const Divider(height: 10),
                              Text(_evaluation.scale.toString())
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          )),
    );
  }
}
