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
import 'package:scolengo_api/scolengo_api.dart';

Future<List<HomeworkAssignment>> getHomework() async {
  return (await ConfigProvider.client!.getHomeworkAssignments(
    ConfigProvider.credentials!.idToken.claims.subject,
    DateTime.now().toIso8601String().substring(0, 10),
    DateTime.now().add(const Duration(days: 14)).toIso8601String().substring(0, 10),
  ))
      .data;
}

Future<List<List<Evaluation>>> getGrades() async {
  final response = await ConfigProvider.client!
      .getEvaluationServices(ConfigProvider.credentials!.idToken.claims.subject, '');
  final evaluations = response.data.map((e) => e.evaluations).expand((e) => e).toList();

  List<List<Evaluation>> r = [];
  for (int i = 0; i < evaluations.length; i++) {
    if (i % 2 == 0) {
      r.add([evaluations[i]]);
    } else {
      r[(i / 2).floor()].add(evaluations[i]);
    }
  }
  return r;
}
