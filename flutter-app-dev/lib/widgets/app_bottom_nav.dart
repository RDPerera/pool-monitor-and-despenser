import 'dart:ui';
import 'package:flutter/material.dart';
import '../main.dart' show kBlue, kSeparator;

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({Key? key, this.currentIndex = 0}) : super(key: key);

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0: Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false); break;
      case 1: Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false, arguments: 1); break;
      case 2: Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false, arguments: 2); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          height: 56 + bottom,
          padding: EdgeInsets.only(bottom: bottom),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.78),
            border: const Border(top: BorderSide(color: kSeparator, width: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _item(context, 0, Icons.bar_chart_rounded,  Icons.bar_chart_rounded,  'Monitor'),
              _item(context, 1, Icons.science_rounded,   Icons.science_outlined,   'Dispense'),
              _item(context, 2, Icons.settings_rounded,  Icons.settings_outlined,  'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int idx,
      IconData activeIcon, IconData inactiveIcon, String label) {
    final active = idx == currentIndex;
    final color  = active ? kBlue : const Color(0xFF8E8E93);
    return GestureDetector(
      onTap: () => _onTap(context, idx),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(active ? activeIcon : inactiveIcon, size: 24, color: color),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: color,
          )),
        ]),
      ),
    );
  }
}
