import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static int _indexFromLocation(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/patterns')) return 1;
    if (location.startsWith('/risk-map')) return 2;
    if (location.startsWith('/coach')) return 3;
    if (location.startsWith('/progress')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.navyLight.withValues(alpha: 0.5), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            switch (index) {
              case 0: context.go('/home');
              case 1: context.go('/patterns');
              case 2: context.go('/risk-map');
              case 3: context.go('/coach');
              case 4: context.go('/progress');
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Patterns'),
            BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Risk Map'),
            BottomNavigationBarItem(icon: Icon(Icons.smart_toy_rounded), label: 'Coach'),
            BottomNavigationBarItem(icon: Icon(Icons.trending_up_rounded), label: 'Progress'),
          ],
        ),
      ),
    );
  }
}
