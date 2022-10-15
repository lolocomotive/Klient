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
import 'package:kosmos_client/api/client.dart';
import 'package:kosmos_client/api/demo.dart';
import 'package:kosmos_client/global.dart';
import 'package:kosmos_client/screens/about.dart';
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

  _login() async {
    // The demo mode is activated like that instead of with an obvious button because it would just uselessly clutter the UI otherwise
    if (_unameController.text == '__DEMO') {
      await Global.storage!.write(key: 'demoMode', value: 'true');
      await Global.db!.close();
      await deleteDatabase(Global.db!.path);
      await Global.initDB();
      generate();
      Global.demo = true;
      Global.client = Client.demo();
      widget.onLogin();
      return;
    }
    Global.demo = false;
    Global.storage!.write(key: 'demoMode', value: 'false');
    if (_loginFormKey.currentState!.validate()) {
      setState(() {
        _processing = true;
      });
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
      } on Exception catch (e, st) {
        Global.onException(e, st);
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
    return Scaffold(
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
      body: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
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
                          value: Global.apiurl,
                          items: Global.dropdownItems,
                          onChanged: (dynamic newValue) async {
                            await Global.storage!.write(key: 'apiurl', value: newValue);
                            Global.apiurl = newValue;
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
                                decoration: const InputDecoration(hintText: 'Code d\'activation'),
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
            ),
          ),
        ],
      ),
    );
  }
}
