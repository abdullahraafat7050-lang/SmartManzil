import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  const LockScreen({super.key, required this.onUnlock});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String error = "";

  // NOTE: For production do NOT hardcode a PIN. This is only for demo/mock.
  final String requiredPin = "123";

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _checkPin() {
    // Hide keyboard
    _focusNode.unfocus();

    if (_pinController.text == requiredPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unlocked')),
      );
      widget.onUnlock();
    } else {
      setState(() => error = "Wrong PIN!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wrong PIN'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text("Enter PIN to unlock:", style: TextStyle(fontSize: 20)),
          Padding(
            padding: const EdgeInsets.all(40),
            child: TextField(
              controller: _pinController,
              focusNode: _focusNode,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                counterText: '',
                hintText: '4-digit PIN',
              ),
              onChanged: (_) {
                if (error.isNotEmpty) {
                  setState(() => error = "");
                }
              },
              onSubmitted: (_) => _checkPin(),
            ),
          ),
          if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red)),
          ElevatedButton(
            onPressed: _checkPin,
            child: const Text("Unlock"),
          )
        ]),
      ),
    );
  }
}