// // // import 'package:flutter/material.dart';
// // // import 'package:image_picker/image_picker.dart';
// // // import '../models/my_post_model.dart';
// // // import '../models/edit_product_model.dart';
// // // import '../services/my_posts_service.dart';

// // // class EditProductScreen extends StatefulWidget {
// // //   final MyPost post;
// // //   final Function() onProductUpdated;

// // //   const EditProductScreen({
// // //     super.key,
// // //     required this.post,
// // //     required this.onProductUpdated,
// // //   });

// // //   @override
// // //   State<EditProductScreen> createState() => _EditProductScreenState();
// // // }

// // // class _EditProductScreenState extends State<EditProductScreen> {
// // //   final _formKey = GlobalKey<FormState>();
// // //   final MyPostsService _postsService = MyPostsService();
// // //   final ImagePicker _imagePicker = ImagePicker();

// // //   late TextEditingController _titleController;
// // //   late TextEditingController _descriptionController;
// // //   late TextEditingController _priceController;
// // //   late TextEditingController _locationController;

// // //   late String _selectedStatus;
// // //   late String _selectedBarterStatus;
// // //   late String _selectedCategoryId;
// // //   late bool _isListed;
// // //   late List<String> _images;

// // //   bool _isSaving = false;
// // //   bool _isLoading = false;

// // //   // Categories - you might want to fetch these from API
// // //   final List<Map<String, dynamic>> _categories = [
// // //     {'id': 'cmllqhpef000ep07k34otpoi6', 'name': 'Laptops', 'type': 'product'},
// // //     {
// // //       'id': 'cmllqhn130004p07kqgyqcqev',
// // //       'name': 'Electronics',
// // //       'type': 'product',
// // //     },
// // //     // Add more categories as needed
// // //   ];

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _initializeControllers();
// // //   }

// // //   void _initializeControllers() {
// // //     _titleController = TextEditingController(text: widget.post.title);
// // //     _descriptionController = TextEditingController(
// // //       text: widget.post.description,
// // //     );
// // //     _priceController = TextEditingController(
// // //       text: widget.post.price != null ? widget.post.price.toString() : '',
// // //     );
// // //     _locationController = TextEditingController(
// // //       text: widget.post.location ?? '',
// // //     );

// // //     _selectedStatus = widget.post.status;
// // //     _selectedBarterStatus = widget.post.barterStatus;
// // //     _selectedCategoryId = widget.post.categoryId;
// // //     _isListed = widget.post.isListed;
// // //     _images = List.from(widget.post.images);
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _titleController.dispose();
// // //     _descriptionController.dispose();
// // //     _priceController.dispose();
// // //     _locationController.dispose();
// // //     // _postsService.dispose();
// // //     super.dispose();
// // //   }

// // //   Future<void> _pickImage() async {
// // //     try {
// // //       final XFile? image = await _imagePicker.pickImage(
// // //         source: ImageSource.gallery,
// // //         maxWidth: 1024,
// // //         maxHeight: 1024,
// // //         imageQuality: 85,
// // //       );

// // //       if (image != null) {
// // //         setState(() {
// // //           _isLoading = true;
// // //         });

// // //         // TODO: Implement actual image upload to your server
// // //         // For now, we'll use a placeholder or the existing image URL pattern
// // //         final String imageUrl =
// // //             'https://yempover-barter-image-store.s3.us-east-1.amazonaws.com/posts/${DateTime.now().millisecondsSinceEpoch}.jpg';

// // //         setState(() {
// // //           _images.add(imageUrl);
// // //           _isLoading = false;
// // //         });

// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(
// // //             content: Text(
// // //               'Image selected. In production, this would be uploaded.',
// // //             ),
// // //             backgroundColor: Colors.blue,
// // //           ),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       setState(() {
// // //         _isLoading = false;
// // //       });
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text('Failed to pick image: $e'),
// // //           backgroundColor: Colors.red,
// // //         ),
// // //       );
// // //     }
// // //   }

// // //   void _removeImage(int index) {
// // //     setState(() {
// // //       _images.removeAt(index);
// // //     });
// // //   }

// // //   Future<void> _saveChanges() async {
// // //     if (!_formKey.currentState!.validate()) {
// // //       return;
// // //     }

// // //     setState(() {
// // //       _isSaving = true;
// // //     });

// // //     try {
// // //       final request = EditProductRequest(
// // //         title: _titleController.text.trim(),
// // //         description: _descriptionController.text.trim(),
// // //         images: _images,
// // //         status: _selectedStatus,
// // //         barterStatus: _selectedBarterStatus,
// // //         price: _priceController.text.isNotEmpty
// // //             ? double.parse(_priceController.text)
// // //             : null,
// // //         categoryId: _selectedCategoryId,
// // //         location: _locationController.text.trim().isNotEmpty
// // //             ? _locationController.text.trim()
// // //             : null,
// // //         isListed: _isListed,
// // //       );

// // //       // Use your existing updatePost method
// // //       final response = await _postsService.updatePost(
// // //         widget.post.id,
// // //         request.toJson(),
// // //       );

// // //       if (!mounted) return;

// // //       if (response.status == 'success') {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(
// // //             content: Text(response.message ?? 'Product updated successfully'),
// // //             backgroundColor: Colors.green,
// // //           ),
// // //         );
// // //         widget.onProductUpdated();
// // //         Navigator.pop(context, true);
// // //       } else {
// // //         throw Exception(response.message ?? 'Update failed');
// // //       }
// // //     } catch (e) {
// // //       if (!mounted) return;

// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text('Failed to update product: ${e.toString()}'),
// // //           backgroundColor: Colors.red,
// // //         ),
// // //       );
// // //     } finally {
// // //       if (mounted) {
// // //         setState(() {
// // //           _isSaving = false;
// // //         });
// // //       }
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       resizeToAvoidBottomInset: true,
// // //       backgroundColor: Colors.grey[100],
// // //       appBar: AppBar(
// // //         title: const Text(
// // //           'Edit Product',
// // //           style: TextStyle(fontWeight: FontWeight.bold),
// // //         ),
// // //         centerTitle: true,
// // //         elevation: 0,
// // //         backgroundColor: Colors.white,
// // //         foregroundColor: Colors.black,
// // //         actions: [
// // //           TextButton(
// // //             onPressed: _isSaving ? null : _saveChanges,
// // //             child: Text(
// // //               'Save',
// // //               style: TextStyle(
// // //                 color: _isSaving ? Colors.grey : Colors.blue,
// // //                 fontSize: 16,
// // //                 fontWeight: FontWeight.w600,
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //       body: SafeArea(
// // //         child: _isLoading
// // //             ? const Center(child: CircularProgressIndicator())
// // //             : Form(
// // //                 key: _formKey,
// // //                 child: SingleChildScrollView(
// // //                   padding: EdgeInsets.fromLTRB(
// // //                     16,
// // //                     16,
// // //                     16,
// // //                     MediaQuery.of(context).viewInsets.bottom +
// // //                         MediaQuery.of(context).padding.bottom +
// // //                         20,
// // //                   ),
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                     children: [
// // //                       // Images Section
// // //                       _buildImagesSection(),

// // //                       const SizedBox(height: 20),

// // //                       _buildTextField(
// // //                         label: 'Title',
// // //                         controller: _titleController,
// // //                         validator: (value) {
// // //                           if (value == null || value.isEmpty) {
// // //                             return 'Please enter a title';
// // //                           }
// // //                           return null;
// // //                         },
// // //                       ),

// // //                       const SizedBox(height: 16),

// // //                       _buildTextField(
// // //                         label: 'Description',
// // //                         controller: _descriptionController,
// // //                         maxLines: 4,
// // //                         validator: (value) {
// // //                           if (value == null || value.isEmpty) {
// // //                             return 'Please enter a description';
// // //                           }
// // //                           return null;
// // //                         },
// // //                       ),

// // //                       const SizedBox(height: 16),

// // //                       _buildDropdownField(
// // //                         label: 'Category',
// // //                         value: _selectedCategoryId,
// // //                         items: _categories.map<DropdownMenuItem<String>>((
// // //                           category,
// // //                         ) {
// // //                           return DropdownMenuItem(
// // //                             value: category['id'] as String,
// // //                             child: Text(category['name']),
// // //                           );
// // //                         }).toList(),
// // //                         onChanged: (value) {
// // //                           setState(() {
// // //                             _selectedCategoryId = value.toString();
// // //                           });
// // //                         },
// // //                       ),

// // //                       const SizedBox(height: 16),

// // //                       _buildTextField(
// // //                         label: 'Price',
// // //                         controller: _priceController,
// // //                         keyboardType: TextInputType.number,
// // //                         prefix: '\$ ',
// // //                       ),

// // //                       const SizedBox(height: 16),

// // //                       _buildDropdownField(
// // //                         label: 'Status',
// // //                         value: _selectedStatus,
// // //                         items: const [
// // //                           DropdownMenuItem(
// // //                             value: 'FOR_SALE',
// // //                             child: Text('For Sale'),
// // //                           ),
// // //                           DropdownMenuItem(value: 'SOLD', child: Text('Sold')),
// // //                         ],
// // //                         onChanged: (value) {
// // //                           setState(() {
// // //                             _selectedStatus = value.toString();
// // //                           });
// // //                         },
// // //                       ),

// // //                       const SizedBox(height: 16),

// // //                       _buildDropdownField(
// // //                         label: 'Barter Status',
// // //                         value: _selectedBarterStatus,
// // //                         items: const [
// // //                           DropdownMenuItem(
// // //                             value: 'NO_BARTER',
// // //                             child: Text('No Barter'),
// // //                           ),
// // //                           DropdownMenuItem(
// // //                             value: 'BARTER',
// // //                             child: Text('Open for Barter'),
// // //                           ),
// // //                         ],
// // //                         onChanged: (value) {
// // //                           setState(() {
// // //                             _selectedBarterStatus = value.toString();
// // //                           });
// // //                         },
// // //                       ),

// // //                       const SizedBox(height: 16),

// // //                       _buildTextField(
// // //                         label: 'Location (Optional)',
// // //                         controller: _locationController,
// // //                         maxLines: 2,
// // //                       ),

// // //                       const SizedBox(height: 16),

// // //                       // Listed Switch
// // //                       Container(
// // //                         padding: const EdgeInsets.all(16),
// // //                         decoration: BoxDecoration(
// // //                           color: Colors.white,
// // //                           borderRadius: BorderRadius.circular(12),
// // //                           boxShadow: [
// // //                             BoxShadow(
// // //                               color: Colors.black.withOpacity(0.05),
// // //                               blurRadius: 8,
// // //                               offset: const Offset(0, 2),
// // //                             ),
// // //                           ],
// // //                         ),
// // //                         child: Row(
// // //                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                           children: [
// // //                             const Text(
// // //                               'Listed Publicly',
// // //                               style: TextStyle(
// // //                                 fontSize: 16,
// // //                                 fontWeight: FontWeight.w500,
// // //                               ),
// // //                             ),
// // //                             Switch(
// // //                               value: _isListed,
// // //                               onChanged: (value) {
// // //                                 setState(() {
// // //                                   _isListed = value;
// // //                                 });
// // //                               },
// // //                               activeColor: Colors.blue,
// // //                             ),
// // //                           ],
// // //                         ),
// // //                       ),

// // //                       const SizedBox(height: 30),

// // //                       // Save Button
// // //                       SizedBox(
// // //                         width: double.infinity,
// // //                         height: 50,
// // //                         child: ElevatedButton(
// // //                           onPressed: _isSaving ? null : _saveChanges,
// // //                           style: ElevatedButton.styleFrom(
// // //                             backgroundColor: Colors.blue,
// // //                             foregroundColor: Colors.white,
// // //                             shape: RoundedRectangleBorder(
// // //                               borderRadius: BorderRadius.circular(8),
// // //                             ),
// // //                           ),
// // //                           child: _isSaving
// // //                               ? const SizedBox(
// // //                                   height: 20,
// // //                                   width: 20,
// // //                                   child: CircularProgressIndicator(
// // //                                     color: Colors.white,
// // //                                     strokeWidth: 2,
// // //                                   ),
// // //                                 )
// // //                               : const Text(
// // //                                   'Save Changes',
// // //                                   style: TextStyle(
// // //                                     fontSize: 16,
// // //                                     fontWeight: FontWeight.bold,
// // //                                   ),
// // //                                 ),
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //               ),
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildImagesSection() {
// // //     return Container(
// // //       padding: const EdgeInsets.all(16),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(12),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Colors.black.withOpacity(0.05),
// // //             blurRadius: 8,
// // //             offset: const Offset(0, 2),
// // //           ),
// // //         ],
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           const Text(
// // //             'Images',
// // //             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
// // //           ),
// // //           const SizedBox(height: 12),
// // //           SizedBox(
// // //             height: 100,
// // //             child: ListView.builder(
// // //               scrollDirection: Axis.horizontal,
// // //               itemCount: _images.length + 1,
// // //               itemBuilder: (context, index) {
// // //                 if (index == _images.length) {
// // //                   return _buildAddImageButton();
// // //                 }
// // //                 return _buildImageItem(index);
// // //               },
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildImageItem(int index) {
// // //     return Container(
// // //       width: 100,
// // //       height: 100,
// // //       margin: const EdgeInsets.only(right: 8),
// // //       decoration: BoxDecoration(
// // //         borderRadius: BorderRadius.circular(8),
// // //         border: Border.all(color: Colors.grey.shade300),
// // //       ),
// // //       child: Stack(
// // //         fit: StackFit.expand,
// // //         children: [
// // //           ClipRRect(
// // //             borderRadius: BorderRadius.circular(8),
// // //             child: Image.network(
// // //               _images[index],
// // //               fit: BoxFit.cover,
// // //               errorBuilder: (context, error, stackTrace) {
// // //                 return Container(
// // //                   color: Colors.grey[200],
// // //                   child: const Icon(Icons.broken_image, color: Colors.grey),
// // //                 );
// // //               },
// // //             ),
// // //           ),
// // //           Positioned(
// // //             top: 4,
// // //             right: 4,
// // //             child: GestureDetector(
// // //               onTap: () => _removeImage(index),
// // //               child: Container(
// // //                 padding: const EdgeInsets.all(4),
// // //                 decoration: const BoxDecoration(
// // //                   color: Colors.red,
// // //                   shape: BoxShape.circle,
// // //                 ),
// // //                 child: const Icon(Icons.close, size: 16, color: Colors.white),
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildAddImageButton() {
// // //     return GestureDetector(
// // //       onTap: _pickImage,
// // //       child: Container(
// // //         width: 100,
// // //         height: 100,
// // //         margin: const EdgeInsets.only(right: 8),
// // //         decoration: BoxDecoration(
// // //           color: Colors.grey[100],
// // //           borderRadius: BorderRadius.circular(8),
// // //           border: Border.all(
// // //             color: Colors.grey.shade300,
// // //             style: BorderStyle.solid,
// // //           ),
// // //         ),
// // //         child: Column(
// // //           mainAxisAlignment: MainAxisAlignment.center,
// // //           children: [
// // //             Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[600]),
// // //             const SizedBox(height: 4),
// // //             Text(
// // //               'Add Image',
// // //               style: TextStyle(fontSize: 12, color: Colors.grey[600]),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildTextField({
// // //     required String label,
// // //     required TextEditingController controller,
// // //     int maxLines = 1,
// // //     TextInputType? keyboardType,
// // //     String? prefix,
// // //     String? Function(String?)? validator,
// // //   }) {
// // //     return Container(
// // //       padding: const EdgeInsets.all(16),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(12),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Colors.black.withOpacity(0.05),
// // //             blurRadius: 8,
// // //             offset: const Offset(0, 2),
// // //           ),
// // //         ],
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Text(
// // //             label,
// // //             style: const TextStyle(
// // //               fontSize: 14,
// // //               fontWeight: FontWeight.w600,
// // //               color: Colors.grey,
// // //             ),
// // //           ),
// // //           const SizedBox(height: 8),
// // //           TextFormField(
// // //             controller: controller,
// // //             maxLines: maxLines,
// // //             keyboardType: keyboardType,
// // //             validator: validator,
// // //             decoration: InputDecoration(
// // //               prefixText: prefix,
// // //               border: OutlineInputBorder(
// // //                 borderRadius: BorderRadius.circular(8),
// // //                 borderSide: BorderSide(color: Colors.grey.shade300),
// // //               ),
// // //               enabledBorder: OutlineInputBorder(
// // //                 borderRadius: BorderRadius.circular(8),
// // //                 borderSide: BorderSide(color: Colors.grey.shade300),
// // //               ),
// // //               focusedBorder: OutlineInputBorder(
// // //                 borderRadius: BorderRadius.circular(8),
// // //                 borderSide: const BorderSide(color: Colors.blue, width: 2),
// // //               ),
// // //               contentPadding: const EdgeInsets.symmetric(
// // //                 horizontal: 12,
// // //                 vertical: 12,
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildDropdownField({
// // //     required String label,
// // //     required String? value,
// // //     required List<DropdownMenuItem<String>> items,
// // //     required Function(String?) onChanged,
// // //   }) {
// // //     return Container(
// // //       padding: const EdgeInsets.all(16),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(12),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Colors.black.withOpacity(0.05),
// // //             blurRadius: 8,
// // //             offset: const Offset(0, 2),
// // //           ),
// // //         ],
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Text(
// // //             label,
// // //             style: const TextStyle(
// // //               fontSize: 14,
// // //               fontWeight: FontWeight.w600,
// // //               color: Colors.grey,
// // //             ),
// // //           ),
// // //           const SizedBox(height: 8),
// // //           DropdownButtonFormField<String>(
// // //             value: value,
// // //             items: items,
// // //             onChanged: onChanged,
// // //             decoration: InputDecoration(
// // //               border: OutlineInputBorder(
// // //                 borderRadius: BorderRadius.circular(8),
// // //                 borderSide: BorderSide(color: Colors.grey.shade300),
// // //               ),
// // //               enabledBorder: OutlineInputBorder(
// // //                 borderRadius: BorderRadius.circular(8),
// // //                 borderSide: BorderSide(color: Colors.grey.shade300),
// // //               ),
// // //               focusedBorder: OutlineInputBorder(
// // //                 borderRadius: BorderRadius.circular(8),
// // //                 borderSide: const BorderSide(color: Colors.blue, width: 2),
// // //               ),
// // //               contentPadding: const EdgeInsets.symmetric(
// // //                 horizontal: 12,
// // //                 vertical: 4,
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:image_picker/image_picker.dart';
// // import '../models/my_post_model.dart';
// // import '../models/edit_product_model.dart';
// // import '../services/my_posts_service.dart';

// // class EditProductScreen extends StatefulWidget {
// //   final MyPost post;
// //   final Function() onProductUpdated;

// //   const EditProductScreen({
// //     super.key,
// //     required this.post,
// //     required this.onProductUpdated,
// //   });

// //   @override
// //   State<EditProductScreen> createState() => _EditProductScreenState();
// // }

// // class _EditProductScreenState extends State<EditProductScreen> {
// //   final _formKey = GlobalKey<FormState>();
// //   final MyPostsService _postsService = MyPostsService();
// //   final ImagePicker _imagePicker = ImagePicker();

// //   late TextEditingController _titleController;
// //   late TextEditingController _descriptionController;
// //   late TextEditingController _priceController;
// //   late TextEditingController _locationController;

// //   late String _selectedStatus;
// //   late String _selectedBarterStatus;
// //   late String _selectedCategoryId;
// //   late bool _isListed;
// //   late List<String> _images;

// //   bool _isSaving = false;
// //   bool _isLoading = false;

// //   // Categories - you might want to fetch these from API
// //   final List<Map<String, dynamic>> _categories = [
// //     {'id': 'cmllqhpef000ep07k34otpoi6', 'name': 'Laptops', 'type': 'product'},
// //     {
// //       'id': 'cmllqhn130004p07kqgyqcqev',
// //       'name': 'Electronics',
// //       'type': 'product',
// //     },
// //     // Add more categories as needed
// //   ];

// //   @override
// //   void initState() {
// //     super.initState();
// //     _initializeControllers();
// //   }

// //   void _initializeControllers() {
// //     _titleController = TextEditingController(text: widget.post.title);
// //     _descriptionController = TextEditingController(
// //       text: widget.post.description,
// //     );
// //     _priceController = TextEditingController(
// //       text: widget.post.price != null ? widget.post.price.toString() : '',
// //     );
// //     _locationController = TextEditingController(
// //       text: widget.post.location ?? '',
// //     );

// //     _selectedStatus = widget.post.status;
// //     _selectedBarterStatus = widget.post.barterStatus;
// //     _selectedCategoryId = widget.post.categoryId;
// //     _isListed = widget.post.isListed;
// //     _images = List.from(widget.post.images);

// //     // Check if the current category ID exists in the categories list
// //     // If not, we'll set it to null initially
// //     _validateCategoryId();
// //   }

// //   void _validateCategoryId() {
// //     // Check if the current category ID exists in the categories list
// //     final categoryExists = _categories.any(
// //       (category) => category['id'] == _selectedCategoryId,
// //     );

// //     // If the category doesn't exist, set it to null (will show hint)
// //     if (!categoryExists) {
// //       _selectedCategoryId = '';
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     _titleController.dispose();
// //     _descriptionController.dispose();
// //     _priceController.dispose();
// //     _locationController.dispose();
// //     super.dispose();
// //   }

// //   Future<void> _pickImage() async {
// //     try {
// //       final XFile? image = await _imagePicker.pickImage(
// //         source: ImageSource.gallery,
// //         maxWidth: 1024,
// //         maxHeight: 1024,
// //         imageQuality: 85,
// //       );

// //       if (image != null) {
// //         setState(() {
// //           _isLoading = true;
// //         });

// //         // TODO: Implement actual image upload to your server
// //         // For now, we'll use a placeholder or the existing image URL pattern
// //         final String imageUrl =
// //             'https://yempover-barter-image-store.s3.us-east-1.amazonaws.com/posts/${DateTime.now().millisecondsSinceEpoch}.jpg';

// //         setState(() {
// //           _images.add(imageUrl);
// //           _isLoading = false;
// //         });

// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text(
// //               'Image selected. In production, this would be uploaded.',
// //             ),
// //             backgroundColor: Colors.blue,
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       setState(() {
// //         _isLoading = false;
// //       });
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Failed to pick image: $e'),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //     }
// //   }

// //   void _removeImage(int index) {
// //     setState(() {
// //       _images.removeAt(index);
// //     });
// //   }

// //   Future<void> _saveChanges() async {
// //     if (!_formKey.currentState!.validate()) {
// //       return;
// //     }

// //     // Validate category selection
// //     if (_selectedCategoryId.isEmpty) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text('Please select a category'),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //       return;
// //     }

// //     setState(() {
// //       _isSaving = true;
// //     });

// //     try {
// //       final request = EditProductRequest(
// //         title: _titleController.text.trim(),
// //         description: _descriptionController.text.trim(),
// //         images: _images,
// //         status: _selectedStatus,
// //         barterStatus: _selectedBarterStatus,
// //         price: _priceController.text.isNotEmpty
// //             ? double.parse(_priceController.text)
// //             : null,
// //         categoryId: _selectedCategoryId,
// //         location: _locationController.text.trim().isNotEmpty
// //             ? _locationController.text.trim()
// //             : null,
// //         isListed: _isListed,
// //       );

// //       final response = await _postsService.updatePost(
// //         widget.post.id,
// //         request.toJson(),
// //       );

// //       if (!mounted) return;

// //       if (response.status == 'success') {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(response.message ?? 'Product updated successfully'),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //         widget.onProductUpdated();
// //         Navigator.pop(context, true);
// //       } else {
// //         throw Exception(response.message ?? 'Update failed');
// //       }
// //     } catch (e) {
// //       if (!mounted) return;

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Failed to update product: ${e.toString()}'),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //     } finally {
// //       if (mounted) {
// //         setState(() {
// //           _isSaving = false;
// //         });
// //       }
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       resizeToAvoidBottomInset: true,
// //       backgroundColor: Colors.grey[100],
// //       appBar: AppBar(
// //         title: const Text(
// //           'Edit Product',
// //           style: TextStyle(fontWeight: FontWeight.bold),
// //         ),
// //         centerTitle: true,
// //         elevation: 0,
// //         backgroundColor: Colors.white,
// //         foregroundColor: Colors.black,
// //         actions: [
// //           TextButton(
// //             onPressed: _isSaving ? null : _saveChanges,
// //             child: Text(
// //               'Save',
// //               style: TextStyle(
// //                 color: _isSaving ? Colors.grey : Colors.blue,
// //                 fontSize: 16,
// //                 fontWeight: FontWeight.w600,
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //       body: SafeArea(
// //         child: _isLoading
// //             ? const Center(child: CircularProgressIndicator())
// //             : Form(
// //                 key: _formKey,
// //                 child: SingleChildScrollView(
// //                   padding: EdgeInsets.fromLTRB(
// //                     16,
// //                     16,
// //                     16,
// //                     MediaQuery.of(context).viewInsets.bottom +
// //                         MediaQuery.of(context).padding.bottom +
// //                         20,
// //                   ),
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       // Images Section
// //                       _buildImagesSection(),

// //                       const SizedBox(height: 20),

// //                       _buildTextField(
// //                         label: 'Title',
// //                         controller: _titleController,
// //                         validator: (value) {
// //                           if (value == null || value.isEmpty) {
// //                             return 'Please enter a title';
// //                           }
// //                           return null;
// //                         },
// //                       ),

// //                       const SizedBox(height: 16),

// //                       _buildTextField(
// //                         label: 'Description',
// //                         controller: _descriptionController,
// //                         maxLines: 4,
// //                         validator: (value) {
// //                           if (value == null || value.isEmpty) {
// //                             return 'Please enter a description';
// //                           }
// //                           return null;
// //                         },
// //                       ),

// //                       const SizedBox(height: 16),

// //                       _buildDropdownField(
// //                         label: 'Category',
// //                         value: _selectedCategoryId.isEmpty
// //                             ? null
// //                             : _selectedCategoryId,
// //                         items: _categories.map<DropdownMenuItem<String>>((
// //                           category,
// //                         ) {
// //                           return DropdownMenuItem(
// //                             value: category['id'] as String,
// //                             child: Text(category['name']),
// //                           );
// //                         }).toList(),
// //                         onChanged: (value) {
// //                           setState(() {
// //                             _selectedCategoryId = value.toString();
// //                           });
// //                         },
// //                         hint: 'Select a category',
// //                       ),

// //                       const SizedBox(height: 16),

// //                       _buildTextField(
// //                         label: 'Price',
// //                         controller: _priceController,
// //                         keyboardType: TextInputType.number,
// //                         prefix: '\$ ',
// //                       ),

// //                       const SizedBox(height: 16),

// //                       _buildDropdownField(
// //                         label: 'Status',
// //                         value: _selectedStatus,
// //                         items: const [
// //                           DropdownMenuItem(
// //                             value: 'FOR_SALE',
// //                             child: Text('For Sale'),
// //                           ),
// //                           DropdownMenuItem(value: 'SOLD', child: Text('Sold')),
// //                         ],
// //                         onChanged: (value) {
// //                           setState(() {
// //                             _selectedStatus = value.toString();
// //                           });
// //                         },
// //                       ),

// //                       const SizedBox(height: 16),

// //                       _buildDropdownField(
// //                         label: 'Barter Status',
// //                         value: _selectedBarterStatus,
// //                         items: const [
// //                           DropdownMenuItem(
// //                             value: 'NO_BARTER',
// //                             child: Text('No Barter'),
// //                           ),
// //                           DropdownMenuItem(
// //                             value: 'BARTER',
// //                             child: Text('Open for Barter'),
// //                           ),
// //                         ],
// //                         onChanged: (value) {
// //                           setState(() {
// //                             _selectedBarterStatus = value.toString();
// //                           });
// //                         },
// //                       ),

// //                       const SizedBox(height: 16),

// //                       _buildTextField(
// //                         label: 'Location (Optional)',
// //                         controller: _locationController,
// //                         maxLines: 2,
// //                       ),

// //                       const SizedBox(height: 16),

// //                       // Listed Switch
// //                       Container(
// //                         padding: const EdgeInsets.all(16),
// //                         decoration: BoxDecoration(
// //                           color: Colors.white,
// //                           borderRadius: BorderRadius.circular(12),
// //                           boxShadow: [
// //                             BoxShadow(
// //                               color: Colors.black.withOpacity(0.05),
// //                               blurRadius: 8,
// //                               offset: const Offset(0, 2),
// //                             ),
// //                           ],
// //                         ),
// //                         child: Row(
// //                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                           children: [
// //                             const Text(
// //                               'Listed Publicly',
// //                               style: TextStyle(
// //                                 fontSize: 16,
// //                                 fontWeight: FontWeight.w500,
// //                               ),
// //                             ),
// //                             Switch(
// //                               value: _isListed,
// //                               onChanged: (value) {
// //                                 setState(() {
// //                                   _isListed = value;
// //                                 });
// //                               },
// //                               activeColor: Colors.blue,
// //                             ),
// //                           ],
// //                         ),
// //                       ),

// //                       const SizedBox(height: 30),

// //                       // Save Button
// //                       SizedBox(
// //                         width: double.infinity,
// //                         height: 50,
// //                         child: ElevatedButton(
// //                           onPressed: _isSaving ? null : _saveChanges,
// //                           style: ElevatedButton.styleFrom(
// //                             backgroundColor: Colors.blue,
// //                             foregroundColor: Colors.white,
// //                             shape: RoundedRectangleBorder(
// //                               borderRadius: BorderRadius.circular(8),
// //                             ),
// //                           ),
// //                           child: _isSaving
// //                               ? const SizedBox(
// //                                   height: 20,
// //                                   width: 20,
// //                                   child: CircularProgressIndicator(
// //                                     color: Colors.white,
// //                                     strokeWidth: 2,
// //                                   ),
// //                                 )
// //                               : const Text(
// //                                   'Save Changes',
// //                                   style: TextStyle(
// //                                     fontSize: 16,
// //                                     fontWeight: FontWeight.bold,
// //                                   ),
// //                                 ),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //       ),
// //     );
// //   }

// //   Widget _buildImagesSection() {
// //     return Container(
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.05),
// //             blurRadius: 8,
// //             offset: const Offset(0, 2),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           const Text(
// //             'Images',
// //             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
// //           ),
// //           const SizedBox(height: 12),
// //           SizedBox(
// //             height: 100,
// //             child: ListView.builder(
// //               scrollDirection: Axis.horizontal,
// //               itemCount: _images.length + 1,
// //               itemBuilder: (context, index) {
// //                 if (index == _images.length) {
// //                   return _buildAddImageButton();
// //                 }
// //                 return _buildImageItem(index);
// //               },
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildImageItem(int index) {
// //     return Container(
// //       width: 100,
// //       height: 100,
// //       margin: const EdgeInsets.only(right: 8),
// //       decoration: BoxDecoration(
// //         borderRadius: BorderRadius.circular(8),
// //         border: Border.all(color: Colors.grey.shade300),
// //       ),
// //       child: Stack(
// //         fit: StackFit.expand,
// //         children: [
// //           ClipRRect(
// //             borderRadius: BorderRadius.circular(8),
// //             child: Image.network(
// //               _images[index],
// //               fit: BoxFit.cover,
// //               errorBuilder: (context, error, stackTrace) {
// //                 return Container(
// //                   color: Colors.grey[200],
// //                   child: const Icon(Icons.broken_image, color: Colors.grey),
// //                 );
// //               },
// //             ),
// //           ),
// //           Positioned(
// //             top: 4,
// //             right: 4,
// //             child: GestureDetector(
// //               onTap: () => _removeImage(index),
// //               child: Container(
// //                 padding: const EdgeInsets.all(4),
// //                 decoration: const BoxDecoration(
// //                   color: Colors.red,
// //                   shape: BoxShape.circle,
// //                 ),
// //                 child: const Icon(Icons.close, size: 16, color: Colors.white),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildAddImageButton() {
// //     return GestureDetector(
// //       onTap: _pickImage,
// //       child: Container(
// //         width: 100,
// //         height: 100,
// //         margin: const EdgeInsets.only(right: 8),
// //         decoration: BoxDecoration(
// //           color: Colors.grey[100],
// //           borderRadius: BorderRadius.circular(8),
// //           border: Border.all(
// //             color: Colors.grey.shade300,
// //             style: BorderStyle.solid,
// //           ),
// //         ),
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[600]),
// //             const SizedBox(height: 4),
// //             Text(
// //               'Add Image',
// //               style: TextStyle(fontSize: 12, color: Colors.grey[600]),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildTextField({
// //     required String label,
// //     required TextEditingController controller,
// //     int maxLines = 1,
// //     TextInputType? keyboardType,
// //     String? prefix,
// //     String? Function(String?)? validator,
// //   }) {
// //     return Container(
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.05),
// //             blurRadius: 8,
// //             offset: const Offset(0, 2),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Text(
// //             label,
// //             style: const TextStyle(
// //               fontSize: 14,
// //               fontWeight: FontWeight.w600,
// //               color: Colors.grey,
// //             ),
// //           ),
// //           const SizedBox(height: 8),
// //           TextFormField(
// //             controller: controller,
// //             maxLines: maxLines,
// //             keyboardType: keyboardType,
// //             validator: validator,
// //             decoration: InputDecoration(
// //               prefixText: prefix,
// //               border: OutlineInputBorder(
// //                 borderRadius: BorderRadius.circular(8),
// //                 borderSide: BorderSide(color: Colors.grey.shade300),
// //               ),
// //               enabledBorder: OutlineInputBorder(
// //                 borderRadius: BorderRadius.circular(8),
// //                 borderSide: BorderSide(color: Colors.grey.shade300),
// //               ),
// //               focusedBorder: OutlineInputBorder(
// //                 borderRadius: BorderRadius.circular(8),
// //                 borderSide: const BorderSide(color: Colors.blue, width: 2),
// //               ),
// //               contentPadding: const EdgeInsets.symmetric(
// //                 horizontal: 12,
// //                 vertical: 12,
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildDropdownField({
// //     required String label,
// //     required String? value,
// //     required List<DropdownMenuItem<String>> items,
// //     required Function(String?) onChanged,
// //     String? hint,
// //   }) {
// //     return Container(
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.05),
// //             blurRadius: 8,
// //             offset: const Offset(0, 2),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Text(
// //             label,
// //             style: const TextStyle(
// //               fontSize: 14,
// //               fontWeight: FontWeight.w600,
// //               color: Colors.grey,
// //             ),
// //           ),
// //           const SizedBox(height: 8),
// //           DropdownButtonFormField<String>(
// //             value: value,
// //             items: items,
// //             onChanged: onChanged,
// //             hint: hint != null ? Text(hint) : null,
// //             decoration: InputDecoration(
// //               border: OutlineInputBorder(
// //                 borderRadius: BorderRadius.circular(8),
// //                 borderSide: BorderSide(color: Colors.grey.shade300),
// //               ),
// //               enabledBorder: OutlineInputBorder(
// //                 borderRadius: BorderRadius.circular(8),
// //                 borderSide: BorderSide(color: Colors.grey.shade300),
// //               ),
// //               focusedBorder: OutlineInputBorder(
// //                 borderRadius: BorderRadius.circular(8),
// //                 borderSide: const BorderSide(color: Colors.blue, width: 2),
// //               ),
// //               contentPadding: const EdgeInsets.symmetric(
// //                 horizontal: 12,
// //                 vertical: 4,
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import '../models/my_post_model.dart';
// import '../models/edit_product_model.dart';
// import '../services/my_posts_service.dart';

// class EditProductScreen extends StatefulWidget {
//   final MyPost post;
//   final Function() onProductUpdated;

//   const EditProductScreen({
//     super.key,
//     required this.post,
//     required this.onProductUpdated,
//   });

//   @override
//   State<EditProductScreen> createState() => _EditProductScreenState();
// }

// class _EditProductScreenState extends State<EditProductScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final MyPostsService _postsService = MyPostsService();
//   final ImagePicker _imagePicker = ImagePicker();

//   late TextEditingController _titleController;
//   late TextEditingController _descriptionController;
//   late TextEditingController _priceController;
//   late TextEditingController _locationController;

//   late String _selectedStatus;
//   late String _selectedBarterStatus;
//   late String _selectedCategoryId;
//   late String _postType; // Add this to track post type
//   late bool _isListed;
//   late List<String> _images;

//   bool _isSaving = false;
//   bool _isLoading = false;

//   // Categories - you might want to fetch these from API
//   final List<Map<String, dynamic>> _categories = [
//     {'id': 'cmllqhpef000ep07k34otpoi6', 'name': 'Laptops', 'type': 'product'},
//     {
//       'id': 'cmllqhn130004p07kqgyqcqev',
//       'name': 'Electronics',
//       'type': 'product',
//     },
//     // Add more categories as needed
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _initializeControllers();
//   }

//   void _initializeControllers() {
//     _titleController = TextEditingController(text: widget.post.title);
//     _descriptionController = TextEditingController(
//       text: widget.post.description,
//     );
//     _priceController = TextEditingController(
//       text: widget.post.price != null ? widget.post.price.toString() : '',
//     );
//     _locationController = TextEditingController(
//       text: widget.post.location ?? '',
//     );

//     _selectedStatus = widget.post.status;
//     _selectedBarterStatus = widget.post.barterStatus;
//     _selectedCategoryId = widget.post.categoryId;
//     _postType = widget.post.type; // Store the post type
//     _isListed = widget.post.isListed;
//     _images = List.from(widget.post.images);

//     // Check if the current category ID exists in the categories list
//     _validateCategoryId();
//     // Validate status based on post type
//     _validateStatus();
//   }

//   void _validateCategoryId() {
//     // Check if the current category ID exists in the categories list
//     final categoryExists = _categories.any(
//       (category) => category['id'] == _selectedCategoryId,
//     );

//     // If the category doesn't exist, set it to null (will show hint)
//     if (!categoryExists) {
//       _selectedCategoryId = '';
//     }
//   }

//   void _validateStatus() {
//     // Define valid statuses based on post type
//     final validStatuses = _getValidStatuses();

//     // If current status is not in valid statuses, set to default
//     if (!validStatuses.contains(_selectedStatus)) {
//       _selectedStatus = _postType == 'service' ? 'PROVIDE_SERVICE' : 'FOR_SALE';
//     }
//   }

//   List<String> _getValidStatuses() {
//     if (_postType == 'service') {
//       return ['PROVIDE_SERVICE', 'SOLD'];
//     } else {
//       return ['FOR_SALE', 'SOLD'];
//     }
//   }

//   String _getStatusDisplayName(String status) {
//     switch (status) {
//       case 'FOR_SALE':
//         return 'For Sale';
//       case 'PROVIDE_SERVICE':
//         return 'Providing Service';
//       case 'SOLD':
//         return 'Sold';
//       default:
//         return status;
//     }
//   }

//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     _priceController.dispose();
//     _locationController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImage() async {
//     try {
//       final XFile? image = await _imagePicker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1024,
//         maxHeight: 1024,
//         imageQuality: 85,
//       );

//       if (image != null) {
//         setState(() {
//           _isLoading = true;
//         });

//         // TODO: Implement actual image upload to your server
//         final String imageUrl =
//             'https://yempover-barter-image-store.s3.us-east-1.amazonaws.com/posts/${DateTime.now().millisecondsSinceEpoch}.jpg';

//         setState(() {
//           _images.add(imageUrl);
//           _isLoading = false;
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Image selected successfully'),
//             backgroundColor: Colors.blue,
//           ),
//         );
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to pick image: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   void _removeImage(int index) {
//     setState(() {
//       _images.removeAt(index);
//     });
//   }

//   Future<void> _saveChanges() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     // Validate category selection
//     if (_selectedCategoryId.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select a category'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() {
//       _isSaving = true;
//     });

//     try {
//       final request = EditProductRequest(
//         title: _titleController.text.trim(),
//         description: _descriptionController.text.trim(),
//         images: _images,
//         status: _selectedStatus,
//         barterStatus: _selectedBarterStatus,
//         price: _priceController.text.isNotEmpty
//             ? double.parse(_priceController.text)
//             : null,
//         categoryId: _selectedCategoryId,
//         location: _locationController.text.trim().isNotEmpty
//             ? _locationController.text.trim()
//             : null,
//         isListed: _isListed,
//       );

//       final response = await _postsService.updatePost(
//         widget.post.id,
//         request.toJson(),
//       );

//       if (!mounted) return;

//       if (response.status == 'success') {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(response.message ?? 'Product updated successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         widget.onProductUpdated();
//         Navigator.pop(context, true);
//       } else {
//         throw Exception(response.message ?? 'Update failed');
//       }
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to update product: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSaving = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: Text(
//           _postType == 'service' ? 'Edit Service' : 'Edit Product',
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         elevation: 0,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         actions: [
//           TextButton(
//             onPressed: _isSaving ? null : _saveChanges,
//             child: Text(
//               'Save',
//               style: TextStyle(
//                 color: _isSaving ? Colors.grey : Colors.blue,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: _isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : Form(
//                 key: _formKey,
//                 child: SingleChildScrollView(
//                   padding: EdgeInsets.fromLTRB(
//                     16,
//                     16,
//                     16,
//                     MediaQuery.of(context).viewInsets.bottom +
//                         MediaQuery.of(context).padding.bottom +
//                         20,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Post Type Indicator
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         margin: const EdgeInsets.only(bottom: 16),
//                         decoration: BoxDecoration(
//                           color: _postType == 'service'
//                               ? Colors.purple.shade50
//                               : Colors.orange.shade50,
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(
//                             color: _postType == 'service'
//                                 ? Colors.purple.shade200
//                                 : Colors.orange.shade200,
//                           ),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(
//                               _postType == 'service'
//                                   ? Icons.build_circle
//                                   : Icons.shopping_bag,
//                               color: _postType == 'service'
//                                   ? Colors.purple.shade700
//                                   : Colors.orange.shade700,
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     _postType == 'service'
//                                         ? 'Service Post'
//                                         : 'Product Post',
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                       color: _postType == 'service'
//                                           ? Colors.purple.shade700
//                                           : Colors.orange.shade700,
//                                     ),
//                                   ),
//                                   Text(
//                                     _postType == 'service'
//                                         ? 'You are offering a service'
//                                         : 'You are selling a product',
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: _postType == 'service'
//                                           ? Colors.purple.shade600
//                                           : Colors.orange.shade600,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                       // Images Section
//                       _buildImagesSection(),

//                       const SizedBox(height: 20),

//                       _buildTextField(
//                         label: 'Title',
//                         controller: _titleController,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter a title';
//                           }
//                           return null;
//                         },
//                       ),

//                       const SizedBox(height: 16),

//                       _buildTextField(
//                         label: 'Description',
//                         controller: _descriptionController,
//                         maxLines: 4,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter a description';
//                           }
//                           return null;
//                         },
//                       ),

//                       const SizedBox(height: 16),

//                       _buildDropdownField(
//                         label: 'Category',
//                         value: _selectedCategoryId.isEmpty
//                             ? null
//                             : _selectedCategoryId,
//                         items: _categories.map<DropdownMenuItem<String>>((
//                           category,
//                         ) {
//                           return DropdownMenuItem(
//                             value: category['id'] as String,
//                             child: Text(category['name']),
//                           );
//                         }).toList(),
//                         onChanged: (value) {
//                           setState(() {
//                             _selectedCategoryId = value.toString();
//                           });
//                         },
//                         hint: 'Select a category',
//                       ),

//                       const SizedBox(height: 16),

//                       _buildTextField(
//                         label: 'Price',
//                         controller: _priceController,
//                         keyboardType: TextInputType.number,
//                         prefix: '\$ ',
//                         validator: (value) {
//                           if (value != null && value.isNotEmpty) {
//                             if (double.tryParse(value) == null) {
//                               return 'Please enter a valid number';
//                             }
//                           }
//                           return null;
//                         },
//                       ),

//                       const SizedBox(height: 16),

//                       _buildDropdownField(
//                         label: 'Status',
//                         value: _selectedStatus,
//                         items: _getValidStatuses().map((status) {
//                           return DropdownMenuItem(
//                             value: status,
//                             child: Text(_getStatusDisplayName(status)),
//                           );
//                         }).toList(),
//                         onChanged: (value) {
//                           setState(() {
//                             _selectedStatus = value.toString();
//                           });
//                         },
//                       ),

//                       const SizedBox(height: 16),

//                       _buildDropdownField(
//                         label: 'Barter Status',
//                         value: _selectedBarterStatus,
//                         items: const [
//                           DropdownMenuItem(
//                             value: 'NO_BARTER',
//                             child: Text('No Barter'),
//                           ),
//                           DropdownMenuItem(
//                             value: 'BARTER',
//                             child: Text('Open for Barter'),
//                           ),
//                         ],
//                         onChanged: (value) {
//                           setState(() {
//                             _selectedBarterStatus = value.toString();
//                           });
//                         },
//                       ),

//                       const SizedBox(height: 16),

//                       _buildTextField(
//                         label: 'Location (Optional)',
//                         controller: _locationController,
//                         maxLines: 2,
//                       ),

//                       const SizedBox(height: 16),

//                       // Listed Switch
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(12),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.05),
//                               blurRadius: 8,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             const Text(
//                               'Listed Publicly',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                             Switch(
//                               value: _isListed,
//                               onChanged: (value) {
//                                 setState(() {
//                                   _isListed = value;
//                                 });
//                               },
//                               activeColor: Colors.blue,
//                             ),
//                           ],
//                         ),
//                       ),

//                       const SizedBox(height: 30),

//                       // Save Button
//                       SizedBox(
//                         width: double.infinity,
//                         height: 50,
//                         child: ElevatedButton(
//                           onPressed: _isSaving ? null : _saveChanges,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.blue,
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           child: _isSaving
//                               ? const SizedBox(
//                                   height: 20,
//                                   width: 20,
//                                   child: CircularProgressIndicator(
//                                     color: Colors.white,
//                                     strokeWidth: 2,
//                                   ),
//                                 )
//                               : const Text(
//                                   'Save Changes',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//       ),
//     );
//   }

//   Widget _buildImagesSection() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Images',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 12),
//           SizedBox(
//             height: 100,
//             child: ListView.builder(
//               scrollDirection: Axis.horizontal,
//               itemCount: _images.length + 1,
//               itemBuilder: (context, index) {
//                 if (index == _images.length) {
//                   return _buildAddImageButton();
//                 }
//                 return _buildImageItem(index);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildImageItem(int index) {
//     return Container(
//       width: 100,
//       height: 100,
//       margin: const EdgeInsets.only(right: 8),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: Image.network(
//               _images[index],
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) {
//                 return Container(
//                   color: Colors.grey[200],
//                   child: const Icon(Icons.broken_image, color: Colors.grey),
//                 );
//               },
//             ),
//           ),
//           Positioned(
//             top: 4,
//             right: 4,
//             child: GestureDetector(
//               onTap: () => _removeImage(index),
//               child: Container(
//                 padding: const EdgeInsets.all(4),
//                 decoration: const BoxDecoration(
//                   color: Colors.red,
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.close, size: 16, color: Colors.white),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAddImageButton() {
//     return GestureDetector(
//       onTap: _pickImage,
//       child: Container(
//         width: 100,
//         height: 100,
//         margin: const EdgeInsets.only(right: 8),
//         decoration: BoxDecoration(
//           color: Colors.grey[100],
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: Colors.grey.shade300,
//             style: BorderStyle.solid,
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[600]),
//             const SizedBox(height: 4),
//             Text(
//               'Add Image',
//               style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required String label,
//     required TextEditingController controller,
//     int maxLines = 1,
//     TextInputType? keyboardType,
//     String? prefix,
//     String? Function(String?)? validator,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey,
//             ),
//           ),
//           const SizedBox(height: 8),
//           TextFormField(
//             controller: controller,
//             maxLines: maxLines,
//             keyboardType: keyboardType,
//             validator: validator,
//             decoration: InputDecoration(
//               prefixText: prefix,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: Colors.grey.shade300),
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: Colors.grey.shade300),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: const BorderSide(color: Colors.blue, width: 2),
//               ),
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 12,
//                 vertical: 12,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDropdownField({
//     required String label,
//     required String? value,
//     required List<DropdownMenuItem<String>> items,
//     required Function(String?) onChanged,
//     String? hint,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey,
//             ),
//           ),
//           const SizedBox(height: 8),
//           DropdownButtonFormField<String>(
//             value: value,
//             items: items,
//             onChanged: onChanged,
//             hint: hint != null ? Text(hint) : null,
//             decoration: InputDecoration(
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: Colors.grey.shade300),
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: Colors.grey.shade300),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: const BorderSide(color: Colors.blue, width: 2),
//               ),
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 12,
//                 vertical: 4,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/my_post_model.dart';
import '../models/edit_product_model.dart';
import '../services/my_posts_service.dart';

class EditProductScreen extends StatefulWidget {
  final MyPost post;
  final Function() onProductUpdated;

  const EditProductScreen({
    super.key,
    required this.post,
    required this.onProductUpdated,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final MyPostsService _postsService = MyPostsService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;

  late String _selectedStatus;
  late String _selectedBarterStatus;
  late String _selectedCategoryId;
  late String _postType;
  late bool _isListed;
  late List<String> _images;

  bool _isSaving = false;
  bool _isLoading = false;

  // Categories - you might want to fetch these from API
  final List<Map<String, dynamic>> _categories = [
    {'id': 'cmllqhpef000ep07k34otpoi6', 'name': 'Laptops', 'type': 'product'},
    {
      'id': 'cmllqhn130004p07kqgyqcqev',
      'name': 'Electronics',
      'type': 'product',
    },
    // Add service categories
    {'id': 'cmllqhoou000bp07ky2y8hgpa', 'name': 'Education', 'type': 'service'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: widget.post.title);
    _descriptionController = TextEditingController(
      text: widget.post.description,
    );
    _priceController = TextEditingController(
      text: widget.post.price != null ? widget.post.price.toString() : '',
    );
    _locationController = TextEditingController(
      text: widget.post.location ?? '',
    );

    _selectedStatus = widget.post.status;
    _selectedBarterStatus = widget.post.barterStatus;
    _selectedCategoryId = widget.post.categoryId;
    _postType = widget.post.type;
    _isListed = widget.post.isListed;
    _images = List.from(widget.post.images);

    _validateCategoryId();
    _validateStatus();
  }

  void _validateCategoryId() {
    final categoryExists = _categories.any(
      (category) => category['id'] == _selectedCategoryId,
    );

    if (!categoryExists) {
      _selectedCategoryId = '';
    }
  }

  void _validateStatus() {
    final validStatuses = _getValidStatuses();

    if (!validStatuses.contains(_selectedStatus)) {
      _selectedStatus = _postType == 'service' ? 'PROVIDE_SERVICE' : 'FOR_SALE';
    }
  }

  List<String> _getValidStatuses() {
    if (_postType == 'service') {
      return ['PROVIDE_SERVICE', 'SOLD'];
    } else {
      return ['FOR_SALE', 'SOLD'];
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'FOR_SALE':
        return 'For Sale';
      case 'PROVIDE_SERVICE':
        return 'Providing Service';
      case 'SOLD':
        return 'Sold';
      default:
        return status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        // TODO: Implement actual image upload to your server
        final String imageUrl =
            'https://yempover-barter-image-store.s3.us-east-1.amazonaws.com/posts/${DateTime.now().millisecondsSinceEpoch}.jpg';

        setState(() {
          _images.add(imageUrl);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selected successfully'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create request with type explicitly set
      final requestData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'images': _images,
        'status': _selectedStatus,
        'barterStatus': _selectedBarterStatus,
        'categoryId': _selectedCategoryId,
        'isListed': _isListed,
        'type': _postType, // IMPORTANT: Include the post type
      };

      // Add price if present
      if (_priceController.text.isNotEmpty) {
        requestData['price'] = double.parse(_priceController.text);
      }

      // Add location if present
      if (_locationController.text.trim().isNotEmpty) {
        requestData['location'] = _locationController.text.trim();
      }

      debugPrint('📦 Sending update request with type: $_postType');
      debugPrint('📦 Request data: $requestData');

      final response = await _postsService.updatePost(
        widget.post.id,
        requestData,
      );

      if (!mounted) return;

      if (response.status == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _postType == 'service'
                  ? 'Service updated successfully'
                  : 'Product updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onProductUpdated();
        Navigator.pop(context, true);
      } else {
        throw Exception(response.message ?? 'Update failed');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          _postType == 'service' ? 'Edit Service' : 'Edit Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isSaving ? Colors.grey : Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(context).viewInsets.bottom +
                        MediaQuery.of(context).padding.bottom +
                        20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post Type Indicator
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _postType == 'service'
                              ? Colors.purple.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _postType == 'service'
                                ? Colors.purple.shade200
                                : Colors.orange.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _postType == 'service'
                                  ? Icons.build_circle
                                  : Icons.shopping_bag,
                              color: _postType == 'service'
                                  ? Colors.purple.shade700
                                  : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _postType == 'service'
                                        ? 'Service Post'
                                        : 'Product Post',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _postType == 'service'
                                          ? Colors.purple.shade700
                                          : Colors.orange.shade700,
                                    ),
                                  ),
                                  Text(
                                    _postType == 'service'
                                        ? 'You are offering a service'
                                        : 'You are selling a product',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _postType == 'service'
                                          ? Colors.purple.shade600
                                          : Colors.orange.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Images Section
                      _buildImagesSection(),

                      const SizedBox(height: 20),

                      _buildTextField(
                        label: 'Title',
                        controller: _titleController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        label: 'Description',
                        controller: _descriptionController,
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildDropdownField(
                        label: 'Category',
                        value: _selectedCategoryId.isEmpty
                            ? null
                            : _selectedCategoryId,
                        items: _categories
                            .where((category) => category['type'] == _postType)
                            .map<DropdownMenuItem<String>>((category) {
                              return DropdownMenuItem(
                                value: category['id'] as String,
                                child: Text(category['name']),
                              );
                            })
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value.toString();
                          });
                        },
                        hint: 'Select a category',
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        label: 'Price',
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        prefix: '\$ ',
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildDropdownField(
                        label: 'Status',
                        value: _selectedStatus,
                        items: _getValidStatuses().map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(_getStatusDisplayName(status)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value.toString();
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildDropdownField(
                        label: 'Barter Status',
                        value: _selectedBarterStatus,
                        items: const [
                          DropdownMenuItem(
                            value: 'NO_BARTER',
                            child: Text('No Barter'),
                          ),
                          DropdownMenuItem(
                            value: 'BARTER',
                            child: Text('Open for Barter'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedBarterStatus = value.toString();
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        label: 'Location (Optional)',
                        controller: _locationController,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 16),

                      // Listed Switch
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Listed Publicly',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Switch(
                              value: _isListed,
                              onChanged: (value) {
                                setState(() {
                                  _isListed = value;
                                });
                              },
                              activeColor: Colors.blue,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Images',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length + 1,
              itemBuilder: (context, index) {
                if (index == _images.length) {
                  return _buildAddImageButton();
                }
                return _buildImageItem(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(int index) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _images[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              'Add Image',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefix,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              prefixText: prefix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            items: items,
            onChanged: onChanged,
            hint: hint != null ? Text(hint) : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
