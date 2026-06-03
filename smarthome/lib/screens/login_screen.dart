import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smarthome/l10n/app_localizations.dart';
import 'package:smarthome/services/firebase_auth_service.dart';
import 'package:smarthome/services/locale_service.dart';

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
  final _auth = FirebaseAuthService();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _showPassword = false;
  String _error = '';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _gold = Color(0xFFBFA86D);
  static const _bg = Color(0xFF0D0D0D);
  static const _card = Color(0xFF1A1A1A);
  static const _input = Color(0xFF242424);

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
        Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
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

  // ── Auth handlers ────────────────────────────────────────────────────────

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final cred = await _auth.signInWithEmail(
          _emailCtrl.text.trim(), _passCtrl.text);
      _navigate(cred.user);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _auth.friendlyError(e));
    } catch (_) {
      setState(() => _error = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _error = '';
    });
    try {
      final cred = await _auth.signInWithGoogle();
      _navigate(cred.user);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _auth.friendlyError(e));
    } catch (e) {
      // User dismissed popup — not an error
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
      await _auth.sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.resetEmailSent),
        backgroundColor: Colors.green.shade800,
      ));
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _auth.friendlyError(e));
    }
  }

  void _navigate(User? user) {
    if (!mounted || user == null) return;
    final name =
        user.displayName ?? user.email?.split('@')[0] ?? 'User';
    Navigator.pushReplacementNamed(context, '/home', arguments: name);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

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
                      _buildHeader(l),
                      const SizedBox(height: 44),
                      _buildCard(l),
                      const SizedBox(height: 16),
                      _buildForgotRow(l),
                      const SizedBox(height: 28),
                      _buildSignInButton(l),
                      const SizedBox(height: 20),
                      _buildDivider(l),
                      const SizedBox(height: 20),
                      _buildGoogleButton(l),
                      const SizedBox(height: 40),
                      _buildFooter(l),
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

  Widget _buildHeader(AppLocalizations l) {
    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
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
        Text(l.appName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const SizedBox(height: 6),
        Text(l.appTagline,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13)),
      ],
    );
  }

  Widget _buildCard(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 28,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.welcomeBack,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(l.signInToContinue,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 13)),
          const SizedBox(height: 28),
          _field(
            ctrl: _emailCtrl,
            label: l.email,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? l.emailRequired
                : null,
          ),
          const SizedBox(height: 16),
          _field(
            ctrl: _passCtrl,
            label: l.password,
            icon: Icons.lock_outline_rounded,
            obscure: !_showPassword,
            suffix: IconButton(
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _showPassword = !_showPassword),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? l.passwordRequired : null,
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ErrorBanner(message: _error),
          ],
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
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
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.07))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _gold, width: 1.4)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFFFF5252), width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFFFF5252), width: 1.4)),
        errorStyle: const TextStyle(fontSize: 11.5),
      ),
    );
  }

  Widget _buildForgotRow(AppLocalizations l) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _forgotPassword,
        style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: Text(l.forgotPassword,
            style: TextStyle(
                color: _gold.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildSignInButton(AppLocalizations l) {
    return GestureDetector(
      onTap: _isLoading ? null : _signIn,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          gradient: _isLoading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFD4C17F), _gold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
          color: _isLoading ? _card : null,
          borderRadius: BorderRadius.circular(16),
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
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: _gold, strokeWidth: 2.5))
              : Text(l.signIn,
                  style: const TextStyle(
                      color: _bg,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
        ),
      ),
    );
  }

  Widget _buildDivider(AppLocalizations l) {
    return Row(children: [
      Expanded(
          child: Divider(color: Colors.white.withValues(alpha: 0.12))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(l.orDivider,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13)),
      ),
      Expanded(
          child: Divider(color: Colors.white.withValues(alpha: 0.12))),
    ]);
  }

  Widget _buildGoogleButton(AppLocalizations l) {
    return OutlinedButton(
      onPressed: _isGoogleLoading ? null : _signInGoogle,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        backgroundColor: _card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: _isGoogleLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white54, strokeWidth: 2))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GoogleLogo(),
                const SizedBox(width: 10),
                Text(l.signInWithGoogle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
    );
  }

  Widget _buildFooter(AppLocalizations l) {
    return Center(
      child: Text(l.appVersion,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.18),
              fontSize: 11,
              letterSpacing: 0.5)),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _LangToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isTr = LocaleService().isTurkish;
    return Align(
      alignment: Alignment.topRight,
      child: GestureDetector(
        onTap: () => LocaleService().setLocale(
            isTr ? const Locale('en') : const Locale('tr')),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.1)),
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

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5252).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFFFF5252).withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline,
            color: Color(0xFFFF5252), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: const TextStyle(
                  color: Color(0xFFFF5252), fontSize: 12.5)),
        ),
      ]),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: const Text(
        'G',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
          height: 1.25,
        ),
      ),
    );
  }
}
