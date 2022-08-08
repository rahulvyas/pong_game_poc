import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './pong.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
  ]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Pong Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
            /* appBar: AppBar(
              title: Text('Simple Pong'),
            ), */
            body: SafeArea(
          child: Pong(),
        )));
  }
}
