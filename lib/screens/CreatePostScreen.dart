import 'dart:io';

import 'package:flutter/material.dart';
import 'package:YemPover_app/models/ProductPost.dart';
import 'package:YemPover_app/utils/image_picker_utils.dart';
import 'package:YemPover_app/widgets/coin_icon.dart';
import 'package:YemPover_app/widgets/app_text_field.dart';

class CreatePostScreen extends StatefulWidget {
  final Function(UserItem) onPostCreated;

  const CreatePostScreen({super.key, required this.onPostCreated});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  List<File> _selectedImages = [];
  bool _isClubbable = true;
  bool _isLoading = false;

  final List<String> _categories = [
    'Electronics',
    'Furniture',
    'Sports',
    'Home Appliance',
    'Clothing',
    'Books',
    'Vehicles',
    'Services',
    'Other',
  ];

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final newItem = UserItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _titleController.text,
      category: _categoryController.text,
      imageUrl: 'https://via.placeholder.com/150', // Placeholder
      isClubbable: _isClubbable,
      isFromExistingPost: false,
      price: _priceController.text.isNotEmpty
          ? '${_priceController.text} coins'
          : null,
      description: _descriptionController.text,
    );

    widget.onPostCreated(newItem);

    setState(() => _isLoading = false);

    Navigator.pop(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Post created successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _createPost,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Upload Section
                    const Text(
                      'Images',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ImageUploadWidget(
                      onImagesSelected: (images) {
                        setState(() {
                          _selectedImages = images;
                        });
                      },
                      maxImages: 10,
                      allowMultiple: true,
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _titleController,
                      decoration: AppInputDecoration.build(
                        label: 'Title',
                        hint: 'Enter post title',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _categoryController.text.isEmpty
                          ? null
                          : _categoryController.text,
                      decoration: AppInputDecoration.build(
                        label: 'Category',
                        hint: 'Select category',
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _categoryController.text = value;
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: AppInputDecoration.build(
                        label: 'Description',
                        hint: 'Describe your item...',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: AppInputDecoration.build(
                        label: 'Price (optional)',
                        hint: 'Enter price',
                        prefixIcon: coinInputPrefix(),
                        prefixIconConstraints: coinPrefixIconConstraints,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Clubbable Option
                    Row(
                      children: [
                        Checkbox(
                          value: _isClubbable,
                          onChanged: (value) {
                            setState(() {
                              _isClubbable = value ?? true;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Can be clubbed with other items',
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Allow this item to be included in multi-item offers',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Create Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createPost,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Create Post'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
