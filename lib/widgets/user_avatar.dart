import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String content;
  const UserAvatar(
    this.content, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
          margin: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: Center(
            child: Text(
              content,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: MediaQuery.of(context).textScaleFactor * 16,
              ),
            ),
          )),
    );
  }
}
