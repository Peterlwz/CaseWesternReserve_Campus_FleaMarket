import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifySuccessPage extends StatefulWidget {
  const VerifySuccessPage({super.key});

  @override
  State<VerifySuccessPage> createState() => _VerifySuccessPageState();
}

class _VerifySuccessPageState extends State<VerifySuccessPage> {
  final supabase = Supabase.instance.client;
  bool _saving = true;

  @override
  void initState() {
    super.initState();
    _insertProfileIfNeeded();
  }

  Future<void> _insertProfileIfNeeded() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _saving = false);
        return;
      }

      // 检查 profiles 表中是否已经存在
      final existing = await supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        // 插入 profile
        await supabase.from('profiles').insert({
          'id': user.id,
          'username': user.email!.split('@').first,
        });
      }
    } catch (e) {
      debugPrint('Insert profile error: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _saving
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 80),
                  const SizedBox(height: 20),
                  const Text(
                    'Email Verified!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your CWRU Flea Market account is now active.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/auth');
                    },
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
      ),
    );
  }
}
