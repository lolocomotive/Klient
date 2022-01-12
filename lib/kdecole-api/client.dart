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

import 'package:http/http.dart' as http;
import 'package:kosmos_client/main.dart';
/// Utility class making it easier to communicate with the API
class Client {
  static const String _appVersion = '3.7.14';
  static const String _serverURL =
      'https://mobilite.kosmoseducation.com/mobilite/';
  late String _token;
  String? idEtablissement;
  String? idEleve;

  /// Make a request to the API
  Future<Map<String, dynamic>> request(Action action,
      {List<String>? params}) async {
    Map<String, String> headers = {
      'X-Kdecole-Vers': _appVersion,
      'X-Kdecole-Auth': _token,
    };
    String url = _serverURL + action.url;
    for (final param in params ?? []) {
      url += param + '/';
    }

    http.Response response;
    switch (action.method) {
      case HTTPRequestMethod.get:
        response = await http.get(Uri.parse(url), headers: headers);
        break;
      case HTTPRequestMethod.put:
        response = await http.put(Uri.parse(url), headers: headers);
        break;
      case HTTPRequestMethod.delete:
        response = await http.delete(Uri.parse(url), headers: headers);
        break;
    }

    if ((response.statusCode >= 200 && response.statusCode < 300) ||
        response.statusCode == 204) {
      var data = jsonDecode(response.body);
      if (response.body.startsWith('[')) {
        data = jsonDecode('{"errmsg":null,"articles":' + response.body + '}');
      }
      if (data['errmsg'] != null) {
        throw Error();
      }
      return data;
    } else {
      stdout.writeln('Error!');
      stdout.writeln(response.body);
      throw Error();
    }
  }

  /// Log in using username and activation code provided by the ENT
  static Future<Client> login(
      String username, String password) async {
    final res = await Client('')
        .request(Action.activate, params: [username, password]);
    if (res['success'] == true) {
      return Client(res['authtoken']);
    } else {
      throw Error();
    }
  }

  Client(String token) {
    _token = token;
    Global.storage!.write(key: 'token', value: _token);
    Global.token = _token;
  }
}

enum HTTPRequestMethod { get, put, delete }

/// A subset of the different actions allowed by the API
class Action {
  String url;
  HTTPRequestMethod method;

  Action(this.url, [this.method = HTTPRequestMethod.get]);

  static final Action activate = Action('activation/');
  static final Action getConversations = Action('messagerie/boiteReception/');
  static final Action getConversationDetail =
      Action('messagerie/communication/');
  static final Action getUserInfo = Action('infosutilisateur/');
  static final Action getNewsArticlesEtablissement =
      Action('actualites/idetablissement/');
  static final Action getArticleDetails = Action('contenuArticle/article/');
  static final Action getTimeTableEleve = Action('calendrier/ideleve/');

  //params ideleve/idseance/idexercise/
  static final Action getExerciseDetails = Action('contenuActivite/ideleve/');
}
