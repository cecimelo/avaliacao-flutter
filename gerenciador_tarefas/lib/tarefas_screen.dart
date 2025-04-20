import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TarefasScreen extends StatefulWidget {
  const TarefasScreen({super.key});

  @override
  State<TarefasScreen> createState() => _TarefasScreenState();
}

class _TarefasScreenState extends State<TarefasScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User? _usuario;
  DateTime _dataSelecionada = DateTime.now();
  List<Map<String, dynamic>> _tarefas = [];

  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _usuario = _auth.currentUser!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consultarTarefas();
    });
  }

  Future<void> _selecionarData() async {
    final DateTime? novaData = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );

    if (novaData != null) {
      setState(() {
        _dataSelecionada = novaData;
      });
      _consultarTarefas();
    }
  }

  Future<void> _consultarTarefas() async {
    if (_usuario == null || _usuario?.email == null) {
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final dataFormatada = DateFormat('yyyy-MM-dd').format(_dataSelecionada);

      final colecao =
          await _firestore
              .collection('users')
              .doc(_usuario?.email)
              .collection(dataFormatada)
              .get();

      final tarefas =
          colecao.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      setState(() {
        _tarefas = _ordenarTarefas(tarefas);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar tarefas: $e')));
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  void _criarTarefa() async {
    if (_usuario == null || _usuario?.email == null) {
      return;
    }

    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Nova tarefa'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Descrição'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final descricao = controller.text.trim();

                if (descricao.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Preencha a descrição')),
                  );
                  return;
                }
                final existe = _tarefas.any(
                  (t) =>
                      (t['descricao'] as String).toLowerCase() ==
                      descricao.toLowerCase(),
                );

                if (existe) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('A tareja já existe nesta data')),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_usuario?.email)
                    .collection(
                      DateFormat('yyyy-MM-dd').format(_dataSelecionada),
                    )
                    .add({'descricao': descricao, 'concluida': false});

                if (context.mounted) {
                  Navigator.of(context).pop();
                }

                // Recarregar lista após adicionar
                await _consultarTarefas();
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _atualizarTarefa(String id, bool concluida) async {
    final dataFormatada = DateFormat('yyyy-MM-dd').format(_dataSelecionada);

    setState(() {
      _carregando = true;
    });

    try {
      await _firestore
          .collection('users')
          .doc(_usuario?.email)
          .collection(dataFormatada)
          .doc(id)
          .update({'concluida': concluida});
      _consultarTarefas();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tarefa atualizada')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao atualizar tarefa: $e')));
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  Future<void> _excluirTarefa(String id) async {
    final dataFormatada = DateFormat('yyyy-MM-dd').format(_dataSelecionada);

    setState(() {
      _carregando = true;
    });

    try {
      await _firestore
          .collection('users')
          .doc(_usuario?.email)
          .collection(dataFormatada)
          .doc(id)
          .delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tarefa excluída')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao excluir tarefa: $e')));
    } finally {
      setState(() {
        _carregando = false;
      });
    }
    _consultarTarefas();
  }

  List<Map<String, dynamic>> _ordenarTarefas(
    List<Map<String, dynamic>> tarefas,
  ) {
    final pendentes = tarefas.where((t) => t['concluida'] != true).toList();
    final concluidas = tarefas.where((t) => t['concluida'] == true).toList();

    pendentes.sort(
      (a, b) => (a['descricao'] ?? '').compareTo(b['descricao'] ?? ''),
    );

    concluidas.sort(
      (a, b) => (a['descricao'] ?? '').compareTo(b['descricao'] ?? ''),
    );

    return [...pendentes, ...concluidas];
  }

  void _logout() async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd/MM/yyyy').format(_dataSelecionada);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciador de tarefas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body:Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _selecionarData,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Selecionar data: $dataFormatada',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_month, color: Colors.deepPurple),
                  ],
                ),
              ),
            ),
            _carregando
                ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
                : _tarefas.isEmpty
                ? const Expanded(
                  child: Center(child: Text('Nenhuma tarefa para esta data')),
                )
                : Expanded(
                  child: ListView.separated(
                    itemCount: _tarefas.length,
                    separatorBuilder:
                        (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tarefa = _tarefas[index];
                      final descricao = tarefa['descricao'] ?? '';
                      final concluida = tarefa['concluida'] ?? false;
                      final id = tarefa['id'];

                      return ListTile(
                        leading: Checkbox(
                          value: concluida,
                          onChanged:
                              (value) => _atualizarTarefa(id, value ?? false),
                        ),
                        title: Text(
                          descricao,
                          style: TextStyle(
                            decoration:
                                concluida
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _excluirTarefa(id),
                        ),
                      );
                    },
                  ),
                ),
          ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _criarTarefa,
        tooltip: 'Criar Tarefa',
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
