import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/schedule.dart';
import 'screens/course_page.dart';
import 'screens/course_detail_page.dart';
import 'screens/assignments_page.dart';
import 'screens/presences.dart';
import 'screens/exames_testes_page.dart';
import 'screens/announcement_page.dart';
import 'screens/grades_page.dart';
import 'screens/messages_page.dart';
import 'package:provider/provider.dart';
import 'widgets/theme_switcher.dart';
import 'screens/profile_page.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/fcm_service.dart';
import 'session/session.dart';
// import 'services/notification_service.dart';

// Handler para notificações em background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase já está inicializado no main()
  print('📨 Notificação em background: ${message.notification?.title}');
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    // Inicializar Firebase apenas uma vez
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        authDomain: "campus-link-def.firebaseapp.com",
        projectId: "campus-link-def",
        storageBucket: "campus-link-def.firebasestorage.app",
        messagingSenderId: "821984532953",
        appId: "1:821984532953:web:166c5b12a2a85e019421c8",
        measurementId: "G-0W8N9BZWJD",
      ),
    );
    print('✅ Firebase inicializado com sucesso');
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      print('⚠️ Firebase já estava inicializado');
    } else {
      print('❌ Erro ao inicializar Firebase: $e');
      rethrow;
    }
  }

  // Configurar handler para notificações em background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializar FCM Service
  try {
    await FCMService.initialize();
    print('✅ FCM Service inicializado com sucesso');
  } catch (e) {
    print('❌ Erro ao inicializar FCM Service: $e');
  }

  // Inicializar Sistema de Sessão (carregar notificações lidas)
  try {
    await Session.initializeSession();
    print('✅ Sistema de sessão inicializado com sucesso');
  } catch (e) {
    print('❌ Erro ao inicializar sistema de sessão: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeSwitcher(),
      child: CampusLink(),
    ),
  );
}

class CampusLink extends StatefulWidget {
  const CampusLink({super.key});

  @override
  State<CampusLink> createState() => _CampusLinkState();
}

class _CampusLinkState extends State<CampusLink> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _initFirebaseMessaging();
  }

  void _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Solicita permissão (necessário no Android 13+ e iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permissão concedida');

      // Obtém o token do dispositivo
      final token = await messaging.getToken();
      print('📱 Token FCM: $token');

      // Podes salvar este token no Firestore para enviar notificações depois
    }

    // Receber notificações em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Mensagem em foreground!');
      print('🔹 Título: ${message.notification?.title}');
      print('🔹 Corpo: ${message.notification?.body}');
    });

    // Quando abre app por notificação
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📬 Abriu a notificação!');
    });
  }

  Future<void> _checkLoginStatus() async {
    try {
      // Verificar se o usuário estava logado anteriormente
      // final isLoggedIn = await NotificationService.isUserLoggedIn();
      final isLoggedIn = false; // Temporary

      setState(() {
        _isLoggedIn = isLoggedIn;
        _isLoading = false;
      });

      print('✅ Status de login verificado: $isLoggedIn');
    } catch (e) {
      print('❌ Erro ao verificar status de login: $e');
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    FlutterNativeSplash.remove();
    final themeSwitcher = Provider.of<ThemeSwitcher>(context);

    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeSwitcher.themeMode,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('pt', 'PT'), // Português de Portugal
      ],
      locale: const Locale('pt', 'PT'),
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black),
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: Colors.grey[300],
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          headlineLarge:
              TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.blue,
          textTheme: ButtonTextTheme.primary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.blue,
          inactiveTrackColor: Colors.grey,
          thumbColor: Colors.blue,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.blue),
          trackColor: WidgetStateProperty.all(Colors.blue.withOpacity(0.4)),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white),
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: Colors.grey[850],
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          headlineLarge:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.blue,
          textTheme: ButtonTextTheme.primary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.blue,
          inactiveTrackColor: Colors.grey,
          thumbColor: Colors.blue,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.blue),
          trackColor: WidgetStateProperty.all(Colors.blue.withOpacity(0.4)),
        ),
      ),
      initialRoute: _isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => Login(),
        '/home': (context) => HomeScreen(),
        '/course_page': (context) => CoursePage(),
        '/course_detail_page': (context) => CourseDetailPage(),
        '/schedule': (context) => SchedulePage(),
        '/assigments_page': (context) => AssignmentsPage(),
        '/presences': (context) => PresencesPage(),
        '/exames_testes': (context) => ExamesTestesPage(),
        '/grades_page': (context) => GradesPage(),
        '/announcement_page': (context) => AnnouncementsPage(),
        '/message': (context) => MessagesPage(),
        '/profile_page': (context) => ProfilePage(),
      },
    );
  }
}
