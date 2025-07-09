import 'package:flutter/material.dart';

class PhoneKeypad extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String) onKeyAdd;
  final void Function(String) onKeyDelete;

  const PhoneKeypad({
    super.key,
    required this.controller,
    required this.onKeyAdd,
    required this.onKeyDelete,
  });

  @override
  State<PhoneKeypad> createState() => _PhoneKeypadState();
}

class _PhoneKeypadState extends State<PhoneKeypad> {
  static const double _buttonSize = 100.0;
  static const TextStyle _digitStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: Colors.indigo,
    letterSpacing: 1.5,
  );

  void _handleInput(String val) {
    widget.onKeyAdd(val);
  }

  void _handleDelete() {
    widget.onKeyDelete(widget.controller.text);
  }

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
      for (var i = 1; i <= 9; i++)
        Center(
          child: _buildKey(
            onTap: () => _handleInput('$i'),
            child: SizedBox(
              child: Center(child: Text('$i', style: _digitStyle)),
            ),
          ),
        ),
      Center(
        child: _buildKey(
          onTap: _handleDelete,
          child: const Center(
            child: Icon(Icons.backspace, size: 32, color: Colors.red),
          ),
        ),
      ),
      Center(
        child: _buildKey(
          onTap: () => _handleInput('0'),
          child: SizedBox(
            child: Center(child: Text('0', style: _digitStyle)),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 1,
      // physics: const NeverScrollableScrollPhysics(),
      children: _buildKeys(),
    );
  }
}
