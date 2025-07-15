import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/mobile_sidebar.dart';
import 'change_password_page.dart';
import '../session/session.dart';
import '../utils/string_utils.dart';
import '../models/student_model.dart';
import '../controllers/aluno_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _gender;
  late Student student;
   Map<String, String?> _fieldErrors = {};

  late TextEditingController nomeController;
  late TextEditingController emailController;
  late TextEditingController nascimentoController;
  late TextEditingController nifController;
  late TextEditingController distritoController;
  late TextEditingController moradaController;
  late TextEditingController codigoPostalController;
  late TextEditingController profissaoController;
  late TextEditingController ibanController;
  late TextEditingController passwordController;
  late TextEditingController courseIdController;

  @override
  void initState() {
    super.initState();
    student = Session.currentStudent!;

    nomeController = TextEditingController(text: student.nome);
    emailController = TextEditingController(text: student.userId);
    nascimentoController = TextEditingController(text: student.dataNascimento);
    nifController = TextEditingController(text: student.nif);
    distritoController = TextEditingController(text: student.distrito);
    moradaController = TextEditingController(text: student.morada);
    codigoPostalController = TextEditingController(text: student.codigoPostal);
    profissaoController = TextEditingController(text: student.profissao);
    ibanController = TextEditingController(text: student.iban);
    passwordController = TextEditingController(text: student.password);
    courseIdController = TextEditingController(text: student.courseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Text(
                      student.nome.initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              _buildReadOnlyField('Nome', nomeController),
              _buildReadOnlyField('Email', emailController),
              _buildReadOnlyField('Data de nascimento', nascimentoController),
              _buildReadOnlyField('NIF', nifController),
              _buildReadOnlyField('IBAN', ibanController),
              _buildReadOnlyField('Curso', courseIdController),

              SizedBox(height: 10),
              _buildEditableField('Morada', moradaController, 'morada'),
              SizedBox(height: 10),
              _buildEditableField('Distrito', distritoController, 'distrito'),
              SizedBox(height: 10),
              _buildEditableField('Código Postal', codigoPostalController, 'codigoPostal'),
              SizedBox(height: 10),
              _buildEditableField('Profissão', profissaoController, 'profissao'),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final morada = moradaController.text.trim();
                  final distrito = distritoController.text.trim();
                  final codigoPostal = codigoPostalController.text.trim();
                  final profissao = profissaoController.text.trim();

                  Map<String, String> errors = {};

                  if (distrito.isEmpty) {
                    errors['distrito'] = 'O distrito é obrigatório';
                  } else if (!RegExp(r'^[A-Za-zÀ-ÿ\s]+$').hasMatch(distrito)) {
                    errors['distrito'] = 'O distrito deve conter apenas letras';
                  }

                  if (morada.isEmpty) {
                    errors['morada'] = 'A morada é obrigatória';
                  }

                  if (codigoPostal.isEmpty) {
                    errors['codigoPostal'] = 'O código postal é obrigatório';
                  } else if (!RegExp(r'^[0-9]{4}-[0-9]{3}$').hasMatch(codigoPostal)) {
                    errors['codigoPostal'] = 'Formato: 1234-123';
                  }

                  if (profissao.isEmpty) {
                    errors['profissao'] = 'A profissão é obrigatória';
                  }

                  if (errors.isNotEmpty) {
                    setState(() {
                      _fieldErrors = errors;
                    });
                    return;
                  }

                  final updatedStudent = student.copyWith(
                    morada: morada,
                    distrito: distrito,
                    codigoPostal: codigoPostal,
                    profissao: profissao,
                  );

                  Session.currentStudent = updatedStudent;
                  await atualizarDadosParciais(updatedStudent);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Perfil atualizado com sucesso')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('Atualizar Perfil'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangePasswordPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('Alterar Palavra-passe'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: MobileSidebar(),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
          ),
          enabled: false,
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, String fieldName) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          errorText: _fieldErrors[fieldName], // <-- Aqui
        ),
      ),
      SizedBox(height: 10),
    ],
  );
}

}
