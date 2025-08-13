import 'dart:ui' as ui;

import 'package:fe/api/agents.dart';
import 'package:flutter/material.dart';

class IncomingCallPopup extends StatelessWidget {
  final String number;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback? onSilence;
  const IncomingCallPopup({
    super.key,
    required this.number,
    required this.onAccept,
    required this.onReject,
    this.onSilence,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final agentFuture = Agents.getByNumber(
      number,
    ).catchError((_) => <String, dynamic>{});

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, scale, _) {
        return Transform.scale(
          scale: scale,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 24,
            ),
            alignment: Alignment.topCenter,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final compact = width < 420;
                final nameFs = compact ? 18.0 : 20.0;
                final gap = compact ? 12.0 : 16.0;

                final actions = Row(
                  mainAxisAlignment: compact
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onSilence != null) ...[
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.surfaceVariant,
                          foregroundColor: cs.onSurfaceVariant,
                          padding: EdgeInsets.all(compact ? 12 : 14),
                          shape: const CircleBorder(),
                          elevation: 0,
                        ),
                        onPressed: onSilence,
                        child: Icon(
                          Icons.notifications_off,
                          size: compact ? 22 : 24,
                        ),
                      ),
                      SizedBox(width: compact ? 10 : 14),
                    ],
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.all(compact ? 14 : 16),
                        shape: const CircleBorder(),
                        elevation: 3,
                      ),
                      onPressed: onAccept,
                      child: Icon(Icons.call, size: compact ? 28 : 30),
                    ),
                    SizedBox(width: compact ? 14 : 20),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.all(compact ? 14 : 16),
                        shape: const CircleBorder(),
                        elevation: 3,
                      ),
                      onPressed: onReject,
                      child: Icon(Icons.call_end, size: compact ? 28 : 30),
                    ),
                  ],
                );

                Widget info(Map<String, dynamic>? agent) {
                  final firstName = (agent?['first_name'] as String?)?.trim();
                  final lastName = (agent?['last_name'] as String?)?.trim();
                  var displayName = [
                    firstName,
                    lastName,
                  ].where((e) => (e?.isNotEmpty ?? false)).join(' ').trim();
                  if (displayName.isEmpty) displayName = 'Unknown Caller';

                  String initials = '';
                  if ((firstName?.isNotEmpty ?? false))
                    initials += firstName![0];
                  if ((lastName?.isNotEmpty ?? false)) initials += lastName![0];
                  if (initials.isEmpty) initials = '?';
                  initials = initials.toUpperCase();

                  final avatar = Container(
                    width: compact ? 56 : 64,
                    height: compact ? 56 : 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          cs.primaryContainer.withOpacity(0.9),
                          cs.secondaryContainer.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: compact ? 22 : 26,
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      avatar,
                      SizedBox(width: gap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: cs.primary.withOpacity(0.22),
                                    ),
                                  ),
                                  child: Text(
                                    'Incoming call',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: nameFs,
                                color: cs.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              number,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cs.surface.withOpacity(0.92),
                            cs.surfaceVariant.withOpacity(0.86),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: cs.outlineVariant.withOpacity(0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: compact ? 180 : 170,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: FutureBuilder(
                            future: agentFuture,
                            builder: (context, snapshot) {
                              final data =
                                  (snapshot.hasData && snapshot.data is Map)
                                  ? snapshot.data as Map<String, dynamic>
                                  : null;

                              final content = compact
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        info(data),
                                        SizedBox(height: gap),
                                        actions,
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(child: info(data)),
                                        const SizedBox(width: 12),
                                        actions,
                                      ],
                                    );

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return content; // shows skeleton-less initial UI
                              }
                              return content;
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
