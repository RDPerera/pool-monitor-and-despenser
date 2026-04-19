import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool useWhiteBackground;
  final Color? backgroundColor;
  const AppLogo({Key? key, this.size = 40, this.useWhiteBackground = true, this.backgroundColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (useWhiteBackground) {
      return SizedBox(
        width: size,
        height: size,
        child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(size * 0.18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.18),
            child: Padding(
              padding: EdgeInsets.zero,
              child: Image.asset(
                'lib/assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.18),
        child: Image.asset(
          'lib/assets/images/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
