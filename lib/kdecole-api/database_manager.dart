import 'dart:io';

import 'package:kosmos_client/kdecole-api/client.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseManager {
  static fetchMessageData(Client client, Database db) async {
    final result = await client.request(Action.getConversations);
    var nMessages = 0;
    for (final conversation in result['communications']) {
      db.insert('Conversations', {
        'ID': conversation['id'],
        'Subject': conversation['objet'],
        'Preview': conversation['premieresLignes'],
        'HasAttachment': (conversation['pieceJointe'] as bool) ? 1 : 0,
        'LastDate': (conversation['dateDernierMessage'])
      });
      final messages = await client.request(Action.getConversationDetail,
          params: [(conversation['id'] as int).toString()]);
      for (final message in messages['participations']) {
        db.insert('Messages', {
          'ParentID': conversation['id'],
          'HTMLContent': message['corpsMessage'],
          'Author': message['redacteur']['libelle']
        });
        for (final attachment in message['pjs'] ?? []) {
          db.insert('MessageAttachments', {
            'ID': attachment['idRessource'],
            'ParentID': message['id'],
            'URL': attachment['url'],
            'Name': attachment['name']
          });
        }
        nMessages++;
      }
    }
  }

  static fetchNewsData(Client client, Database db) async {
    final result = await client.request(Action.getNewsArticlesEtablissement,
        params: [client.idEtablissement ?? '0']);
    for (final newsArticle in result['articles']) {
      final articleDetails = await client
          .request(Action.getArticleDetails, params: [newsArticle['uid']]);
      await db.insert('NewsArticles', {
        'UID': newsArticle['uid'],
        'Type': articleDetails['type'],
        'Author': articleDetails['auteur'],
        'Title': articleDetails['titre'],
        'PublishingDate': articleDetails['date'],
        'HTMLContent': articleDetails['codeHTML'],
        'URL': articleDetails['url'],
      });
    }
  }

  static int _lessonIDByTimestamp(
      int timestamp, Iterable<dynamic> listeJourCdt) {
    for (final day in listeJourCdt) {
      for (final lesson in day['listeSeances']) {
        if (lesson['hdeb'] == timestamp) {
          return lesson['idSeance'];
        }
      }
    }
    return 0;
  }

  static fetchTimetable(Client client, Database db) async {
    final result = await client.request(Action.getTimeTableEleve,
        params: [(client.idEleve ?? 0).toString()]);
    for (final day in result['listeJourCdt']) {
      for (final lesson in day['listeSeances']) {
        db.insert('Lessons', {
          'ID': lesson['idSeance'],
          'LessonDate': lesson['hdeb'],
          'StartTime': lesson['heureDebut'],
          'EndTime': lesson['heureFin'],
          'Room': lesson['salle'],
          'Title': lesson['titre'],
          'Subject': lesson['matiere'],
          'IsModified': lesson['flagModif'] ? 1 : 0,
          'ModificationMessage': lesson['motifModif'],
        });

        for (final exercise in lesson['aFaire'] ?? []) {
          final exerciseDetails =
              await client.request(Action.getExerciseDetails, params: [
            (client.idEleve ?? 0).toString(),
            (lesson['idSeance']).toString(),
            (exercise['uid']).toString()
          ]);
          db.insert('Exercises', {
            'Type': exercise['type'],
            'Title': exerciseDetails['titre'],
            'ID': exercise['uid'],
            'LessonFor':
                _lessonIDByTimestamp(exercise['date'], result['listeJourCdt']),
            'DateFor': exercise['date'],
            'ParentDate': lesson['hdeb'],
            'ParentLesson': lesson['idSeance'],
            'HTMLContent': exerciseDetails['codeHTML'],
            'Done': exerciseDetails['flagRealise'] ? 1 : 0,
          });
          for (final attachment in exerciseDetails['pjs'] ?? []) {
            db.insert('MessageAttachments', {
              'ID': attachment['idRessource'],
              'ParentID': exerciseDetails['uid'],
              'URL': attachment['url'],
              'Name': attachment['name']
            });
          }
        }
        for (final exercise in lesson['enSeance'] ?? []) {
          final exerciseDetails =
              await client.request(Action.getExerciseDetails, params: [
            (client.idEleve ?? 0).toString(),
            (lesson['idSeance']).toString(),
            (exercise['uid']).toString()
          ]);
          db.insert('Exercises', {
            'Type': 'Cours',
            'Title': exerciseDetails['titre'],
            'ID': exercise['uid'],
            'ParentDate': exercise['date'],
            'ParentLesson': lesson['idSeance'],
            'HTMLContent': exerciseDetails['codeHTML'],
            'Done': exerciseDetails['flagRealise'] ? 1 : 0,
          });
          for (final attachment in exerciseDetails['pjs'] ?? []) {
            db.insert('MessageAttachments', {
              'ID': attachment['idRessource'],
              'ParentID': exerciseDetails['uid'],
              'URL': attachment['url'],
              'Name': attachment['name']
            });
          }
        }
        for (final exercise in lesson['aRendre'] ?? []) {
          if ((await db.query('Exercises',
                  where: 'ID = ?', whereArgs: exercise['id']))
              .isEmpty) {
            continue;
          }
          final exerciseDetails =
              await client.request(Action.getExerciseDetails, params: [
            (client.idEleve ?? 0).toString(),
            (lesson['idSeance']).toString(),
            (exercise['uid']).toString()
          ]);
          stdout.writeln('exercise[date]: ' +
              exercise['date'].toString() +
              ' exerciseDetails[date]: ' +
              exerciseDetails['date'].toString());
          db.insert('Exercises', {
            'Type': exercise['type'],
            'Title': exerciseDetails['titre'],
            'ID': exercise['uid'],
            'LessonFor': lesson['idSeance'],
            'DateFor': exerciseDetails['date'],
            'ParentDate': exercise['date'],
            'ParentLesson':
                _lessonIDByTimestamp(exercise['date'], result['listeJourCdt']),
            'HTMLContent': exerciseDetails['codeHTML'],
            'Done': exerciseDetails['flagRealise'] ? 1 : 0,
          });
          for (final attachment in exerciseDetails['pjs'] ?? []) {
            db.insert('MessageAttachments', {
              'ID': attachment['idRessource'],
              'ParentID': exerciseDetails['uid'],
              'URL': attachment['url'],
              'Name': attachment['name']
            });
          }
        }
      }
    }
  }
}
