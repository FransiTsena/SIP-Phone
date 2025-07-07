import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onHistory;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.onHistory,
    required this.onSettings,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            colors: [
              Colors.blueAccent.withOpacity(0.8),
              Colors.purpleAccent.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds);
        },
        child: Text(title),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'Call History',
          onPressed: onHistory,
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Profile/Settings',
          onPressed: onSettings,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: onLogout,
        ),
      ],
      systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
          ? null
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
