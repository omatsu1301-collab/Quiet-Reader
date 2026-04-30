import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DocTypeBadge extends StatelessWidget {
  final String type;
  final bool small;

  const DocTypeBadge({super.key, required this.type, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 9,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: DocTypes.badgeColor(type),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: DocTypes.badgeTextColor(type),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
