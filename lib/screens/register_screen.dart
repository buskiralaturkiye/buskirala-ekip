import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnack('Lütfen tüm alanları doldurun.', Colors.red);
      return;
    }

    if (_passwordController.text != _passwordConfirmController.text) {
      _showSnack('Şifreler eşleşmiyor.', Colors.red);
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnack('Şifre en az 6 karakter olmalı.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. ADIM: WordPress'e kayıt
      final wpResponse = await http.post(
        Uri.parse('https://www.buskirala.com/wp-admin/admin-ajax.php'),
        body: {
          'action': 'bk_mobile_api',
          'secret': 'BuskiralaApp2026',
          'command': 'register',
          'email': _emailController.text.trim(),
          'reg_email': _emailController.text.trim(),
          'reg_password': _passwordController.text.trim(),
          'reg_name': _nameController.text.trim(),
          'reg_phone': _phoneController.text.trim(),
        },
      );

      final wpResult = json.decode(wpResponse.body);

      if (wpResult['success'] != true &&
          wpResult['data'] != 'Bu e-posta zaten kayıtlı.') {
        _showSnack('Hata: ${wpResult['data']}', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      // 2. ADIM: Firebase'e kayıt
      try {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await credential.user?.updateDisplayName(_nameController.text.trim());

        // Kayıt başarılı, direkt giriş yaptır
        if (mounted) {
          _showSnack('Kayıt başarılı! Hoş geldiniz.', Colors.green);
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Google ile kayıtlı, Google ile giriş yaptırmayı dene
          _showSnack(
            'Bu e-posta Google hesabınızla kayıtlı. Google ile giriş yapılıyor...',
            Colors.orange,
          );
          await Future.delayed(const Duration(seconds: 1));
          await _signInWithGoogle();
        } else {
          _showSnack('Kayıt hatası: ${e.code}', Colors.red);
        }
      }
    } catch (e) {
      _showSnack('Bağlantı hatası: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showSnack('Google ile giriş başarısız: $e', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kayıt Ol',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hesap Oluştur',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Bilgilerinizi girerek kayıt olun.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _nameController,
                decoration: _inputDec('Ad Soyad', Icons.person_outline),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDec('Telefon Numarası', Icons.phone_outlined),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDec('E-posta', Icons.email_outlined),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDec('Şifre', Icons.lock_outlined).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordConfirmController,
                obscureText: _obscureConfirm,
                decoration:
                    _inputDec('Şifre Tekrar', Icons.lock_outlined).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'KAYIT OL',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Zaten hesabınız var mı?',
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Giriş Yap',
                      style: TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}