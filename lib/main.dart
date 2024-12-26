import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unote/screens/home_screen.dart';
import 'package:unote/Models/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.loadLastState();
  
  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Consumer<AppState>(
        builder: (context, appState, child) {
          return HomeScreen();
        },
      ),
    );
  }
}