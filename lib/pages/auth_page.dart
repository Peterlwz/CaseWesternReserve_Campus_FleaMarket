import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Auth extends StatefulWidget {
  final bool initialLogin;
  const Auth({super.key, this.initialLogin = true});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  late bool isLogin;
  final _emailController = TextEditingController(); // 登录完整邮箱
  final _prefixController = TextEditingController(); // 注册时的前缀
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  static const _caseSuffix = '@case.edu';
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    isLogin = widget.initialLogin;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _prefixController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void toggleMode() {
    setState(() {
      isLogin = !isLogin;
      _emailController.clear();
      _prefixController.clear();
      _passwordController.clear();
      _confirmController.clear();
    });
  }

  // 注册成功后写入 user_profiles 表
  Future<void> _createProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null || user.email == null) return;

    final email = user.email!;
    final username = email.split('@').first;

    try {
      await supabase.from('user_profiles').insert({
        'id': user.id,
        'email': email,
        'username': username,
      });
    } catch (e) {
      debugPrint('❗Failed to insert profile: $e');
    }
  }

  Future<void> _submit() async {
    final password = _passwordController.text.trim();

    if (isLogin) {
      // ---------------------- 登录逻辑 ----------------------
      final email = _emailController.text.trim();
      if (email.isEmpty || password.isEmpty) {
        _showMessage('Please fill in all required fields.');
        return;
      }

      try {
        final response = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.user != null) {
          if (response.user!.emailConfirmedAt == null) {
            _showMessage('Please verify your email before logging in.');
          } else {
            final userEmail = response.user!.email ?? '';
            final username = userEmail.split('@').first;
            _showMessage('Welcome back, $username!');

            await Future.delayed(const Duration(milliseconds: 800));

            if (context.mounted) {
              // ✅ 网页直接跳转到 /main
              Navigator.pushReplacementNamed(context, '/main');
            }
          }
        } else {
          _showMessage('Login failed. Please try again.');
        }
      } on AuthException catch (e) {
        _showMessage('Login failed: ${e.message}');
      } catch (e) {
        _showMessage('Unexpected error: $e');
      }
    } else {
      // ---------------------- 注册逻辑 ----------------------
      final prefix = _prefixController.text.trim();
      if (prefix.isEmpty ||
          password.isEmpty ||
          _confirmController.text.trim().isEmpty) {
        _showMessage('Please fill in all required fields.');
        return;
      }
      if (password != _confirmController.text.trim()) {
        _showMessage('Passwords do not match.');
        return;
      }
      if (prefix.contains('@') || prefix.contains(' ')) {
        _showMessage('Enter only your CWRU email prefix.');
        return;
      }

      final email = '$prefix@case.edu';

      try {
        // ✅ 检查重复邮箱
        final existing = await supabase
            .from('user_profiles')
            .select('email')
            .eq('email', email);

        if (existing.isNotEmpty) {
          _showMessage('This email is already registered.');
          return;
        }

        final response = await supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo:
              'https://cwrufleamarket.vercel.app/verify-success', // ✅ 改为你的域名
        );

        if (response.user != null) {
          await _createProfile();
          _showMessage(
              'Verification email sent to $email.\nPlease check your CWRU inbox.');
        } else {
          _showMessage('Registration failed. Try again.');
        }
      } on AuthException catch (e) {
        _showMessage('Sign up failed: ${e.message}');
      } catch (e) {
        _showMessage('Unexpected error: $e');
      }
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.storefront, color: Colors.indigo, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'CWRU Flea Market',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                Text(
                  isLogin ? 'Welcome Back' : 'Create Account',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin
                      ? 'Sign in to continue exploring the marketplace.'
                      : 'Sign up to join the CWRU community (must be a @case.edu address).',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 30),

                if (isLogin)
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@case.edu',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  )
                else
                  TextField(
                    controller: _prefixController,
                    decoration: InputDecoration(
                      labelText: 'CWRU Email',
                      hintText: 'e.g., abc123',
                      suffixText: _caseSuffix,
                      filled: true,
                      fillColor: Colors.grey[100],
                      helperText:
                          'Only @case.edu accounts allowed — enter the prefix only.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'[@\s]')),
                    ],
                  ),

                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                if (!isLogin) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[100],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isLogin ? 'SIGN IN' : 'SIGN UP',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: GestureDetector(
                    onTap: toggleMode,
                    child: RichText(
                      text: TextSpan(
                        text: isLogin
                            ? "Don't have an account? "
                            : "Already have an account? ",
                        style: const TextStyle(color: Colors.black54),
                        children: [
                          TextSpan(
                            text: isLogin ? 'Sign Up' : 'Sign In',
                            style: const TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/main'),
                    child: const Text('← Back to Home',
                        style: TextStyle(color: Colors.indigo)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
