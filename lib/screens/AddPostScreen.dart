// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:yempower_app/models/TradePost.dart';

// class PostDetailScreen extends StatelessWidget {
//   final TradePost post;

//   const PostDetailScreen({
//     super.key,
//     required this.post,
//     required List<dynamic> userItems,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.9,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       child: Column(
//         children: [
//           // Header
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Post Details',
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//                 IconButton(
//                   onPressed: () => Navigator.pop(context),
//                   icon: const Icon(Icons.close),
//                 ),
//               ],
//             ),
//           ),

//           // Images
//           SizedBox(
//             height: 200,
//             child: PageView.builder(
//               itemCount: post.images.length,
//               itemBuilder: (context, index) {
//                 return Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 16),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(12),
//                     image: DecorationImage(
//                       image: NetworkImage(post.images[index]),
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),

//           // Details
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Title and Date
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         post.title,
//                         style: const TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         DateFormat('MMM dd, yyyy').format(post.postedDateTime),
//                         style: const TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),

//                   // Views and Offers
//                   Row(
//                     children: [
//                       Row(
//                         children: [
//                           const Icon(
//                             Icons.remove_red_eye,
//                             size: 16,
//                             color: Colors.grey,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${post.views} views',
//                             style: const TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(width: 16),
//                       GestureDetector(
//                         onTap: () {
//                           // Navigate to offers inbox
//                         },
//                         child: Row(
//                           children: [
//                             const Icon(
//                               Icons.local_offer,
//                               size: 16,
//                               color: Colors.blue,
//                             ),
//                             const SizedBox(width: 4),
//                             Text(
//                               '${post.openOffers} Open Offers',
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.blue,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 24),

//                   // Price
//                   if (post.price.isNotEmpty)
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Price:',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           post.price,
//                           style: const TextStyle(
//                             fontSize: 20,
//                             color: Colors.green,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//                       ],
//                     ),

//                   // Description
//                   const Text(
//                     'Description:',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     post.description,
//                     style: const TextStyle(fontSize: 14, color: Colors.black87),
//                   ),

//                   const SizedBox(height: 24),

//                   // Barter Details
//                   if (post.isOpenForBarter)
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Barter:',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           post.returnDetails,
//                           style: const TextStyle(
//                             fontSize: 14,
//                             color: Colors.black87,
//                           ),
//                         ),
//                         if (post.wishListCategory.isNotEmpty)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 4),
//                             child: Text(
//                               'Looking for: ${post.wishListCategory}',
//                               style: const TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.green,
//                               ),
//                             ),
//                           ),
//                         const SizedBox(height: 24),
//                       ],
//                     ),

//                   // Location
//                   const Text(
//                     'Product Location:',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     post.location,
//                     style: const TextStyle(fontSize: 14, color: Colors.black87),
//                   ),

//                   const SizedBox(height: 24),

//                   // Transportation Flexibility
//                   const Text(
//                     'Transportation:',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     post.transportationFlexibility,
//                     style: const TextStyle(fontSize: 14, color: Colors.black87),
//                   ),

//                   const SizedBox(height: 40),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class AddPostScreen extends StatefulWidget {
//   final TradePost? editPost;

//   const AddPostScreen({super.key, this.editPost});

//   @override
//   _AddPostScreenState createState() => _AddPostScreenState();
// }

// class _AddPostScreenState extends State<AddPostScreen> {
//   int _selectedOption = 1;
//   String _postType = 'Product';
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _locationController = TextEditingController();
//   String? _selectedCategory;
//   final List<String> _categories = [
//     'Furniture',
//     'Electronics',
//     'Home Decor',
//     'Plumbing',
//     'Clothing',
//     'Books',
//     'Services',
//   ];

//   // Step 2 variables
//   bool _barterAvailable = false;
//   String? _barterCategory;
//   final TextEditingController _barterWishController = TextEditingController();
//   bool _canClubItems = true;
//   bool _soldForMoney = false;
//   final TextEditingController _priceController = TextEditingController();
//   String _transportationOption = 'transport_desired';

//   // Looking for variables
//   bool _willPay = false;
//   final TextEditingController _willPayAmountController =
//       TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     if (widget.editPost != null) {
//       _initializeEditMode();
//     }
//   }

//   void _initializeEditMode() {
//     final post = widget.editPost!;
//     _titleController.text = post.title;
//     _descriptionController.text = post.description;
//     _locationController.text = post.location;
//     _selectedCategory = post.category;
//     _barterAvailable = post.isOpenForBarter;
//     _canClubItems = post.canClubItems;
//     _barterWishController.text = post.wishListCategory;
//     _transportationOption = _getTransportationOption(
//       post.transportationFlexibility,
//     );

//     if (post.price.isNotEmpty && post.price.startsWith('\$')) {
//       _soldForMoney = true;
//       _priceController.text = post.price
//           .replaceAll('\$', '')
//           .replaceAll(',', '');
//     }
//   }

//   String _getTransportationOption(String flexibility) {
//     if (flexibility.contains('transported to desired location')) {
//       return 'transport_desired';
//     } else if (flexibility.contains('picked from location')) {
//       return 'pickup_only';
//     } else {
//       return 'transport_with_charge';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.95,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       child: Column(
//         children: [
//           // Header
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   widget.editPost != null ? 'Edit Post' : 'Add Post',
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: () => Navigator.pop(context),
//                   icon: const Icon(Icons.close),
//                 ),
//               ],
//             ),
//           ),

//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (widget.editPost == null) ...[
//                     const Text(
//                       'Select Your Post Type',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     _buildOptionCard(
//                       1,
//                       'You want to add your product/service to barter/sell in Marketplace.',
//                     ),
//                     const SizedBox(height: 12),
//                     _buildOptionCard(
//                       2,
//                       'You need (or are you looking for) a specific product or service in the Marketplace.',
//                     ),
//                     const SizedBox(height: 24),
//                   ],

//                   // Step 1: Basic Details
//                   if (_selectedOption == 1 || widget.editPost != null)
//                     _buildStep1(),

//                   if (_selectedOption == 2 && widget.editPost == null)
//                     _buildLookingForStep1(),

//                   const SizedBox(height: 40),
//                 ],
//               ),
//             ),
//           ),

//           // Navigation Buttons
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text('Back'),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _proceedToNextStep,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF2E5BFF),
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: Text(
//                       widget.editPost != null ? 'Re-post' : 'Next',
//                       style: const TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOptionCard(int option, String description) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(
//           color: _selectedOption == option
//               ? const Color(0xFF2E5BFF)
//               : Colors.transparent,
//           width: 2,
//         ),
//       ),
//       child: InkWell(
//         onTap: () => setState(() => _selectedOption = option),
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Container(
//                 width: 24,
//                 height: 24,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: _selectedOption == option
//                         ? const Color(0xFF2E5BFF)
//                         : Colors.grey,
//                     width: 2,
//                   ),
//                 ),
//                 child: _selectedOption == option
//                     ? const Icon(
//                         Icons.circle,
//                         size: 12,
//                         color: Color(0xFF2E5BFF),
//                       )
//                     : null,
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Text(description, style: const TextStyle(fontSize: 14)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStep1() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Create a New Post',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         const SizedBox(height: 24),

//         // Post Type
//         const Text(
//           'Post Type',
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             Expanded(
//               child: ChoiceChip(
//                 label: const Text('Product'),
//                 selected: _postType == 'Product',
//                 onSelected: (selected) => setState(() => _postType = 'Product'),
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: ChoiceChip(
//                 label: const Text('Service'),
//                 selected: _postType == 'Service',
//                 onSelected: (selected) => setState(() => _postType = 'Service'),
//               ),
//             ),
//           ],
//         ),

//         const SizedBox(height: 24),

//         // Title
//         const Text(
//           'Title *',
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           controller: _titleController,
//           decoration: InputDecoration(
//             hintText: 'Enter product/service title',
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//         ),

//         const SizedBox(height: 24),

//         // Category
//         const Text(
//           'Category *',
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//         ),
//         const SizedBox(height: 8),
//         DropdownButtonFormField<String>(
//           value: _selectedCategory,
//           decoration: InputDecoration(
//             hintText: 'Select category',
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//           items: _categories.map((category) {
//             return DropdownMenuItem(value: category, child: Text(category));
//           }).toList(),
//           onChanged: (value) => setState(() => _selectedCategory = value),
//         ),

//         const SizedBox(height: 24),

//         // Description
//         const Text(
//           'Description *',
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           controller: _descriptionController,
//           maxLines: 4,
//           decoration: InputDecoration(
//             hintText: 'Describe your product/service',
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//         ),

//         const SizedBox(height: 24),

//         // Upload Photos
//         const Text(
//           'Upload Photos *',
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           height: 120,
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey.shade300),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
//               const SizedBox(height: 8),
//               const Text(
//                 'Upload your Images',
//                 style: TextStyle(color: Colors.grey),
//               ),
//               const SizedBox(height: 4),
//               const Text(
//                 'Image Here, or click to upload',
//                 style: TextStyle(fontSize: 12, color: Colors.grey),
//               ),
//               const SizedBox(height: 8),
//               if (_postType == 'Product')
//                 const Text(
//                   '*At least 1 image required for products',
//                   style: TextStyle(fontSize: 11, color: Colors.red),
//                 ),
//             ],
//           ),
//         ),

//         const SizedBox(height: 24),

//         // Location
//         const Text(
//           'Enter Product Location *',
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           controller: _locationController,
//           decoration: InputDecoration(
//             hintText: 'Enter location',
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//             prefixIcon: const Icon(Icons.location_on),
//             suffixIcon: IconButton(
//               icon: const Icon(Icons.my_location),
//               onPressed: () {
//                 // Get current location
//                 _locationController.text = 'Current Location';
//               },
//             ),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             Checkbox(value: true, onChanged: (value) {}),
//             const Expanded(
//               child: Text(
//                 'Use my current location: 1062 Clarksburg Park Road, Hollenberg, Kansas, 66946',
//                 style: TextStyle(fontSize: 12),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildLookingForStep1() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Looking For',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         const SizedBox(height: 24),

//         // Similar fields as Step 1 but for "Looking For"
//         const Text(
//           'Post Type',
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             Expanded(
//               child: ChoiceChip(
//                 label: const Text('Product'),
//                 selected: _postType == 'Product',
//                 onSelected: (selected) => setState(() => _postType = 'Product'),
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: ChoiceChip(
//                 label: const Text('Service'),
//                 selected: _postType == 'Service',
//                 onSelected: (selected) => setState(() => _postType = 'Service'),
//               ),
//             ),
//           ],
//         ),

//         const SizedBox(height: 24),

//         const Text(
//           'Title *',
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           decoration: InputDecoration(
//             hintText: 'What are you looking for?',
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//         ),

//         const SizedBox(height: 24),

//         const Text(
//           'Category *',
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//         ),
//         const SizedBox(height: 8),
//         DropdownButtonFormField<String>(
//           decoration: InputDecoration(
//             hintText: 'Select category',
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//           items: const [],
//           onChanged: (String? value) {},
//         ),

//         const SizedBox(height: 24),

//         const Text(
//           'Description *',
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           maxLines: 4,
//           decoration: InputDecoration(
//             hintText: 'Describe what you are looking for',
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//         ),

//         const SizedBox(height: 24),

//         const Text(
//           'Upload Photos (Optional)',
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           height: 120,
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey.shade300),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: const Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
//               SizedBox(height: 8),
//               Text(
//                 'Add reference images (optional)',
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ],
//           ),
//         ),

//         const SizedBox(height: 24),

//         const Text(
//           'Location *',
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           decoration: InputDecoration(
//             hintText: 'Enter preferred location',
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//             prefixIcon: const Icon(Icons.location_on),
//           ),
//         ),
//       ],
//     );
//   }

//   void _proceedToNextStep() {
//     if (_selectedOption == 1 && widget.editPost == null) {
//       _showStep2Dialog();
//     } else {
//       _submitPost();
//     }
//   }

//   void _showStep2Dialog() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => _buildStep2Dialog(),
//     );
//   }

//   Widget _buildStep2Dialog() {
//     return StatefulBuilder(
//       builder: (context, setState) {
//         return Container(
//           height: MediaQuery.of(context).size.height * 0.9,
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//           ),
//           child: Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       'Additional Details',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     IconButton(
//                       onPressed: () => Navigator.pop(context),
//                       icon: const Icon(Icons.close),
//                     ),
//                   ],
//                 ),
//               ),

//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Barter Available
//                       Row(
//                         children: [
//                           Checkbox(
//                             value: _barterAvailable,
//                             onChanged: (value) =>
//                                 setState(() => _barterAvailable = value!),
//                           ),
//                           const Text('Barter Available'),
//                         ],
//                       ),

//                       if (_barterAvailable) ...[
//                         const SizedBox(height: 16),
//                         const Text(
//                           'Select Barter Category',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         DropdownButtonFormField<String>(
//                           value: _barterCategory,
//                           decoration: InputDecoration(
//                             hintText: 'What do you want in return?',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           items: _categories.map((category) {
//                             return DropdownMenuItem(
//                               value: category,
//                               child: Text(category),
//                             );
//                           }).toList(),
//                           onChanged: (value) =>
//                               setState(() => _barterCategory = value),
//                         ),

//                         const SizedBox(height: 16),

//                         const Text(
//                           'Describe Barter Wish',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         TextField(
//                           controller: _barterWishController,
//                           decoration: InputDecoration(
//                             hintText: 'Describe what you want in return',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                         ),
//                       ],

//                       const SizedBox(height: 24),

//                       // Club Items Option
//                       const Text(
//                         'Item Clubbing Option',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Column(
//                         children: [
//                           RadioListTile<bool>(
//                             title: const Text(
//                               'This item can be clubbed with other items in your list while users make an offer',
//                             ),
//                             value: true,
//                             groupValue: _canClubItems,
//                             onChanged: (value) =>
//                                 setState(() => _canClubItems = value!),
//                           ),
//                           RadioListTile<bool>(
//                             title: const Text(
//                               'No, this item cannot be clubbed and traded as a single product',
//                             ),
//                             value: false,
//                             groupValue: _canClubItems,
//                             onChanged: (value) =>
//                                 setState(() => _canClubItems = value!),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 24),

//                       // Sold for Money
//                       Row(
//                         children: [
//                           Checkbox(
//                             value: _soldForMoney,
//                             onChanged: (value) =>
//                                 setState(() => _soldForMoney = value!),
//                           ),
//                           const Text('This item is sold for money'),
//                         ],
//                       ),

//                       if (_soldForMoney) ...[
//                         const SizedBox(height: 8),
//                         TextField(
//                           controller: _priceController,
//                           decoration: InputDecoration(
//                             hintText: 'Enter price',
//                             prefixText: '\$ ',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           keyboardType: TextInputType.number,
//                         ),
//                       ],

//                       const SizedBox(height: 24),

//                       // Transportation Flexibility
//                       const Text(
//                         'Transportation Flexibility',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Column(
//                         children: [
//                           RadioListTile<String>(
//                             title: const Text(
//                               'This item can be transported to desired location',
//                             ),
//                             value: 'transport_desired',
//                             groupValue: _transportationOption,
//                             onChanged: (value) =>
//                                 setState(() => _transportationOption = value!),
//                           ),
//                           RadioListTile<String>(
//                             title: const Text(
//                               'This item has to be picked from location',
//                             ),
//                             value: 'pickup_only',
//                             groupValue: _transportationOption,
//                             onChanged: (value) =>
//                                 setState(() => _transportationOption = value!),
//                           ),
//                           RadioListTile<String>(
//                             title: const Text(
//                               'This item can be transported with a delivery charge',
//                             ),
//                             value: 'transport_with_charge',
//                             groupValue: _transportationOption,
//                             onChanged: (value) =>
//                                 setState(() => _transportationOption = value!),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 40),
//                     ],
//                   ),
//                 ),
//               ),

//               // Action Buttons
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () => Navigator.pop(context),
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: const Text('Back'),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: _submitPost,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF2E5BFF),
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: const Text(
//                           'Post',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   void _submitPost() {
//     Navigator.pop(context); // Close bottom sheet
//     Navigator.pop(context); // Close add post screen

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           widget.editPost != null
//               ? 'Post updated successfully!'
//               : 'Post added successfully!',
//         ),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yempower_app/models/TradePost.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PostDetailScreen extends StatelessWidget {
  final TradePost post;

  const PostDetailScreen({
    super.key,
    required this.post,
    required List<dynamic> userItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Post Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Images
          SizedBox(
            height: 200,
            child: PageView.builder(
              itemCount: post.images.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(post.images[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),

          // Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(post.postedDateTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Views and Offers
                  Row(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.remove_red_eye,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.views} views',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          // Navigate to offers inbox
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_offer,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.openOffers} Open Offers',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Price
                  if (post.price.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Price:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.price,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Description
                  const Text(
                    'Description:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.description,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),

                  const SizedBox(height: 24),

                  // Barter Details
                  if (post.isOpenForBarter)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Barter:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.returnDetails,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        if (post.wishListCategory.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Looking for: ${post.wishListCategory}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Location
                  const Text(
                    'Product Location:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.location,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),

                  const SizedBox(height: 24),

                  // Transportation Flexibility
                  const Text(
                    'Transportation:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.transportationFlexibility,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddPostScreen extends StatefulWidget {
  final TradePost? editPost;

  const AddPostScreen({super.key, this.editPost});

  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  int _selectedOption = 1;
  String _postType = 'Product';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _selectedCategory;
  final List<String> _categories = [
    'Furniture',
    'Electronics',
    'Home Decor',
    'Plumbing',
    'Clothing',
    'Books',
    'Services',
  ];

  // Step 2 variables
  bool _barterAvailable = false;
  String? _barterCategory;
  final TextEditingController _barterWishController = TextEditingController();
  bool _canClubItems = true;
  bool _soldForMoney = false;
  final TextEditingController _priceController = TextEditingController();
  String _transportationOption = 'transport_desired';

  // Looking for variables
  bool _willPay = false;
  final TextEditingController _willPayAmountController =
      TextEditingController();

  // Image upload variables
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.editPost != null) {
      _initializeEditMode();
    }
  }

  void _initializeEditMode() {
    final post = widget.editPost!;
    _titleController.text = post.title;
    _descriptionController.text = post.description;
    _locationController.text = post.location;
    _selectedCategory = post.category;
    _barterAvailable = post.isOpenForBarter;
    _canClubItems = post.canClubItems;
    _barterWishController.text = post.wishListCategory;
    _transportationOption = _getTransportationOption(
      post.transportationFlexibility,
    );

    if (post.price.isNotEmpty && post.price.startsWith('\$')) {
      _soldForMoney = true;
      _priceController.text = post.price
          .replaceAll('\$', '')
          .replaceAll(',', '');
    }
  }

  String _getTransportationOption(String flexibility) {
    if (flexibility.contains('transported to desired location')) {
      return 'transport_desired';
    } else if (flexibility.contains('picked from location')) {
      return 'pickup_only';
    } else {
      return 'transport_with_charge';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick image'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Choose Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Photos *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        // Selected Images Grid
        if (_selectedImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(_selectedImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        if (_selectedImages.isNotEmpty) const SizedBox(height: 8),

        // Upload Button
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: _postType == 'Product' && _selectedImages.isEmpty
                    ? Colors.red
                    : Colors.grey.shade300,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                const Text(
                  'Upload your Images',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap to upload',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                if (_postType == 'Product')
                  Text(
                    _selectedImages.isEmpty
                        ? '*At least 1 image required for products'
                        : 'Add more images (optional)',
                    style: TextStyle(
                      fontSize: 11,
                      color: _selectedImages.isEmpty ? Colors.red : Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLookingForImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Photos (Optional)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        // Selected Images Grid
        if (_selectedImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(_selectedImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        if (_selectedImages.isNotEmpty) const SizedBox(height: 8),

        // Upload Button
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                const Text(
                  'Add reference images (optional)',
                  style: TextStyle(color: Colors.grey),
                ),
                if (_selectedImages.isEmpty) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to upload',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.editPost != null ? 'Edit Post' : 'Add Post',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.editPost == null) ...[
                    const Text(
                      'Select Your Post Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildOptionCard(
                      1,
                      'You want to add your product/service to barter/sell in Marketplace.',
                    ),
                    const SizedBox(height: 12),
                    _buildOptionCard(
                      2,
                      'You need (or are you looking for) a specific product or service in the Marketplace.',
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Step 1: Basic Details
                  if (_selectedOption == 1 || widget.editPost != null)
                    _buildStep1(),

                  if (_selectedOption == 2 && widget.editPost == null)
                    _buildLookingForStep1(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Navigation Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _validateAndProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E5BFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.editPost != null ? 'Re-post' : 'Next',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(int option, String description) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _selectedOption == option
              ? const Color(0xFF2E5BFF)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedOption = option),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedOption == option
                        ? const Color(0xFF2E5BFF)
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: _selectedOption == option
                    ? const Icon(
                        Icons.circle,
                        size: 12,
                        color: Color(0xFF2E5BFF),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(description, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create a New Post',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),

        // Post Type
        const Text(
          'Post Type',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Product'),
                selected: _postType == 'Product',
                onSelected: (selected) => setState(() => _postType = 'Product'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ChoiceChip(
                label: const Text('Service'),
                selected: _postType == 'Service',
                onSelected: (selected) => setState(() => _postType = 'Service'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Title
        const Text(
          'Title *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Enter product/service title',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        const SizedBox(height: 24),

        // Category
        const Text(
          'Category *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            hintText: 'Select category',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
          onChanged: (value) => setState(() => _selectedCategory = value),
        ),

        const SizedBox(height: 24),

        // Description
        const Text(
          'Description *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe your product/service',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        const SizedBox(height: 24),

        // Upload Photos
        _buildImageUploadSection(),

        const SizedBox(height: 24),

        // Location
        const Text(
          'Enter Product Location *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'Enter location',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () {
                // Get current location
                _locationController.text = 'Current Location';
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(value: true, onChanged: (value) {}),
            const Expanded(
              child: Text(
                'Use my current location: 1062 Clarksburg Park Road, Hollenberg, Kansas, 66946',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLookingForStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Looking For',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),

        // Similar fields as Step 1 but for "Looking For"
        const Text(
          'Post Type',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Product'),
                selected: _postType == 'Product',
                onSelected: (selected) => setState(() => _postType = 'Product'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ChoiceChip(
                label: const Text('Service'),
                selected: _postType == 'Service',
                onSelected: (selected) => setState(() => _postType = 'Service'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        const Text(
          'Title *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'What are you looking for?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Category *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            hintText: 'Select category',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
          onChanged: (value) => setState(() => _selectedCategory = value),
        ),

        const SizedBox(height: 24),

        const Text(
          'Description *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe what you are looking for',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        const SizedBox(height: 24),

        // Upload Photos
        _buildLookingForImageUploadSection(),

        const SizedBox(height: 24),

        const Text(
          'Location *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'Enter preferred location',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.location_on),
          ),
        ),
      ],
    );
  }

  void _validateAndProceed() {
    if (_selectedOption == 1 && widget.editPost == null) {
      // Validate required fields for regular post
      if (_titleController.text.isEmpty) {
        _showError('Please enter a title');
        return;
      }
      if (_selectedCategory == null) {
        _showError('Please select a category');
        return;
      }
      if (_descriptionController.text.isEmpty) {
        _showError('Please enter a description');
        return;
      }
      if (_postType == 'Product' && _selectedImages.isEmpty) {
        _showError('Please upload at least one image for products');
        return;
      }
      if (_locationController.text.isEmpty) {
        _showError('Please enter a location');
        return;
      }
      _showStep2Dialog();
    } else {
      _submitPost();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showStep2Dialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildStep2Dialog(),
    );
  }

  Widget _buildStep2Dialog() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Additional Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barter Available
                      Row(
                        children: [
                          Checkbox(
                            value: _barterAvailable,
                            onChanged: (value) =>
                                setState(() => _barterAvailable = value!),
                          ),
                          const Text('Barter Available'),
                        ],
                      ),

                      if (_barterAvailable) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Select Barter Category',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _barterCategory,
                          decoration: InputDecoration(
                            hintText: 'What do you want in return?',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _barterCategory = value),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Describe Barter Wish',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _barterWishController,
                          decoration: InputDecoration(
                            hintText: 'Describe what you want in return',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Club Items Option
                      const Text(
                        'Item Clubbing Option',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          RadioListTile<bool>(
                            title: const Text(
                              'This item can be clubbed with other items in your list while users make an offer',
                            ),
                            value: true,
                            groupValue: _canClubItems,
                            onChanged: (value) =>
                                setState(() => _canClubItems = value!),
                          ),
                          RadioListTile<bool>(
                            title: const Text(
                              'No, this item cannot be clubbed and traded as a single product',
                            ),
                            value: false,
                            groupValue: _canClubItems,
                            onChanged: (value) =>
                                setState(() => _canClubItems = value!),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Sold for Money
                      Row(
                        children: [
                          Checkbox(
                            value: _soldForMoney,
                            onChanged: (value) =>
                                setState(() => _soldForMoney = value!),
                          ),
                          const Text('This item is sold for money'),
                        ],
                      ),

                      if (_soldForMoney) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            hintText: 'Enter price',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Transportation Flexibility
                      const Text(
                        'Transportation Flexibility',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text(
                              'This item can be transported to desired location',
                            ),
                            value: 'transport_desired',
                            groupValue: _transportationOption,
                            onChanged: (value) =>
                                setState(() => _transportationOption = value!),
                          ),
                          RadioListTile<String>(
                            title: const Text(
                              'This item has to be picked from location',
                            ),
                            value: 'pickup_only',
                            groupValue: _transportationOption,
                            onChanged: (value) =>
                                setState(() => _transportationOption = value!),
                          ),
                          RadioListTile<String>(
                            title: const Text(
                              'This item can be transported with a delivery charge',
                            ),
                            value: 'transport_with_charge',
                            groupValue: _transportationOption,
                            onChanged: (value) =>
                                setState(() => _transportationOption = value!),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E5BFF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Post',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitPost() {
    // Here you would typically upload the images to your server
    // and create the post with the image URLs
    print('Selected images: ${_selectedImages.length}');

    Navigator.pop(context); // Close bottom sheet if open
    Navigator.pop(context); // Close add post screen

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.editPost != null
              ? 'Post updated successfully!'
              : 'Post added successfully!',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}
