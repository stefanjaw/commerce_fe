
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? selectedValue;
  List<Map<String, dynamic>> places = [];

  @override
  void initState() {
    super.initState();
    loadPlaces();
    loadSavedPlace();
  }

  Future<void> loadPlaces() async {
    try {
      final String jsonString = await rootBundle.loadString('places.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      setState(() {
        places = jsonData.map((place) => {
          'id': place['id'],
          'name': place['name'],
        }).toList();
      });
    } catch (e) {
      print('Error loading places: $e');
    }
  }

  Future<void> loadSavedPlace() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('place_id');
    setState(() {
      // Only set the selected value if it exists in the places list
      selectedValue = places.any((place) => place['id'] == savedId) ? savedId : null;
    });
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void _saveSelectedPlace() async {
    if (selectedValue != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('place_id', selectedValue!);
      
      // Find the selected place name from the places list
      final selectedPlace = places.firstWhere(
        (place) => place['id'] == selectedValue,
        orElse: () => {'name': 'Unknown'},
      );
      await prefs.setString('place_name', selectedPlace['name']);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected place saved: ${selectedPlace['name']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text('Welcome ${user?.email ?? "User"}!'),
            const SizedBox(height: 20),
            Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return places;
                }
                return places.where((place) => 
                  place['name'].toString().toLowerCase()
                    .contains(textEditingValue.text.toLowerCase())
                );
              },
              displayStringForOption: (Map<String, dynamic> option) => option['name'],
              onSelected: (Map<String, dynamic> selection) {
                setState(() {
                  selectedValue = selection['id'];
                });
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search for a place',
                    suffixIcon: selectedValue != null ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        textEditingController.clear();
                        setState(() {
                          selectedValue = null;
                        });
                      },
                    ) : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedValue != null ? _saveSelectedPlace : null,
              child: const Text('Save Selection'),
            ),
          ],
        ),
      ),
    );
  }
}
