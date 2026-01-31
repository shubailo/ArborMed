import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/social_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SocialProvider>(context, listen: false).fetchNetwork();
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
    return Consumer<SocialProvider>(
      builder: (context, social, _) {
        return CozyDialogSheet(
          onTapOutside: () => Navigator.pop(context),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Medical Network",
                      style: TextStyle(fontFamily: 'Quicksand', fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF5D4037)),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _handleSearch,
                  decoration: InputDecoration(
                    hintText: "Search @handle or ID...",
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
          ),
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
           // Users can visit ANYONE now!
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
                onPressed: () => social.unfriend(u.id),
                tooltip: "Remove Colleague",
              )
            else if (status == 'request_sent')
              const Text("SENT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))
            else if (status == 'none')
              ElevatedButton(
                onPressed: () async {
                  await social.sendRequest(u.id);
                  _handleSearch(_searchController.text); // Refresh row UI
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
