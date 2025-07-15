import 'package:flutter/material.dart';
import '../controllers/aluno_controller.dart';
import '../session/session.dart';
import '../models/student_model.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  late Student student;

  late TextEditingController currentPasswordController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;

  Map<String, String?> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    student = Session.currentStudent!;

    currentPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alterar Palavra-passe'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/profile_page');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPasswordField('Palavra-passe atual', currentPasswordController, 'atual'),
            _buildPasswordField('Nova palavra-passe', newPasswordController, 'nova'),
            _buildPasswordField('Confirmar nova palavra-passe', confirmPasswordController, 'confirmar'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _atualizarSenha,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('Atualizar Palavra-passe'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, String fieldName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
            errorText: _fieldErrors[fieldName],
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Future<void> _atualizarSenha() async {
    final atual = currentPasswordController.text.trim();
    final nova = newPasswordController.text.trim();
    final confirmar = confirmPasswordController.text.trim();

    Map<String, String> errors = {};

    if (atual != student.password) {
      errors['atual'] = 'Palavra-passe atual incorreta';
    }

    if (nova.length < 6) {
      errors['nova'] = 'A nova palavra-passe deve ter pelo menos 6 caracteres';
    }

    if (confirmar != nova) {
      errors['confirmar'] = 'As palavras-passe não coincidem';
    }

    if (errors.isNotEmpty) {
      setState(() {
        _fieldErrors = errors;
      });
      return;
    }

    await atualizarSenha(student.id, nova);

    final updatedStudent = student.copyWith(password: nova);
    Session.currentStudent = updatedStudent;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Palavra-passe atualizada com sucesso')),
    );

    Navigator.of(context).pushReplacementNamed('/profile_page');
  }
}
