import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:livelocation/firebase_options.dart';
import 'package:livelocation/login_page.dart';
import 'package:livelocation/tracker_home.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  String driverId = prefs.getString('driverId') ?? '';
  runApp(MyApp(isLoggedIn: isLoggedIn, driverId: driverId));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String driverId;

  const MyApp({Key? key, required this.isLoggedIn, required this.driverId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Location',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: isLoggedIn && driverId.isNotEmpty
          ? const TrackerHome()
          : const LoginPage(),
    );
  }
}
