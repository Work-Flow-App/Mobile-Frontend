import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandLogo extends StatelessWidget {
  final double iconSize;
  final double textSvgWidth;
  final bool isAppBar;
  final Axis axis;

  const BrandLogo({
    super.key,
    this.iconSize = 24,
    this.textSvgWidth = 80, // Default width for the WorkFloow_text.svg
    this.isAppBar = true,
    this.axis = Axis.horizontal, // Use Axis.vertical to stack them
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      SvgPicture.asset(
        'assets/images/logo_green.svg',
        height: iconSize,
        width: iconSize,
      ),
      // Add spacing based on the layout axis
      SizedBox(
        width: axis == Axis.horizontal ? 10 : 0,
        height: axis == Axis.vertical ? 12 : 0,
      ),
      SvgPicture.asset('assets/images/WorkFloow_text_white.svg', width: textSvgWidth),
    ];

    // Arrange children based on the provided Axis
    final content = axis == Axis.vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          );

    if (isAppBar) {
      return Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: content,
      );
    }

    return content;
  }
}
