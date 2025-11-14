import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GlassAppBar extends StatelessWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final double blurSigma;
  final double opacity;
  final double borderOpacity;
  final Color tintColor;
  final Color? foregroundColor;
  final SystemUiOverlayStyle? systemUiOverlayStyle;

  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.blurSigma = 16,
    this.opacity = 0.16,
    this.borderOpacity = 0.22,
    this.tintColor = Colors.white,
    this.foregroundColor,
    this.systemUiOverlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? Theme.of(context).colorScheme.onSurface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiOverlayStyle ??
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
          ),
      child: Container(
        // Прозрачный контейнер, в котором делаем blur и полупрозрачную заливку
        decoration: BoxDecoration(
          color: tintColor.withOpacity(opacity),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(borderOpacity),
              width: 0.6,
            ),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    if (leading != null)
                      IconTheme(
                        data: IconThemeData(color: fg),
                        child: leading!,
                      )
                    else
                      const SizedBox.shrink(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DefaultTextStyle(
                        style: TextStyle(
                          color: fg,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        child: title ?? const SizedBox.shrink(),
                      ),
                    ),
                    if (actions != null)
                      IconTheme(
                        data: IconThemeData(color: fg),
                        child: Row(children: actions!),
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}