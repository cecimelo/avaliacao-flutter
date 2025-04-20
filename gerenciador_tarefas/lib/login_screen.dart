import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final txtEmailController = TextEditingController();
  final txtSenhaController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _carregando = false;

  Future<void> _fazerLogin() async {
    if (!_form.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _carregando = true;
      });

      final UserCredential credencial = await _auth.signInWithEmailAndPassword(
        email: txtEmailController.text.trim(),
        password: txtSenhaController.text,
      );
      if (credencial.user != null) {
        Navigator.pushReplacementNamed(context, '/tarefas');
      }
    } on FirebaseAuthException catch (e) {
      String erro;
      switch (e.code) {
        case 'invalid-email':
          erro = 'E-mail inválido';
          break;
        case 'user-disabled':
          erro = 'Usuário desativado';
          break;
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          erro = 'E-mail ou senha incorretos';
          break;
        default:
          erro = 'Erro ao fazer login: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  void _abrirCadastro() {
    Navigator.pushNamed(context, '/cadastro');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gerenciador de tarefas")),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                child: Form(
                  key: _form,
                  child: Column(
                    children: [
                      const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: txtEmailController,
                        decoration: InputDecoration(labelText: "Email"),
                        keyboardType: TextInputType.emailAddress,
                        validator:
                            (value) =>
                                value == null || !value.contains('@')
                                    ? 'Email inválido'
                                    : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: txtSenhaController,
                        decoration: InputDecoration(labelText: "Senha"),
                        obscureText: true,
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Preencha a senha'
                                    : null,
                      ),
                      SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _carregando ? null : _fazerLogin,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child:
                            _carregando
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text('Entrar'),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: _carregando ? null : _abrirCadastro,
                        child: const Text('Cadastrar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    txtEmailController.dispose();
    txtSenhaController.dispose();
    super.dispose();
  }
}
