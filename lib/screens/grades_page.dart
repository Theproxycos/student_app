import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/subject_model.dart';
import '../screens/grades_page_detail.dart';
import '../widgets/mobile_sidebar.dart';
import '../../session/session.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  _GradesPageState createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  late Future<List<Subject>> _subjectsFuture;

  @override
  void initState() {
    super.initState();
    _subjectsFuture = _fetchSubjects();
  }

  Future<List<Subject>> _fetchSubjects() async {
    final student = Session.currentStudent;
    if (student == null) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('name', isEqualTo: student.courseId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return [];

    final courseDoc = querySnapshot.docs.first;

    final subjectsSnapshot = await courseDoc.reference
        .collection('subjects')
        .where('courseYear', isEqualTo: student.year)
        .get();

    return subjectsSnapshot.docs
        .map((doc) => Subject.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notas"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]?.withOpacity(0.7)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[600]!
                      : Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.library_books,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.blue,
                    size: 24.0,
                  ),
                  SizedBox(width: 12.0),
                  Text(
                    "Disciplinas",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Subject>>(
                future: _subjectsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erro ao carregar disciplinas'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('Nenhuma disciplina encontrada'));
                  } else {
                    return ListView(
                      children: snapshot.data!
                          .map((subject) => _subjectCard(subject))
                          .toList(),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: MobileSidebar(),
    );
  }

  Widget _subjectCard(Subject subject) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            gradient: LinearGradient(
              colors: [
                Colors.blue,
                Colors.blue.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            leading: Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                Icons.school,
                color: Colors.white,
                size: 24.0,
              ),
            ),
            title: Text(
              subject.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text(
                "Ver notas e avaliações",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14.0,
                ),
              ),
            ),
            trailing: Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16.0,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GradesPageDetail(subject: subject),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
