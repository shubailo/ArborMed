/// Avatar asset catalog — maps item IDs to SVG layer strings.
/// Adapted from RoadTripMoustache/avatar_maker (MIT License).
///
/// Each category maps string IDs to inline SVG `<g>` fragments
/// that are composed by [AvatarRenderer].
///
/// Color placeholders use Dart string interpolation at render time.
class AvatarAssets {
  AvatarAssets._();

  // ── Skin Colors ──────────────────────────────────────────────
  static const Map<String, String> skinColors = {
    'tanned': '#FD9841',
    'yellow': '#F8D25C',
    'white': '#FFDBB4',
    'peach': '#EDB98A',
    'brown': '#D08B5B',
    'dark_brown': '#AE5D29',
    'black': '#614335',
  };

  // ── Hair Colors ──────────────────────────────────────────────
  static const Map<String, String> hairColors = {
    'auburn': '#A55728',
    'black': '#2C1B18',
    'blonde': '#B58143',
    'blonde_golden': '#D6B370',
    'brown': '#724133',
    'brown_dark': '#4A312C',
    'pastel_pink': '#F59797',
    'platinum': '#ECDCBF',
    'red': '#C93305',
    'silver': '#E8E1E1',
  };

  // ── Outfit Colors ────────────────────────────────────────────
  static const Map<String, String> outfitColors = {
    'black': '#262E33',
    'blue01': '#65C9FF',
    'blue02': '#5199E4',
    'blue03': '#25557C',
    'gray01': '#929598',
    'gray02': '#3C4F5C',
    'heather': '#3C4F5C',
    'pastel_blue': '#B1E2FF',
    'pastel_green': '#A7FFC4',
    'pastel_orange': '#FFDEB5',
    'pastel_red': '#FFAFB9',
    'pastel_yellow': '#FFFFB1',
    'pink': '#FF488E',
    'red': '#FF5C5C',
    'white': '#FFFFFF',
  };

  // ── Category Labels (for Studio UI) ──────────────────────────
  static const List<AvatarCategory> categories = [
    AvatarCategory(
      id: 'skin_color',
      label: 'Skin',
      icon: '🎨',
      isColorPicker: true,
    ),
    AvatarCategory(id: 'hair', label: 'Hair', icon: '💇'),
    AvatarCategory(
      id: 'hair_color',
      label: 'Hair Color',
      icon: '🎨',
      isColorPicker: true,
    ),
    AvatarCategory(id: 'eyes', label: 'Eyes', icon: '👁️'),
    AvatarCategory(id: 'eyebrows', label: 'Eyebrows', icon: '🤨'),
    AvatarCategory(id: 'mouth', label: 'Mouth', icon: '👄'),
    AvatarCategory(id: 'facial_hair', label: 'Facial Hair', icon: '🧔'),
    AvatarCategory(id: 'outfit', label: 'Outfit', icon: '👕'),
    AvatarCategory(
      id: 'outfit_color',
      label: 'Outfit Color',
      icon: '🎨',
      isColorPicker: true,
    ),
    AvatarCategory(id: 'accessory', label: 'Accessory', icon: '🕶️'),
  ];

  // ── SVG Data Maps ───────────────────────────────────────────

  static const Map<String, String> eyesSvg = {
    'default': '<circle cx="30" cy="22" r="6" fill-opacity="0.6" fill="#000000" /><circle cx="82" cy="22" r="6" fill-opacity="0.6" fill="#000000" />',
    'closed': '<path d="M16 32c2-4 6-6 11-6s9 2 11 6" stroke="#000" stroke-width="2" fill="none" /><path d="M74 32c2-4 6-6 11-6s9 2 11 6" stroke="#000" stroke-width="2" fill="none" />',
    'happy': '<path d="M16 26c2 4 6 6 11 6s9-2 11-6" stroke="#000" stroke-width="2" fill="none" /><path d="M74 26c2 4 6 6 11 6s9-2 11-6" stroke="#000" stroke-width="2" fill="none" />',
    'cry': '<circle cx="30" cy="22" r="6" fill="#000" fill-opacity="0.6"/><path d="M25 27c0 0-6 7-6 11s2 6 5 6 6-5 6-11-5-6-5-6z" fill="#92D9FF"/><circle cx="82" cy="22" r="6" fill="#000" fill-opacity="0.6"/>',
  };

  static const Map<String, String> eyebrowSvg = {
    'default': '<path d="M12 12c4-6 15-9 24-7" stroke="#000" stroke-width="2" fill="none" transform="translate(0,-4)"/><path d="M72 12c4-6 15-9 24-7" stroke="#000" stroke-width="2" fill="none" transform="translate(0,-4) scale(-1,1) translate(-168,0)"/>',
    'angry': '<path d="M15 15c4-6 7-6 13-1" stroke="#000" stroke-width="2" fill="none"/><path d="M73 15c4-6 7-6 13-1" stroke="#000" stroke-width="2" fill="none" transform="scale(-1,1) translate(-168,0)"/>',
  };

  static const Map<String, String> mouthSvg = {
    'default': '<path d="M40 15c0 8 6 14 14 14s14-6 14-14" stroke="#000" stroke-width="2" fill="none" transform="translate(2, 52)"/>',
    'smile': '<path d="M35 15c1 9 9 17 19 17s18-8 19-17" fill="#000" fill-opacity="0.7" transform="translate(2, 52)"/>',
    'sad': '<path d="M40 29c0-8 6-14 14-14s14 6 14 14" stroke="#000" stroke-width="2" fill="none" transform="translate(2, 52)"/>',
  };

  static const Map<String, String> facialHairSvg = {
    'nothing': '',
    'beard_medium': '<path d="M27 26c0 40 115 40 115 0" fill="\$COLOR_PLACEHOLDER" opacity="0.8" transform="translate(-28, -8)"/>',
  };

  static const Map<String, String> outfitSvg = {
    'hoodie': '<path d="M40 140h120v60H40z" fill="\$COLOR_PLACEHOLDER"/><path d="M70 140l-20 20v40h60v-60H70z" fill="#000" opacity="0.1"/>',
    'blazer': '<path d="M40 140h120v60H40z" fill="\$COLOR_PLACEHOLDER"/><path d="M80 140l20 60 20-60z" fill="#fff" opacity="0.5"/>',
  };

  static const Map<String, String> accessorySvg = {
    'nothing': '',
    'glasses': '<path d="M20 30h30v10H20zM70 30h30v10H70z" fill="#D6EAF2" stroke="#000" stroke-width="2"/>',
  };

  static const Map<String, String> hairSvg = {
    'bald': '',
    'short_flat': '<path d="M40 60c0-40 120-40 120 0z" fill="\$COLOR_PLACEHOLDER"/>',
    'long_straight': '<path d="M40 60c-20 0-20 100-20 100h160s0-100-20-100z" fill="\$COLOR_PLACEHOLDER"/>',
  };


  /// Returns item list for a given category ID.
  static List<String> getItemsForCategory(String categoryId) {
    switch (categoryId) {
      case 'hair':
        return hairSvg.keys.toList();
      case 'eyes':
        return eyesSvg.keys.toList();
      case 'eyebrows':
        return eyebrowSvg.keys.toList();
      case 'mouth':
        return mouthSvg.keys.toList();
      case 'facial_hair':
        return facialHairSvg.keys.toList();
      case 'outfit':
        return outfitSvg.keys.toList();
      case 'accessory':
        return accessorySvg.keys.toList();
      case 'skin_color':
        return skinColors.keys.toList();
      case 'hair_color':
        return hairColors.keys.toList();
      case 'outfit_color':
        return outfitColors.keys.toList();
      default:
        return [];
    }
  }

  static String getSvgForId(String categoryId, String itemId) {
    switch (categoryId) {
      case 'hair': return hairSvg[itemId] ?? '';
      case 'eyes': return eyesSvg[itemId] ?? '';
      case 'eyebrows': return eyebrowSvg[itemId] ?? '';
      case 'mouth': return mouthSvg[itemId] ?? '';
      case 'facial_hair': return facialHairSvg[itemId] ?? '';
      case 'outfit': return outfitSvg[itemId] ?? '';
      case 'accessory': return accessorySvg[itemId] ?? '';
      default: return '';
    }
  }
}

class AvatarCategory {
  final String id;
  final String label;
  final String icon;
  final bool isColorPicker;

  const AvatarCategory({
    required this.id,
    required this.label,
    required this.icon,
    this.isColorPicker = false,
  });
}
