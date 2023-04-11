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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:klient/main.dart';
import 'package:klient/widgets/default_activity.dart';
import 'package:klient/widgets/default_card.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class ExceptionWidget extends StatelessWidget {
  final Exception e;
  final StackTrace st;

  const ExceptionWidget({
    required this.e,
    required this.st,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String message = 'Erreur';
    String? hint;
    if (e is SocketException) {
      message = 'Erreur de réseau';
    } else if (e is DatabaseException) {
      message = 'Erreur de base de données';
      hint =
          'Essayez de redémarrer l\'application. Si l\'erreur persiste effacez les données de l\'application et reconnectez-vous';
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              if (hint != null)
                Text(
                  hint,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            KlientApp.messengerKey.currentState?.hideCurrentSnackBar();
            KlientApp.navigatorKey.currentState!.push(
              MaterialPageRoute(builder: (context) {
                return DefaultSliverActivity(
                  title: message,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DefaultCard(
                            child: Column(
                              children: [
                                Text(
                                  'Descriptif de l\'erreur',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(e.toString()),
                              ],
                            ),
                          ),
                          DefaultCard(
                            child: Column(
                              children: [
                                Text(
                                  'Stack trace',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(st.toString()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
          child: const Text("Plus d'infos"),
        )
      ],
    );
  }
}
