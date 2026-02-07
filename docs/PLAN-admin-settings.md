# Admin Settings Implementation Plan

## Goal Description
Update the Admin Sidebar to replace the existing "Back" button with a dedicated "Settings" menu. This menu will provide administrative users with quick access to navigation, authentication, and personalization options, specifically:
- **Go to Game**: Navigate back to the student dashboard/game view.
- **Sign Out**: Securely log out of the application.
- **Set Theme**: Toggle between Light and Dark modes.

## User Review Required
> [!NOTE]
> **Design Choice**: The "Settings" item in the sidebar will open a **modal dialog** (using `CozyDialogSheet`) rather than expanding inline or navigating to a full page. This maintains context and aligns with the existing "Hub" design pattern used in the student view. Is this acceptable?

## Proposed Changes

### Mobile Frontend
#### [MODIFY] [admin_sidebar.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/admin/components/admin_sidebar.dart)
- Replace the "Back" `_SidebarItem` with a "Settings" `_SidebarItem` (Icon: `Icons.settings_outlined` / `Icons.settings`).
- Update the `onTap` handler to show the new `AdminSettingsDialog`.

#### [NEW] [admin_settings_dialog.dart](file:///c:/Users/shuba/Desktop/Med_buddy/mobile/lib/screens/admin/components/admin_settings_dialog.dart)
- Create a new widget extending `CozyDialogSheet`.
- **Content**:
    - **Header**: "Admin Settings".
    - **Option 1**: "Go to Game" (Icon: `Icons.videogame_asset_outlined`). Action: `Navigator.pushReplacementNamed(context, '/game')`.
    - **Option 2**: "Theme Mode" (Icon: `Icons.dark_mode_outlined` / `Icons.light_mode_outlined`). Action: Toggle `ThemeService`, update UI state locally.
    - **Option 3**: "Sign Out" (Icon: `Icons.logout_rounded`, Destructive Color). Action: `auth.logout()` + `Navigator.pushNamedAndRemoveUntil('/', ...)`.

## Verification Plan

### Manual Verification
1.  **Sidebar Check**: Verify "Back" button is gone and "Settings" button appears at the bottom.
2.  **Dialog Open**: Click "Settings" and confirm the dialog opens smoothly.
3.  **Theme Toggle**: Click "Theme Mode" and verify the app switches between Light and Dark modes instantly.
4.  **Navigation**: Click "Go to Game" and verify redirection to the Student Dashboard.
5.  **Logout**: Click "Sign Out" and verify redirection to the Login Screen.
