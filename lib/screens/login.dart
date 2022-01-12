import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../kdecole-api/client.dart';
import '../main.dart';

class Login extends StatefulWidget {
  Login(this._messengerKey, {Key? key}) : super(key: key);
  final GlobalKey<ScaffoldMessengerState> _messengerKey;

  @override
  State<StatefulWidget> createState() {
    return LoginState(_messengerKey);
  }
}

class LoginState extends State<Login> {
  final _loginFormKey = GlobalKey<FormState>();
  final _unameController = TextEditingController();
  final _pwdController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _messengerKey;

  LoginState(this._messengerKey);

  _login() async {
    if (_loginFormKey.currentState!.validate()) {
      try {
        Global.client = await Client.login(_unameController.text,
            _pwdController.text);
        setState(() {});
      } catch (e) {
        _messengerKey.currentState!.showSnackBar(
            const SnackBar(content: Text('Mauvais identifiant/mot de passe')));
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
      appBar: AppBar(title: Text('Connexion')),
      body: Container(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _loginFormKey,
          child: Column(
            children: [
              TextFormField(
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
                controller: _pwdController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un mot de passe';
                  }
                  return null;
                },
                enableSuggestions: false,
                autocorrect: false,
                obscureText: true,
              ),
              ElevatedButton(onPressed: _login, child: Text('Se connecter'))
            ],
          ),
        ),
      ),
    );
  }
}
