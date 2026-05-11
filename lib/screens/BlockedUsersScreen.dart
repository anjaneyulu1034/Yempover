import 'package:YemPover_app/services/blocked_user_service.dart';
import 'package:flutter/material.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final BlockedUserService _blockedUserService = BlockedUserService();

  List<BlockedUserItem> _blockedUsers = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  @override
  void dispose() {
    _blockedUserService.dispose();
    super.dispose();
  }

  Future<void> _loadBlockedUsers({bool isRefresh = false}) async {
    if (!mounted) return;

    setState(() {
      if (isRefresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
    });

    try {
      final users = await _blockedUserService.getBlockedUsers();
      if (!mounted) return;

      setState(() {
        _blockedUsers = users;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load blocked users: ${e.toString()}'),
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

  Future<void> _confirmAndUnblock(BlockedUserItem user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Do you want to unblock ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _blockedUserService.unblockUser(user.blockedId);
      if (!mounted) return;

      setState(() {
        _blockedUsers.removeWhere((item) => item.blockedId == user.blockedId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.fullName} has been unblocked.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unblock user: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAvatar(BlockedUserItem user) {
    if (user.profileImage != null && user.profileImage!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(user.profileImage!),
      );
    }

    final initial = user.fullName.isNotEmpty
        ? user.fullName.substring(0, 1).toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.red.shade50,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F8FF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
          ? RefreshIndicator(
              onRefresh: () => _loadBlockedUsers(isRefresh: true),
              child: ListView(
                children: const [
                  SizedBox(height: 220),
                  Center(
                    child: Text(
                      'No blocked users',
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
              onRefresh: () => _loadBlockedUsers(isRefresh: true),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _blockedUsers.length,
                itemBuilder: (context, index) {
                  final user = _blockedUsers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      leading: _buildAvatar(user),
                      title: Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        (user.mobileNumber ?? '').trim().isNotEmpty
                            ? user.mobileNumber!
                            : 'No phone number',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: TextButton(
                        onPressed: _isRefreshing
                            ? null
                            : () => _confirmAndUnblock(user),
                        child: const Text('Unblock'),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
