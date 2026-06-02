import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:smarthome/services/home_service.dart';

enum ResetStep {
  requestUsername,
  verifyCode,
  setNewPassword,
}

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final HomeService _homeService = HomeService();
  
  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Theme Colors
  final Color _bgColor = const Color(0xFF0F1115);
  final Color _gold = const Color(0xFFBFA86D);

  // State variables
  ResetStep _currentStep = ResetStep.requestUsername;
  bool _isLoading = false;
  String _message = ''; 

  @override
  void dispose() {
    _usernameController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- STEP 1: REQUEST USERNAME & SMS CODE ---
  void _requestResetCode() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _message = 'Please enter your username.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final result = await _homeService.requestPasswordReset(username);
      
      if (!mounted) return;

      if (result['success'] == true) {
        HapticFeedback.mediumImpact(); 
        setState(() {
          _message = result['message']!;
          _currentStep = ResetStep.verifyCode; 
        });
      } else {
        setState(() => _message = result['message'] ?? 'User not found.');
      }
    } catch (e) {
      setState(() => _message = 'Network error during reset request.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- STEP 2: VERIFY CODE ---
  void _verifyCode() {
    final code = _codeController.text.trim();
    // In our mock logic, the code is always 123456
    if (code != '123456') { 
      setState(() => _message = 'Invalid code. Please try again.');
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
        _message = 'Code accepted. Create your new password.';
        _currentStep = ResetStep.setNewPassword;
    });
  }
  
  // --- STEP 3: SET NEW PASSWORD ---
  void _setNewPassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final username = _usernameController.text.trim(); 
    final code = _codeController.text.trim();

    if (newPassword.length < 8) {
      setState(() => _message = 'Minimum 8 characters required.');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _message = 'Passwords do not match.');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final result = await _homeService.verifyResetCode(username, code, newPassword);
      
      if (!mounted) return;

      if (result['success'] == true) {
        HapticFeedback.mediumImpact(); // Corrected from successImpact
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']!), 
            backgroundColor: Colors.green.shade800
          ),
        );
        Navigator.pop(context); 
      } else {
        setState(() => _message = result['message'] ?? 'Reset failed.');
      }
    } catch (e) {
      setState(() => _message = 'Error during password change.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildActionButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _gold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            Text(
              _currentStep == ResetStep.requestUsername
                  ? 'Identify\nAccount'
                  : _currentStep == ResetStep.verifyCode
                      ? 'Secure\nVerification'
                      : 'New\nCredentials',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: _gold, height: 1.1),
            ),
            const SizedBox(height: 16),
            if (_message.isNotEmpty) 
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // FIXED: withOpacity replaced with a color mix for better precision
                  color: _message.contains('sent') || _message.contains('accepted') 
                      ? Colors.green.withAlpha(25) 
                      : Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message, 
                  style: TextStyle(
                    color: _message.contains('sent') || _message.contains('accepted') ? Colors.green : Colors.redAccent
                  )
                ),
              ),
            const SizedBox(height: 30),
            _buildStepContent(),
            const SizedBox(height: 30),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel Request', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case ResetStep.requestUsername:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(controller: _usernameController, label: 'Username', icon: Icons.person_outline),
            const SizedBox(height: 30),
            _buildActionButton(label: 'Request SMS Code', onPressed: _requestResetCode),
          ],
        );
      case ResetStep.verifyCode:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(controller: _codeController, label: '6-Digit Code', icon: Icons.sms_outlined, isNumeric: true),
            const SizedBox(height: 30),
            _buildActionButton(label: 'Verify & Continue', onPressed: _verifyCode),
          ],
        );
      case ResetStep.setNewPassword:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(controller: _newPasswordController, label: 'New Password', icon: Icons.lock_outline, isPassword: true),
            const SizedBox(height: 20),
            _buildTextField(controller: _confirmPasswordController, label: 'Confirm Password', icon: Icons.lock_reset, isPassword: true),
            const SizedBox(height: 30),
            _buildActionButton(label: 'Reset Password', onPressed: _setNewPassword),
          ],
        );
    }
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false, bool isNumeric = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: _gold),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withAlpha(30))),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _gold)),
      ),
    );
  }
}