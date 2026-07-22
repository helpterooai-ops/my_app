import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  bool _isLogin = true; // true = تسجيل دخول، false = إنشاء حساب
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'البريد الإلكتروني وكلمة المرور مطلوبان');
      return;
    }

    if (!_isLogin && name.isEmpty) {
      setState(() => _errorMessage = 'الاسم مطلوب');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      User? user;
      
      if (_isLogin) {
        user = await _authService.signInWithEmail(
          email: email,
          password: password,
        );
      } else {
        user = await _authService.signUpWithEmail(
          email: email,
          password: password,
          name: name,
        );
      }

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      
      switch (e.code) {
        case 'user-not-found':
          message = 'المستخدم غير موجود';
          break;
        case 'wrong-password':
          message = 'كلمة المرور خاطئة';
          break;
        case 'email-already-in-use':
          message = 'البريد الإلكتروني مستخدم بالفعل';
          break;
        case 'weak-password':
          message = 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
          break;
        case 'invalid-email':
          message = 'البريد الإلكتروني غير صحيح';
          break;
        default:
          message = 'حدث خطأ: ${e.message}';
      }

      setState(() => _errorMessage = message);
    } catch (e) {
      setState(() => _errorMessage = 'حدث خطأ غير متوقع');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      User? user = await _authService.signInWithGoogle();

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'فشل تسجيل الدخول بـ Google');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // العنوان
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // حقل الاسم (فقط عند إنشاء حساب)
                if (!_isLogin) ...[
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // حقل البريد الإلكتروني
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),

                // حقل كلمة المرور
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 16),

                // رسالة الخطأ
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),

                // زر تسجيل الدخول/إنشاء حساب
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailAuth,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 16),

                // فاصل
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'أو',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // زر Google
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  icon: Image.network(
                    'https://www.google.com/favicon.ico',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.g_mobiledata, size: 24);
                    },
                  ),
                  label: Text(
                    'تسجيل الدخول بـ Google',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(height: 24),

                // التبديل بين تسجيل الدخول وإنشاء حساب
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _errorMessage = null;
                    });
                  },
                  child: Text(
                    _isLogin
                        ? 'ليس لديك حساب؟ إنشاء حساب جديد'
                        : 'لديك حساب بالفعل؟ تسجيل الدخول',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}