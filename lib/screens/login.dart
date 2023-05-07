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

import 'package:flutter/material.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/database_provider.dart';
import 'package:klient/main.dart';
import 'package:klient/screens/about.dart';
import 'package:klient/widgets/default_activity.dart';
import 'package:klient/widgets/default_card.dart';
import 'package:klient/widgets/exception_widget.dart';
import 'package:openid_client/openid_client_io.dart';
import 'package:scolengo_api/scolengo_api.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Login extends StatefulWidget {
  const Login(this.onLogin, {Key? key}) : super(key: key);
  final void Function() onLogin;
  @override
  State<StatefulWidget> createState() {
    return LoginState();
  }
}

class LoginState extends State<Login> {
  final _controller = WebViewController();
  bool _showBrowser = false;

  final _searchController = TextEditingController();

  String _query = '';
  LoginState();

  _postLogin(Database db) async {
    await ConfigProvider.getStorage().write(key: 'firstTime', value: 'true');
    await _resetDb(db);
    widget.onLogin();
    await KlientApp.cache.init();
    return;
  }

  _resetDb(Database db) async {
    await db.close();
    await DatabaseProvider.deleteDb(db.path);
    await DatabaseProvider.initDB();
  }

  _login(School school) async {
    _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    _controller.setNavigationDelegate(NavigationDelegate(onUrlChange: (change) {
      if (change.url == null) return;
      if (change.url!.startsWith('skoapp-prod://')) {
        _controller.loadRequest(
            Uri.parse(change.url!.replaceAll('skoapp-prod://', 'http://localhost:3000/')));
      }
    }));
    final client = Skolengo.unauthenticated();
    final oidclient = await client.getOIDClient(school);

    urlLauncher(String url) async {
      setState(() {});
      _showBrowser = true;
      _controller.loadRequest(Uri.parse(url));
    }

    final authenticator = Authenticator(
      oidclient,
      redirectUri: Uri.parse('skoapp-prod://sign-in-callback'),
      urlLancher: urlLauncher,
    );

    ConfigProvider.credentials = await authenticator.authorize();
    ConfigProvider.school = school;

    ConfigProvider.getStorage()
      ..write(key: 'credentials', value: jsonEncode(ConfigProvider.credentials!.toJson()))
      ..write(key: 'school', value: jsonEncode(ConfigProvider.school!.toJson()));

    _postLogin(await DatabaseProvider.getDB());

    // TODO rewrite demo mode
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultSliverActivity(
      title: 'Connexion',
      actions: [
        IconButton(
          tooltip: 'À propos',
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AboutPage()));
          },
          icon: const Icon(
            Icons.info_outline_rounded,
          ),
        ),
        if (_showBrowser)
          IconButton(
            tooltip: 'Fermer le navigateur',
            onPressed: () {
              setState(() {
                _showBrowser = false;
                _controller.loadHtmlString(' ');
                //TODO cancel login
              });
            },
            icon: const Icon(
              Icons.close_rounded,
            ),
          ),
      ],
      child: _showBrowser
          ? WebViewWidget(controller: _controller)
          : SingleChildScrollView(
              child: Column(
                children: [
                  DefaultCard(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: _searchController,
                            decoration:
                                const InputDecoration(hintText: 'Rechercher un établissement'),
                            onChanged: (value) {
                              setState(() {
                                _query = value;
                              });
                            },
                          ),
                        ),
                        _query.length < 3
                            ? Text('Entrez au moins 3 caractères',
                                style: TextStyle(color: Theme.of(context).colorScheme.secondary))
                            : FutureBuilder<SkolengoResponse<List<School>>>(
                                future: Skolengo.unauthenticated().searchSchool(_query),
                                builder: (context, snapshot) {
                                  if (snapshot.data != null) {
                                    List<School> schools = snapshot.data!.data;
                                    return Column(
                                      children: schools
                                          .map((e) => ListTile(
                                                title: Text(e.name),
                                                subtitle: Text(
                                                  '${e.addressLine1} ${e.city}',
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.secondary,
                                                  ),
                                                ),
                                                onTap: () {
                                                  _login(e);
                                                },
                                              ))
                                          .toList(),
                                    );
                                  }
                                  return const CircularProgressIndicator();
                                },
                              ),
                      ],
                    ),
                  ),
                  FutureBuilder<AppInfo>(
                    future: AppInfo.getAppInfo(),
                    builder: ((context, snapshot) {
                      if (snapshot.hasError) {
                        return ExceptionWidget(e: snapshot.error!, st: snapshot.stackTrace!);
                      } else if (snapshot.data != null) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Opacity(
                            opacity: snapshot.data!.branch != 'master' ? .3 : 0,
                            child: Text(
                              '${snapshot.data!.branch}-${snapshot.data!.commitID}${snapshot.data!.version}+${snapshot.data!.build}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        );
                      } else {
                        return Container();
                      }
                    }),
                  ),
                ],
              ),
            ),
    );
  }
}
