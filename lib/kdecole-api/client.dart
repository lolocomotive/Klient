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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:kosmos_client/global.dart';
import 'package:kosmos_client/screens/login.dart';

import 'conversation.dart';

class Request {
  final String _url;
  final HTTPRequestMethod _method;
  final void Function(Map<String, dynamic> result) _onSuccess;
  final void Function(Map<String, dynamic> result) _onJsonErr;
  final void Function() _onHttp400;
  final Map<String, String> _headers;

  Request(
      this._url, this._onSuccess, this._headers, this._method, this._onJsonErr, this._onHttp400);

  process() async {
    http.Response? response;
    final context = SecurityContext.defaultContext;
    //Including the ISRG root certificate for older devices (looking at you Gloria)
    ByteData data = await rootBundle.load('assets/isrgrootx1.pem');
    try {
      context.setTrustedCertificatesBytes(data.buffer.asUint8List());
    } on TlsException {
      //Ignore the exception since this happens when the certificate is already there
    }
    final httpClient = HttpClient(context: context);
    final client = IOClient(httpClient);
    bool success = false;
    do {
      try {
        switch (_method) {
          case HTTPRequestMethod.get:
            response = await client.get(Uri.parse(_url), headers: _headers);
            break;
          case HTTPRequestMethod.put:
            response = await client.put(Uri.parse(_url), headers: _headers);
            break;
          case HTTPRequestMethod.delete:
            response = await client.delete(Uri.parse(_url), headers: _headers);
            break;
        }
        success = true;
      } catch (_) {
        rethrow;
        //success = false;
        //sleep(const Duration(milliseconds: 1000));
      }
    } while (!success);

    if ((response.statusCode >= 200 && response.statusCode < 300) || response.statusCode == 204) {
      var data = jsonDecode(response.body);
      if (response.body.startsWith('[')) {
        data = jsonDecode('{"errmsg":null,"articles":${response.body}}');
      }
      if (data['errmsg'] != null) {
        _onJsonErr(data);
      }
      _onSuccess(data);
    } else {
      if (response.statusCode >= 400) {
        _onHttp400();
      }
      throw Error();
    }
  }
}

/// Utility class making it easier to communicate with the API
class Client {
  static const String _appVersion = '3.7.14';
  late String _token;
  String? idEtablissement;
  String? idEleve;
  final List<Request> _requests = [];
  static const int _maxConcurrentDownloads = 4;
  int _currentlyDownloading = 0;

  ///This usually happens when the user is logged out
  default403Handler() {
    while (_requests.isNotEmpty) {
      _requests.removeAt(0);
    }
    showDialog(
        context: Global.navigatorKey.currentContext!,
        builder: (context) {
          return AlertDialog(
            alignment: Alignment.center,
            actionsAlignment: MainAxisAlignment.end,
            title: const Text('Erreur 403'),
            content: const Text(
                'Cette erreur se produit en général quand le jeton d\'authentification n\'est plus valide auquel cas il faut se reconnecter.'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'ANNULER',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                  )),
              TextButton(
                  onPressed: () {
                    Global.storage!.delete(key: 'token');
                    Global.navigatorKey.currentState!
                      ..pop()
                      ..push(
                        MaterialPageRoute(
                          builder: (_) => Login(() {
                            Global.navigatorKey.currentState!.pop();
                            Global.onLogin!();
                          }),
                        ),
                      );
                  },
                  child: const Text('SE RECONNTECTER')),
            ],
          );
        });
    throw NetworkException403();
  }

  addRequest(Action action, void Function(Map<String, dynamic> result) onSuccess,
      {List<String>? params,
      void Function(Map<String, dynamic> result)? onJsonErr,
      void Function()? onHttpErr}) {
    Map<String, String> headers = {
      'X-Kdecole-Vers': _appVersion,
      'X-Kdecole-Auth': _token,
    };
    String url = Global.apiurl + action.url;
    for (final param in params ?? []) {
      url += param + '/';
    }
    _requests.add(
      Request(
        url,
        onSuccess,
        headers,
        action.method,
        onJsonErr ??
            (result) {
              throw UnimplementedError();
            },
        onHttpErr ??
            () {
              throw UnimplementedError();
            },
      ),
    );
  }

  process() async {
    Global.progress = 0;
    Global.progressOf = _requests.length;
    while (_requests.isNotEmpty) {
      if (_currentlyDownloading <= _maxConcurrentDownloads) {
        _currentlyDownloading++;
        _requests[0].process().then((_) {
          _currentlyDownloading--;
          Global.progress++;
        });
        _requests.removeAt(0);
      } else {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
    while (_currentlyDownloading > 0) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    Global.progress = 0;
    Global.progressOf = 0;
  }

  /// Make a request to the API
  Future<Map<String, dynamic>> request(Action action, {List<String>? params, String? body}) async {
    Map<String, String> headers = {
      'X-Kdecole-Vers': _appVersion,
      'X-Kdecole-Auth': _token,
    };

    String url = Global.apiurl + action.url;
    for (final param in params ?? []) {
      url += param + '/';
    }

    http.Response response;
    final context = SecurityContext.defaultContext;
    //Including the ISRG root certificate for older devices (looking at you Gloria)
    ByteData data = await rootBundle.load('assets/isrgrootx1.pem');
    try {
      context.setTrustedCertificatesBytes(data.buffer.asUint8List());
    } on TlsException {
      //Ignore the exception since this happens when the certificate is already there
    }
    final httpClient = HttpClient(context: context);
    final client = IOClient(httpClient);

    switch (action.method) {
      case HTTPRequestMethod.get:
        response = await client.get(Uri.parse(url), headers: headers);
        break;
      case HTTPRequestMethod.put:
        response = await client.put(Uri.parse(url), headers: headers, body: body);
        break;
      case HTTPRequestMethod.delete:
        response = await client.delete(Uri.parse(url), headers: headers);
        break;
    }

    if ((response.statusCode >= 200 && response.statusCode < 300) || response.statusCode == 204) {
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = jsonDecode('{"errmsg":null}');
      }
      if (response.body.startsWith('[')) {
        data = jsonDecode('{"errmsg":null,"articles":${response.body}}');
      }
      if (data['errmsg'] != null) {
        throw Error();
      }
      return data;
    } else {
      if (response.statusCode == 403) {
        default403Handler();
      }
      print('Error!');
      print(response.body);
      throw Error();
    }
  }

  markConversationRead(Conversation conv) {
    conv.read = true;
    request(Action.markConversationRead, params: [conv.id.toString()]);
    Global.db!
        .update('Conversations', {'Read': 1}, where: 'ID = ?', whereArgs: [conv.id.toString()]);
  }

  /// Log in using username and activation code provided by the ENT
  static Future<Client> login(String username, String password) async {
    final res = await Client('').request(Action.activate, params: [username, password]);
    if (res['success'] == true) {
      return Client(res['authtoken']);
    } else {
      throw BadCredentialsException();
    }
  }

  Client(String token) {
    _token = token;
    Global.storage!.write(key: 'token', value: _token);
    Global.token = _token;
    if (token == '') return;
    request(Action.startup);
  }

  void clear() {
    while (_requests.isNotEmpty) {
      _requests.removeAt(0);
    }
  }
}

class NetworkException403 implements Exception {}

class BadCredentialsException implements Exception {}

enum HTTPRequestMethod { get, put, delete }

/// A subset of the different actions allowed by the API
class Action {
  String url;
  HTTPRequestMethod method;

  Action(this.url, [this.method = HTTPRequestMethod.get]);

  static final Action activate = Action('activation/');
  static final Action startup = Action('starting/');
  static final Action getConversations = Action('messagerie/boiteReception/');
  static final Action getConversationDetail = Action('messagerie/communication/');
  static final Action getUserInfo = Action('infosutilisateur/');
  static final Action getNewsArticlesEtablissement = Action('actualites/idetablissement/');
  static final Action getArticleDetails = Action('contenuArticle/article/');
  static final Action getTimeTableEleve = Action('calendrier/ideleve/');

  //params ideleve/idseance/idexercise/
  static final Action getExerciseDetails = Action('contenuActivite/ideleve/');

  //param idconversations
  static final Action markConversationRead =
      Action('messagerie/communication/lu/', HTTPRequestMethod.put);
  static final Action getGrades = Action('consulterNotes/idetablissement/');
  static final Action reply =
      Action('messagerie/communication/nouvelleParticipation/', HTTPRequestMethod.put);
  static final Action logout = Action('desactivation/');
}
