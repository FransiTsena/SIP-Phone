import 'package:flutter/material.dart';

typedef KeypadInputCallback = void Function(String value);

typedef KeypadDeleteCallback = void Function();

typedef KeypadCallCallback = void Function();

class PhoneKeypad extends StatelessWidget {
  final KeypadInputCallback onInput;
  final KeypadDeleteCallback onDelete;
  final KeypadCallCallback onCall;
  final bool callEnabled;

  static const double _buttonSize = 100.0;
  static const TextStyle _digitStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: Colors.indigo,
    letterSpacing: 1.5,
  );

  const PhoneKeypad({
    super.key,
    required this.onInput,
    required this.onDelete,
    required this.onCall,
    this.callEnabled = true,
  });

  Widget _buildKey({required Widget child, VoidCallback? onTap}) => SizedBox(
    height: _buttonSize,
    width: _buttonSize,
    child: Padding(
      padding: const EdgeInsets.all(6.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black12,
        ),
        onPressed: onTap,
        child: child,
      ),
    ),
  );

  List<Widget> _buildKeys() {
    return [
      // Digits 1-9
      for (var i = 1; i <= 9; i++)
        Center(
          child: _buildKey(
            onTap: () => onInput('$i'),
            child: SizedBox(
              child: Center(child: Text('$i', style: _digitStyle)),
            ),
          ),
        ),

      // Backspace key
      Center(
        child: _buildKey(
          onTap: onDelete,
          child: SizedBox(
            child: const Center(
              child: Icon(Icons.backspace, size: 32, color: Colors.red),
            ),
          ),
        ),
      ),

      Center(
        child: _buildKey(
          onTap: () => onInput('0'),
          child: SizedBox(
            child: Center(child: Text('0', style: _digitStyle)),
          ),
        ),
      ),

      // Call key
      Center(
        child: _buildKey(
          onTap: callEnabled ? onCall : null,
          child: SizedBox(
            child: Center(
              child: Icon(
                callEnabled ? Icons.call : Icons.call_end,
                size: 32,
                color: callEnabled ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 1,
      physics: const NeverScrollableScrollPhysics(),
      children: _buildKeys(),
    );
  }
}
