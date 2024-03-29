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
import 'package:klient/api/client.dart';
import 'package:klient/api/demo.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/database_provider.dart';
import 'package:klient/main.dart';
import 'package:klient/screens/about.dart';
import 'package:klient/util.dart';
import 'package:klient/widgets/default_activity.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class Login extends StatefulWidget {
  const Login(this.onLogin, {Key? key}) : super(key: key);
  final void Function() onLogin;
  @override
  State<StatefulWidget> createState() {
    return LoginState();
  }
}

class LoginState extends State<Login> {
  final _loginFormKey = GlobalKey<FormState>();
  final _unameController = TextEditingController();
  final _pwdController = TextEditingController();

  bool _processing = false;
  LoginState();

  _postLogin(Database db) async {
    await ConfigProvider.getStorage().write(key: 'firstTime', value: 'true');
    _resetDb(db);
    widget.onLogin();
    return;
  }

  _resetDb(Database db) async {
    await db.close();
    await DatabaseProvider.deleteDb(db.path);
    await DatabaseProvider.initDB();
  }

  _login() async {
    // The demo mode is activated like that instead of with an obvious button because it would just uselessly clutter the UI otherwise
    final db = await DatabaseProvider.getDB();
    if (_unameController.text == '__DEMO') {
      await _resetDb(db);
      generate();
      ConfigProvider.demo = true;
      Client.demo();
      widget.onLogin();
      return;
    }

    if (_unameController.text.length == 125) {
      //Set the token directly.
      Client(_unameController.text);
      await _postLogin(db);
    }
    ConfigProvider.demo = false;
    ConfigProvider.getStorage().write(key: 'demoMode', value: 'false');
    if (_loginFormKey.currentState!.validate()) {
      setState(() {
        _processing = true;
      });
      try {
        await Client.login(_unameController.text, _pwdController.text);
        await _postLogin(db);
      } on BadCredentialsException catch (_) {
        KlientApp.messengerKey.currentState!.showSnackBar(
          SnackBar(
            backgroundColor: KlientApp.theme!.colorScheme.surface,
            content: Text(
              'Mauvais identifiant/code d\'activation',
              style: TextStyle(
                color: KlientApp.theme!.colorScheme.onSurface,
              ),
            ),
          ),
        );
      } on Exception catch (e, st) {
        Util.onException(e, st);
      } finally {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _unameController.dispose();
    _pwdController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultActivity(
      appBar: AppBar(
        title: const Text('Connexion'),
        actions: [
          IconButton(
            tooltip: 'À propos',
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => const AboutPage()));
            },
            icon: const Icon(
              Icons.info_outline_rounded,
            ),
          )
        ],
      ),
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _loginFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Portail de connexion:',
                                style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                            DropdownButton(
                              isExpanded: true,
                              value: Client.apiurl,
                              items: KlientApp.dropdownItems,
                              onChanged: (dynamic newValue) async {
                                await ConfigProvider.getStorage()
                                    .write(key: 'apiurl', value: newValue);
                                Client.apiurl = newValue;
                                setState(() {});
                              },
                            ),
                            TextFormField(
                              decoration: const InputDecoration(hintText: 'Identifiant mobile'),
                              controller: _unameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre identifiant mobile';
                                }
                                return null;
                              },
                              enableSuggestions: false,
                              autocorrect: false,
                              autofocus: true,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    decoration:
                                        const InputDecoration(hintText: 'Code d\'activation'),
                                    controller: _pwdController,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre code d\'activation';
                                      }
                                      return null;
                                    },
                                    enableSuggestions: false,
                                    autocorrect: false,
                                    obscureText: true,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Où trouver ce code?',
                                  alignment: Alignment.bottomCenter,
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        content: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                                'L\'identifiant mobile et le code d\'activation sont disponibles dans le menu "Application mobile" dans les paramètres utilisateur de l\'ENT'),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('OK'),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.help_outline,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                )
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (_processing)
                                    Expanded(
                                      child: Center(
                                          child: Transform.scale(
                                              scale: .7, child: const CircularProgressIndicator())),
                                    ),
                                  OutlinedButton(
                                    onPressed: _processing ? null : _login,
                                    child: const Text('Se connecter'),
                                  ),
                                ],
                              ),
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
                        print(snapshot.error);
                        return Text('Erreur: "${snapshot.error}"');
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
          ),
        ],
      ),
    );
  }
}
