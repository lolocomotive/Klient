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

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  late final WebViewController _controller;
  late final Webview _webview;
  bool _showBrowser = false;

  final _searchController = TextEditingController();

  String _query = '';
  bool _useLocation = false;

  Stream<SkolengoResponse<List<School>>>? _data;
  LoginState();
  final isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  @override
  initState() {
    if (isDesktop) {
    } else {
      _controller = WebViewController();
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      _controller.setNavigationDelegate(NavigationDelegate(onUrlChange: (change) {
        if (change.url == null) return;
        if (change.url!.startsWith('skoapp-prod://')) {
          _controller.loadRequest(
              Uri.parse(change.url!.replaceAll('skoapp-prod://', 'http://localhost:3000/')));
        }
      }));
    }
    super.initState();
  }

  _postLogin(Database db) async {
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
    final client = Skolengo.unauthenticated();
    final oidclient = await client.getOIDClient(school);

    urlLauncher(String url) async {
      setState(() {});
      if (isDesktop) {
        _webview = await WebviewWindow.create(
            configuration: const CreateConfiguration(
          title: 'Se connecter',
          titleBarHeight: 40,
          titleBarTopPadding: 0,
        ));
        _webview.launch(url);
        _webview.addOnUrlRequestCallback((url) {
          print(url);
          if (url.startsWith('skoapp-prod://')) {
            _webview.launch(url.replaceAll('skoapp-prod://', 'http://localhost:3000/'));
          }
        });
      } else {
        _showBrowser = true;
        _controller.loadRequest(Uri.parse(url));
      }
    }

    final authenticator = Authenticator(
      oidclient,
      redirectUri: Uri.parse('skoapp-prod://sign-in-callback'),
      urlLancher: urlLauncher,
    );

    ConfigProvider.credentials = await authenticator.authorize();
    ConfigProvider.school = school;

    if (isDesktop) {
      _webview.close();
    }

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
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: DefaultCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                    _useLocation = false;
                                    if (_query.length > 3) {
                                      _data = Skolengo.unauthenticated()
                                          .searchSchool(value)
                                          .asBroadcastStream();
                                    } else {
                                      _data = null;
                                    }
                                  });
                                },
                              ),
                            ),
                            StreamBuilder<SkolengoResponse<List<School>>>(
                              stream: _data,
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return ExceptionWidget(
                                      e: snapshot.error!, st: snapshot.stackTrace!);
                                }
                                if (!_useLocation && _query.length <= 3) {
                                  return Text(
                                    'Entrez au moins 3 caractères',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                }
                                if (snapshot.hasData) {
                                  List<School> schools = snapshot.data!.data;
                                  if (schools.isEmpty) {
                                    return Text(
                                      'Aucun résultat',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    );
                                  }
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
                                return const Center(child: CircularProgressIndicator());
                              },
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Ou', textAlign: TextAlign.center),
                            ),
                            ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.resolveWith(
                                  (states) => ElevationOverlay.applySurfaceTint(
                                    Theme.of(context).colorScheme.surface,
                                    Theme.of(context).colorScheme.primary,
                                    3,
                                  ),
                                ),
                                elevation: MaterialStateProperty.resolveWith(
                                  (states) => 2,
                                ),
                              ),
                              onPressed: () async {
                                _data = null;
                                _useLocation = true;

                                setState(() {});
                                bool serviceEnabled;
                                LocationPermission permission;
                                serviceEnabled = await Geolocator.isLocationServiceEnabled();
                                if (!serviceEnabled) {
                                  throw Exception('Location services are disabled.');
                                }

                                permission = await Geolocator.checkPermission();
                                if (permission == LocationPermission.denied) {
                                  permission = await Geolocator.requestPermission();
                                  if (permission == LocationPermission.denied) {
                                    throw Exception('Location permissions are denied');
                                  }
                                }

                                if (permission == LocationPermission.deniedForever) {
                                  throw Exception(
                                      'Location permissions are permanently denied, we cannot request permissions.');
                                }
                                final position = await Geolocator.getCurrentPosition();
                                _data = Skolengo.unauthenticated()
                                    .searchSchoolGPS(position.latitude, position.longitude)
                                    .asBroadcastStream();
                                setState(() {});
                              },
                              child: const Text('Utiliser la géolocalisation'),
                            )
                          ],
                        ),
                      ),
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
