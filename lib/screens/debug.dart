import 'package:flutter/material.dart';
import 'package:kosmos_client/kdecole-api/database_manager.dart';
import 'package:kosmos_client/main.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({Key? key}) : super(key: key);

  _updateMessages() {
    DatabaseManager.fetchMessageData();
  }

  _updateNews() {
    DatabaseManager.fetchNewsData();
  }

  _updateTimetable() {
    DatabaseManager.fetchTimetable();
  }

  _closeDB() {
    Global.db!.close();
  }

  _updateGrades() {
    DatabaseManager.fetchGradesData();
  }

  _clearDatabase() {
    Global.db!.delete('NewsArticles');
    Global.db!.delete('NewsAttachments');
    Global.db!.delete('Conversations');
    Global.db!.delete('Messages');
    Global.db!.delete('MessageAttachments');
    Global.db!.delete('Grades');
    Global.db!.delete('Lessons');
    Global.db!.delete('Exercises');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Debug")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
                onPressed: _updateMessages,
                child: const Text('Update messages')),
            ElevatedButton(
                onPressed: _updateNews, child: const Text('Update news')),
            ElevatedButton(
                onPressed: _updateTimetable,
                child: const Text('Update Timetable')),
            ElevatedButton(
                onPressed: _updateGrades, child: const Text('Update grades')),
            ElevatedButton(
                onPressed: _clearDatabase, child: const Text('Clear database')),
            ElevatedButton(
                onPressed: _closeDB, child: const Text('Close database')),
            ElevatedButton(
                onPressed: () {
                  Global.db!.execute('DROP TABLE GRADES');
                },
                child: const Text('drop grades')),
          ],
        ),
      ),
    );
  }
}
