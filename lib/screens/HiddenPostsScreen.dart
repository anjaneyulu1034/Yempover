import 'package:Yempover_app/screens/PostDetailScreen.dart';
import 'package:Yempover_app/services/post_action_service.dart';
import 'package:flutter/material.dart';

class HiddenPostsScreen extends StatefulWidget {
  const HiddenPostsScreen({super.key});

  @override
  State<HiddenPostsScreen> createState() => _HiddenPostsScreenState();
}

class _HiddenPostsScreenState extends State<HiddenPostsScreen> {
  final PostActionService _postActionService = PostActionService();
  List<HiddenPostItem> _hiddenPosts = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadHiddenPosts();
  }

  Future<void> _loadHiddenPosts({bool isRefresh = false}) async {
    if (!mounted) return;

    setState(() {
      if (isRefresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
    });

    try {
      final items = await _postActionService.getHiddenPosts();
      if (!mounted) return;

      setState(() {
        _hiddenPosts = items;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load hidden posts: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _unhidePost(HiddenPostItem item) async {
    if (item.hiddenPostId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to unhide this post right now'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _postActionService.unhidePost(
        postId: item.hiddenPostId,
        isService: item.isService,
      );

      if (!mounted) return;
      setState(() {
        _hiddenPosts.removeWhere(
          (element) => element.hiddenPostId == item.hiddenPostId,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post unhidden successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unhide post: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hidden Posts'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F8FF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hiddenPosts.isEmpty
          ? RefreshIndicator(
              onRefresh: () => _loadHiddenPosts(isRefresh: true),
              child: ListView(
                children: const [
                  SizedBox(height: 220),
                  Center(
                    child: Text(
                      'No hidden posts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadHiddenPosts(isRefresh: true),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _hiddenPosts.length,
                itemBuilder: (context, index) {
                  final item = _hiddenPosts[index];
                  final post = item.post;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetailScreen(
                              post: post,
                              userItems: const [],
                            ),
                          ),
                        );
                      },
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          post.processedImages.isNotEmpty
                              ? post.processedImages.first
                              : 'https://via.placeholder.com/80',
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),
                      title: Text(
                        post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        post.location.isNotEmpty
                            ? post.location
                            : 'No location',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: _isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: () => _unhidePost(item),
                              child: const Text('Unhide'),
                            ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
