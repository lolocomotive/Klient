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
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kosmos_client/api/client.dart';
import 'package:kosmos_client/api/color_provider.dart';
import 'package:kosmos_client/main.dart';
import 'package:kosmos_client/widgets/color_picker.dart';

class ConfigProvider {
  static FlutterSecureStorage? _storage;
  static String? username;
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
  static ColorScheme? lightDynamic;
  static ColorScheme? darkDynamic;
  static Color? enforcedColor;

  static setTheme() {
    Color primary =
        enforcedColor ?? darkDynamic?.primary ?? lightDynamic?.primary ?? Colors.deepPurple;
    Brightness brightness =
        enforcedBrightness ?? SchedulerBinding.instance.window.platformBrightness;
    Color highlight = HSLColor.fromColor(primary)
        .withLightness(brightness == Brightness.light ? .6 : .8)
        .toColor()
        .withAlpha(80);
    Color splash = HSLColor.fromColor(primary).withLightness(.7).toColor().withAlpha(60);
    ColorScheme colorScheme;
    if (enforcedColor == null && lightDynamic != null && darkDynamic != null) {
      colorScheme = brightness == Brightness.light ? lightDynamic! : darkDynamic!;
    } else {
      colorScheme = ColorScheme.fromSeed(seedColor: primary, brightness: brightness);
    }

    KosmosApp.theme = ThemeData.from(colorScheme: colorScheme, useMaterial3: true).copyWith(
      highlightColor: highlight,
      splashColor: splash,
    );
  }

  static setMessageNotifications(bool value, Function callback) {
    if (value == true) {
      FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
          .requestPermission()
          .then((success) {
        if (success == true) {
          ConfigProvider.notifMsgEnabled = true;
        } else {
          ConfigProvider.notifMsgEnabled = false;
        }
        callback();
      });
    } else {
      ConfigProvider.notifMsgEnabled = false;
      callback();
    }
    ConfigProvider.getStorage().write(
        key: 'notifications.messages', value: ConfigProvider.notifMsgEnabled! ? 'true' : 'false');
  }

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
      //getStorage().deleteAll();
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
          case 'apiurl':
            Client.apiurl = value;
            break;
          case 'token':
            token = value;
            break;
          case 'username':
            username = value;
            break;
          case 'demoMode':
            demo = value == 'true';
            break;
          case 'display.compact':
            compact = value == 'true';
            break;
          case 'display.enforcedColor':
            if (int.parse(value) != -1) {
              enforcedColor = ColorPickerPageState.colors[int.parse(value)];
            }
            break;
          case 'display.enforcedBrightness':
            enforcedBrightness = value == 'light'
                ? Brightness.light
                : value == 'dark'
                    ? Brightness.dark
                    : null;
            break;
          case 'notifications.messages':
            FlutterLocalNotificationsPlugin()
                .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
                .areNotificationsEnabled()
                .then((enabled) {
              notifMsgEnabled = value == 'true' && enabled == true;
            });
            break;
        }
      });
    } on PlatformException catch (_) {
      // Workaround for https://github.com/mogol/flutter_secure_storage/issues/43
      await getStorage().deleteAll();
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  static setColor(Color? color) {
    enforcedColor = color;
    final int index;
    if (color == null) {
      index = -1;
    } else {
      index = ColorPickerPageState.colors.indexOf(color);
    }
    getStorage().write(key: 'display.enforcedColor', value: index.toString());
  }
}
