import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../theme/dark_theme.dart';
import 'role_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState()=>_LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>{
  final _u=TextEditingController(); final _p=TextEditingController(); String? _err;

  void _login() {
    final usersBox = Hive.box('usersBox');
    final u=_u.text.trim(); final p=_p.text;
    final user = usersBox.values.cast<Map>().firstWhere(
      (x)=> x['username']==u, orElse: ()=>{});
    if(user.isEmpty) { setState(()=>_err='User not found'); return; }
    if(user['password']!=p){ setState(()=>_err='Incorrect password'); return; }
    final level = (user['level'] ?? 1) as int;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_)=>RoleRouter(level: level, username: u)));
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      body: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24), child: Column(children:[
          const SizedBox(height: 10),
          Text('ProMould', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.primary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          TextField(controller:_u, decoration: const InputDecoration(labelText:'Username')),
          const SizedBox(height: 12),
          TextField(controller:_p, obscureText:true, decoration: const InputDecoration(labelText:'Password')),
          const SizedBox(height: 8),
          if(_err!=null) Text(_err!, style: const TextStyle(color: AppTheme.danger)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed:_login, child: const Text('Login'))),
        ]),
      )),
    );
  }
}
