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

import 'package:flutter/material.dart';
import 'package:klient/api/custom_requests.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/screens/new_communication.dart';
import 'package:klient/screens/timetable.dart';

import 'home.dart';
import 'messages.dart';

class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);

  @override
  State<Main> createState() => MainState();
}

class MainState extends State<Main> {
  int _currentIndex = 0;

  MainState();

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      floatingActionButton: currentWidget is MessagesPage
          ? FloatingActionButton(
              tooltip: 'Nouveau message',
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const NewCommunicationPage()));
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: StreamBuilder<int>(
                stream: unreadCount().asBroadcastStream(),
                builder: (context, snapshot) {
                  return Badge(
                    textColor: Theme.of(context).colorScheme.background,
                    label: Text(snapshot.data.toString()),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    isLabelVisible: (snapshot.data ?? 0) > 0,
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
      backgroundColor: ConfigProvider.bgColor.toColor(),
    );
  }
}
