import 'package:flutter/material.dart';
 import 'package:mobile/screens/admin/dashboard_screen.dart';
 import 'package:mobile/screens/admin/questions_screen.dart';
 import 'package:mobile/screens/admin/admin_quotes_screen.dart';
 import 'package:mobile/screens/admin/admin_users_screen.dart';
 import '../../../widgets/admin/admin_guard.dart';
import '../../../theme/cozy_theme.dart';
import '../components/admin_sidebar.dart';
import '../components/command_center.dart'; // NEW
import 'package:flutter/services.dart'; // NEW

class AdminResponsiveShell extends StatefulWidget {
  const AdminResponsiveShell({super.key});

  @override
  State<AdminResponsiveShell> createState() => _AdminResponsiveShellState();
}

class _AdminResponsiveShellState extends State<AdminResponsiveShell> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;
  final GlobalKey<AdminQuestionsScreenState> _questionsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _screens = [
      const AdminDashboardScreen(),
      AdminQuestionsScreen(key: _questionsKey),
      const AdminUsersScreen(),
      const AdminQuotesScreen(),
    ];
  }

  void _onDestinationSelected(int index) {
    // Handle "Back to App" button (index 4)
    if (index == 4) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.pushReplacementNamed(context, '/game');
      }
      return;
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showCommandCenter() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.1),
      builder: (context) => AdminCommandCenter(
        onNavigate: _onDestinationSelected,
        onAction: _handleCommand,
        onExit: () => _onDestinationSelected(4),
      ),
    );
  }

  void _handleCommand(String command) {
    if (command == 'new_question') {
      _onDestinationSelected(1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _questionsKey.currentState?.showQuestionEditor(null);
      });
    } else if (command == 'new_ecg') {
      _onDestinationSelected(1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _questionsKey.currentState?.showECGEditor(null);
      });
    }
  }

  void _handleGlobalKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isControlPressed = HardwareKeyboard.instance.isControlPressed;
      final isDesktop = MediaQuery.of(context).size.width > 900;

      // 1. Tab to open Command Center (only if not in a text field)
      if (event.logicalKey == LogicalKeyboardKey.tab && !isControlPressed) {
        final focus = FocusManager.instance.primaryFocus;
        if (focus == null || (focus.context?.widget is! EditableText && focus.context?.widget is! TextField)) {
          if (isDesktop) {
            _showCommandCenter();
          }
        }
      }

      // 2. Ctrl + [Letter] Commands
      if (isControlPressed) {
        if (event.logicalKey == LogicalKeyboardKey.keyD) {
          _onDestinationSelected(0);
        } else if (event.logicalKey == LogicalKeyboardKey.keyQ) {
          _onDestinationSelected(1);
        } else if (event.logicalKey == LogicalKeyboardKey.keyU) {
          _onDestinationSelected(2);
        } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
          _onDestinationSelected(3);
        } else if (event.logicalKey == LogicalKeyboardKey.keyN) {
          _handleCommand('new_question');
        } else if (event.logicalKey == LogicalKeyboardKey.keyE) {
          _handleCommand('new_ecg');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    return AdminGuard(
      child: Scaffold(
        backgroundColor: palette.background,
        body: KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          autofocus: true,
          onKeyEvent: _handleGlobalKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return _buildDesktopLayout();
              } else {
                return _buildMobileLayout();
              }
            },
          ),
        ),
        bottomNavigationBar: MediaQuery.of(context).size.width <= 900
            ? NavigationBarTheme(
                data: NavigationBarThemeData(
                  indicatorColor: Colors.white.withValues(alpha: 0.1),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12);
                    }
                    return TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12);
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const IconThemeData(color: Colors.white, size: 26);
                    }
                    return IconThemeData(color: Colors.white.withValues(alpha: 0.7), size: 24);
                  }),
                ),
                child: NavigationBar(
                  backgroundColor: palette.textPrimary, // Brown for Mobile too
                  elevation: 10,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
                    NavigationDestination(icon: Icon(Icons.question_answer_outlined), selectedIcon: Icon(Icons.question_answer_rounded), label: 'Questions'),
                    NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people_rounded), label: 'Users'),
                    NavigationDestination(icon: Icon(Icons.format_quote_outlined), selectedIcon: Icon(Icons.format_quote_rounded), label: 'Quotes'),
                    NavigationDestination(icon: Icon(Icons.exit_to_app), selectedIcon: Icon(Icons.exit_to_app), label: 'Exit'),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        AdminSidebar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
        ),
        Expanded(
          child: RepaintBoundary(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.02, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey('admin_screen_$_selectedIndex'),
                child: _screens[_selectedIndex],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey('admin_screen_mobile_$_selectedIndex'),
        child: _screens[_selectedIndex],
      ),
    );
  }
}
