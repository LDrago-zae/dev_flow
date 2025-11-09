import 'package:flutter/material.dart';
import 'package:dev_flow/presentation/widgets/app_bottom_nav_bar.dart';

class AppShellScaffold extends StatelessWidget {
  final Widget child;
  final int selectedIndex;

  const AppShellScaffold({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: child,
      bottomNavigationBar: AppBottomNavBar(selectedIndex: selectedIndex),
    );
  }
}
