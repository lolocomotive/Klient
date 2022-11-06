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

import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:kosmos_client/api/conversation.dart';
import 'package:kosmos_client/screens/setup.dart';
import 'package:kosmos_client/screens/timetable.dart';

import '../global.dart';
import 'home.dart';
import 'messages.dart';

class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);

  @override
  State<Main> createState() => MainState();
}

class MainState extends State<Main> {
  int _currentIndex = 0;
  _openFirstSteps() async {
    if (await Global.storage!.read(key: 'firstTime') != 'false' && !Global.demo) {
      Global.storage!.write(key: 'firstTime', value: 'false');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WillPopScope(
            onWillPop: () async => false,
            child: SetupPage(() {
              setState(() {
                _currentIndex = 0;
              });
            }),
          ),
        ),
      );
    }
  }

  MainState();

  @override
  Widget build(BuildContext context) {
    _openFirstSteps();
    Global.mainState = this;
    final Widget currentWidget;
    switch (_currentIndex) {
      case 0:
        currentWidget = HomePage(
          key: GlobalKey(),
        );
        break;
      case 1:
        currentWidget = MessagesPage(key: GlobalKey());
        break;
      default:
        currentWidget = TimetablePage(key: GlobalKey());
    }

    if (currentWidget is! MessagesPage) {
      Global.fab = null;
    }
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: FutureBuilder<bool>(
                future: Conversation.existsUnread(),
                builder: (context, snapshot) {
                  return Badge(
                    badgeColor: Theme.of(context).colorScheme.primary,
                    showBadge: snapshot.data == true,
                    child: const Icon(Icons.message_outlined),
                  );
                }),
            selectedIcon: const Icon(Icons.message),
            label: 'Messagerie',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Emploi du temps',
          )
        ],
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      body: currentWidget,
      floatingActionButton: Global.fab,
    );
  }
}
