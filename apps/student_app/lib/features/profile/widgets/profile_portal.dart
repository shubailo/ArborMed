import 'package:flutter/material.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'package:arbor_med/widgets/cozy/cozy_dialog_sheet.dart';
import 'package:arbor_med/widgets/cozy/cozy_panel.dart';
import 'package:arbor_med/widgets/cozy/liquid_button.dart';
import 'package:arbor_med/services/audio_provider.dart';
import 'activity_view.dart';
import 'change_password_dialog.dart';

enum ProfileTab { profile, activity }

class ProfilePortal extends StatefulWidget {
  final Function(String name, String slug)? onSectionSelected;

  const ProfilePortal({super.key, this.onSectionSelected});

  @override
  createState() => _ProfilePortalState();
}

class _ProfilePortalState extends State<ProfilePortal> {
  ProfileTab _activeTab = ProfileTab.profile;

  int? _failedSession;
  bool _editorOpen = false;
  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final session = auth.sessionRevision;
    try {
      await auth.refreshUser();
      if (mounted &&
          session == auth.sessionRevision &&
          _failedSession != null) {
        setState(() => _failedSession = null);
      }
    } catch (_) {
      if (mounted && session == auth.sessionRevision) {
        setState(() => _failedSession = session);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
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
              child: _activeTab == ProfileTab.profile
                  ? _buildProfileContent()
                  : const ActivityView(),
            ),
          ),

          // Bottom Navigation
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (user == null) {
      return Center(
          child:
              CircularProgressIndicator(color: CozyTheme.of(context).primary));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (_failedSession == auth.sessionRevision)
          TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.profileRefreshRetry)),
        // Avatar & Identity Header
        Center(
          child: Column(
            children: [
              // Avatar Placeholder (Default Bean)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: CozyTheme.of(context).paperCream,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: CozyTheme.of(context).primary, width: 4),
                  boxShadow: [
                    BoxShadow(
                        color: CozyTheme.of(context)
                            .textPrimary
                            .withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Icon(Icons.person_pin,
                    size: 80, color: CozyTheme.of(context).primary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                      child: Text(
                    user.displayName ?? user.username ?? 'Doctor',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: CozyTheme.of(context).textPrimary),
                  )),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: AppLocalizations.of(context)!.changeNickname,
                    child: GestureDetector(
                      onTap: () {
                        Provider.of<AudioProvider>(context, listen: false)
                            .playSfx('click');
                        _showChangeNicknameDialog();
                      },
                      child: Icon(Icons.badge_outlined,
                          size: 20, color: CozyTheme.of(context).primary),
                    ),
                  ),
                ],
              ),
              Text(
                "@${user.username ?? 'doctor'}",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: CozyTheme.of(context).textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                "${AppLocalizations.of(context)!.medicalId}: #${user.id.toString().padLeft(3, '0')}",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: CozyTheme.of(context)
                        .textSecondary
                        .withValues(alpha: 0.5),
                    letterSpacing: 1.2),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Stats Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2, // Much smaller height
          children: [
            _buildStatTile(
                AppLocalizations.of(context)!.streak,
                user.streakCount.toString(),
                Icons.local_fire_department,
                CozyTheme.of(context).warning),
            _buildStatTile(AppLocalizations.of(context)!.xp, user.xp.toString(),
                Icons.bolt, CozyTheme.of(context).primary),
          ],
        ),

        const SizedBox(height: 32),

        // Settings Section
        Text(AppLocalizations.of(context)!.accountSettings,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF8D6E63))),
        const SizedBox(height: 12),

        CozyPanel(
          onTap: () => showChangePasswordDialog(context),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.lock_outline,
                  color: CozyTheme.of(context).textPrimary),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.changePassword,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: CozyTheme.of(context).textPrimary)),
              const Spacer(),
              Icon(Icons.chevron_right,
                  color: CozyTheme.of(context)
                      .textSecondary
                      .withValues(alpha: 0.5)),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatTile(
      String label, String value, IconData icon, Color color) {
    return CozyPanel(
      onTap: () {},
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: CozyTheme.of(context).textSecondary)),
            ],
          ),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: CozyTheme.of(context).textPrimary)),
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
                  AppLocalizations.of(context)!.profile,
                  _activeTab == ProfileTab.profile,
                  () => setState(() => _activeTab = ProfileTab.profile))),
          const SizedBox(width: 12),
          Expanded(
              child: _buildBottomButton(
                  AppLocalizations.of(context)!.activityTab,
                  _activeTab == ProfileTab.activity,
                  () => setState(() => _activeTab = ProfileTab.activity))),
        ],
      ),
    );
  }

  Widget _buildBottomButton(String label, bool active, VoidCallback onTap) {
    return LiquidButton(
      onPressed: onTap,
      label: label.toUpperCase(),
      variant:
          active ? LiquidButtonVariant.primary : LiquidButtonVariant.outline,
      enabled: true,
    );
  }

  Future<void> _showChangeNicknameDialog() async {
    final auth = context.read<AuthProvider>();
    final owner = auth.user?.id;
    if (owner == null || _editorOpen) return;
    final session = auth.sessionRevision;
    final initialName = auth.user?.displayName ?? '';
    _editorOpen = true;
    bool? saved;
    try {
      saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _NicknameEditor(
            auth: auth,
            owner: owner,
            session: session,
            initialName: initialName),
      );
    } finally {
      _editorOpen = false;
    }
    if (!mounted ||
        saved != true ||
        auth.sessionRevision != session ||
        auth.user?.id != owner) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nicknameUpdated)));
  }
}

class _NicknameEditor extends StatefulWidget {
  final AuthProvider auth;
  final int owner;
  final int session;
  final String initialName;
  const _NicknameEditor(
      {required this.auth,
      required this.owner,
      required this.session,
      required this.initialName});
  @override
  State<_NicknameEditor> createState() => _NicknameEditorState();
}

class _NicknameEditorState extends State<_NicknameEditor> {
  final _form = GlobalKey<FormState>();
  late String _name = widget.initialName;
  bool _saving = false;
  bool _failed = false;
  bool get _current =>
      widget.auth.sessionRevision == widget.session &&
      widget.auth.user?.id == widget.owner;

  Future<void> _save() async {
    if (_saving || !_current || !(_form.currentState?.validate() ?? false)) {
      return;
    }
    final route = ModalRoute.of(context)!;
    final navigator = Navigator.of(context);
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.auth.updateNickname(_name.trim());
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted || !route.isActive) return;
    if (route.isCurrent) {
      navigator.pop(_current);
    } else {
      navigator.removeRoute(route, _current);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return ListenableBuilder(
        listenable: widget.auth,
        builder: (context, _) => PopScope(
              canPop: !_saving || !_current,
              child: AlertDialog(
                scrollable: true,
                title: Text(strings.changeNickname),
                content: _current
                    ? Form(
                        key: _form,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(strings.nicknameHint),
                          TextFormField(
                              initialValue: widget.initialName,
                              enabled: !_saving,
                              autofocus: true,
                              onChanged: (value) => _name = value,
                              onFieldSubmitted: (_) => _save(),
                              decoration: InputDecoration(
                                  labelText: strings.enterNickname),
                              validator: (value) {
                                final name = value?.trim() ?? '';
                                return name.isEmpty || name.runes.length > 255
                                    ? strings.nicknameLength
                                    : null;
                              }),
                          if (_failed) Text(strings.nicknameSaveFailed),
                        ]))
                    : Text(strings.profileSessionChanged),
                actions: [
                  TextButton(
                      onPressed: _saving && _current
                          ? null
                          : () => Navigator.pop(context, false),
                      child: Text(strings.cancel.toUpperCase())),
                  if (_current)
                    ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: Text(strings.save.toUpperCase())),
                ],
              ),
            ));
  }
}
