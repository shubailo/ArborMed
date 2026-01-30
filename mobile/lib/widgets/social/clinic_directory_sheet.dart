import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/social_provider.dart';
import '../cozy/floating_medical_icons.dart';
import '../cozy/cozy_tile.dart';
import '../cozy/cozy_dialog_sheet.dart';

class ClinicDirectorySheet extends StatelessWidget {
  const ClinicDirectorySheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SocialProvider>(
      builder: (context, social, _) {
        return CozyDialogSheet(
          onTapOutside: () => Navigator.pop(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unified Header (Back + Close)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF8D6E63)),
                          SizedBox(width: 8),
                          Text(
                            "Medical Network",
                            style: TextStyle(
                              fontFamily: 'Quicksand', 
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: Color(0xFF5D4037)
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF8D6E63)),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),

              // List of Doctor Contacts (Scrollable)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // 1. Add Friend Button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: CozyTile(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Search Medical Network coming soon!'),
                                backgroundColor: Color(0xFF5D7A7A),
                              ),
                            );
                          },
                          backgroundColor: const Color(0xFFF0F7F0),
                          border: const BorderSide(color: Color(0xFF8CAA8C), width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: const Row(
                            children: [
                              Icon(Icons.person_add_rounded, color: Color(0xFF8CAA8C), size: 24),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  "Add New Colleague",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16, 
                                    fontWeight: FontWeight.bold, 
                                    color: Color(0xFF8CAA8C)
                                  ),
                                ),
                              ),
                              Icon(Icons.add_rounded, color: Color(0xFF8CAA8C), size: 24),
                            ],
                          ),
                        ),
                      ),

                      // 2. Friends list
                      ...social.friends.map((doctor) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: CozyTile(
                            onTap: () {
                              social.startVisiting(doctor.id);
                              Navigator.pop(context);
                            },
                            isListTile: true,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doctor.name,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 16, 
                                          fontWeight: FontWeight.bold, 
                                          color: Color(0xFF5D4037)
                                        ),
                                      ),
                                      Text(
                                        doctor.level,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12, 
                                          color: Color(0xFF8CAA8C)
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_rounded, color: Color(0xFF8CAA8C), size: 24),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ], 
          ),
        );
      },
    );
  }
}
