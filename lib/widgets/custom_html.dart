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
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomHtml extends StatefulWidget {
  final String data;
  final Map<String, Style> style;

  const CustomHtml({
    Key? key,
    required this.data,
    this.style = const {},
  }) : super(key: key);

  @override
  State<CustomHtml> createState() => _CustomHtmlState();
}

class _CustomHtmlState extends State<CustomHtml> {
  Widget? _cache;
  String? _oldData;

  @override
  Widget build(BuildContext context) {
    final Map<String, Style> defaultStyle = {
      'a': Style(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      )
    };
    //HACK: This keeps the HTML from being reparsed each frame during animations.
    _cache = _oldData != widget.data || _cache == null
        ? Html(
            // Empty paragraphs take up too much space.
            data: widget.data
                .replaceAll(RegExp(r'<p[^>]*>\s*<\/p>', caseSensitive: false, multiLine: true), ''),
            style: defaultStyle..addAll(widget.style),
            onLinkTap: (url, context, element) {
              launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication);
            },
            extensions: [CachedImageRenderer()],
          )
        : _cache;
    return _cache!;
  }
}

class CachedImageRenderer extends HtmlExtension {
  @override
  Set<String> get supportedTags => {'img'};

  @override
  bool matches(context) =>
      context.attributes.containsKey('src') && !context.attributes['src']!.startsWith('data:');

  @override
  InlineSpan build(ExtensionContext context) {
    return WidgetSpan(
      child: InteractiveViewer(
        child: CachedNetworkImage(
          imageUrl: context.attributes['src']!,
          progressIndicatorBuilder: (context, url, progress) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator(value: progress.progress)),
          ),
        ),
      ),
    );
  }
}
