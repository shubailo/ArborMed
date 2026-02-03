import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/social_provider.dart';
import '../../services/notification_provider.dart';
import '../../models/user.dart';
import '../cozy/cozy_tile.dart';
import '../cozy/cozy_dialog_sheet.dart';

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
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? const Color(0xFF8CAA8C) : Colors.white,
        foregroundColor: active ? Colors.white : const Color(0xFF8CAA8C),
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: active ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), 
          side: const BorderSide(color: Color(0xFF8CAA8C))
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
          return const Center(child: CircularProgressIndicator(color: Color(0xFF8CAA8C)));
        }

        if (pager.messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text("Your pager is silent.", style: GoogleFonts.quicksand(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pager.messages.length,
          itemBuilder: (context, index) {
            final msg = pager.messages[index];
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
                      color: msg.type == 'admin_alert' ? Colors.orange : const Color(0xFF8CAA8C),
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
                                  color: msg.type == 'admin_alert' ? Colors.orange : const Color(0xFF8CAA8C),
                                  letterSpacing: 1.1,
                                ),
                              ),
                              Text(
                                timeago.format(msg.createdAt),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg.message,
                            style: TextStyle(
                              color: const Color(0xFF5D4037),
                              fontWeight: msg.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          if (msg.senderName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "From: ${msg.senderName}",
                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
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
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                      onPressed: () {
                        // Confirm deletion
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text("Delete Message?"),
                            content: const Text("This record will be permanently removed from your pager."),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
                              ElevatedButton(
                                onPressed: () {
                                  pager.deleteMessage(msg.id, msg.type);
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                child: const Text("DELETE", style: TextStyle(color: Colors.white)),
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
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF8CAA8C)),
                  filled: true,
                  fillColor: Colors.white,
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFF8CAA8C)));
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Text("No doctors found", style: TextStyle(color: Colors.grey)));
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFF8CAA8C)));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (social.pendingRequests.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text("CONSULT REQUESTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFB0BEC5))),
          ),
          ...social.pendingRequests.map((u) => _buildUserTile(u, social, isPending: true)),
          const Divider(height: 32),
        ],

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text("COLLEAGUES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFB0BEC5))),
        ),
        if (social.colleagues.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("No colleagues yet. Search for your peers!", style: TextStyle(color: Colors.grey, fontSize: 13)),
          ))
        else
          ...social.colleagues.map((u) => _buildUserTile(u, social)),
      ],
    );
  }

  Widget _buildUserTile(User u, SocialProvider social, {bool isPending = false}) {
    String? status = u.friendshipStatus;
    
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
              backgroundColor: const Color(0xFFEFEBE9),
              child: Text(u.username?[0].toUpperCase() ?? "D", style: const TextStyle(color: Color(0xFF8CAA8C))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.displayName ?? u.username ?? "Doctor", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
                  Text("Medical ID: #${u.id.toString().padLeft(3, '0')}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            if (isPending)
               Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   IconButton(
                     icon: const Icon(Icons.check_circle, color: Color(0xFF8CAA8C)),
                     onPressed: () => social.respondToRequest(u.id, 'accept'),
                   ),
                   IconButton(
                     icon: const Icon(Icons.cancel, color: Colors.redAccent),
                     onPressed: () => social.respondToRequest(u.id, 'decline'),
                   ),
                 ],
               )
            else if (status == 'colleague')
            IconButton(
                icon: const Icon(Icons.person_remove_rounded, size: 18, color: Colors.redAccent),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text("Remove Colleague?"),
                      content: Text("Are you sure you want to remove ${u.username} from your network?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
                        ElevatedButton(
                          onPressed: () async {
                            await social.unfriend(u.id);
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          child: const Text("REMOVE", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: "Remove Colleague",
              )
            else if (status == 'request_sent')
              const Text("SENT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))
            else if (status == 'none')
              ElevatedButton(
                onPressed: () async {
                  await social.sendRequest(u.id);
                  _handleSearch(_searchController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8CAA8C),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(60, 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("ADD", style: TextStyle(fontSize: 10, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
