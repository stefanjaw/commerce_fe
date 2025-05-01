import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/services.dart' show rootBundle;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? selectedValue;
  List<Map<String, dynamic>> places = [];
  String? placeName;
  Map<String, List<String>> selectedProducts = {};
  Map<String, Map<String, int>> quantities = {};
  Map<String, dynamic> currentPlace = {};

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
          'products': place['products'] // Assuming places.json has a 'products' field
        }).toList();
      });
    } catch (e) {
      print('Error loading places: $e');
    }
  }

  Future<void> loadSavedPlace() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('place_id');
    final savedName = prefs.getString('place_name');
    setState(() {
      selectedValue = places.any((place) => place['id'] == savedId) ? savedId : null;
      placeName = savedName;
      if (selectedValue != null) {
        currentPlace = places.firstWhere((place) => place['id'] == selectedValue);
      }
    });
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _saveSelectedPlace() async {
    if (selectedValue != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('place_id', selectedValue!);

      final selectedPlace = places.firstWhere(
        (place) => place['id'] == selectedValue,
        orElse: () => {'name': 'Unknown'},
      );
      await prefs.setString('place_name', selectedPlace['name']);

      setState(() {
        placeName = selectedPlace['name'];
        currentPlace = selectedPlace;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected place saved: ${selectedPlace['name']}')),
      );
    }
  }

  void _updateQuantity(String category, String product, int quantity) {
    setState(() {
      quantities[category] ??= {};
      quantities[category]![product] = quantity;
    });
  }

  List<dynamic> orders = [];

  void _showOrders() {
    js.context.callMethod('showOrders');
    final callback = js.allowInterop((dynamic result) {
      setState(() {
        orders = result;
      });
    });
    js.context['setOrdersCallback'] = callback;
  }

  void _placeOrder() {
    // Convert quantities to a format suitable for JS
    Map<String, dynamic> orderData = {
      'quantities': quantities,
      'selectedProducts': selectedProducts,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Use JS interop to store data in IndexedDB
    js.context.callMethod('storeOrder', [json.encode(orderData)]);

    // Clear current selections and show orders
    setState(() {
      quantities.clear();
      selectedProducts.clear();
    });

    _showOrders();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order saved successfully')),
    );
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
                    place['name'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              displayStringForOption: (Map<String, dynamic> option) => option['name'],
              onSelected: (Map<String, dynamic> selection) {
                setState(() {
                  selectedValue = selection['id'];
                  currentPlace = selection;
                });
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search for a place',
                    suffixIcon: selectedValue != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              textEditingController.clear();
                              setState(() {
                                selectedValue = null;
                                currentPlace = {};
                              });
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedValue != null ? _saveSelectedPlace : null,
              child: const Text('Save Selection'),
            ),
            if (placeName != null)
              Text('Selected Place: $placeName'),
            if (currentPlace.containsKey('products'))
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const <DataColumn>[
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Qty')),
                      DataColumn(label: Text('')),
                    ],
                    rows: currentPlace['products'].entries.expand<DataRow>((entry) {
                      String category = entry.key;
                      return (entry.value as List).map<DataRow>((productName) {
                        return DataRow(
                          cells: <DataCell>[
                            DataCell(Text(category)),
                            DataCell(Text(productName.toString())),
                            DataCell(
                              Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    final currentQty = quantities[category]?[productName] ?? 0;
                                    _updateQuantity(category, productName, currentQty > 0 ? currentQty - 1 : 0);
                                  },
                                ),
                                Text('${quantities[category]?[productName] ?? 0}'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    final currentQty = quantities[category]?[productName] ?? 0;
                                    _updateQuantity(category, productName, currentQty + 1);
                                  },
                                ),
                              ],
                            ),
                          ),
                          DataCell(Checkbox(
                            value: selectedProducts[category]?.contains(productName) ?? false,
                            onChanged: (value) {
                              setState(() {
                                selectedProducts[category] ??= [];
                                if (value!) {
                                  selectedProducts[category]!.add(productName);
                                } else {
                                  selectedProducts[category]!.remove(productName);
                                }
                              });
                            },
                          )),
                        ],
                      );
                    }).toList();
                    }).toList(),
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: _placeOrder,
              child: const Text('Place Order'),
            ),
            if (orders.isNotEmpty) ...[
              const Divider(height: 20),
              const Text('Recent Orders:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        title: Text('Order ${index + 1}'),
                        subtitle: Text('Time: ${order['timestamp']}'),
                        trailing: const Icon(Icons.receipt_long),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}