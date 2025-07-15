import 'package:flutter/material.dart';

class MobileSidebar extends StatelessWidget {
  const MobileSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => SizedBox(
            height: 300,
            child: _buildSidebarContent(context),
          ),
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.menu, color: Colors.white),
      ),
    );
  }

  Widget _buildSidebarContent(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: Icon(Icons.home),
          title: Text('Início'),
          onTap: () {
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
        ListTile(
          leading: Icon(Icons.book),
          title: Text('Disciplinas'),
          onTap: () {
            Navigator.of(context).pushReplacementNamed('/course_page');
          },
        ),
        ListTile(
          leading: Icon(Icons.schedule),
          title: Text('Horário'),
          onTap: () {
            Navigator.of(context).pushReplacementNamed('/schedule');
          },
        ),
        ListTile(
          leading: Icon(Icons.assignment),
          title: Text('Trabalhos'),
          onTap: () {
            Navigator.of(context).pushReplacementNamed('/assigments_page');
          },
        ),
        ListTile(
          leading: Icon(Icons.check_circle),
          title: Text('Presenças'),
          onTap: () {
            Navigator.of(context).pushReplacementNamed('/presences');
          },
        ),
        ListTile(
          leading: Icon(Icons.assignment_turned_in),
          title: Text('Exames e Testes'),
          onTap: () {
            Navigator.of(context).pushReplacementNamed('/exames_testes');
          },
        ),
        ListTile(
          leading: Icon(Icons.grade),
          title: Text('Notas'),
          onTap: () {
            Navigator.of(context).pushReplacementNamed('/grades_page');
          },
        ),
        ListTile(
          leading: Icon(Icons.chat),
          title: Text('Conversas'),
          onTap: () {
            Navigator.of(context).pushReplacementNamed('/message');
          },
        ),
        ListTile(
          leading: Icon(Icons.person),
          title: Text('Perfil'),
          onTap: () {
            Navigator.of(context).pushReplacementNamed('/profile_page');
          },
        ),
        ListTile(
          leading: Icon(Icons.accessibility_outlined),
          title: Text('Anúncios'),
          onTap: () {
            Navigator.of(context).pushReplacementNamed('/announcement_page');
          },
        ),
      ],
    );
  }
}
