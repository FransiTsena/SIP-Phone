import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fe/api/config.dart';
import 'login.dart';
import 'package:fe/utils/call_ui_prefs.dart';

class ProfileSettingsPage extends StatefulWidget {
  final String initialUsername;
  final String initialAccessToken;
  // If false, page will not pop itself when saving (for embedded / tab usage)
  final bool autoPopOnSave;
  final VoidCallback? onSaved; // Optional callback after successful save
  final VoidCallback? onLogout; // Optional logout handler from parent
  const ProfileSettingsPage({
    super.key,
    required this.initialUsername,
    required this.initialAccessToken,
    this.autoPopOnSave = true,
    this.onSaved,
    this.onLogout,
  });

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  late TextEditingController _ipController;
  bool _loading = true;
  String? _message;
  bool _loggingOut = false;
  bool _autoMinimize = false;
  bool _useChip = true;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: AppConfig.ip);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('server_ip') ?? AppConfig.ip;
      _loading = false;
    });
    _autoMinimize = await CallUiPrefs.getAutoMinimizeOnConnect();
    _useChip = await CallUiPrefs.getUseChipCompactUi();
    if (mounted) setState(() {});
  }

  Future<void> _saveProfile() async {
    final newIp = _ipController.text.trim();
    if (newIp.isNotEmpty) {
      await AppConfig.setIp(newIp);
    }
    setState(() => _message = 'Profile updated!');
    // Callback for parent (e.g., to trigger re-registration)
    widget.onSaved?.call();
    // Return true to indicate profile was updated if auto pop is enabled
    if (widget.autoPopOnSave && Navigator.canPop(context)) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _confirmAndLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'You will be logged out and must sign in again to change username or password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (shouldLogout != true) return;
    setState(() => _loggingOut = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('username');
      await prefs.remove('access_token');
      // Prefer parent handler (can stop SIP, hang up, etc.)
      if (widget.onLogout != null) {
        widget.onLogout!.call();
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.settings,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 24),
                          // Call UI preferences
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Call UI',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: const Text('Auto-minimize call on connect'),
                            subtitle: const Text(
                              'Collapse to a compact UI when the call connects',
                            ),
                            value: _autoMinimize,
                            onChanged: (v) async {
                              setState(() => _autoMinimize = v);
                              await CallUiPrefs.setAutoMinimizeOnConnect(v);
                            },
                          ),
                          SwitchListTile(
                            title: const Text(
                              'Use floating chip for compact UI',
                            ),
                            subtitle: const Text('Off uses a top bar instead'),
                            value: _useChip,
                            onChanged: (v) async {
                              setState(() => _useChip = v);
                              await CallUiPrefs.setUseChipCompactUi(v);
                            },
                          ),
                          const SizedBox(height: 12),
                          // Removed username editing; must re-login to change.
                          TextField(
                            controller: _ipController,
                            keyboardType: TextInputType.url,
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.5),
                              labelText: 'Server IP / Host',
                              hintText: 'e.g. 10.0.0.5 or sip.example.com',
                              labelStyle: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w400,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 1.2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.7),
                                  width: 1.2,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.dns,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF4f8cff,
                                ).withOpacity(0.85),
                                shadowColor: Colors.blueAccent.withOpacity(
                                  0.18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                elevation: 8,
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _loggingOut ? null : _confirmAndLogout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.logout),
                              label: Text(
                                _loggingOut ? 'Logging out...' : 'Logout',
                              ),
                            ),
                          ),
                          if (_message != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _message!,
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
