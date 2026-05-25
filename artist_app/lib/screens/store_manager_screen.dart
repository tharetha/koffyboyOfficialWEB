import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../services/api_service.dart';
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
      final response = await ApiService().get('/store/').timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timed out'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _products = data['products'] ?? [];
        });
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load store: $e')));
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
    List<File> selectedImages = [];

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
                        final picked = await picker.pickMultiImage();
                        if (picked.isNotEmpty) {
                          setStateDialog(() {
                            // Max 3 images
                            selectedImages = picked.take(3).map((x) => File(x.path)).toList();
                          });
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
                        child: selectedImages.isNotEmpty
                            ? ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: selectedImages.length,
                                itemBuilder: (ctx, i) => Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(selectedImages[i], width: 110, fit: BoxFit.cover),
                                  ),
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: Colors.white54, size: 32),
                                  SizedBox(height: 8),
                                  Text('Select up to 3 images', style: TextStyle(color: Colors.white54)),
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
                    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty || selectedImages.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide all details and at least one image.')));
                      return;
                    }
                    Navigator.pop(context, {
                      'name': nameCtrl.text,
                      'desc': descCtrl.text,
                      'price': priceCtrl.text,
                      'stock': stockCtrl.text,
                      'category': categoryCtrl.text,
                      'images': selectedImages,
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
          final files = result['images'] as List<File>;
          List<String> uploadedUrls = [];
          
          for (var file in files) {
             final url = await ApiService().uploadFile('/upload/', file.path);
             if (url != null) uploadedUrls.add(url);
          }
          
          if (uploadedUrls.isNotEmpty) {
            final response = await ApiService().post('/artist-mgmt/products', {
              'name': result['name'],
              'description': result['desc'],
              'price': double.tryParse(result['price']) ?? 0.0,
              'stock': int.tryParse(result['stock']) ?? 0,
              'category': result['category'],
              'image_url': uploadedUrls[0], // First image as main
              'images_json': jsonEncode(uploadedUrls), // All images
            });

            if (response.statusCode == 201) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully!')));
              _fetchProducts();
            } else {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add product: ${response.statusCode}')));
            }
          } else {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image. Please check your connection or file size.')));
          }
        } catch (e) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    });
  }

  Future<void> _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final response = await ApiService().delete('/artist-mgmt/products/$id');
        if (response.statusCode == 200) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
          _fetchProducts();
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: ${response.statusCode}')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showEditProductDialog(Map<String, dynamic> product) async {
    final nameCtrl = TextEditingController(text: product['name']);
    final descCtrl = TextEditingController(text: product['description'] ?? '');
    final priceCtrl = TextEditingController(text: product['price'].toString());
    final stockCtrl = TextEditingController(text: product['stock'].toString());
    final categoryCtrl = TextEditingController(text: product['category'] ?? 'Clothing');
    File? selectedImage;
    String? existingImageUrl = product['image_url'];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text('Edit Merch'),
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
                            : existingImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(existingImageUrl!, fit: BoxFit.cover),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, color: Colors.white54, size: 32),
                                      SizedBox(height: 8),
                                      Text('Tap to select main image', style: TextStyle(color: Colors.white54)),
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
                    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide at least a name and price.')));
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
                  child: const Text('Update & Save', style: TextStyle(color: Color(0xFF00E676))),
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
          String? url = existingImageUrl;
          if (result['image'] != null) {
            final file = result['image'] as File;
            url = await ApiService().uploadFile('/upload/', file.path);
          }
          
          final response = await ApiService().patch('/artist-mgmt/products/${product['id']}', {
            'name': result['name'],
            'description': result['desc'],
            'price': double.tryParse(result['price']) ?? 0.0,
            'stock': int.tryParse(result['stock']) ?? 0,
            'category': result['category'],
            'image_url': url,
          });

          if (response.statusCode == 200) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated successfully!')));
            _fetchProducts();
          } else {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update product.')));
          }
        } catch (e) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white54),
                              onPressed: () => _showEditProductDialog(product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProduct(product['id']),
                            ),
                          ],
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
