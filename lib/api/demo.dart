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

import 'dart:math';

import 'package:kosmos_client/database_provider.dart';

int? _lessonIdByTimestamp(timestamp, List<Map<String, Object?>> lessons) {
  return null;
}

generate() async {
  List<Map<String, Object?>> newsArticles = [];
  List<Map<String, Object?>> newsAttachments = [];
  List<Map<String, Object?>> conversations = [];
  List<Map<String, Object?>> messages = [];
  List<Map<String, Object?>> messageAttachments = [];
  List<Map<String, Object?>> grades = [];
  List<Map<String, Object?>> exercises = [];
  List<Map<String, Object?>> lessons = [];
  List<Map<String, Object?>> exerciseAttachments = [];

  const articleCount = 5;
  const conversationCount = 20;
  const gradeCount = 4;
  const dayCount = 14;

  final people = [
    'GRANDE Ariana',
    'TÉRIEUR Alain',
    'TÉRIEUR Alex',
    'CAPÉ Handy',
    'HO Bob',
    'AFRITT Barack',
    'ATÉRAL Bill',
    'LAPÊCHE Ella',
    'LAGE Carl',
    'FRANCOIS Claude',
    'FISCHER Helene',
    'OCTAVIUS Caius',
  ];

  final articleTitles = [
    'La photogénicité',
    'Les antopophages',
    'Les ornithologues',
    'Symphonie non-illustrée pour little brother',
    'Les sardines!!!',
    'Partick, qu’est-ce que tu as fait encore?',
    'Non mais Martine là ca va plus!!',
    'Am Rand des Nervenzusammenbruchs',
  ];
  final articleContents = [
    'Coucou mes petits chats! 🐱😎🎀 Aujourd’hui, je vais vous présenter un super livre qui m’a vraiment beaucoup plu!! 😁 Il s’agit de la Princesse de Clèves, un roman écrit par Mme de Lafayette. L’intrigue se joue en 1558 dans la cour du roi Henri II, et ce qu’il faut savoir à propos de la cour à cette époque c’est que c’est un monde rempli d’hypocrisie! 😣😫 Eh oui les amis! Tout le monde est fake, comme diraient les jeunes de nos jours! (décidément, jamais je ne m’adapterai au langage des jeunes!😲😝) Et donc tout le monde essaye de se montrer sous son plus beau jour (un peu comme sur ce que les jeunes appellent les réseaux sociaux, Istagram je crois📸). Et dans cette cour, eh bien Mme de Chartres présente sa fille: Mlle de Chartres, qui est vraiment très belle!🙆‍♀️💁‍♀️💆‍♀️💅 Et bien évidemment, elle fait craquer plusieurs galants gentilshommes, notamment le prince de Clèves.🤴🤷‍♂️ Sa mère la marie avec lui après plusieurs demandes (même si Mlle de Chartres n’est pas amoureuse, elle se laisse malgré tout marier, elle aurait pu se défendre un peu quand même…). Mais bien sûr, tout ne peut pas se passer miraculeusement bien, donc elle tombe amoureuse de quelqu’un d’autre (le duc de Nemours) aux fiançailles du duc de Lorraine et de Claude de France (quelle sotte!). 🙅‍♀️ C’est un véritable coup de foudre ⚡⚡🔥! Les deux tombent amoureux instantanément! (c’est beau l’amour quand meme!💕💞💖💗) Mais elle décide de fuir sa passion en allant a la campagne alors que le prince de Clèves reste à Paris. Et tout cela seulement dans le premier tome, quelle lecture haletante! 😍',
    'Rebonjour mes loulou.tes! 🤩🤗 Aujourd’hui je continue de vous parler de ma lecture de la Princesse de Clèves! 😻 Le tome deux débute avec la mort de Mme Tournon et alors là, il va bien falloir me suivre les cocos! Alors Sancerre, un ami du prince de Clèves, était amoureux d’elle mais elle aimait M d’Estouteville (qui avait montré les lettres d’amour que lui envoyait Mme Tournon à Sancerre). Ensuite, le prince de Clèves demande à la princesse de Clèves de retourner à Paris (elle lui manque sûrement beaucoup, ça ne doit pas être simple de vivre loin de ceux qu’on aime, n’est ce pas?). Une fois de retour, elle se rend compte qu’elle est vraiment amoureuse du duc de Nemours. Celui-ci avait comme ambition d’épouser la reine d’Angleterre, mais il refuse la couronne d’Angleterre rien que pour la princesse (trop mignon!🤩). Elle veut à nouveau retourner à la campagne (qu’est-ce qui la prend de toujours vouloir aller à la campagne???). Après cela, le duc de Nemours vole un portrait de la princesse SOUS SES YEUX 👀 et elle le LAISSE PARTIR (j’étais choquée, mais on dit que l’amour rend aveugle, ça doit être ça💞💕). Le duc de Nemours a remarqué qu’elle l’avait laissé partir et comprend ainsi qu’elle l’aime! Et maintenant vient la partie avec le suspense oulala!🤯😵 Le duc de Nemours se blesse lors d’un tournoi (non mais je vous jure…) et la princesse le regarde avec une tendresse inimaginable!🥰😖 Mais là, CATASTROPHE! La princesse découvre une lettre d’amour adressée à la reine Dauphine qui appartient au duc de Nemours (du moins, c’est ce qu’elle croit ^^). Elle se met en tête qu’il l’aime et subit les souffrances atroces de la jalousie! 😥😣😰',
    'Salut mes petits copains!!💖💫 Dans cette session, c’est là que le conflit se résout car il s’avère que la lettre n’appartient non pas au duc de Nemours, mais au Vidame de Chartres (quel rebondissement! J’en perds la tête!), oncle de la princesse et ami proche du duc de Nemours! C’est le soulagement pour la princesse!😚🤭 Ensuite, par une demande du roi, la princesse de Clèves se retrouve à devoir rédiger à nouveau la lettre avec le duc de Nemours, ce qui leur prend plusieurs heures, qu’ils savourent ensemble. Elle se rend compte de la passion qu’elle a pour lui et décide à nouveau de fuir vers la campagne (c’est fou ça, toujours la campagne! Il ne faut pas fuir ses problèmes comme ça les enfants! Quand on fuit, on emmène ses problèmes avec soi. Il faut affronter ses problèmes au lieu de les fuir!🧐) après avoir avoué sa passion au prince de Clèves (mais le duc de Nemours l’a entendue!). La cour est très vite au courant de ce qui se passe entre le duc de Nemours et la princesse. (Les secrets y circulent plus vite que les informations normales! C’est insolite!) A la fin du tome, un événement tragique a lieu: le roi Henri II meurt suite à un tournoi! (que c’est triste😥😣)',
    'Kikou les cocottes!😄😋 On se revoit pour la toute fin du roman!! Alors que toute la cour est présente au sacre du nouveau roi, la princesse de Clèves décide à nouveau de rejoindre la campagne! (décidément, cette campagne!🌿🌲) Mais lorsqu’elle fuit vers la campagne, le duc de Nemours la suit (Je vous avais bien dit qu’on emmène ses problèmes avec soi!🤭🧐) mais lui-même est suivi par un espion du prince de Clèves. Le duc cherche a parler a la princesse mais n’y parvient pas pendant plusieurs jours. L’espion fait part au prince de Clèves de la présence du duc de Nemours auprès de la princesse de Clèves. Le prince se sent trahi et a une forte fièvre. Sur ce, la princesse retourne vers son mari et sur son lit de mort lui dit qu’elle ne l’a jamais trompé.⚡ Suite à ça survient le passage le plus dramatique du livre!🔥🎇 Lors d’un rendez-vous organisé par le vidame de Chartres, la princesse de Clèves avoue sa passion au duc de Nemours, qui lui fait comprendre que ces sentiments sont réciproques. Mais à ce moment-là, ASCENSEUR ÉMOTIONNEL!🎉✨😲😣 La princesse le quitte!!!! Elle décide de s’exiler dans un couvent tandis que le duc de Nemours part en Espagne. Quelle histoire tragique!😵 C’est la fin de cette petite série d’articles, j’espère que ça vous a plu et à bientôt pour un autre livre! (J’ai décidément découvert une nouvelle passion pour la lecture📈📚)',
    'https://www.marmiton.org/recettes/recette_beignets-d-avocat_28112.aspx <br> Avec ces beignets d’avocat vous etes surs d’impressionner vos invités! J’en ai fait et il n’en restait plus apres quelques secondes!!! Ils se sont jetés dessus!! Définitivement à refaire!',
    'https://www.marmiton.org/recettes/recette_gaufres-du-nord_26458.aspx <br> Recette au top ! J’ai presque tout suivie à la lettre, n’ayant pas de bière, j’ai fait sans. J’ai aussi ajouté des perles de sucre ce qui a donné une modernité surprenante au dessert! Délectable!',
    'https://www.marmiton.org/recettes/recette_fondant-au-chocolat-et-coulis-de-framboise_168967.aspx <br> Succulent !! J’ai fait cette recette sous forme de mini cake avec un cœur confiture de framboise! Un véritable régal !!',
    'https://www.marmiton.org/recettes/recette_pain-perdu-a-la-vanille_29507.aspx <br> Servi chaud saupoudré de sucre glace c’est le remede parfait dont avait besoin mon fils pour se remettre de son 0/20 en Francais!!!',
    'https://www.marmiton.org/recettes/recette_crepes-banane-chocolat_87095.aspx <br> Surveillez bien les crêpes dans le four, car elles peuvent devenir un peu dures!!! Mis à part ça, excellente recette, je me suis rarement autant régalée!',
    'https://www.marmiton.org/recettes/recette_spaghetti-a-l-ail_10583.aspx <br> Cette recette est très simple et très rapide à réaliser, mais elle est surtout délicieuse. C’est un classique peu connu de la Provence et de sa soeur l’Italie du Nord. La réussite de la recette dépend de la qualité de l’ail utilisé. C’est le fait de faire revenir doucement les pâtes dans l’ail qui lie les goûts. En italien, le verbe qui correspond à cette action est INSAPPORIRE, "faire prendre saveur"... C’est tout dire !',
  ];
  final attachmentTitles = [
    'Nouveau document texte.txt',
    'Ornithorinque.pdf',
    'Coléptère (12).pdf',
    'Pharyngite.pdf',
    'Ornithorinque.pdf',
    'Amoureuse.xls',
  ];
  final exerciceContents = [
    'Tous les exercices du Manuel',
    'Tous les exercices du chapitre 2',
    'Activité 3 p.102',
    'Lire le dossier sur Kant (page 256)',
    'Résumé ',
    'feur',
    'ECD p.52 + EDD p.65',
    'Lire tout le cours puis le relire et en suite faire les exercices du chapitre 3. Ensuite faire un DS. Puis un autre. Sans oublier le DM ni le parcours sacado',
    'Pages 35 à 65',
    'Ex21p3',
    'HT1 C1 Résumé + ADD p.25',
    'Pages 125 à 3',
    'Rien ;)',
  ];

  final conversationTitles = [
    'Nouvelle époque de la littérature',
    'Louis de Funès est au secrétariat',
    'J’aime très fort la soupe',
    'Absence de Mme CORTISOL',
    'Que de la poésie',
    'Une oeuvre littéraire sans précédent'
  ];
  final messageContents = [
    'Quand il allume son réverbère, c’est comme s’il faisait naître une étoile de plus, ou une fleur. Quand il éteint son réverbère, ça endort la fleur ou l’étoile. C’est une occupation très jolie. C’est véritablement utile puisque c’est joli.',
    'Tu n’es encore pour moi qu’un petit garçon tout semblable à cent mille petits garçons. Et je n’ai pas besoin de toi. Et tu n’as pas besoin de moi non plus. Je ne suis pour toi qu’un renard semblable à cent mille renards. Mais, si tu m’apprivoises, nous aurons besoin l’un de l’autre. Tu seras pour moi unique au monde. Je serais pour toi unique au monde…',
    'Les grandes personnes aiment les chiffres. Quand vous leur parlez d’un nouvel ami, elles ne vous questionnent jamais sur l’essentiel. Elles ne vous disent jamais : "Quel est le son de sa voix ? Quels sont les jeux qu’il préfère ? Est-ce qu’il collectionne les papillons ?" Elles vous demandent : "Quel âge a-t-il ? Combien a-t-il de frères ? Combien pèse-t-il ? Combien gagne son père ?" Alors seulement elles croient le connaître.',
    'Vous êtes belles, mais vous êtes vides, leur dit-il encore.On ne peut pas mourir pour vous. Bien sûr, ma rose à moi, un passant ordinaire croirait quelle vous ressemble. Mais à elle seule, elle est plus importante que vous toutes, puisque cest elle que jai arrosée…',
    'J’ai toujours aimé le désert. On s’assoit sur une dune de sable. On ne voit rien. On n’entend rien. Et cependant quelque chose rayonne en silence…',
    'Et le Petit Prince dit à l’homme : " les grandes personnes, elles ne comprennent rien toutes seules et c’est très fatiguant pour les enfants de toujours et toujours leur donner des explications "',
    'Ma vie est monotone. Je chasse les poules, les hommes me chassent. Toutes les poules se ressemblent, et tous les hommes se ressemblent. Je m’ennuie donc un peu. Mais, si tu m’apprivoises, ma vie sera comme ensoleillée. Je connaîtrai un bruit de pas qui sera différent de tous les autres. Les autres pas me font rentrer sous terre. Le tien m’appellera hors du terrier, comme une musique. Et puis regarde ! Tu vois, là-bas, les champs de blé ? Je ne mange pas de pain. Le blé pour moi est inutile. Les champs de blé ne me rappellent rien. Et ça, c’est triste ! Mais tu as des cheveux couleur d’or. Alors ce sera merveilleux quand tu m’auras apprivoisé ! Le blé, qui est doré, me fera souvenir de toi. Et j’aimerai le bruit du vent dans le blé…',
    'Les gens ont des étoiles qui ne sont pas les mêmes. Pour les uns, qui voyagent, ce sont des guides. Pour d’autres, elles ne sont rien que de petites lumières. Pour d’autres, qui sont savants, elles sont des problèmes.',
    'Les hommes de chez toi cultivent cinq mille rose dans un même jardin… et ils n’y trouvent pas ce qu’ils cherchent… Et cependant ce qu’ils cherchent pourrait être trouvé dans une seule rose et un peu d’eau…',
    'Ça c’est, pour moi, le plus beau et le plus triste paysage du monde. C’est le même paysage que celui de la page précédente, mais je l’ai dessiné une fois encore pour bien vous le montrer. C’est ici que le petit prince a apparu sur terre, puis disparu. Regardez attentivement ce paysage afin d’être sûrs de le reconnaître, si vous voyagez un jour en Afrique, dans le désert. Et, s’il vous arrive de passer par là, je vous en supplie, ne vous pressez pas, attendez un peu juste sous l’étoile ! Si alors un enfant vient à vous, s’il rit, s’il a des cheveux d’or, s’il ne répond pas quand on l’interroge, vous devinerez bien qui il est. Alors soyez gentils ! Ne me laissez pas tellement triste : écrivez-moi vite qu’il est revenu…',
    'Il faut exiger de chacun ce que chacun peut donner, reprit le roi. L’autorité repose d’abord sur la raison. Si tu ordonnes à ton peuple d’aller se jeter à la mer, il fera la révolution.',
  ];

  final subjects = [
    'Maths',
    'Histoire',
    'Physique',
    'Chimie',
    'Sciences',
    'Géographie',
    'Allemand',
    'Anglais',
    'Francais',
    'Philosophie'
  ];

  final random = Random();
  int range = 5 * 365;

  for (var i = 0; i < gradeCount; i++) {
    grades.add({
      'Subject': subjects[random.nextInt(subjects.length)],
      'Grade': random.nextInt(8) + 13,
      'GradeString': null,
      'Of': 20,
      'Date': DateTime.now().add(Duration(hours: random.nextInt(range))).millisecondsSinceEpoch,
      'UniqueID': random.nextInt(1 << 32),
    });
  }
  for (var i = 0; i < articleCount; i++) {
    final offset = random.nextInt(range);
    newsArticles.add(
      {
        'UID': i,
        'Type': 'article',
        'Author': people[random.nextInt(people.length)],
        'Title': articleTitles[random.nextInt(articleTitles.length)],
        'PublishingDate': DateTime.now().add(Duration(days: -offset)).millisecondsSinceEpoch,
        'HTMLContent': articleContents[random.nextInt(articleContents.length)],
        'URL': 'https://le-blog-de-sylvie.web.app/',
      },
    );
    for (var j = 0; j < random.nextInt(4); j++) {
      newsAttachments.add({
        'Name': attachmentTitles[random.nextInt(attachmentTitles.length)],
        'ParentUID': i,
      });
    }
  }
  range = 5 * 365 * 24;

  for (var i = 0; i < conversationCount; i++) {
    final offset = random.nextInt(range);

    final attachments = random.nextBool();
    final lastMsg = messageContents[random.nextInt(messageContents.length)];
    var totalContents = '';
    final cid = random.nextInt(1 << 32);

    for (var j = 0; j < random.nextInt(30); j++) {
      final message = messageContents[random.nextInt(messageContents.length)];
      totalContents += message;
      final mid = random.nextInt(1 << 32);
      messages.add({
        'ID': mid,
        'ParentID': cid,
        'HTMLContent': message,
        'Author': people[random.nextInt(people.length)],
        'DateSent': DateTime.now().add(Duration(hours: offset)).millisecondsSinceEpoch
      });
      if (attachments) {
        for (var k = 0; k < random.nextInt(4) * random.nextInt(2); k++) {
          messageAttachments.add({
            'ParentID': mid,
            'Name': attachmentTitles[random.nextInt(attachmentTitles.length)],
            'URL': 'slay',
          });
        }
      }
    }
    conversations.add(
      {
        'ID': cid,
        'Subject': conversationTitles[random.nextInt(conversationTitles.length)],
        'Preview': lastMsg.substring(0, min(200, lastMsg.length)),
        'HasAttachment': attachments ? 1 : 0,
        'Read': random.nextInt(2),
        'NotificationShown': 1,
        'LastDate': DateTime.now().add(Duration(hours: -offset)).millisecondsSinceEpoch,
        'LastAuthor': people[random.nextInt(people.length)],
        'FirstAuthor': people[random.nextInt(people.length)],
        'FullMessageContents': totalContents,
        'CanReply': random.nextInt(1),
      },
    );
  }

  for (var i = 0; i < dayCount; i++) {
    var day = DateTime.now().add(Duration(days: -i + (dayCount / 2).floor()));
    day = day.add(Duration(
      hours: -day.hour + 8,
      minutes: -day.minute,
      seconds: -day.second,
      milliseconds: -day.millisecond,
    ));
    day = day.add(Duration(minutes: 55 * random.nextInt(3)));

    while (day.hour < 18) {
      final l = random.nextInt(2) + 1;
      final end = day.add(Duration(minutes: 55 * l));
      final lid = random.nextInt(1 << 32);
      final subject = subjects[random.nextInt(subjects.length)];
      lessons.add({
        'ID': lid,
        'LessonDate': day.millisecondsSinceEpoch,
        'StartTime':
            '${day.hour.toString().padLeft(2, '0')}:${day.minute.toString().padLeft(2, '0')}',
        'EndTime':
            '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
        'Room': random.nextInt(999),
        'Title': '',
        'Subject': subject,
        'IsModified': random.nextInt(2) * random.nextInt(2),
        'ShouldNotify': 0,
        'ModificationMessage': 'Cours annulé',
      });
      // Lesson content
      for (var j = 0; j < random.nextInt(3) * random.nextInt(2); j++) {
        final eid = random.nextInt(1 << 32);
        exercises.add({
          'Type': 'Cours',
          'Title': 'Cours',
          'ID': eid,
          'ParentDate': day.millisecondsSinceEpoch,
          'ParentLesson': lid,
          'HTMLContent': exerciceContents[random.nextInt(exerciceContents.length)],
          'Done': 0,
        });
      }
      // Work for this lesson
      for (var j = 0; j < random.nextInt(3) * random.nextInt(2); j++) {
        final eid = random.nextInt(1 << 32);
        final filtered = lessons.where((lesson) => lesson['Subject'] == subject).toList();
        final parent = filtered[random.nextInt(filtered.length)];
        exercises.add({
          'Type': 'Exercices',
          'Title': 'Exercices',
          'ID': eid,
          'ParentDate': parent['LessonDate'],
          'ParentLesson': parent['ID'],
          'DateFor': day.millisecondsSinceEpoch,
          'LessonFor': lid,
          'HTMLContent': exerciceContents[random.nextInt(exerciceContents.length)],
          'Done': 0,
        });
      }
      day = end;
      if (random.nextInt(10) == 0) break;
      if (random.nextInt(5) == 0) day = day.add(const Duration(minutes: 55));
    }
  }
  final batch = (await DatabaseProvider.getDB()).batch();
  for (final article in newsArticles) {
    batch.insert('NewsArticles', article);
  }
  for (final attachment in newsAttachments) {
    batch.insert('NewsAttachments', attachment);
  }
  for (final conversation in conversations) {
    batch.insert('Conversations', conversation);
  }
  for (final message in messages) {
    batch.insert('Messages', message);
  }
  for (final attachment in messageAttachments) {
    batch.insert('MessageAttachments', attachment);
  }
  for (final grade in grades) {
    batch.insert('Grades', grade);
  }
  for (final lesson in lessons) {
    batch.insert('Lessons', lesson);
  }
  for (final exercise in exercises) {
    batch.insert('Exercises', exercise);
  }
  for (final attachment in exerciseAttachments) {
    batch.insert('ExerciseAttachments', attachment);
  }
  await batch.commit();
}
