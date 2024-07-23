import 'package:coffee_new_app/model/coffee_shop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/coffee.dart';

class CoffeeManager extends StatefulWidget {

  _CoffeeManagerState createState() => _CoffeeManagerState();
}

class _CoffeeManagerState extends State<CoffeeManager> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imagePathController = TextEditingController(text: 'lib/images/');

  void _addProduct() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final imagePath = _imagePathController.text.trim();

    if (name.isNotEmpty && price > 0 && imagePath.isNotEmpty) {
      final coffee = Coffee(name: name, price: price, imagePath: imagePath);
      Provider.of<CoffeeShop>(context, listen: false).addProduct(coffee);
      _nameController.clear();
      _priceController.clear();
      _imagePathController.text = 'lib/images/'; // Reset Default path
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter valid products details'),
        backgroundColor: Colors.red, 
        ));
    }
  }

  void _deleteProduct(Coffee coffee) {
    Provider.of<CoffeeShop>(context, listen: false).deleteProducts(coffee);
  }


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manages Products'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Product Name'),
            ),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Product Price'),
            ),
            TextField(
              controller: _imagePathController,
              decoration: InputDecoration(labelText: 'Image Path'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addProduct,
              child: Text('Add Product'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Consumer<CoffeeShop>(
                builder: (context, coffeeShop, child) {
                  return ListView.builder(
                    itemCount: coffeeShop.coffeeShop.length,
                    itemBuilder: (context, index) {
                      final coffee = coffeeShop.coffeeShop[index];
                      return ListTile(
                        title: Text(coffee.name),
                        subtitle: Text('\$${coffee.price.toStringAsFixed(2)}'),
                        leading: Image.asset(coffee.imagePath, height: 50),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProduct(coffee),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}