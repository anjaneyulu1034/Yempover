import 'dart:io';
import 'package:flutter/material.dart';
import 'package:yempower_app/models/ProductPost.dart';
import 'package:yempower_app/screens/CreatePostScreen.dart';
import 'package:yempower_app/screens/OfferDescriptionScreen.dart';
import 'package:yempower_app/utils/image_picker_utils.dart';

class OfferDeckScreen extends StatefulWidget {
  final ProductPost post;
  final List<UserItem> userItems;

  const OfferDeckScreen({
    super.key,
    required this.post,
    required this.userItems,
  });

  @override
  State<OfferDeckScreen> createState() => _OfferDeckScreenState();
}

class _OfferDeckScreenState extends State<OfferDeckScreen> {
  final List<UserItem> _selectedItems = <UserItem>[];
  final List<String> _selectedItemIds = [];

  // Post owner's items (for top section)
  final List<PostItem> _postItems = [
    PostItem(
      name: 'Sofa',
      category: 'Furniture',
      imageUrl:
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=500&q=80',
      isClubbable: true,
    ),
    PostItem(
      name: 'Coffee Table',
      category: 'Furniture',
      imageUrl:
          'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=500&q=80',
      isClubbable: false,
    ),
    PostItem(
      name: 'Dining Table',
      category: 'Furniture',
      imageUrl:
          'https://images.unsplash.com/photo-1540574163026-643ea20ade25?w=500&q=80',
      isClubbable: true,
    ),
  ];

  bool get _canShowAddButton {
    if (!widget.post.canClubItems) return false;

    // Check if any remaining items are clubbable
    final remainingItems = widget.userItems
        .where((item) => !_selectedItemIds.contains(item.id))
        .toList();

    return remainingItems.any((item) => item.isClubbable);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Offer Deck',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Top Section: Post Owner's Profile and Items
          _buildTopSection(),

          const Divider(height: 1, thickness: 1),

          // Middle Section: Add Items Button (if clubbing is allowed AND there are clubbable items)
          if (_canShowAddButton) _buildAddItemsSection(),

          // Bottom Section: User's Items
          Expanded(child: _buildBottomSection()),

          // Continue Button
          if (_selectedItems.isNotEmpty) _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Owner Profile
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=${widget.post.userName.hashCode % 70}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.post.title,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Post Owner's Items Deck
          const Text(
            'Item Deck',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _postItems.length,
              itemBuilder: (context, index) {
                final item = _postItems[index];
                return Container(
                  width: 100,
                  margin: EdgeInsets.only(
                    right: index < _postItems.length - 1 ? 12 : 0,
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(item.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (!item.isClubbable)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'No Club',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Add items to the deck make an offer',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          IconButton(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2E5BFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
            onPressed: _showAddItemsOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    final availableItems = widget.userItems
        .where((item) => item.isClubbable || _selectedItemIds.contains(item.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Items',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_selectedItems.isNotEmpty)
                Text(
                  '${_selectedItems.length} selected',
                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                ),
            ],
          ),
        ),

        // Selected Items Carousel (scroll sideways to view)
        if (_selectedItems.isNotEmpty)
          SizedBox(
            height: 140,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _selectedItems.length,
              itemBuilder: (context, index) {
                final item = _selectedItems[index];
                return _buildSelectedItemCard(item, index);
              },
            ),
          ),

        const SizedBox(height: 16),

        // All User Items Grid (only show clubbable items or already selected items)
        Expanded(
          child: availableItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No items available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: availableItems.length,
                  itemBuilder: (context, index) {
                    final item = availableItems[index];
                    final isSelected = _selectedItemIds.contains(item.id);
                    return _buildUserItemCard(item, isSelected);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSelectedItemCard(UserItem item, int index) {
    return Container(
      width: 120,
      margin: EdgeInsets.only(
        right: index < _selectedItems.length - 1 ? 12 : 0,
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                width: 120,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(item.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              if (item.price != null)
                Text(
                  item.price!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              icon: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
              onPressed: () => _removeItem(item.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItemCard(UserItem item, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleItemSelection(item),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E5BFF) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                  child: Image.network(
                    item.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 120,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),

                // Selection Checkbox
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E5BFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),

                // Clubbing Status
                if (!item.isClubbable)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'No Club',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Item Details
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.category,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.isFromExistingPost ? 'Existing' : 'New',
                          style: TextStyle(
                            fontSize: 10,
                            color: item.isFromExistingPost
                                ? Colors.green
                                : Colors.blue,
                          ),
                        ),
                      ),
                      if (item.price != null)
                        Text(
                          item.price!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _navigateToDescriptionScreen,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E5BFF),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Continue',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddItemsOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Items',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.list, color: Colors.blue),
              ),
              title: const Text('Add from existing posts'),
              subtitle: const Text('Select from your marketplace listings'),
              onTap: () {
                Navigator.pop(context);
                _showExistingPosts();
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.add_circle, color: Colors.green),
              ),
              title: const Text('Add a new post'),
              subtitle: const Text('Create new listing to add to offer'),
              onTap: () {
                Navigator.pop(context);
                _createNewPost();
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExistingPosts() {
    // Filter to show only clubbable items that aren't already selected
    final availableClubbableItems = widget.userItems
        .where(
          (item) =>
              item.isClubbable &&
              !_selectedItemIds.contains(item.id) &&
              item.isFromExistingPost,
        )
        .toList();

    if (availableClubbableItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No clubbable items available from existing posts'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Items'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: availableClubbableItems.length,
            itemBuilder: (context, index) {
              final item = availableClubbableItems[index];
              return CheckboxListTile(
                title: Text(item.name),
                subtitle: Text(
                  '${item.category} • ${item.price ?? "No price"}',
                ),
                secondary: CircleAvatar(
                  backgroundImage: NetworkImage(item.imageUrl),
                ),
                value: _selectedItemIds.contains(item.id),
                onChanged: (value) {
                  if (value == true) {
                    _addItem(item);
                  } else {
                    _removeItem(item.id);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _createNewPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(
          onPostCreated: (newItem) {
            // Add the newly created item to user's items and select it
            setState(() {
              widget.userItems.add(newItem);
              _addItem(newItem);
            });
          },
        ),
      ),
    );
  }

  void _toggleItemSelection(UserItem item) {
    setState(() {
      if (_selectedItemIds.contains(item.id)) {
        _removeItem(item.id);
      } else {
        _addItem(item);
      }
    });
  }

  void _addItem(UserItem item) {
    if (!item.isClubbable && _selectedItems.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} cannot be clubbed with other items'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_selectedItemIds.contains(item.id)) {
      setState(() {
        _selectedItemIds.add(item.id);
        _selectedItems.add(item);
      });
    }
  }

  void _removeItem(String itemId) {
    setState(() {
      _selectedItemIds.remove(itemId);
      _selectedItems.removeWhere((item) => item.id == itemId);
    });
  }

  void _navigateToDescriptionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfferDescriptionScreen(
          post: widget.post,
          selectedItems: _selectedItems,
        ),
      ),
    );
  }
}
