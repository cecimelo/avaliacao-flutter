import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _form = GlobalKey<FormState>();
  final txtEmailController = TextEditingController();
  final txtSenhaController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _carregando = false;

  Future<void> _cadastrar() async {
    if (!_form.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _carregando = true;
      });
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: txtEmailController.text.trim(),
        password: txtSenhaController.text,
      );

      if (credencial.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado com sucesso')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String erro;
      switch (e.code) {
        case 'email-already-in-use':
          erro = 'E-mail já cadastrado';
          break;
        case 'invalid-email':
          erro = 'E-mail inválido';
          break;
        case 'weak-password':
          erro = 'A senha deve ter pelo menos 6 caracteres';
          break;
        default:
          erro = 'Erro ao cadastrar: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciador de tarefas')),
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
                        'Cadastro',
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
                        onPressed: _carregando ? null : _cadastrar,
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
                                    color: Colors.deepPurple,
                                  ),
                                )
                                : const Text('Cadastrar'),
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
}
