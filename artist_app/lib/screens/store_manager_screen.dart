import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/firebase_storage_service.dart';
import 'dart:convert';

class StoreManagerScreen extends StatefulWidget {
  const StoreManagerScreen({super.key});

  @override
  State<StoreManagerScreen> createState() => _StoreManagerScreenState();
}

class _StoreManagerScreenState extends State<StoreManagerScreen> {
  bool _isLoading = false;
  List<dynamic> _products = [];
  
  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().get('/store/products');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _products = data['products'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching products: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddProductDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'Clothing');
    File? selectedImage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text('Add New Merch'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setStateDialog(() => selectedImage = File(picked.path));
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(selectedImage!, fit: BoxFit.cover),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: Colors.white54, size: 32),
                                  SizedBox(height: 8),
                                  Text('Tap to select image', style: TextStyle(color: Colors.white54)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Product Name'),
                    ),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 2,
                    ),
                    TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            decoration: const InputDecoration(labelText: 'Price (ZMW)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: stockCtrl,
                            decoration: const InputDecoration(labelText: 'Stock'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty || selectedImage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide all details and an image.')));
                      return;
                    }
                    Navigator.pop(context, {
                      'name': nameCtrl.text,
                      'desc': descCtrl.text,
                      'price': priceCtrl.text,
                      'stock': stockCtrl.text,
                      'category': categoryCtrl.text,
                      'image': selectedImage,
                    });
                  },
                  child: const Text('Upload & Save', style: TextStyle(color: Color(0xFF00E676))),
                ),
              ],
            );
          }
        );
      },
    ).then((result) async {
      if (result != null) {
        setState(() => _isLoading = true);
        try {
          final file = result['image'] as File;
          final url = await FirebaseStorageService().uploadFile(file, 'store_products');
          
          if (url != null) {
            final response = await ApiService().post('/artist-mgmt/products', {
              'name': result['name'],
              'description': result['desc'],
              'price': double.tryParse(result['price']) ?? 0.0,
              'stock': int.tryParse(result['stock']) ?? 0,
              'category': result['category'],
              'image_url': url,
            });

            if (response.statusCode == 201) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully!')));
              _fetchProducts();
            } else {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add product to backend.')));
            }
          }
        } catch (e) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 80.0), // Above nav bar
            child: FloatingActionButton.extended(
              onPressed: _showAddProductDialog,
              backgroundColor: const Color(0xFF00E676),
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Add Merch', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
          body: _products.isEmpty && !_isLoading
              ? const Center(child: Text('Your store is empty. Add some merch!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0).copyWith(bottom: 120),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                            image: product['image_url'] != null
                                ? DecorationImage(image: NetworkImage(product['image_url']), fit: BoxFit.cover)
                                : null,
                          ),
                          child: product['image_url'] == null ? const Icon(Icons.shopping_bag, color: Colors.white24) : null,
                        ),
                        title: Text(product['name'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('ZMW ${product['price']} • Stock: ${product['stock']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white54),
                          onPressed: () {
                            // TODO: Edit product
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
          ),
      ],
    );
  }
}
