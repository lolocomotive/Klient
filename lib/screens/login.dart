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

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../global.dart';
import '../kdecole-api/client.dart';

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
  LoginState();

  _login() async {
    if (_loginFormKey.currentState!.validate()) {
      try {
        Global.client = await Client.login(_unameController.text, _pwdController.text);
        await Global.storage!.write(key: 'firstTime', value: 'true');
        await Global.db!.close();
        await deleteDatabase(Global.db!.path);
        await Global.initDB();
        Global.client!.clear();
        widget.onLogin();
      } on BadCredentialsException catch (_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Mauvais identifiant/mot de passe')));
      } catch (e, st) {
        Navigator.of(context).push(MaterialPageRoute(builder: (ctx) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Erreur'),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Text(e.toString()),
                  Text(st.toString()),
                ],
              ),
            ),
          );
        }));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 2,
              margin: const EdgeInsets.all(32.0),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _loginFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButton(
                          isExpanded: true,
                          value: Global.apiurl,
                          items: Global.dropdownItems,
                          onChanged: (dynamic newValue) async {
                            await Global.storage!.write(key: 'apiurl', value: newValue);
                            Global.apiurl = newValue;
                            setState(() {});
                          }),
                      TextFormField(
                        decoration: const InputDecoration(hintText: 'Nom d\'utilisateur'),
                        controller: _unameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un nom d\'utilisateur';
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
                              decoration: const InputDecoration(hintText: 'Code d\'activation'),
                              controller: _pwdController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer un code d\'activation';
                                }
                                return null;
                              },
                              enableSuggestions: false,
                              autocorrect: false,
                              obscureText: true,
                            ),
                          ),
                          IconButton(
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
                            OutlinedButton(onPressed: _login, child: const Text('Se connecter')),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
