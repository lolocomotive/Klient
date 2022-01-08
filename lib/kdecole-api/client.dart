import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Client {
  static const String _appVersion = '3.7.14';
  static const String _serverURL =
      'https://mobilite.kosmoseducation.com/mobilite/';
  late String _token;
  late SharedPreferences _prefs;

  Future<Map<String, dynamic>> _request(String url) async {
    stdout.writeln(url);
    Map<String, String> headers = {
      'X-Kdecole-Vers': _appVersion,
      'X-Kdecole-Auth': _token,
    };
    final response = await http.get(Uri.parse(url), headers: headers);
    if ((response.statusCode >= 200 && response.statusCode < 300) ||
        response.statusCode == 204) {
      final data = jsonDecode(response.body);
      if (data['errmsg'] != null) {
        throw Error();
      }
      return data;
    } else {
      throw Error();
    }
  }

  static Future<Client> login(String username, String password,
      SharedPreferences prefs) async {
    final res = await Client('', prefs)._request(
        _serverURL + Action.activate.url + username + '/' + password + '/');
    if (res['success'] == true) {
      return Client(res['authtoken'], prefs);
    } else {
      throw Error();
    }
  }

  Client(String token, SharedPreferences prefs) {
    _prefs = prefs;
    _token = token;
    _prefs.setString('token', _token);
  }
}

class Action {
  String url;

  Action(this.url);

  static final Action activate = Action('activation/');
  static final Action startup = Action('login/');
}
