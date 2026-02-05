import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/social_provider.dart';
import '../../services/notification_provider.dart';
import '../../models/user.dart';
import '../cozy/cozy_tile.dart';
import '../cozy/cozy_dialog_sheet.dart';
import '../../theme/cozy_theme.dart';

class ClinicDirectorySheet extends StatefulWidget {
  const ClinicDirectorySheet({super.key});

  @override
  State<ClinicDirectorySheet> createState() => _ClinicDirectorySheetState();
}

class _ClinicDirectorySheetState extends State<ClinicDirectorySheet> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isSearching = false;
  bool _isSearchingLoading = false;
  int _activeTab = 0; // 0: Pager, 1: Network

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SocialProvider>(context, listen: false).fetchNetwork();
      Provider.of<NotificationProvider>(context, listen: false).fetchInbox();
    });
  }

  void _handleSearch(String val) async {
    if (val.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isSearchingLoading = true;
    });

    final results = await Provider.of<SocialProvider>(context, listen: false).searchUsers(val);
    
    setState(() {
      _searchResults = results;
      _isSearchingLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CozyDialogSheet(
      onTapOutside: () => Navigator.pop(context),
      child: Column(
        children: [
          const SizedBox(height: 10), // Small gap from handle

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _activeTab == 0 ? _buildPagerView() : _buildNetworkView(),
            ),
          ),

          // Bottom Navigation
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: _buildBottomButton(
              "Pager", 
              _activeTab == 0, 
              () => setState(() => _activeTab = 0)
            )
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildBottomButton(
              "Network", 
              _activeTab == 1, 
              () => setState(() => _activeTab = 1)
            )
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(String label, bool active, VoidCallback onTap) {
    final palette = CozyTheme.of(context);
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? palette.primary : palette.paperWhite,
        foregroundColor: active ? palette.textInverse : palette.primary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: active ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), 
          side: BorderSide(color: palette.primary)
        ),
      ),
      child: Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPagerView() {
    return Consumer<NotificationProvider>(
      key: const ValueKey('pager'),
      builder: (context, pager, _) {
        if (pager.isLoading) {
          return Center(child: CircularProgressIndicator(color: CozyTheme.of(context).primary));
        }

        if (pager.messages.isEmpty) {
          final palette = CozyTheme.of(context);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: palette.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text("Your pager is silent.", style: GoogleFonts.quicksand(color: palette.textSecondary)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pager.messages.length,
          itemBuilder: (context, index) {
            final msg = pager.messages[index];
            final palette = CozyTheme.of(context);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CozyTile(
                onTap: () => pager.markAsRead(msg.id),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      msg.type == 'admin_alert' ? Icons.warning_amber_rounded : Icons.note_alt_outlined,
                      color: msg.type == 'admin_alert' ? palette.warning : palette.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                msg.type == 'admin_alert' ? "ADMIN ALERT" : "PEER NOTE",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: msg.type == 'admin_alert' ? palette.warning : palette.primary,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              Text(
                                timeago.format(msg.createdAt),
                                style: TextStyle(fontSize: 10, color: palette.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg.message,
                            style: TextStyle(
                              color: CozyTheme.of(context).textPrimary,
                              fontWeight: msg.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          if (msg.senderName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "From: ${msg.senderName}",
                                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: palette.textSecondary),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!msg.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(color: palette.error, shape: BoxShape.circle),
                      ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: palette.textSecondary),
                      onPressed: () {
                        // Confirm deletion
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: CozyTheme.of(context).paperCream,
                            title: const Text("Delete Message?"),
                            content: const Text("This record will be permanently removed from your pager."),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
                              ElevatedButton(
                                onPressed: () {
                                  pager.deleteMessage(msg.id, msg.type);
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: palette.error),
                                child: Text("DELETE", style: TextStyle(color: palette.textInverse)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNetworkView() {
    return Consumer<SocialProvider>(
      key: const ValueKey('network'),
      builder: (context, social, _) {
        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                onChanged: _handleSearch,
                decoration: InputDecoration(
                  hintText: "Search colleagues...",
                  prefixIcon: Icon(Icons.search, color: CozyTheme.of(context).primary),
                  filled: true,
                  fillColor: CozyTheme.of(context).paperWhite,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),

            Expanded(
              child: _isSearching ? _buildSearchResults(social) : _buildDirectory(social),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(SocialProvider social) {
    if (_isSearchingLoading) {
      return Center(child: CircularProgressIndicator(color: CozyTheme.of(context).primary));
    }
    if (_searchResults.isEmpty) {
      final palette = CozyTheme.of(context);
      return Center(child: Text("No doctors found", style: TextStyle(color: palette.textSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final u = _searchResults[index];
        return _buildUserTile(u, social);
      },
    );
  }

  Widget _buildDirectory(SocialProvider social) {
    if (social.isLoading) {
      return Center(child: CircularProgressIndicator(color: CozyTheme.of(context).primary));
    }

    final palette = CozyTheme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (social.pendingRequests.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text("CONSULT REQUESTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: palette.textSecondary)),
          ),
          ...social.pendingRequests.map((u) => _buildUserTile(u, social, isPending: true)),
          const Divider(height: 32),
        ],

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text("COLLEAGUES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: palette.textSecondary)),
        ),
        if (social.colleagues.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text("No colleagues yet. Search for your peers!", style: TextStyle(color: CozyTheme.of(context).textSecondary, fontSize: 13)),
          ))
        else
          ...social.colleagues.map((u) => _buildUserTile(u, social)),
      ],
    );
  }

  Widget _buildUserTile(User u, SocialProvider social, {bool isPending = false}) {
    final palette = CozyTheme.of(context);
    String? status = u.friendshipStatus;
    bool isFriend = status == 'friend';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CozyTile(
        onTap: () {
           social.startVisiting(u, context);
           Navigator.pop(context);
        },
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: CozyTheme.of(context).paperCream,
              child: Text(u.username?[0].toUpperCase() ?? "D", style: TextStyle(color: CozyTheme.of(context).primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.displayName ?? u.username ?? "Doctor", style: TextStyle(fontWeight: FontWeight.bold, color: palette.textPrimary)),
                  Text("Medical ID: #${u.id.toString().padLeft(3, '0')}", style: TextStyle(fontSize: 11, color: palette.textSecondary)),
                ],
              ),
            ),
            if (isPending)
               Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   IconButton(
                     icon: Icon(Icons.check_circle, color: palette.primary),
                     onPressed: () => social.respondToRequest(u.id, 'accept'),
                   ),
                   IconButton(
                     icon: Icon(Icons.cancel, color: palette.error),
                     onPressed: () => social.respondToRequest(u.id, 'decline'),
                   ),
                 ],
               )
            else if (isFriend)
              IconButton(
                  icon: Icon(Icons.person_remove_rounded, size: 18, color: palette.error),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: CozyTheme.of(context).paperCream,
                        title: const Text("Remove Colleague?"),
                        content: Text("Are you sure you want to remove ${u.username} from your network?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
                          ElevatedButton(
                            onPressed: () async {
                              await social.unfriend(u.id);
                              if (context.mounted) Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: palette.error),
                            child: Text("REMOVE", style: TextStyle(color: palette.textInverse)),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: "Remove Colleague",
                )
            else if (status == 'request_sent')
              Text("SENT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: palette.textSecondary))
            else if (status == 'none')
              ElevatedButton(
                onPressed: () async {
                  await social.sendRequest(u.id);
                  _handleSearch(_searchController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CozyTheme.of(context).primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(60, 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text("ADD", style: TextStyle(fontSize: 10, color: palette.textInverse)),
              ),
          ],
        ),
      ),
    );
  }
}
