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
    await ConfigProvider.currentId!,
    DateTime.now().toIso8601String().substring(0, 10),
    DateTime.now().add(const Duration(days: 14)).toIso8601String().substring(0, 10),
  ));
  await for (final result in results) {
    yield result.data;
  }
}

Stream<List<Evaluation>> getEvaluations() async* {
  try {
    final settingsResponse = await ConfigProvider.client!
        .getEvaluationSettings(
          await ConfigProvider.currentId!,
        )
        .first;
    if (settingsResponse.data.periods.isEmpty) {
      yield [];
      return;
    }
    final responses = ConfigProvider.client!.getEvaluationServices(
      await ConfigProvider.currentId!,
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
      final r = <Evaluation>[];
      for (final e in evaluations) {
        if (e is List<Evaluation>) {
          r.addAll(e);
        } else if (e is Evaluation) {
          r.add(e);
        }
      }
      r.sort((a, b) => b.date.date().compareTo(a.date.date()));

      yield r;
    }
  } on Exception catch (e) {
    //HACK this shouldn't happen
    // - checking for 403 like this is bad
    // - permissions should be able to avoid this (I just couldn't figure it out yet)
    // - 403s also happen elsewhere
    if (e.toString().contains('403')) {
      yield [];
    } else {
      rethrow;
    }
  }
}

Stream<List<List<Evaluation>>> getEvaluationsAsTable() async* {
  final results = getEvaluations();
  await for (final evaluations in results) {
    List<List<Evaluation>> r = [];
    for (int i = 0; i < evaluations.length; i++) {
      if (i % 2 == 0) {
        r.add([evaluations[i]]);
      } else {
        r[(i / 2).floor()].add(evaluations[i]);
      }
    }
    yield r;
  }
}

Stream<List<SchoolInfo>> getSchoolInfos() async* {
  await for (final response in ConfigProvider.client!.getSchoolInfos()) {
    yield response.data;
  }
}

Stream<List<Communication>> getUnread(String folderId) async* {
  await for (final response in ConfigProvider.client!.getCommunicationsFromFolder(folderId)) {
    yield response.data.where((element) => !element.read!).toList();
  }
}

Stream<int> unreadCount() async* {
  final folderId = (await ConfigProvider.client!
          .getUsersMailSettings(ConfigProvider.credentials!.idToken.claims.subject)
          .first)
      .data
      .folders
      .firstWhere((folder) => folder.folderType == FolderType.INBOX)
      .id;
  await for (final unread in getUnread(folderId).asBroadcastStream()) {
    yield unread.length;
  }
}

switchUser(User student) async {
  if (student.school != null) {
    ConfigProvider.client!.headers['X-Skolengo-School-Id'] = student.school!.id;
    ConfigProvider.currentSchool = student.school!.id;
  }
  ConfigProvider.currentId = Future.value(student.id);
}
