import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../locale_service.dart';
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
      setState(() => _error = S.of(context).connectionError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final s = S.of(context);
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = s.enterEmailFirst);
      return;
    }
    try {
      await AuthService().sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.resetEmailSent),
        backgroundColor: Colors.green,
      ));
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService().friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

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
                      const SizedBox(height: 20),
                      _LangToggle(),
                      const SizedBox(height: 32),
                      _buildHeader(s),
                      const SizedBox(height: 44),
                      _buildCard(s),
                      const SizedBox(height: 14),
                      _buildForgotBtn(s),
                      const SizedBox(height: 28),
                      _buildSignInBtn(s),
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

  Widget _buildHeader(S s) {
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
      Text(s.tagline,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
    ]);
  }

  Widget _buildCard(S s) {
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
        Text(s.welcomeBack,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 20,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(s.signInToContinue,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35), fontSize: 13)),
        const SizedBox(height: 26),
        _field(
          ctrl: _emailCtrl,
          label: s.email,
          icon: Icons.email_outlined,
          type: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return s.emailRequired;
            final email = v.trim().toLowerCase();
            if (!email.endsWith('@admin.com') && !email.endsWith('@gmail.com')) {
              return s.emailDomainError;
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        _field(
          ctrl: _passCtrl,
          label: s.password,
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
              (v == null || v.isEmpty) ? s.passwordRequired : null,
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

  Widget _buildForgotBtn(S s) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _forgotPassword,
        style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: Text(s.forgotPassword,
            style: TextStyle(
                color: _gold.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildSignInBtn(S s) {
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
              : Text(s.signIn,
                  style: const TextStyle(
                      color: _bg,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
        ),
      ),
    );
  }
}

// ── Language toggle widget ────────────────────────────────────────────────────

class _LangToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isTr = LocaleService().isTurkish;
    return Align(
      alignment: Alignment.topRight,
      child: GestureDetector(
        onTap: () => LocaleService().toggle(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(isTr ? '🇹🇷' : '🇬🇧',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(isTr ? 'TR' : 'EN',
                style: const TextStyle(
                    color: Color(0xFFBFA86D),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}
