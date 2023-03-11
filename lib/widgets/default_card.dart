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

class DefaultCard extends StatelessWidget {
  final double? elevation;
  final bool outlined;
  final Widget? child;
  final EdgeInsets padding;
  final void Function()? onTap;
  final Color? shadowColor;
  final Color? surfaceTintColor;

  const DefaultCard(
      {Key? key,
      this.surfaceTintColor,
      this.shadowColor,
      this.elevation,
      this.outlined = false,
      this.child,
      this.onTap,
      this.padding = const EdgeInsets.all(16)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      surfaceTintColor: surfaceTintColor,
      shadowColor: shadowColor,
      margin: const EdgeInsets.all(8.0),
      elevation: elevation ?? 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: outlined ? BorderSide(color: Theme.of(context).colorScheme.outline) : BorderSide.none,
      ),
      //clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
