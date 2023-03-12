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
import 'package:kosmos_client/config_provider.dart';

/// All screens have some thing in common.
/// Having a widget with all the common parts makes it easier to modify later.
class DefaultActivity extends StatelessWidget {
  const DefaultActivity({Key? key, required this.child, this.appBar}) : super(key: key);

  final Widget child;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ConfigProvider.bgColor.toColor(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: Scaffold(
            appBar: appBar,
            body: child,
          ),
        ),
      ),
    );
  }
}

class DefaultSliverActivity extends StatelessWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? titleBackground;
  final Color? titleColor;

  const DefaultSliverActivity({
    Key? key,
    required this.title,
    required this.child,
    this.actions,
    this.leading,
    this.titleBackground,
    this.titleColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultActivity(
      child: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: titleBackground,
              leading: leading,
              title: Text(
                title,
                style: TextStyle(color: titleColor),
              ),
              floating: true,
              forceElevated: innerBoxIsScrolled,
              actions: actions,
            )
          ];
        },
        body: Scrollbar(child: child),
      ),
    );
  }
}
