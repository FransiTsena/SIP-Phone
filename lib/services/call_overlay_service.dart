import 'package:flutter/material.dart';
import 'package:fe/screens/incoming_call_popup.dart';
import 'package:fe/screens/call_popup.dart';
import 'package:fe/widgets/mini_call_chip.dart';
import 'package:fe/widgets/call_top_bar.dart';
import 'package:fe/utils/call_ui_prefs.dart';

/// A singleton service that can show/hide call popups using the root navigator overlay,
/// so they appear regardless of the current route/screen.
class CallOverlayService {
  CallOverlayService._();
  static final CallOverlayService instance = CallOverlayService._();

  /// Attach this to MaterialApp.navigatorKey
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  OverlayEntry? _entry;
  OverlayEntry? _miniEntry;

  bool get isShowing => _entry != null;

  void _insert(Widget child, {bool withBarrier = true}) {
    final context = navigatorKey.currentContext;
    final overlay = navigatorKey.currentState?.overlay;
    if (context == null || overlay == null) return;

    _entry?.remove();
    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          if (withBarrier)
            const ModalBarrier(dismissible: false, color: Colors.black26),
          Positioned.fill(child: child),
        ],
      ),
    );
    overlay.insert(_entry!);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }

  void hideMini() {
    _miniEntry?.remove();
    _miniEntry = null;
  }

  /// Show the incoming call popup at the top center.
  void showIncomingCall({
    required String number,
    required VoidCallback onAccept,
    required VoidCallback onReject,
    VoidCallback? onSilence,
  }) {
    _insert(
      SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Dismissible(
            key: const ValueKey('incoming_call_popup'),
            direction: DismissDirection.vertical,
            onDismissed: (_) {
              // Swiping the popup should mute the ringtone
              if (onSilence != null) onSilence();
              hide();
            },
            child: IncomingCallPopup(
              number: number,
              onAccept: () {
                hide();
                onAccept();
              },
              onReject: () {
                hide();
                onReject();
              },
              onSilence: onSilence,
            ),
          ),
        ),
      ),
      withBarrier: true,
    );
  }

  /// Show the full-screen active call UI.
  void showActiveCall({
    required String number,
    required String status,
    required bool isIncoming,
    required VoidCallback onHangUp,
    required VoidCallback onToggleMute,
    required VoidCallback onToggleSpeaker,
    required VoidCallback onToggleHold,
    required VoidCallback onTransferCall,
    DateTime? Function()? callStartTimeProvider,
  }) {
    _insert(
      CallPopup(
        number: number,
        status: status,
        isIncoming: isIncoming,
        onHangUp: () {
          hide();
          onHangUp();
        },
        onToggleMute: onToggleMute,
        onToggleSpeaker: onToggleSpeaker,
        onToggleHold: onToggleHold,
        onTransferCall: onTransferCall,
        callStartTimeProvider: callStartTimeProvider,
        // Prevent the widget from trying to pop a route; overlay will be closed by this service.
        closeSelfOnHangUp: false,
        onMinimize: () {
          // Replace the full-screen UI with a mini chip
          final args = (
            number: number,
            callStartTimeProvider: callStartTimeProvider,
            onHangUp: onHangUp,
          );
          hide();
          showMiniCall(
            number: args.number,
            callStartTimeProvider: args.callStartTimeProvider,
            onExpand: () {
              hideMini();
              showActiveCall(
                number: number,
                status: status,
                isIncoming: isIncoming,
                onHangUp: onHangUp,
                onToggleMute: onToggleMute,
                onToggleSpeaker: onToggleSpeaker,
                onToggleHold: onToggleHold,
                onTransferCall: onTransferCall,
                callStartTimeProvider: callStartTimeProvider,
              );
            },
            onHangUp: onHangUp,
          );
        },
      ),
      withBarrier: false,
    );
  }

  /// Show a draggable mini call chip while the call is active but minimized.
  Future<void> showMiniCall({
    required String number,
    required DateTime? Function()? callStartTimeProvider,
    required VoidCallback onExpand,
    required VoidCallback onHangUp,
  }) async {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _miniEntry?.remove();
    final useChip = await CallUiPrefs.getUseChipCompactUi();
    _miniEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          if (useChip)
            SafeArea(
              child: MiniCallChip(
                number: number,
                callStartTimeProvider: callStartTimeProvider,
                onExpand: onExpand,
                onHangUp: () {
                  hideMini();
                  onHangUp();
                },
              ),
            )
          else
            CallTopBar(
              number: number,
              callStartTimeProvider: callStartTimeProvider,
              onExpand: onExpand,
              onHangUp: () {
                hideMini();
                onHangUp();
              },
            ),
        ],
      ),
    );
    overlay.insert(_miniEntry!);
  }
}
