import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _showPass = false;
  String _error = '';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _gold = Color(0xFFBFA86D);
  static const _bg = Color(0xFF121212);
  static const _card = Color(0xFF1E1E1E);
  static const _input = Color(0xFF2A2A2A);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = ''; });
    try {
      await AuthService().signInWithEmail(_emailCtrl.text, _passCtrl.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService().friendlyError(e));
    } catch (_) {
      setState(() => _error = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _isGoogleLoading = true; _error = ''; });
    try {
      await AuthService().signInWithGoogle();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService().friendlyError(e));
    } catch (e) {
      if (e.toString().contains('popup-closed')) return;
      setState(() => _error = 'Google sign-in failed.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    try {
      await AuthService().sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password reset email sent.'),
        backgroundColor: Colors.green,
      ));
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService().friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60),
                      _buildHeader(),
                      const SizedBox(height: 44),
                      _buildCard(),
                      const SizedBox(height: 14),
                      _buildForgotBtn(),
                      const SizedBox(height: 28),
                      _buildSignInBtn(),
                      const SizedBox(height: 18),
                      _buildDivider(),
                      const SizedBox(height: 18),
                      _buildGoogleBtn(),
                      const SizedBox(height: 40),
                      Center(
                        child: Text('SmartHome Pro v1.0',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.18),
                                fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(children: [
      Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFD4C17F), _gold],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
                color: _gold.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 2)
          ],
        ),
        child: const Icon(Icons.home_outlined, size: 36, color: _bg),
      ),
      const SizedBox(height: 18),
      const Text('SmartHome Pro',
          style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1)),
      const SizedBox(height: 6),
      Text('Control your home, anywhere',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
    ]);
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 28,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome back',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 20,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Sign in to continue',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35), fontSize: 13)),
        const SizedBox(height: 26),
        _field(
          ctrl: _emailCtrl,
          label: 'Email',
          icon: Icons.email_outlined,
          type: TextInputType.emailAddress,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Email is required' : null,
        ),
        const SizedBox(height: 14),
        _field(
          ctrl: _passCtrl,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          obscure: !_showPass,
          suffix: IconButton(
            icon: Icon(
                _showPass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: 20),
            onPressed: () => setState(() => _showPass = !_showPass),
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Password is required' : null,
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_error,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 12.5)),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
        prefixIcon:
            Icon(icon, color: _gold.withValues(alpha: 0.75), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: _input,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.07))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: _gold, width: 1.4)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 1.4)),
        errorStyle: const TextStyle(fontSize: 11.5),
      ),
    );
  }

  Widget _buildForgotBtn() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _forgotPassword,
        style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: Text('Forgot password?',
            style: TextStyle(
                color: _gold.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildSignInBtn() {
    return GestureDetector(
      onTap: _isLoading ? null : _signIn,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: _isLoading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFD4C17F), _gold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
          color: _isLoading ? _card : null,
          borderRadius: BorderRadius.circular(15),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                      color: _gold.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6))
                ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: _gold, strokeWidth: 2.5))
              : const Text('Sign In',
                  style: TextStyle(
                      color: _bg,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(children: [
      Expanded(
          child: Divider(color: Colors.white.withValues(alpha: 0.1))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text('or',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13)),
      ),
      Expanded(
          child: Divider(color: Colors.white.withValues(alpha: 0.1))),
    ]);
  }

  Widget _buildGoogleBtn() {
    return OutlinedButton(
      onPressed: _isGoogleLoading ? null : _googleSignIn,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        backgroundColor: _card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: _isGoogleLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white54, strokeWidth: 2))
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('G',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4285F4))),
                SizedBox(width: 10),
                Text('Continue with Google',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
    );
  }
}
