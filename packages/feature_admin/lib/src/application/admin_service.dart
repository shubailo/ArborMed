import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:logger/logger.dart';

import 'package:arbormed_core/arbormed_core.dart'; // contains Isar setup

class AdminService extends ChangeNotifier {
  final Logger _logger;
  final DatabaseService _dbService;
  
  bool _isLoading = false;
  List<dynamic> _questions = []; // Will switch to QuestionCollection once verified

  AdminService({Logger? logger, required DatabaseService dbService}) 
    : _logger = logger ?? Logger(),
      _dbService = dbService;

  bool get isLoading => _isLoading;
  List<dynamic> get questions => _questions;

  Future<void> fetchQuestions() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // _questions = await _dbService.isar.questions.where().findAll();
      _logger.i('Fetched questions successfully');
    } catch (e) {
      _logger.e('Failed to fetch questions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
