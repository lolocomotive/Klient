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

import 'package:klient/config_provider.dart';
import 'package:klient/util.dart';
import 'package:scolengo_api/scolengo_api.dart';

Stream<List<HomeworkAssignment>> getHomework() async* {
  final results = (ConfigProvider.client!.getHomeworkAssignments(
    await ConfigProvider.currentlySelectedId!,
    DateTime.now().toIso8601String().substring(0, 10),
    DateTime.now().add(const Duration(days: 14)).toIso8601String().substring(0, 10),
  ));
  await for (final result in results) {
    yield result.data;
  }
}

Stream<List<List<Evaluation>>> getGrades() async* {
  final settingsResponse = await ConfigProvider.client!
      .getEvaluationSettings(
        await ConfigProvider.currentlySelectedId!,
      )
      .first;
  if (settingsResponse.data.periods.isEmpty) {
    yield [];
    return;
  }
  final responses = ConfigProvider.client!.getEvaluationServices(
    await ConfigProvider.currentlySelectedId!,
    settingsResponse.data.periods.firstWhere(
      (element) =>
          element.startDate.date().isBefore(DateTime.now()) &&
          element.endDate.date().isAfter(DateTime.now()),
      orElse: () {
        return settingsResponse.data.periods.first;
      },
    ).id,
  );
  await for (final response in responses) {
    final evaluations = response.data.map((e) {
      if (e is Evaluation) {
        return e;
      } else if (e is EvaluationService) {
        return e.evaluations;
      } else {
        throw Exception('Unknown evalutation type: ${e.runtimeType}');
      }
    });
    final evaluationsExpanded = <Evaluation>[];
    for (final e in evaluations) {
      if (e is List<Evaluation>) {
        evaluationsExpanded.addAll(e);
      } else if (e is Evaluation) {
        evaluationsExpanded.add(e);
      }
    }
    evaluationsExpanded.sort((a, b) => b.date.date().compareTo(a.date.date()));

    List<List<Evaluation>> r = [];
    for (int i = 0; i < evaluationsExpanded.length; i++) {
      if (i % 2 == 0) {
        r.add([evaluationsExpanded[i]]);
      } else {
        r[(i / 2).floor()].add(evaluationsExpanded[i]);
      }
    }
    yield r;
  }
}
