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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kosmos_client/api/color_provider.dart';
import 'package:kosmos_client/main.dart';

class ConfigProvider {
  static FlutterSecureStorage? _storage;
  static bool? compact;
  static String? token;
  static bool? notifMsgEnabled;
  static Brightness? enforcedBrightness;
  static bool demo = false;
  static const apiUrls = {
    'Mon Bureau Numérique': 'https://mobilite.monbureaunumerique.fr/mobilite/',
    'Mon ENT Occitanie': 'https://mobilite.mon-ent-occitanie.fr/mobilite/',
    'Arsene 76': 'https://mobilite.arsene76.fr/mobilite/',
    'ENT27': 'https://mobilite.ent27.fr/mobilite/',
    'ENT Creuse': 'https://mobilite.entcreuse.fr/mobilite/',
    'ENT Auvergne-Rhône-Alpes': 'https://mobilite.ent.auvergnerhonealpes.fr/mobilite/',
    'Agora 06': 'https://mobilite.agora06.fr/mobilite/',
    'CyberCollèges 42': 'https://mobilite.cybercolleges42.fr/mobilite/',
    'eCollège 31 Haute-Garonne': 'https://mobilite.ecollege.haute-garonne.fr/mobilite/',
    "Mon collège en Val d'Oise": 'https://mobilite.moncollege.valdoise.fr/mobilite/',
    'Webcollège Seine-Saint-Denis  ': 'https://mobilite.webcollege.seinesaintdenis.fr/mobilite/',
    'Eclat-BFC': 'https://mobilite.eclat-bfc.fr/mobilite/',
    '@ucollège84': 'https://mobilite.aucollege84.vaucluse.fr/mobilite/',
    'Skolengo Demo': 'https://mobilite.demo.skolengo.com/mobilite/',
    'Kosmos Éducation (aefe, etc.)': 'https://mobilite.kosmoseducation.com/mobilite/',
    'Skolengo formation': 'https://mobilite.formation.skolengo.com/mobilite/',
    'Schulportal Ostbelgien': 'https://mobilite.schulen.be/mobilite/'
  };

  static FlutterSecureStorage getStorage() {
    if (_storage != null) return _storage!;
    _storage =
        const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
    return _storage!;
  }

  static save() {}
  static load() async {
    apiUrls.forEach((key, value) {
      KosmosApp.dropdownItems.add(DropdownMenuItem(
        value: value,
        child: Text(key),
      ));
    });
    if (kDebugMode) {
      //ConfigProvider.getStorage().deleteAll();
    }
    try {
      print('Reading preferences');
      var data = await getStorage().readAll();

      compact = false;

      data.forEach((key, value) {
        if (key.startsWith('color.')) {
          ColorProvider.addColor(key.substring(6), int.parse(value));
        }
        switch (key) {
          case 'token':
            token = value;
            break;
          case 'demoMode':
            demo = value == 'true';
            break;
          case 'display.compact':
            compact = value == 'true';
            break;
          case 'display.enforcedBrightness':
            enforcedBrightness = value == 'light'
                ? Brightness.light
                : value == 'dark'
                    ? Brightness.dark
                    : null;
            break;
          case 'notifications.messages':
            notifMsgEnabled = value == 'true';
            break;
        }
      });
    } on PlatformException catch (_) {
      // Workaround for https://github.com/mogol/flutter_secure_storage/issues/43
      await getStorage().deleteAll();
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}