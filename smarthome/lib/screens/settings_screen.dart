import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smarthome/services/home_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HomeService _homeService = HomeService(); 

  // --- CONTROLLERS ---
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  // --- STATE VARIABLES ---
  bool _isPasswordChanging = false;
  String? _passwordErrorText;
  String _mockPhoneNumber = 'Loading...'; 
  String? _phoneNumberErrorText;

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmNewPasswordVisible = false;

  // --- LUMINA NOIR THEME COLORS ---
  final Color _bgColor = const Color(0xFF0F1115);
  final Color _gold = const Color(0xFFBFA86D);
  final Color _cardColor = const Color(0xFF131418);
  final Color _muted = Colors.grey;

  @override
  void initState() {
    super.initState();
    _loadUserData(); 
  }
  
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _loadUserData() async {
    final userData = await _homeService.getMockUserData();
    if (mounted) {
      setState(() {
        _mockPhoneNumber = userData['phone'] ?? 'N/A';
      });
    }
  }

  // FIXED: Async gap guarded with 'mounted' check
  void _changePassword() async {
    final newPassword = _newPasswordController.text;

    if (newPassword.length < 8) {
      setState(() => _passwordErrorText = "Minimum 8 characters required.");
      return;
    }
    
    setState(() {
      _passwordErrorText = null;
      _isPasswordChanging = true;
    });

    try {
      final response = await _homeService.changePassword(
        _currentPasswordController.text, 
        newPassword,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        // FIXED: Using standard vibration pattern
        HapticFeedback.mediumImpact(); 
        _showSnackBar(response['message']!);
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        setState(() => _passwordErrorText = response['message']);
      }
    } catch (e) {
      _showSnackBar("Connection error.", isError: true);
    } finally {
      if (mounted) setState(() => _isPasswordChanging = false);
    }
  }

  void _changePhoneNumber() async {
    final rawNumber = _phoneNumberController.text.trim();
    final newNumber = rawNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (newNumber.length != 11) {
      setState(() => _phoneNumberErrorText = "Enter a number.");
      return;
    }

    try {
      final formattedNumber = "${newNumber.substring(0, 4)} ${newNumber.substring(4, 7)} ${newNumber.substring(7, 9)} ${newNumber.substring(9)}";
      final response = await _homeService.updateMockPhoneNumber(formattedNumber);

      if (!mounted) return;

      if (response['success'] == true) {
        HapticFeedback.mediumImpact();
        setState(() => _mockPhoneNumber = formattedNumber);
        _showSnackBar("Number stored securely.");
        Navigator.of(context).pop(); 
      }
    } catch (e) {
      _showSnackBar("Error saving number.", isError: true);
    }
  }

  // ==========================================================
  // UI COMPONENTS
  // ==========================================================

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 24),
      child: Text(
        title,
        style: TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userName = ModalRoute.of(context)?.settings.arguments as String? ?? 'Guest';

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Security & Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildSectionHeader('IDENTITY'),
          Card(
            color: _cardColor,
            // FIXED: Removed 'border' parameter, used 'side'
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15), 
              side: const BorderSide(color: Colors.white10),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person_outline, color: _gold),
                  title: const Text('Username', style: TextStyle(color: Colors.white)),
                  subtitle: Text(userName, style: TextStyle(color: _muted)),
                  trailing: Icon(Icons.lock_outline, color: _muted, size: 16),
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: Icon(Icons.phone_outlined, color: _gold),
                  title: const Text('Registered SMS Number', style: TextStyle(color: Colors.white)),
                  subtitle: Text(_mockPhoneNumber, style: TextStyle(color: _muted)),
                  trailing: Icon(Icons.edit_note, color: _gold),
                  onTap: _showChangePhoneNumberDialog,
                ),
              ],
            ),
          ),

          _buildSectionHeader('SECURITY ACCESS'),
          Card(
            color: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15), 
              side: const BorderSide(color: Colors.white10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Update Access Key', style: TextStyle(color: _gold, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildClassyField(_currentPasswordController, 'Current Password', _isCurrentPasswordVisible, (v) => setState(() => _isCurrentPasswordVisible = v)),
                  _buildClassyField(_newPasswordController, 'New Password', _isNewPasswordVisible, (v) => setState(() => _isNewPasswordVisible = v), error: _passwordErrorText),
                  _buildClassyField(_confirmNewPasswordController, 'Confirm New', _isConfirmNewPasswordVisible, (v) => setState(() => _isConfirmNewPasswordVisible = v)),
                  
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPasswordChanging ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isPasswordChanging 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Text('Confirm Change'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildSectionHeader('SYSTEM'),
          Card(
            color: _cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_none, color: Colors.white70),
                  title: const Text('Alert Preferences', style: TextStyle(color: Colors.white)),
                  onTap: () {},
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.white70),
                  title: const Text('About Lumina v1.0', style: TextStyle(color: Colors.white)),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildClassyField(TextEditingController controller, String label, bool visible, Function(bool) toggle, {String? error}) {
    return Padding(
      // FIXED: Constant constructor 'bottom' corrected
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: !visible,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _muted, fontSize: 14),
          errorText: error,
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _gold)),
          suffixIcon: IconButton(
            icon: Icon(visible ? Icons.visibility_off : Icons.visibility, color: _muted, size: 18),
            onPressed: () => toggle(!visible),
          ),
        ),
      ),
    );
  }

  void _showChangePhoneNumberDialog() {
    _phoneNumberController.text = _mockPhoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text('Update SMS Target', style: TextStyle(color: _gold)),
        content: TextField(
          controller: _phoneNumberController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '05XXXXXXXXX',
            hintStyle: TextStyle(color: _muted),
            errorText: _phoneNumberErrorText,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black),
            onPressed: _changePhoneNumber,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}