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

class DefaultTransition extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final bool animate;
  const DefaultTransition({
    Key? key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 200),
    this.animate = true,
  }) : super(key: key);

  @override
  State<DefaultTransition> createState() => _DefaultTransitionState();
}

class _DefaultTransitionState extends State<DefaultTransition> with TickerProviderStateMixin {
  late CurvedAnimation _scaleAnimation;
  late CurvedAnimation _fadeAnimation;
  late AnimationController _controller;
  bool disposed = false;
  bool ran = false;

  @override
  void dispose() {
    disposed = true;
    _controller.dispose();
    _scaleAnimation.dispose();
    _fadeAnimation.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: Duration.zero,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!ran) {
      _controller.reset();
      if (widget.delay == Duration.zero) {
        _controller.forward(from: 0.0);
      } else {
        Future.delayed(widget.delay).then((value) {
          if (!disposed) {
            _controller.forward(from: 0.0);
          }
        });
      }
      ran = true;
    }
    if (widget.duration == Duration.zero) {
      return widget.child;
    }
    return widget.animate
        ? ScaleTransition(
            scale: Tween(begin: 1.0, end: 1.0).animate(_scaleAnimation),
            child: FadeTransition(
              opacity: Tween(begin: 0.0, end: 1.0).animate(_fadeAnimation),
              child: widget.child,
            ),
          )
        : widget.child;
  }
}
