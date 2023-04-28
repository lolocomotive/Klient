/*
 * This file is part of the Klient (https://github.com/lolocomotive/klient)
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
import 'package:flutter_html/flutter_html.dart';
import 'package:klient/widgets/attachments_widget.dart';
import 'package:klient/widgets/default_activity.dart';
import 'package:scolengo_api/scolengo_api.dart';
import 'package:url_launcher/url_launcher.dart';

class SchoolInfoPage extends StatelessWidget {
  const SchoolInfoPage(this._info, {Key? key}) : super(key: key);
  final SchoolInfo _info;

  @override
  Widget build(BuildContext context) {
    return DefaultSliverActivity(
      title: _info.title,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_info.attachments.isNotEmpty)
              AttachmentsWidget(
                attachments: _info.attachments,
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Html(
                data: _info.content,
                onLinkTap: (url, context, map, element) {
                  launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
