import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String content;
  final Color? color;
  const UserAvatar(
    this.content, {
    Key? key,
    this.color,
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
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
            color: color?.withAlpha(50),
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
