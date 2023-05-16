import 'package:flutter/material.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/screens/user_dialog.dart';
import 'package:klient/widgets/default_transition.dart';
import 'package:klient/widgets/delayed_progress_indicator.dart';
import 'package:klient/widgets/user_avatar.dart';
import 'package:scolengo_api/scolengo_api.dart';

class UserAvatarAction extends StatefulWidget {
  final void Function()? onUpdate;

  const UserAvatarAction({Key? key, this.onUpdate}) : super(key: key);

  @override
  State<UserAvatarAction> createState() => _UserAvatarActionState();
}

class _UserAvatarActionState extends State<UserAvatarAction> {
  bool loaded = false;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => UserDialog(onUpdate: () {
            if (!mounted) return;
            setState(() {});
            if (widget.onUpdate != null) widget.onUpdate!();
          }),
        );
      },
      borderRadius: BorderRadius.circular(1000),
      child: FutureBuilder<User>(
          future: ConfigProvider.user,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Builder(builder: (context) {
                loaded = true;
                return UserAvatar(snapshot.data!.firstName[0] + snapshot.data!.lastName[0]);
              });
            } else if (snapshot.hasError) {
              return const DefaultTransition(child: UserAvatar('ERR'));
            } else {
              return const DelayedProgressIndicator(
                delay: Duration(milliseconds: 300),
              );
            }
          }),
    );
  }
}
