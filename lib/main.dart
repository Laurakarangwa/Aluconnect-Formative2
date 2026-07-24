import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:formative_assignment/firebase_options.dart';
import 'package:formative_assignment/state/app_state.dart';
import 'package:formative_assignment/theme.dart';
import 'package:formative_assignment/ui/auth_screen.dart';
import 'package:formative_assignment/ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'Firebase initialization',
        context: ErrorDescription('Could not initialize Firebase for this project configuration.'),
      ),
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'ALU Connect',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: _appState.currentUser == null ? AuthScreen(appState: _appState) : HomeScreen(appState: _appState),
        );
      },
    );
  }
}
