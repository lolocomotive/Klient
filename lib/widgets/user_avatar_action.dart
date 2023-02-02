import 'package:flutter/material.dart';
import 'package:kosmos_client/api/client.dart';
import 'package:kosmos_client/screens/user_dialog.dart';
import 'package:kosmos_client/widgets/user_avatar.dart';

class UserAvatarAction extends StatefulWidget {
  final void Function()? onUpdate;

  const UserAvatarAction({Key? key, this.onUpdate}) : super(key: key);

  @override
  State<UserAvatarAction> createState() => _UserAvatarActionState();
}

class _UserAvatarActionState extends State<UserAvatarAction> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => UserDialog(onUpdate: () {
            setState(() {});
            if (widget.onUpdate != null) widget.onUpdate!();
          }),
        );
      },
      borderRadius: BorderRadius.circular(1000),
      child: UserAvatar(Client.currentlySelected != null
          ? Client.currentlySelected!.name.split(' ').map((e) => e[0]).join()
          : 'ERR'),
    );
  }
}
