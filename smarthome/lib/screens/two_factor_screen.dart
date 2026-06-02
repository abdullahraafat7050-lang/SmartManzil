import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TwoFactorScreen extends StatefulWidget {
  final String username;
  const TwoFactorScreen({super.key, required this.username});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  static const String API_URL = 'https://api.example.com'; // <- replace with your server
  final _storage = const FlutterSecureStorage();
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;
  String _message = '';
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  int _verifyAttempts = 0;

  @override
  void initState() {
    super.initState();
    _startCooldownIfNeeded(); // if you want to start an initial cooldown
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  void _startCooldownIfNeeded() {
    // Optionally start a cooldown on screen open
    // _startCooldown(30);
  }

  Future<void> _requestCode() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final res = await http.post(
        Uri.parse('$API_URL/auth/2fa/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': widget.username}),
      );

      final Map<String, dynamic> body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() => _message = body['message'] ?? 'Code sent.');
        _startCooldown(30); // 30s cooldown before another resend
      } else {
        setState(() => _message = body['message'] ?? 'Failed to send code.');
      }
    } catch (e) {
      setState(() => _message = 'Network error while requesting code.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode(String code) async {
    if (code.length != 6) {
      setState(() => _message = 'Enter the 6-digit code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final res = await http.post(
        Uri.parse('$API_URL/auth/2fa/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': widget.username, 'code': code}),
      );

      final Map<String, dynamic> body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true && body['token'] != null) {
        final token = body['token'] as String;
        // Persist token securely
        await _storage.write(key: 'session_token', value: token);
        // Navigate to home (clear stack)
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home', arguments: widget.username);
      } else {
        _verifyAttempts++;
        // Basic exponential backoff suggestion (client-side delay)
        final delay = (1 << (_verifyAttempts.clamp(0, 5))) * 100; // ms
        await Future.delayed(Duration(milliseconds: delay));
        setState(() => _message = body['message'] ?? 'Invalid code.');
      }
    } catch (e) {
      setState(() => _message = 'Network error while verifying code.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Two-Factor Verification')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'A 6-digit verification code was sent to the contact on file for ${widget.username}.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 18),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _codeController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(6),
                  fieldHeight: 48,
                  fieldWidth: 40,
                  activeFillColor: Colors.white,
                ),
                onChanged: (_) {},
                onCompleted: (value) => _verifyCode(value),
              ),
              const SizedBox(height: 12),
              if (_message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_message, style: const TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _verifyCode(_codeController.text.trim()),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Verify'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: (_resendCooldown > 0 || _isLoading) ? null : _requestCode,
                child: _resendCooldown > 0
                    ? Text('Resend code ($_resendCooldown s)')
                    : const Text('Resend code'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}