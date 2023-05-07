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
      child: FutureBuilder<SkolengoResponse<User>>(
          future: ConfigProvider.client!
              .getUserInfo(ConfigProvider.client!.credentials!.idToken.claims.subject),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return DefaultTransition(
                  child: UserAvatar(
                      snapshot.data!.data.firstName[0] + snapshot.data!.data.lastName[0]));
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
