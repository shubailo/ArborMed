# Wireframe Descriptions & Mockups

## Profile Modal - Tab Redesign
The current Profile modal uses pill-shaped buttons for tabs, which can look like actions instead of navigation. We recommend a segmented control or connected tab design.

```mermaid
graph TD
    A[Profile Header Info: Avatar, Name, ID] --> B[Segmented Control / Tabs]
    B --> C(Profile Tab Active)
    B --> D(Activity Tab Inactive)
    C --> E[Streak & XP Stats]
    C --> F[Action Buttons: Start Session, etc.]
```

### Text Mockup:
```text
+---------------------------------------+
|             [ Avatar ]                |
|           Test Agent                  |
|          @testagent                   |
|                                       |
|  [    PROFILE    |    Activity   ]    |
|  +---------------------------------+  |
|  |  🔥 Streak: 0      ⚡ XP: 0    |  |
|  +---------------------------------+  |
+---------------------------------------+
```

## Settings Screen - Destructive Action
The "Delete Account" button needs visual demotion to prevent accidental clicks.

### Text Mockup:
```text
+---------------------------------------+
|                SETTINGS               |
|                                       |
|  [Toggle] Sound Effects               |
|  [Toggle] Haptic Feedback             |
|                                       |
|  [        LOG OUT (Primary)       ]   |
|                                       |
|  -----------------------------------  |
|        [ Delete Account (Text) ]      |
+---------------------------------------+
```
