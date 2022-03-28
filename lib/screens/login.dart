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

import '../kdecole-api/client.dart';
import '../global.dart';

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
//      widget.onLogin();
//
//      return;
      try {
        Global.client =
            await Client.login(_unameController.text, _pwdController.text);
        widget.onLogin();
      } on BadCredentialsException catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mauvais identifiant/mot de passe')));
      } catch (e, st) {
        Navigator.of(context).push(MaterialPageRoute(builder: (ctx) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Erreur'),
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
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _loginFormKey,
          child: Column(
            children: [
              TextFormField(
                decoration:
                    const InputDecoration(hintText: 'Nom d\'utilisateur'),
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
              TextFormField(
                decoration:
                    const InputDecoration(hintText: 'Code d\'activation'),
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
              ElevatedButton(
                  onPressed: _login, child: const Text('Se connecter'))
            ],
          ),
        ),
      ),
    );
  }
}
