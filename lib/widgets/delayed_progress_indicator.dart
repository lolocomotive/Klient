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

class DelayedProgressIndicator extends StatelessWidget {
  final Duration delay;

  const DelayedProgressIndicator({Key? key, required this.delay}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.delayed(delay),
        builder: (context, snapshot) {
          return AnimatedOpacity(
              opacity: snapshot.connectionState == ConnectionState.done ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: const CircularProgressIndicator());
        });
  }
}
