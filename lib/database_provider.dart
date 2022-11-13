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

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:kosmos_client/config_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DatabaseProvider {
  static Database? _database;
  static Future<Database> getDB() async {
    if (_database != null) return _database!;
    await initDB();
    return _database!;
  }

  static initDB() async {
    final dbDir = await getDatabasesPath();
    final dbPath = '$dbDir/kdecole.db';
    if (kDebugMode) {
      //await deleteDatabase(dbPath);
    }

    final password = await ConfigProvider.getStorage().read(key: 'dbPassword') ??
        base64Url.encode(List<int>.generate(32, (i) => Random.secure().nextInt(256)));
    print('Database URL: $dbPath');
    ConfigProvider.getStorage().write(key: 'dbPassword', value: password);
    try {
      _database = await openDatabase(dbPath, password: password);
    } on DatabaseException catch (e, st) {
      // Delete database if password is wrong
      print(e);
      print(st);
      print('Deleting database');
      await deleteDatabase(dbPath);
      _database = await openDatabase(dbPath, password: password);
    }
    final queryResult = await _database!.query('sqlite_master');
    final tables = [
      'NewsArticles',
      'NewsAttachments',
      'Conversations',
      'Messages',
      'MessageAttachments',
      'Grades',
      'Lessons',
      'Exercises',
    ];
    for (final el in queryResult) {
      if (tables.contains(el['name'])) {
        tables.remove(el['name']);
      }
    }
    if (tables.isNotEmpty) {
      await deleteDatabase(dbPath);
      _database = await openDatabase(dbPath, password: password);

      print('Initializing database');
      await _database!.execute('''
    CREATE TABLE IF NOT EXISTS NewsArticles(
      ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      UID TEXT UNIQUE NOT NULL,
      Type TEXT NOT NULL,
      Author TEXT NOT NULL,
      Title TEXT NOT NULL,
      PublishingDate INTEGER NOT NULL,
      HTMLContent TEXT NOT NULL,
      URL TEXT NOT NULL
    );''');

      await _database!.execute('''
    CREATE TABLE IF NOT EXISTS NewsAttachments(
      ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      ParentUID TEXT NOT NULL,
      Name TEXT NOT NULL,
      foreign KEY(parentUID) REFERENCES NewsArticles(UID)
    );''');
      await _database!.execute('''
    CREATE TABLE IF NOT EXISTS Conversations(
      ID INTEGER PRIMARY KEY NOT NULL,
      Subject TEXT NOT NULL,
      Preview TEXT NOT NULL,
      HasAttachment BOOLEAN NOT NULL,
      Read BOOLEAN NOT NULL,
      CanReply BOOLEAN NOT NULL,
      NotificationShown BOOLEAN NOT NULL,
      LastDate INTEGER NOT NULL,
      LastAuthor STRING NOT NULL,
      FirstAuthor STRING NOT NULL,
      FullMessageContents STRING NOT NULL
    );''');
      await _database!.execute('''
    CREATE TABLE IF NOT EXISTS Messages(
      ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      ParentID INTEGER NOT NULL,
      HTMLContent TEXT NOT NULL,
      Author TEXT NOT NULL,
      DateSent INT NOT NULL,
      FOREIGN KEY (ParentID) REFERENCES Conversations(ID)
    );''');
      await _database!.execute('''
    CREATE TABLE IF NOT EXISTS MessageAttachments(
      ID INTEGER PRIMARY KEY NOT NULL,
      ParentID INTEGER NOT NULL,
      URL TEXT,
      Name TEXT NOT NULL,
      FOREIGN KEY (ParentID) references Messages(ID)
    );''');
      await _database!.execute('''
    CREATE TABLE IF NOT EXISTS Grades(
      ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      Subject TEXT NOT NULL,
      Grade REAL NOT NULL,
      GradeString TEXT,
      Of REAL NOT NULL,
      Date INT NOT NULL,
      UniqueID TEXT NOT NULL UNIQUE
    );''');
      await _database!.execute('''
    CREATE TABLE IF NOT EXISTS Lessons(
      ID INTEGER PRIMARY KEY NOT NULL,
      LessonDate INTEGER NOT NULL,
      StartTime TEXT NOT NULL,
      EndTime TEXT NOT NULL,
      Room TEXT NOT NULL,
      Subject TEXT NOT NULL,
      Title TEXT NOT NULL,
      IsModified BOOLEAN NOT NULL,
      ShouldNotify BOOLEAN NOT NULL,
      ModificationMessage TEXT
    );''');
      await _database!.execute('''
    CREATE TABLE IF NOT EXISTS Exercises(
      ID INTEGER PRIMARY KEY NOT NULL,
      ParentLesson INTEGER,
      LessonFor INTEGER,
      Type TEXT NOT NULL,
      DateFor INTEGER,
      ParentDate INTEGER NOT NULL,
      Title TEXT NOT NULL,
      HTMLContent TEXT NOT NULL,
      Done BOOLEAN NOT NULL,
      FOREIGN KEY (ParentLesson) REFERENCES Lessons(ID),
      FOREIGN KEY (LessonFor) REFERENCES Lessons(ID)
    );''');
      await _database!.execute('''
    CREATE TABLE IF NOT EXISTS ExerciseAttachments(
      ID INTEGER PRIMARY KEY NOT NULL,
      ParentID INTEGER NOT NULL,
      URL TEXT,
      Name TEXT NOT NULL,
      FOREIGN KEY (ParentID) references Exercises(ID)
    );''');
      print('Done creating tables');
    }
  }
}
