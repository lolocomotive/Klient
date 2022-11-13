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
import 'dart:math';

import 'package:kosmos_client/api/client.dart';
import 'package:kosmos_client/api/exercise.dart';
import 'package:kosmos_client/api/lesson.dart';
import 'package:kosmos_client/config_provider.dart';
import 'package:kosmos_client/database_provider.dart';
import 'package:kosmos_client/screens/messages.dart';
import 'package:kosmos_client/screens/setup.dart';
import 'package:kosmos_client/util.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'conversation.dart';

/// Utility class that fetches data from the API and stores it inside the database
class DatabaseManager {
  static bool loadingMessages = false;

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
    try {
      SetupPage.downloadStep = 0;
      print('Downloading grades');
      await fetchGradesData();
      SetupPage.downloadStep++;
      print('Downloading timetable');
      await fetchTimetable();
      SetupPage.downloadStep++;
      print('Downloading News');
      await fetchNewsData();
      SetupPage.downloadStep++;
      print('Downloading Messages');
      await fetchMessageData();
      SetupPage.downloadStep++;
      print('Finished downloading');
    } catch (_) {
      print('EEEE $_');
    }
  }

  /// Download/update, the associated messages and their attachments
  static fetchMessageData() async {
    if (ConfigProvider.demo) return;
    loadingMessages = true;
    int pgNumber = 0;
    try {
      while (true) {
        final result = await Client.getClient().request(
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
            await deleteConversation(conversation['id']);
          }
          modified = true;
          final batch = (await DatabaseProvider.getDB()).batch();
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
                'CanReply': conversation['modeReponse'] == 'TOUS' ? 1 : 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
          fetchSingleConversation(conversation['id'], batch);
        }
        if (!modified) {
          break;
        }
      }
      SetupPage.downloadStep++;
      await Client.getClient().process();
      if (MessagesPageState.currentState != null) {
        MessagesPageState.currentState!.reloadFromDB();
      }
      loadingMessages = false;
    } on Exception catch (e, st) {
      Util.onException(e, st);
    }
  }

  static deleteConversation(int id) async {
    await (await DatabaseProvider.getDB())
        .delete('Conversations', where: 'ID = ?', whereArgs: [id]);
    clearConversation(id);
  }

  static clearConversation(int id) async {
    final db = await DatabaseProvider.getDB();
    await db.delete('Messages', where: 'ParentID = ?', whereArgs: [id]);
    await db.delete('MessageAttachments', where: 'ParentID = ?', whereArgs: [id]);
  }

  static fetchSingleConversation(int id, Batch batch) async {
    if (ConfigProvider.demo) return;

    try {
      await Client.getClient().addRequest(Action.getConversationDetail, (conversation) async {
        String messageContents = '';
        for (final message in conversation['participations']) {
          //Generate a random message ID because the API returns the conversationID
          final messageID = Random().nextInt(4294967296 /*2^32*/);
          batch.insert(
              'Messages',
              {
                'ID': messageID,
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
                  'ParentID': messageID,
                  'URL': attachment['url'],
                  'Name': attachment['name'],
                },
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
          // Preview and LastDate are redundant in some cases, but we need to update them
          // when the user replies.
          batch.update(
              'Conversations',
              {
                'FullMessageContents': messageContents,
                'Preview': conversation['premieresLignes'],
                'LastDate': conversation['dateDernierMessage'],
              },
              where: 'ID = $id');
        }
        await batch.commit();
      }, params: [(id).toString()]);
    } on Exception catch (e, st) {
      Util.onException(e, st);
    }
  }

  /// Download all the grades
  static fetchGradesData([r = 3]) async {
    final db = await DatabaseProvider.getDB();
    if (ConfigProvider.demo) return;
    try {
      if (r == 0) return;
      try {
        final result = await Client.getClient()
            .request(Action.getGrades, params: [Client.getClient().idEtablissement ?? '0']);
        db.delete('Grades');
        for (final grade in result['listeNotes']) {
          final double value =
              double.tryParse((grade['note'] as String).replaceAll(',', '.')) ?? -1;
          db.insert(
            'Grades',
            {
              'Subject': grade['matiere'] as String,
              'Grade': value,
              'GradeString': value == -1 ? grade['note'] : null,
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
      Util.onException(e, st);
    }
  }

  /// Download all the available NewsArticles, and their associated attachments
  static fetchNewsData() async {
    final db = await DatabaseProvider.getDB();
    if (ConfigProvider.demo) return;
    try {
      final result = await Client.getClient().request(Action.getNewsArticlesEtablissement,
          params: [Client.getClient().idEtablissement ?? '0']);
      for (final newsArticle in result['articles']) {
        Client.getClient().addRequest(Action.getArticleDetails, (articleDetails) async {
          await db.insert(
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
            await db.delete(
              'NewsAttachments',
              where: 'ParentUID = ?',
              whereArgs: [newsArticle['uid']],
            );
            await db.insert('NewsAttachments', {
              'Name': attachment['name'],
              'ParentUID': newsArticle['uid'],
            });
          }
        }, params: [newsArticle['uid']]);
      }
      await Client.getClient().process();
    } on Exception catch (e, st) {
      Util.onException(e, st);
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
    final db = await DatabaseProvider.getDB();
    if (ConfigProvider.demo) return;
    try {
      //TODO clean up this horrific code
      final result = await Client.getClient().request(Action.getTimeTableEleve,
          params: [(Client.getClient().idEleve ?? 0).toString()]);

      await db.delete('Lessons');
      await db.delete('Exercises');
      await db.delete('ExerciseAttachments');

      for (final day in result['listeJourCdt']) {
        for (final lesson in day['listeSeances']) {
          //Check if this lesson is the same as the previous

          final oldLesson = await Lesson.byID(lesson['idSeance'], true);
          var shouldNotify = false;
          if (oldLesson != null) {
            shouldNotify = oldLesson.isModified != lesson['flagModif'];
          }

          db.insert(
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
            Client.getClient().addRequest(Action.getExerciseDetails, (exerciseDetails) async {
              await db.insert(
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
              await db.delete('ExerciseAttachments',
                  where: 'ParentID = ?', whereArgs: [exercise['uid']]);
              for (final attachment in exerciseDetails['pjs'] ?? []) {
                db.insert(
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
              (Client.getClient().idEleve ?? 0).toString(),
              (lesson['idSeance']).toString(),
              (exercise['uid']).toString()
            ]);
          }
          for (final exercise in lesson['enSeance'] ?? []) {
            Client.getClient().addRequest(Action.getExerciseDetails, (exerciseDetails) async {
              await db.insert(
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
              await db.delete('ExerciseAttachments',
                  where: 'ParentID = ?', whereArgs: [exercise['uid']]);
              for (final attachment in exerciseDetails['pjs'] ?? []) {
                db.insert(
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
              (Client.getClient().idEleve ?? 0).toString(),
              (lesson['idSeance']).toString(),
              (exercise['uid']).toString()
            ]);
          }
          for (final exercise in lesson['aRendre'] ?? []) {
            if ((await db.query('Exercises', where: 'ID = ?', whereArgs: [exercise['uid']]))
                .isNotEmpty) {
              continue;
            }
            Client.getClient().addRequest(Action.getExerciseDetails, (exerciseDetails) async {
              await db.insert(
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
              await db.delete('ExerciseAttachments',
                  where: 'ParentID = ?', whereArgs: [exercise['uid']]);
              for (final attachment in exerciseDetails['pjs'] ?? []) {
                db.insert(
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
              (Client.getClient().idEleve ?? 0).toString(),
              (lesson['idSeance']).toString(),
              (exercise['uid']).toString()
            ]);
          }
        }
      }
      await Client.getClient().process();
    } on Exception catch (e, st) {
      Util.onException(e, st);
    }
  }
}
