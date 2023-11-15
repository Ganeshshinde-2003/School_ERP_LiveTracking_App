// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:livelocation/text_field_widget.dart';
import 'package:livelocation/tracker_home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController vehicleController = TextEditingController();
  TextEditingController noController = TextEditingController();

  Future<void> storeDriverDataInSharedPreferences(
    String driverId,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Store driverId, name, vehicle, and login status in SharedPreferences
      await prefs.setString('driverId', driverId);
      await prefs.setString('name', nameController.text);
      await prefs.setString('vehicle', vehicleController.text);
      await prefs.setBool('isLoggedIn', true);

      // Navigate to the TrackerHome screen
      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TrackerHome()),
      );
    } catch (e) {
      print('Error storing driver data in SharedPreferences: $e');
    }
  }

  void _handleLoginButtonClick() async {
    String enteredMobileNumber = noController.text;

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      CollectionReference addDriverCollection =
          firestore.collection('AddDriver');

      QuerySnapshot querySnapshot = await addDriverCollection.get();
      bool isMatchFound = false;
      for (QueryDocumentSnapshot document in querySnapshot.docs) {
        String mobileNo = document.get('mobileNo');

        if (mobileNo == enteredMobileNumber) {
          String driverId = document.get('driverId');
          await storeDriverDataInSharedPreferences(driverId);

          isMatchFound = true;

          break;
        }
      }

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isMatchFound ? 'Found driver' : 'Driver not found',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error fetching data from AddDriver collection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "School Driver Vehicle Tracking App",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 50),
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
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
                      Colors.grey.shade900,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomTextField(
                        controller: nameController,
                        hintText: "Enter Your Name",
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: vehicleController,
                        hintText: "Enter Your Vehicle",
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: noController,
                        hintText: "Enter Your Mobile No",
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _handleLoginButtonClick,
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 20,
                            color: Color.fromARGB(255, 95, 94, 94),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
