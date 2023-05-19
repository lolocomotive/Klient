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

import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:klient/config_provider.dart';
import 'package:klient/screens/school_info.dart';
import 'package:klient/util.dart';
import 'package:scolengo_api/scolengo_api.dart';

class SchoolInfoCard extends StatelessWidget {
  final SchoolInfo _info;
  const SchoolInfoCard(this._info, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: OpenContainer(
          closedColor: ElevationOverlay.applySurfaceTint(
              Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.primary, 1),
          openColor: ElevationOverlay.applySurfaceTint(
              Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.primary, 1),
          backgroundColor: Colors.black12,
          closedElevation: 2,
          openElevation: 0,
          openBuilder: (context, action) => SchoolInfoPage(_info),
          closedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          closedBuilder: (context, action) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _info.author == null
                              ? const Text('Auteur inconnu')
                              : Text(
                                  _info.author!.fullName,
                                  style: const TextStyle(fontSize: 16),
                                ),
                          Text(_info.publicationDateTime.format()),
                        ],
                      ),
                      Text(
                        _info.title,
                      ),
                      if (_info.content.innerText != '')
                        Text(
                          _info.content.innerText,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                    ],
                  ),
                ),
                if (_info.illustration != null)
                  Hero(
                    tag: _info.id,
                    child: InteractiveViewer(
                      child: Image(
                          fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width,
                          image: CachedNetworkImageProvider(
                            _info.illustration!.url,
                            headers: ConfigProvider.client!.headers,
                          )),
                    ),
                  ),
              ],
            );
          }),
    );
  }
}
