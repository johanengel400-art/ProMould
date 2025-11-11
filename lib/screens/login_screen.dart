import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../theme/dark_theme.dart';
import '../utils/validators.dart';
import '../services/error_handler.dart';
import '../services/log_service.dart';
import 'role_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usersBox = Hive.box('usersBox');
      final u = _u.text.trim();
      final p = _p.text;

      final user = usersBox.values
          .cast<Map>()
          .firstWhere((x) => x['username'] == u, orElse: () => {});

      if (user.isEmpty) {
        throw AuthenticationException('User not found');
      }

      if (user['password'] != p) {
        throw AuthenticationException('Incorrect password');
      }

      final level = (user['level'] ?? 1) as int;
      LogService.auth('User $u logged in successfully (Level $level)');

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => RoleRouter(level: level, username: u)));
      }
    } catch (e) {
      ErrorHandler.handle(e, context: 'Login');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(children: [
            const SizedBox(height: 10),
            Image.asset('assets/logo.png', width: 120, height: 120),
            const SizedBox(height: 16),
            Text('ProMould',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primary, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _u,
              decoration: const InputDecoration(labelText: 'Username'),
              validator: (value) => Validators.required(value, 'Username'),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _p,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) => Validators.required(value, 'Password'),
              enabled: !_isLoading,
              onFieldSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
            ),
          ]),
        ),
      )),
    );
  }
}
