import 'package:flutter/material.dart';
import 'package:crm_train/utills/app_colors.dart';

class HierarchyBreadcrumb extends StatelessWidget {
  final String? stationName;
  final String? platformName;
  final String? areaName;
  final VoidCallback? onStationTap;
  final VoidCallback? onPlatformTap;
  final VoidCallback? onAreaTap;

  const HierarchyBreadcrumb({
    super.key,
    this.stationName,
    this.platformName,
    this.areaName,
    this.onStationTap,
    this.onPlatformTap,
    this.onAreaTap,
  });

  @override
  Widget build(BuildContext context) {
    final crumbs = <Widget>[];
    if (stationName != null) {
      crumbs.add(_crumb(stationName!, onStationTap));
    }
    if (platformName != null) {
      if (crumbs.isNotEmpty) crumbs.add(_separator());
      crumbs.add(_crumb(platformName!, onPlatformTap));
    }
    if (areaName != null) {
      if (crumbs.isNotEmpty) crumbs.add(_separator());
      crumbs.add(_crumb(areaName!, onAreaTap, isLast: true));
    }
    if (crumbs.isEmpty) {
      crumbs.add(Text('No location selected', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(children: crumbs),
    );
  }

  Widget _crumb(String label, VoidCallback? onTap, {bool isLast = false}) {
    return GestureDetector(
      onTap: isLast ? null : onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
          color: isLast ? kRailwayBlue : Colors.grey.shade700,
          decoration: isLast ? TextDecoration.none : TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _separator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
    );
  }
}
