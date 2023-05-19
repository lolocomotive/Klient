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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/main.dart';
import 'package:klient/util.dart';
import 'package:klient/widgets/attachments_widget.dart';
import 'package:klient/widgets/custom_html.dart';
import 'package:klient/widgets/default_activity.dart';
import 'package:klient/widgets/default_transition.dart';
import 'package:scolengo_api/scolengo_api.dart';

class SchoolInfoPage extends StatefulWidget {
  const SchoolInfoPage(this._info, {Key? key}) : super(key: key);
  final SchoolInfo _info;

  @override
  State<SchoolInfoPage> createState() => _SchoolInfoPageState();
}

class _SchoolInfoPageState extends State<SchoolInfoPage> {
  late SchoolInfo _info;
  @override
  void initState() {
    _info = widget._info;
    load();
    super.initState();
  }

  load() async {
    final responses = ConfigProvider.client!.getSchoolInfo(_info.id);
    await for (final response in responses) {
      if (!mounted) return;
      setState(() {
        _info = response.data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultSliverActivity(
      title: widget._info.title,
      child: RefreshIndicator(
        onRefresh: () async {
          KlientApp.cache.forceRefresh = true;
          load();
          KlientApp.cache.forceRefresh = false;
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${widget._info.author?.fullName ?? 'Auteur inconnu'} - ${widget._info.publicationDateTime.format()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget._info.school.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget._info.illustration != null)
                Hero(
                  tag: widget._info.illustration!.url,
                  child: InteractiveViewer(
                    child: Image(
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width,
                      image: CachedNetworkImageProvider(
                        widget._info.illustration!.url,
                        headers: ConfigProvider.client!.headers,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomHtml(
                  data: widget._info.content,
                ),
              ),
              if (_info.attachments != null)
                DefaultTransition(
                  child: AttachmentsWidget(
                    attachments: _info.attachments!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
