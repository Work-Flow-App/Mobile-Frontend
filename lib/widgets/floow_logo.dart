import 'package:flutter/material.dart';
// 1. Import the SVG package
import 'package:flutter_svg/flutter_svg.dart';

class FloowLogo extends StatelessWidget {
  final Color textColor;
  final double iconSize;
  final double fontSize;
  final bool isAppBar;

  const FloowLogo({
    super.key,
    // 2. Change default text color from white to black
    this.textColor = Colors.black,
    this.iconSize = 24,
    this.fontSize = 18,
    this.isAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment:
          CrossAxisAlignment.center, // Ensure vertical centering
      children: [
        // 3. Use SvgPicture.asset instead of Image.asset
        SvgPicture.asset(
          'assets/images/logo.svg', // Ensure this path matches your assets folder
          height: iconSize,
          width: iconSize,
        ),
        const SizedBox(width: 10),
        Text(
          'Floow',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
            color: textColor, // Uses the new default black
            letterSpacing: 1.0,
          ),
        ),
      ],
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
