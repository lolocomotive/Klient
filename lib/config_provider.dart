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

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:klient/api/color_provider.dart';
import 'package:klient/main.dart';
import 'package:klient/widgets/color_picker.dart';
import 'package:openid_client/openid_client.dart';
import 'package:scolengo_api/scolengo_api.dart';

enum NotificationType { messages, evaluations, info, homework }

class ConfigProvider {
  static FlutterSecureStorage? _storage;

  static String? username;
  static Future<String>? currentId;
  static Future<User>? user;
  static String? currentSchool;
  static ColorScheme? lightDynamic;
  static ColorScheme? darkDynamic;
  static Skolengo? client;
  static late HSLColor bgColor;

  static bool? _compact;
  static bool? get compact => _compact;
  static set compact(bool? value) {
    _compact = value;
    setValue('display.compact', value);
  }

  static Credential? _credentials;
  static Credential? get credentials => _credentials;
  static set credentials(Credential? value) {
    _credentials = value;
    setValue('credentials', value);
  }

  static School? _school;
  static School? get school => _school;
  static set school(School? value) {
    _school = value;
    setValue('school', value);
  }

  static const disabled = {
    NotificationType.messages: false,
    NotificationType.evaluations: false,
    NotificationType.info: false,
    NotificationType.homework: false,
  };
  static Map<NotificationType, bool>? _notificationSettings;
  static Map<NotificationType, bool>? get notificationSettings => _notificationSettings;
  static set notificationSettings(Map<NotificationType, bool>? value) {
    _notificationSettings = value;
    setValue('notifications', value?.map((key, value) => MapEntry(key.name, value)));
  }

  static Brightness? _enforcedBrightness;
  static Brightness? get enforcedBrightness => _enforcedBrightness;
  static set enforcedBrightness(Brightness? value) {
    _enforcedBrightness = value;
    setValue('display.enforcedBrightness', value);
  }

  static bool _demo = false;
  static bool get demo => _demo;
  static set demo(bool value) {
    _demo = value;
    setValue('demoMode', value);
  }

  static Color? _enforcedColor;
  static Color? get enforcedColor => _enforcedColor;
  static set enforcedColor(Color? value) {
    _enforcedColor = value;
    setValue(
        'display.enforcedColor', value == null ? -1 : ColorPickerPageState.colors.indexOf(value));
  }

  static String? _dbPassword;
  static String? get dbPassword => _dbPassword;
  static set dbPassword(String? value) {
    _dbPassword = value;
    setValue('dbPassword', value);
  }

  static setValue(String key, dynamic value) {
    if (value == null) {
      getStorage().delete(key: key);
    } else if (value is String) {
      getStorage().write(key: key, value: value);
    } else if (value is bool || value is num) {
      getStorage().write(key: key, value: value.toString());
    } else if (value is Enum) {
      getStorage().write(key: key, value: value.name);
    } else if (value is Map) {
      getStorage().write(key: key, value: jsonEncode(value));
    } else {
      getStorage().write(key: key, value: jsonEncode(value.toJson()));
    }
  }

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

    bgColor = HSLColor.fromColor(colorScheme.background);
    if (brightness == Brightness.light) {
      bgColor = bgColor.withLightness(bgColor.lightness - .05).withSaturation(.3);
    } else {
      bgColor = bgColor.withLightness(bgColor.lightness - .01);
    }

    KlientApp.theme = ThemeData.from(colorScheme: colorScheme, useMaterial3: true).copyWith(
      highlightColor: highlight,
      splashColor: splash,
      scaffoldBackgroundColor: colorScheme.background,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ElevationOverlay.applySurfaceTint(
          colorScheme.surface,
          colorScheme.primary,
          4,
        ),
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
        insetPadding: const EdgeInsets.all(8),
        behavior: SnackBarBehavior.floating,
        width: 700,
      ),
    );
  }

  static setNotifications(bool value, Function callback, NotificationType notificationType) {
    if (value) {
      if (Platform.isLinux) {
        _notificationSettings![notificationType] = true;
        callback();
      } else {
        FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
            .requestPermission()
            .then((success) {
          if (success == true) {
            _notificationSettings![notificationType] = true;
          } else {
            _notificationSettings![notificationType] = false;
          }
          callback();
          notificationSettings = _notificationSettings;
        });
        return;
      }
    } else {
      _notificationSettings![notificationType] = false;
      callback();
    }
    notificationSettings = _notificationSettings;
  }

  static FlutterSecureStorage getStorage() {
    if (_storage != null) return _storage!;
    _storage =
        const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
    return _storage!;
  }

  static load() async {
    if (kDebugMode) {
      //getStorage().deleteAll();
    }
    try {
      print('Reading preferences');
      var data = await getStorage().readAll();
      compact = false;

      data.forEach((key, value) {
        debugPrint('[Config] $key : $value');
        switch (key) {
          case 'dbPassword':
            dbPassword = value;
            break;
          case 'credentials':
            credentials = Credential.fromJson(jsonDecode(value));
            break;
          case 'school':
            school = School.fromJson(jsonDecode(value));
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
            enforcedBrightness = Brightness.values.byName(value);
            break;
          case 'notifications':
            _notificationSettings = Map<NotificationType, bool>.from(jsonDecode(value).map(
              (key, value) => MapEntry(NotificationType.values.byName(key), value),
            ));
            if (_notificationSettings!.values.contains(true)) {
              FlutterLocalNotificationsPlugin()
                  .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
                  .areNotificationsEnabled()
                  .then((enabled) {
                if (enabled != true) {
                  notificationSettings = Map.from(disabled);
                }
              });
            }
            break;
          case 'lessonColors':
            ColorProvider.init(value);
        }
      });
      notificationSettings ??= Map.from(disabled);
    } on PlatformException catch (_) {
      // Workaround for https://github.com/mogol/flutter_secure_storage/issues/43
      await getStorage().deleteAll();
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
