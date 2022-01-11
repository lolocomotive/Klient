import 'package:flutter/material.dart';

class UserInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(10.0, 50.0, 10.0, 20.0),
            decoration:
                BoxDecoration(color: Theme.of(context).colorScheme.primary),
            child: Text(
              'Username',
              style: TextStyle(fontSize: 30.0),
            ),
          )
        ]);
  }
}
