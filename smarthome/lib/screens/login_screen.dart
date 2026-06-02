// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:smarthome/services/home_service.dart';
import 'package:smarthome/screens/two_factor_screen.dart';
// 💡 Import the new screen (will be created next)
import 'password_reset_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final HomeService _homeService = HomeService(); 

  bool _isLoading = false;
  String _errorMessage = '';
  bool _isPasswordVisible = false; 

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    // ... (rest of the _handleLogin logic remains the same)
    final String username = _usernameController.text;
    final String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both username and password.';
      });
      return;
    }

    setState(() {
      _isLoading = true; 
      _errorMessage = ''; 
    });

    try {
      final Map<String, dynamic> result = await _homeService.login(username, password);

      if (result['success'] == true) {
        if (result['requires2FA'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TwoFactorScreen(username: username),
            ),
          );
             setState(() {
                _errorMessage = result['message']; 
                _isLoading = false;
            });
        } else {
            Navigator.pushReplacementNamed(
              context,
              '/home',
              arguments: username,
            );
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Login failed. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Check your connection.';
        _isLoading = false;
      });
      print('Login error: $e'); 
    }
  }

  // 💡 NEW: Handler for navigating to the reset screen
  void _goToPasswordReset() {
      Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => const PasswordResetScreen()),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home Login'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(
                Icons.security,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 30),
              
              // Username Field (same as before)
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field (same as before)
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible, 
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Error Message Display (same as before)
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Login Button (same as before)
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin, 
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text('Login'),
              ),
              
              // 💡 NEW: Forgot Password Button
              TextButton(
                  onPressed: _goToPasswordReset, 
                  child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.blueGrey),
                  ),
              )
            ],
          ),
        ),
      ),
    );
  }
}