import 'package:flutter/material.dart';
import 'package:sip_ua/sip_ua.dart';
import '../utils/ringtone_helper.dart';
import '../widgets/incoming_call_popup.dart';

class CallHelpers {
  static void handleIncomingCall(
    BuildContext context,
    Call call,
    CallState state,
    RingtoneHelper ringtoneHelper,
    Function(Call) onAccept,
    Function(Call) onReject,
  ) {
    if (call.direction == "INCOMING" && state.state == CallStateEnum.PROGRESS) {
      ringtoneHelper.start();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => IncomingCallPopup(
            number: call.remote_identity ?? call.id.toString(),
            onAccept: () {
              ringtoneHelper.stop();
              Navigator.of(context).pop();
              onAccept(call);
            },
            onReject: () {
              ringtoneHelper.stop();
              Navigator.of(context).pop();
              onReject(call);
            },
          ),
        );
      });
    }
  }

  static void handleOutgoingCall(
    Call call,
    CallState state,
    Function(Call) onOutgoing,
  ) {
    if (call.direction != "INCOMING" && state.state == CallStateEnum.PROGRESS) {
      onOutgoing(call);
    }
  }

  static void handleCallConfirmedOrHold(
    Call call,
    CallState state,
    Function(Call) onConfirmedOrHold,
  ) {
    if (state.state == CallStateEnum.CONFIRMED ||
        state.state == CallStateEnum.HOLD) {
      onConfirmedOrHold(call);
    }
  }

  static void handleCallEndedOrFailed(
    BuildContext context,
    Call call,
    CallState state,
    Function(Call) onEndedOrFailed,
  ) {
    if (state.state == CallStateEnum.FAILED ||
        state.state == CallStateEnum.ENDED ||
        state.state == CallStateEnum.NONE) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      });
      onEndedOrFailed(call);
    }
  }
}
