import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Represents a clinic facility.
class Clinic {
  final String id;
  final String name;
  final String specialty;
  final String address;

  const Clinic({
    required this.id,
    required this.name,
    required this.specialty,
    required this.address,
  });
}

/// Service managing social networking and directory operations.
class SocialService extends ChangeNotifier {
  final Logger _logger;
  
  bool _isLoading = false;
  List<Clinic> _clinics = [];

  SocialService({Logger? logger}) : _logger = logger ?? Logger();

  bool get isLoading => _isLoading;
  List<Clinic> get clinics => _clinics;

  /// Loads dummy clinic directories
  Future<void> loadDirectory() async {
    _isLoading = true;
    notifyListeners();
    
    _logger.i('Loading clinic directory...');
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    _clinics = [
      const Clinic(
        id: '1',
        name: 'ArborMed Central Clinic',
        specialty: 'General Practice',
        address: '123 Medical Way',
      ),
      const Clinic(
        id: '2',
        name: 'Heart Care Center',
        specialty: 'Cardiology',
        address: '456 Cardiac Ave',
      ),
      const Clinic(
        id: '3',
        name: 'Neurology Institute',
        specialty: 'Neurology',
        address: '789 Brain Blvd',
      ),
    ];
    
    _isLoading = false;
    notifyListeners();
  }
}
