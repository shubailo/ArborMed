import 'package:flutter/material.dart';

class IconPickerDialog extends StatelessWidget {
  final String selectedIcon;
  final Function(String iconName) onIconSelected;

  const IconPickerDialog({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  // Healthcare and study-themed icons - Public for access by Randomizer
  static const Map<String, IconData> availableIcons = {
    'menu_book_rounded': Icons.menu_book_rounded,
    'lightbulb': Icons.lightbulb,
    'favorite': Icons.favorite,
    'star': Icons.star,
    'local_cafe': Icons.local_cafe,
    'self_improvement': Icons.self_improvement,
    'psychology': Icons.psychology,
    'fitness_center': Icons.fitness_center,
    'eco': Icons.eco,
    'emoji_events': Icons.emoji_events,
    'spa': Icons.spa,
    'auto_awesome': Icons.auto_awesome,
    'wb_sunny': Icons.wb_sunny,
    'nights_stay': Icons.nights_stay,
    'rocket_launch': Icons.rocket_launch,
    'medical_services': Icons.medical_services,
    'healing': Icons.healing,
    'monitor_heart': Icons.monitor_heart,
    'local_hospital': Icons.local_hospital,
    'medication': Icons.medication,
    'science': Icons.science,
    'biotech': Icons.biotech,
    'school': Icons.school,
    'border_color': Icons.border_color,
    'library_books': Icons.library_books,
    'quiz': Icons.quiz,
    'timer': Icons.timer,
    'check_circle': Icons.check_circle,
  };

  static IconData getIconData(String iconName) {
    return availableIcons[iconName] ?? Icons.menu_book_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Icon',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, // Denser grid
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: availableIcons.length,
                itemBuilder: (context, index) {
                  final entry = availableIcons.entries.elementAt(index);
                  final iconName = entry.key;
                  final iconData = entry.value;
                  final isSelected = selectedIcon == iconName;

                  return InkWell(
                    onTap: () {
                      onIconSelected(iconName);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8CAA8C)
                            : Colors.grey[50], // Subtle default
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFF6B8E6B), width: 2)
                            : Border.all(color: Colors.grey[200]!),
                      ),
                      child: Icon(
                        iconData,
                        size: 24, // Smaller icon
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
