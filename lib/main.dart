import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:livelocation/firebase_options.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Location',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double? lat;
  double? lon;
  String address = "";
  late Timer _timer;
  late String userId;

  @override
  void initState() {
    super.initState();
    _initializeUserId();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      getCurrentLocation();
    });
  }

  Future<void> _initializeUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString('userId');

    if (storedUserId == null) {
      // Generate a new UUID and store it in SharedPreferences
      userId = const Uuid().v4();
      await prefs.setString('userId', userId);
    } else {
      userId = storedUserId;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        address = "Locaiton services are disabled";
      });
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        address = "Location Permission is denied";
      });
      await Geolocator.requestPermission();
    } else {
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      setState(() {
        lat = currentPosition.latitude;
        lon = currentPosition.longitude;
      });
      getAddress(lat, lon);
    }
  }

  getAddress(double? lat, double? long) async {
    if (lat != null && long != null) {
      List<Placemark> placeMarks = await placemarkFromCoordinates(lat, long);
      setState(() {
        address =
            "${placeMarks[0].street!} ${placeMarks[0].subLocality!} ${placeMarks[0].subAdministrativeArea!} ${placeMarks[0].postalCode!} ${placeMarks[0].administrativeArea!} ${placeMarks[0].country!}";
      });

      await storeLocationInFireStore(lat, lon, address);
    }
  }

  Future<void> storeLocationInFireStore(
      double? lat, double? lon, String address) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      DocumentReference userLocationDoc =
          firestore.collection('Locations').doc(userId);

      await userLocationDoc.set({
        'latitude': lat,
        'longitude': lon,
        'address': address,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      showResultSnackbar(false);
    }
  }

  void showResultSnackbar(bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Location data stored successfully'
            : 'Failed to store location data'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(children: [
                  Text(
                    "Longtide: $lon",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Latitude: $lat",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Current Address: $address",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
