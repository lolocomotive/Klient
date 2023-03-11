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
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:kosmos_client/api/client.dart';
import 'package:kosmos_client/api/downloader.dart';
import 'package:kosmos_client/config_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DatabaseProvider {
  static Database? _database;
  static bool lock = false;
  static Future<Database> getDB() async {
    // Keeps database from being created twice at the same time
    while (lock) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (_database != null) return _database!;
    lock = true;
    await initDB();
    lock = false;
    return _database!;
  }

  static initDB() async {
    final String dbDir;
    if (Platform.isWindows || Platform.isLinux) {
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory
      dbDir = '${await getDownloadsDirectory()}/kosmos_client/kdecole.db';
    } else {
      dbDir = await getDatabasesPath();
    }

    final dbPath = '$dbDir/kdecole.db';
    if (kDebugMode) {
      //await deleteDatabase(dbPath);
    }

    final password = await ConfigProvider.getStorage().read(key: 'dbPassword') ??
        base64Url.encode(List<int>.generate(32, (i) => Random.secure().nextInt(256)));
    ConfigProvider.getStorage().write(key: 'dbPassword', value: password);
    try {
      _database = await openDB(dbPath, password);
    } on DatabaseException catch (e, st) {
      // Delete database if password is wrong
      print(e);
      print(st);
      print('Deleting database');
      await deleteDb(dbPath);
      _database = await openDB(dbPath, password);
    }
  }

  static deleteDb(dbPath) {
    if (Platform.isWindows || Platform.isLinux) {
      return databaseFactoryFfi.deleteDatabase(dbPath);
    } else {
      return deleteDatabase(dbPath);
    }
  }

  static migrate0to2(Database db) async {
    print('Upgrading database...');
    await db.execute('''
            CREATE TABLE Students(
              ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
              UID TEXT NOT NULL UNIQUE,
              Name TEXT NOT NULL,
              Permissions TEXT NOT NULL
            )''');
    await db.execute('ALTER TABLE NewsArticles ADD StudentUID TEXT');
    await db.execute('ALTER TABLE NewsAttachments ADD StudentUID TEXT');
    await db.execute('ALTER TABLE Grades ADD StudentUID TEXT');
    await db.execute('ALTER TABLE Lessons ADD StudentUID TEXT');
    await db.execute('ALTER TABLE Exercises ADD StudentUID TEXT');
    await db.execute('ALTER TABLE ExerciseAttachments ADD StudentUID TEXT');

    print('Client init...');
    if (ConfigProvider.token != null) {
      Client(ConfigProvider.token!);
      print('Downloading user info...');
      await Downloader.fetchUserInfo(db: db);
      print('Attempting to fix db...');
      await db.update('NewsArticles', {'StudentUID': '0'});
      await db.update('Lessons', {'StudentUID': '0'});
      await db.update('Exercises', {'StudentUID': '0'});
      await db.update('Lessons', {'StudentUID': '0'});
      print('Done upgrading');
    }
  }

  static migrate3to4(Database db) async {
    print('Upgrading database...');
    await db.execute('ALTER TABLE Exercises ADD Subject TEXT');
    print('Attempting to fix data...');
    final results = await (await DatabaseProvider.getDB()).rawQuery('''SELECT 
          Lessons.ID as LessonID,
          Exercises.ID as ExerciseID,
          ExerciseAttachments.ID AS ExerciseAttachmentID,
          Lessons.Subject as LessonSubject,
          Exercises.Subject as ExerciseSubject,
          * FROM Lessons 
          LEFT JOIN Exercises ON Lessons.ID = Exercises.ParentLesson OR Lessons.ID = Exercises.LessonFor
          LEFT JOIN ExerciseAttachments ON Exercises.ID = ExerciseAttachments.ParentID
          ORDER BY LessonDate;''');
    final batch = db.batch();
    for (final result in results) {
      batch.update('Exercises', {'Subject': result['LessonSubject']},
          where: 'ID = ?', whereArgs: [result['ExerciseID']]);
    }
    await batch.commit();
    print('Done upgrading');
  }

  static Future<void> createTables(Database db) async {
    final batch = db.batch();
    batch.execute('''
        CREATE TABLE IF NOT EXISTS NewsArticles(
          ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          UID TEXT UNIQUE NOT NULL,
          Type TEXT NOT NULL,
          Author TEXT NOT NULL,
          Title TEXT NOT NULL,
          PublishingDate INTEGER NOT NULL,
          HTMLContent TEXT NOT NULL,
          StudentUID TEXT,
          URL TEXT NOT NULL
        )''');
    batch.execute('''
        CREATE TABLE IF NOT EXISTS NewsAttachments(
          ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          ParentUID TEXT NOT NULL,
          Name TEXT NOT NULL,
          StudentUID TEXT,
          foreign KEY(parentUID) REFERENCES NewsArticles(UID)
        )''');
    batch.execute('''
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
        )''');
    batch.execute('''
        CREATE TABLE IF NOT EXISTS Messages(
          ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          ParentID INTEGER NOT NULL,
          HTMLContent TEXT NOT NULL,
          Author TEXT NOT NULL,
          DateSent INT NOT NULL,
          FOREIGN KEY (ParentID) REFERENCES Conversations(ID)
        )''');
    batch.execute('''
        CREATE TABLE IF NOT EXISTS MessageAttachments(
          ID INTEGER PRIMARY KEY NOT NULL,
          ParentID INTEGER NOT NULL,
          URL TEXT,
          Name TEXT NOT NULL,
          FOREIGN KEY (ParentID) references Messages(ID)
        )''');
    batch.execute('''
        CREATE TABLE IF NOT EXISTS Grades(
          ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          Subject TEXT NOT NULL,
          Grade REAL NOT NULL,
          GradeString TEXT,
          Of REAL NOT NULL,
          Date INT NOT NULL,
          StudentUID TEXT,
          UniqueID TEXT NOT NULL UNIQUE
        )''');
    batch.execute('''
        CREATE TABLE IF NOT EXISTS Lessons(
          ID INTEGER PRIMARY KEY NOT NULL,
          LessonDate INTEGER NOT NULL,
          StartTime TEXT NOT NULL,
          EndTime TEXT NOT NULL,
          Room TEXT NOT NULL,
          Subject TEXT NOT NULL,
          Title TEXT NOT NULL,
          IsModified BOOLEAN NOT NULL,
          IsCanceled INT NOT NULL,
          ShouldNotify BOOLEAN NOT NULL,
          ModificationMessage TEXT,
          StudentUID TEXT
        )''');
    batch.execute('''
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
          StudentUID TEXT,
          Subject TEXT,
          FOREIGN KEY (ParentLesson) REFERENCES Lessons(ID),
          FOREIGN KEY (LessonFor) REFERENCES Lessons(ID)
        )''');
    batch.execute('''
        CREATE TABLE IF NOT EXISTS ExerciseAttachments(
          ID INTEGER PRIMARY KEY NOT NULL,
          ParentID INTEGER NOT NULL,
          URL TEXT,
          Name TEXT NOT NULL,
          StudentUID TEXT,
          FOREIGN KEY (ParentID) references Exercises(ID)
        )''');
    batch.execute('''
        CREATE TABLE IF NOT EXISTS Students(
          ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          UID TEXT UNIQUE,
          Name TEXT NOT NULL,
          Permissions TEXT NOT NULL
        )''');
    await batch.commit();
    print('Tables created');
  }

  static Future<Database> openDB(String dbPath, String password) async {
    if (Platform.isLinux || Platform.isWindows) {
      final db = await databaseFactoryFfi.openDatabase(dbPath);
      print('Opening databse with FFI');
      await createTables(db);
      return db;
    }
    return openDatabase(
      dbPath,
      password: password,
      version: 4,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE Lessons ADD IsCanceled INT NOT NULL DEFAULT 0');
        }
        print('Upgrading DB $oldVersion -> $newVersion');
        if (oldVersion < 4) {
          migrate3to4(db);
        }
      },
      onCreate: (db, version) async {
        print('Creating db version $version');
        final tables = await db.query('sqlite_master');
        print('${tables.length} tables');
        if (tables.length == 12) {
          //The database has been created with an old version of the app and it can't be upgraded with onUpgrade.
          //We have to force the migration
          await migrate0to2(db);
          return;
        }
        await createTables(db);
      },
    );
  }
}
