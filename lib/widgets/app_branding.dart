import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppBranding extends StatelessWidget {
  final double size;
  final double fontSize;
  final Color? color;
  final bool showText;

  const AppBranding({
    super.key,
    this.size = 30,
    this.fontSize = 20,
    this.color,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.black;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
/*         if (showText) ...[
          Text(
            "Floow",
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: effectiveColor,
              letterSpacing: -0.5,
              fontFamily: 'Roboto', // Ensure branding font is consistent
            ),
          ),
          const SizedBox(width: 8),
        ],
        // The Logo follows the text */
        SvgPicture.asset(
          'assets/images/logo.svg',
          height: size,
          width: size,
          // If your SVG is black/single color and you want to tint it:
          // colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
        ),
      ],
    );
  }
}
