import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrackerHome extends StatefulWidget {
  const TrackerHome({Key? key}) : super(key: key);

  @override
  State<TrackerHome> createState() => _TrackerHomeState();
}

class _TrackerHomeState extends State<TrackerHome> {
  double? lat;
  double? lon;
  String address = "";
  late Timer _timer;
  late String storedDriverId;
  bool tripStatus = false;

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
    storedDriverId = prefs.getString('driverId')!;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void getCurrentLocation() async {
    if (tripStatus) {
      LocationPermission permission = await Geolocator.checkPermission();
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          address = "Location services are disabled";
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
          firestore.collection('Locations').doc(storedDriverId);

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
      appBar: AppBar(
        title: const Text(
          "Tracking Live Location of driver",
          style: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade700,
              Colors.grey.shade800,
              Colors.grey.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(children: [
                    const Icon(
                      Icons.location_pin,
                      size: 60,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Current Address: $address",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        tripStatus = !tripStatus;
                      });
                    },
                    child: Text(
                      tripStatus ? 'End Trip' : 'Start Trip',
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
