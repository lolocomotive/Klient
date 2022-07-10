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

import 'dart:async';

import 'package:kosmos_client/kdecole-api/client.dart';
import 'package:kosmos_client/kdecole-api/exercise.dart';
import 'package:kosmos_client/kdecole-api/lesson.dart';
import 'package:sqflite/sqflite.dart';

import '../global.dart';
import 'conversation.dart';

/// Utility class that fetches data from the API and stores it inside the database
class DatabaseManager {
  static String _cleanupHTML(String html) {
    //TODO add anchors to links
    String result = html
        .replaceAll(RegExp('title=".*"'), '')
        .replaceAll(RegExp('style=".*" type="cite"'), '')
        .replaceAll(RegExp("<a.*Consulter le message dans l'ENT<\\/a><br>"), '')
        .replaceAll('onclick="window.open(this.href);return false;"', '')
        .replaceAll('&nbsp;', '')
        .replaceAll('\r', '')
        .replaceAll('\f', '')
        .replaceAll('\n', '')
        .replaceAll(RegExp('<p>\\s+<\\/p>'), '')
        .replaceAll(RegExp('<div>\\s+<\\/div>'), '')
        .replaceAll('<p class="notsupported"></p>', '')
        .replaceAll('<div class="js-signature panel panel--full panel--margin-sm">', '')
        .replaceAll('</div>', '')
        .replaceAll('<div>', '<br>')
        .replaceAll('<div class="detail-code" style="padding: 0; border: none;">', '');
    return result;
  }

  static downloadAll() async {
    Global.step1 = false;
    Global.step2 = false;
    Global.step3 = false;
    Global.step4 = false;
    Global.step5 = false;
    print('Downloading grades');
    await fetchGradesData();
    Global.step1 = true;
    print('Downloading timetable');
    await fetchTimetable();
    Global.step2 = true;
    print('Downloading News');
    await fetchNewsData();
    Global.step3 = true;
    print('Downloading Messages');
    await fetchMessageData();
    Global.step5 = true;
    print('Finished downloading');
  }

  /// Download/update, the associated messages and their attachments
  static fetchMessageData() async {
    Global.loadingMessages = true;
    int pgNumber = 0;
    try {
      while (true) {
        final result = await Global.client!.request(
          Action.getConversations,
          params: [(pgNumber * 20).toString()],
        );
        pgNumber++;
        var modified = false;
        if (result['communications'].isEmpty) break;
        for (final conversation in result['communications']) {
          final conv = await Conversation.byID(conversation['id']);
          if (conv != null) {
            if (conv.lastDate ==
                DateTime.fromMillisecondsSinceEpoch(conversation['dateDernierMessage'])) {
              continue;
            }
            Global.db!.delete('Conversations', where: 'ID = ?', whereArgs: [conversation['id']]);
            Global.db!.delete('Messages', where: 'ParentID = ?', whereArgs: [conversation['id']]);
            Global.db!.delete('MessageAttachments',
                where: 'ParentID = ?', whereArgs: [conversation['id']]);
          }
          modified = true;
          final batch = Global.db!.batch();
          batch.insert(
              'Conversations',
              {
                'ID': conversation['id'],
                'Subject': conversation['objet'],
                'Preview': conversation['premieresLignes'],
                'HasAttachment': conversation['pieceJointe'] as bool ? 1 : 0,
                'LastDate': (conversation['dateDernierMessage']),
                'Read': conversation['etatLecture'] as bool ? 1 : 0,
                'NotificationShown': 0,
                'LastAuthor': conversation['expediteurActuel']['libelle'],
                'FirstAuthor': conversation['expediteurInitial']['libelle'],
                'FullMessageContents': '',
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
          fetchSingleConversation(conversation['id'], batch);
        }
        if (!modified) {
          break;
        }
      }
      Global.step4 = true;
      await Global.client!.process();
      if (Global.messagesState != null) {
        Global.messagesState!.reloadFromDB();
      }
      Global.loadingMessages = false;
    } on Exception catch (e, st) {
      Global.onException(e, st);
    }
  }

  static fetchSingleConversation(int id, Batch batch) async {
    try {
      String messageContents = '';
      await Global.client!.addRequest(Action.getConversationDetail, (messages) async {
        for (final message in messages['participations']) {
          batch.insert(
              'Messages',
              {
                'ParentID': id,
                'HTMLContent': _cleanupHTML(message['corpsMessage']),
                'Author': message['redacteur']['libelle'],
                'DateSent': message['dateEnvoi'],
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
          messageContents += ('${_cleanupHTML(message['corpsMessage'])}\n')
              .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');
          for (final attachment in message['pjs'] ?? []) {
            batch.insert(
                'MessageAttachments',
                {
                  'ParentID': message['id'],
                  'URL': attachment['url'],
                  'Name': attachment['name'],
                },
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
          batch.update('Conversations', {'FullMessageContents': messageContents},
              where: 'ID = $id');
        }
        await batch.commit();
      }, params: [(id).toString()]);
    } on Exception catch (e, st) {
      Global.onException(e, st);
    }
  }

  /// Download all the grades
  static fetchGradesData([r = 3]) async {
    try {
      if (r == 0) return;
      try {
        final result = await Global.client!
            .request(Action.getGrades, params: [Global.client!.idEtablissement ?? '0']);
        for (final grade in result['listeNotes']) {
          Global.db!.insert(
            'Grades',
            {
              'Subject': grade['matiere'] as String,
              'Grade': double.parse((grade['note'] as String).replaceAll(',', '.')),
              'Of': (grade['bareme'] as int).toDouble(),
              'Date': grade['date'] as int,
              'UniqueID': (grade['date'] as int).toString() +
                  (grade['matiere'] as String) +
                  (grade['note'] as String) +
                  (grade['bareme'] as int).toString(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } on NetworkException403 catch (_) {
        rethrow;
      } on Error catch (_) {
        await Future.delayed(const Duration(seconds: 1));
        fetchGradesData(r - 1);
      }
    } on Exception catch (e, st) {
      Global.onException(e, st);
    }
  }

  /// Download all the available NewsArticles, and their associated attachments
  static fetchNewsData() async {
    try {
      final result = await Global.client!.request(Action.getNewsArticlesEtablissement,
          params: [Global.client!.idEtablissement ?? '0']);
      for (final newsArticle in result['articles']) {
        Global.client!.addRequest(Action.getArticleDetails, (articleDetails) async {
          await Global.db!.insert(
            'NewsArticles',
            {
              'UID': newsArticle['uid'],
              'Type': articleDetails['type'],
              'Author': articleDetails['auteur'],
              'Title': articleDetails['titre'],
              'PublishingDate': articleDetails['date'],
              'HTMLContent': _cleanupHTML(articleDetails['codeHTML']),
              'URL': articleDetails['url'],
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          for (final attachment in articleDetails['pjs'] ?? []) {
            // Prevent duplicates since the given attachment UID is null we have to use
            // auto-incremented IDs and delete all each time we update
            await Global.db!.delete(
              'NewsAttachments',
              where: 'ParentUID = ?',
              whereArgs: [newsArticle['uid']],
            );
            await Global.db!.insert('NewsAttachments', {
              'Name': attachment['name'],
              'ParentUID': newsArticle['uid'],
            });
          }
        }, params: [newsArticle['uid']]);
      }
      await Global.client!.process();
    } on Exception catch (e, st) {
      Global.onException(e, st);
    }
  }

  /// Returns the ID of the lesson that occurs at the timestamp, returns null if nothing is found
  static int? _lessonIdByTimestamp(int timestamp, Iterable<dynamic> listeJourCdt) {
    for (final day in listeJourCdt) {
      for (final lesson in day['listeSeances']) {
        if (lesson['hdeb'] == timestamp) {
          return lesson['idSeance'];
        }
      }
    }
    return null;
  }

  /// Download the timetable from D-7 to D+7 with the associated [Exercise]s and their attachments
  static fetchTimetable() async {
    try {
      //TODO clean up this horrific code
      final result = await Global.client!
          .request(Action.getTimeTableEleve, params: [(Global.client!.idEleve ?? 0).toString()]);
      for (final day in result['listeJourCdt']) {
        for (final lesson in day['listeSeances']) {
          //Check if this lesson is the same as the previous

          final oldLesson = await Lesson.byID(lesson['idSeance'], true);
          var shouldNotify = false;
          if (oldLesson != null) {
            shouldNotify = oldLesson.isModified != lesson['flagModif'];
          }

          Global.db!.insert(
            'Lessons',
            {
              'ID': lesson['idSeance'],
              'LessonDate': lesson['hdeb'],
              'StartTime': lesson['heureDebut'],
              'EndTime': lesson['heureFin'],
              'Room': lesson['salle'],
              'Title': lesson['titre'],
              'Subject': lesson['matiere'],
              'IsModified': lesson['flagModif'] ? 1 : 0,
              'ShouldNotify': shouldNotify ? 1 : 0,
              'ModificationMessage': lesson['motifModif'],
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          for (final exercise in lesson['aFaire'] ?? []) {
            Global.client!.addRequest(Action.getExerciseDetails, (exerciseDetails) async {
              await Global.db!.insert(
                'Exercises',
                {
                  'Type': exercise['type'],
                  'Title': exerciseDetails['titre'],
                  'ID': exercise['uid'],
                  'LessonFor': _lessonIdByTimestamp(exercise['date'], result['listeJourCdt']),
                  'DateFor': exercise['date'],
                  'ParentDate': lesson['hdeb'],
                  'ParentLesson': lesson['idSeance'],
                  'HTMLContent': _cleanupHTML(exerciseDetails['codeHTML']),
                  'Done': exerciseDetails['flagRealise'] ? 1 : 0,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              for (final attachment in exerciseDetails['pjs'] ?? []) {
                Global.db!.insert(
                  'ExerciseAttachments',
                  {
                    'ID': attachment['idRessource'],
                    'ParentID': exercise['uid'],
                    'URL': attachment['url'],
                    'Name': attachment['name']
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }, params: [
              (Global.client!.idEleve ?? 0).toString(),
              (lesson['idSeance']).toString(),
              (exercise['uid']).toString()
            ]);
          }
          for (final exercise in lesson['enSeance'] ?? []) {
            Global.client!.addRequest(Action.getExerciseDetails, (exerciseDetails) async {
              await Global.db!.insert(
                'Exercises',
                {
                  'Type': 'Cours',
                  'Title': exerciseDetails['titre'],
                  'ID': exercise['uid'],
                  'ParentDate': exercise['date'],
                  'ParentLesson': lesson['idSeance'],
                  'HTMLContent': _cleanupHTML(exerciseDetails['codeHTML']),
                  'Done': exerciseDetails['flagRealise'] ? 1 : 0,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              for (final attachment in exerciseDetails['pjs'] ?? []) {
                Global.db!.insert(
                  'ExerciseAttachments',
                  {
                    'ID': attachment['idRessource'],
                    'ParentID': exercise['uid'],
                    'URL': attachment['url'],
                    'Name': attachment['name']
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }, params: [
              (Global.client!.idEleve ?? 0).toString(),
              (lesson['idSeance']).toString(),
              (exercise['uid']).toString()
            ]);
          }
          for (final exercise in lesson['aRendre'] ?? []) {
            if ((await Global.db!.query('Exercises', where: 'ID = ?', whereArgs: [exercise['uid']]))
                .isNotEmpty) {
              continue;
            }
            Global.client!.addRequest(Action.getExerciseDetails, (exerciseDetails) async {
              await Global.db!.insert(
                'Exercises',
                {
                  'Type': exercise['type'],
                  'Title': exerciseDetails['titre'],
                  'ID': exercise['uid'],
                  'LessonFor': lesson['idSeance'],
                  'DateFor': exerciseDetails['date'],
                  'ParentDate': exercise['date'],
                  'ParentLesson': _lessonIdByTimestamp(exercise['date'], result['listeJourCdt']),
                  'HTMLContent': _cleanupHTML(exerciseDetails['codeHTML']),
                  'Done': exerciseDetails['flagRealise'] ? 1 : 0,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              for (final attachment in exerciseDetails['pjs'] ?? []) {
                Global.db!.insert(
                  'ExerciseAttachments',
                  {
                    'ID': attachment['idRessource'],
                    'ParentID': exercise['uid'],
                    'URL': attachment['url'],
                    'Name': attachment['name']
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }, params: [
              (Global.client!.idEleve ?? 0).toString(),
              (lesson['idSeance']).toString(),
              (exercise['uid']).toString()
            ]);
          }
        }
      }
      await Global.client!.process();
    } on Exception catch (e, st) {
      Global.onException(e, st);
    }
  }
}
