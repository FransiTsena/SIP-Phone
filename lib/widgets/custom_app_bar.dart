import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onHistory;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.onHistory,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(title),
      actions: [
        PopupMenuButton<int>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 0:
                onHistory();
                break;
              case 1:
                onLogout();

                break;
              case 2:
                onSettings();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 0,
              child: ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Call History'),
              ),
            ),

            PopupMenuItem(
              value: 1,
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
              ),
            ),
            PopupMenuItem(
              value: 2,
              child: ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
              ),
            ),
          ],
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
