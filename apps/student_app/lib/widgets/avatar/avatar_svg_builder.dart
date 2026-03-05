import '../../models/avatar_config.dart';
import '../../models/avatar_assets.dart';

/// Generates a complete SVG string from an [AvatarConfig].
///
/// Adapted from AvatarService in RoadTripMoustache/avatar_maker (MIT).
/// Uses a 264x280 viewBox to match the reference avatar system.
class AvatarSvgBuilder {
  AvatarSvgBuilder._();

  /// Build a full composited SVG from config.
  static String build(AvatarConfig config) {
    final skinHex = AvatarAssets.skinColors[config.palette.skin] ?? '#EDB98A';
    final hairHex = AvatarAssets.hairColors[config.palette.hair] ?? '#2C1B18';
    final outfitHex =
        AvatarAssets.outfitColors[config.palette.outfit] ?? '#65C9FF';

    // Compose layers bottom-to-top
    final skinLayer = _buildSkinLayer(skinHex);
    final outfitLayer = _buildOutfitLayer(config.layers['outfit'], outfitHex);
    final mouthLayer = _buildSimpleLayer(
      'mouth',
      config.layers['mouth'] ?? 'default',
    );
    final eyeLayer = _buildSimpleLayer(
      'eyes',
      config.layers['eyes'] ?? 'default',
    );
    final eyebrowLayer = _buildSimpleLayer(
      'eyebrows',
      config.layers['eyebrows'] ?? 'default',
    );
    final noseLayer = _buildNoseLayer();
    final facialHairLayer = _buildFacialHairLayer(
      config.layers['facial_hair'],
      hairHex,
    );
    final hairLayer = _buildHairLayer(config.layers['hair'], hairHex);
    final accessoryLayer = _buildAccessoryLayer(config.layers['accessory']);

    return '''
<svg width="264px" height="280px" viewBox="0 0 264 280" version="1.1"
  xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
  <defs>
    <path
      d="M124,144.610951 L124,163 L128,163 L128,163 C167.764502,163 200,195.235498 200,235 L200,244 L0,244 L0,235 C-4.86974701e-15,195.235498 32.235498,163 72,163 L72,163 L76,163 L76,144.610951 C58.7626345,136.422372 46.3722246,119.687011 44.3051388,99.8812385 C38.4803105,99.0577866 34,94.0521096 34,88 L34,74 C34,68.0540074 38.3245733,63.1180731 44,62.1659169 L44,56 L44,56 C44,25.072054 69.072054,5.68137151e-15 100,0 L100,0 L100,0 C130.927946,-5.68137151e-15 156,25.072054 156,56 L156,62.1659169 C161.675427,63.1180731 166,68.0540074 166,74 L166,88 C166,94.0521096 161.51969,99.0577866 155.694861,99.8812385 C153.627775,119.687011 141.237365,136.422372 124,144.610951 Z"
      id="body-path" />
    <circle id="head-circle" cx="132" cy="92" r="55" />
  </defs>
  <g id="AvatarMaker" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
    <g id="Body" transform="translate(32.000000, 36.000000)">
      <mask id="body-mask" fill="white">
        <use xlink:href="#body-path" />
      </mask>
      <use fill="#D0C6AC" xlink:href="#body-path" />
      $skinLayer
      <path
        d="M156,79 L156,102 C156,132.927946 130.927946,158 100,158 C69.072054,158 44,132.927946 44,102 L44,79 L44,94 C44,124.927946 69.072054,150 100,150 C130.927946,150 156,124.927946 156,94 L156,79 Z"
        id="Neck-Shadow" opacity="0.100000001" fill="#000000"
        mask="url(#body-mask)" />
    </g>
    $outfitLayer
    <g id="Face" transform="translate(76.000000, 82.000000)">
      $mouthLayer
      $noseLayer
      $eyeLayer
      $eyebrowLayer
    </g>
    $facialHairLayer
    $hairLayer
    $accessoryLayer
  </g>
</svg>
''';
  }

  static String _buildSkinLayer(String hex) {
    return '''
      <g id="SkinColor" mask="url(#body-mask)" fill="$hex">
        <g transform="translate(0.000000, 0.000000)">
          <rect x="0" y="0" width="264" height="280" />
        </g>
      </g>
    ''';
  }

  static String _buildOutfitLayer(String? outfitId, String colorHex) {
    if (outfitId == null) return '';
    return '''
    <g id="Outfit" transform="translate(0.000000, 170.000000)">
      <defs>
        <path d="M133.960472,0.294916112 C170.936473,3.32499816 200,34.2942856 200,72.0517235 L200,81 L0,81 L0,72.0517235 C1.22536245e-14,33.9525631 29.591985,2.76498122 67.0454063,0.219526408 C67.0152598,0.593114549 67,0.969227185 67,1.34762511 C67,13.2107177 81.9984609,22.8276544 100.5,22.8276544 C119.001539,22.8276544 134,13.2107177 134,1.34762511 C134,0.994669088 133.986723,0.64370138 133.960472,0.294916112 Z" id="outfit-path" />
      </defs>
      <g id="Shirt" transform="translate(32.000000, 29.000000)">
        <mask id="outfit-mask" fill="white">
          <use xlink:href="#outfit-path" />
        </mask>
        <use id="Clothes" fill="#E6E6E6" xlink:href="#outfit-path" />
        <g id="OutfitColor" mask="url(#outfit-mask)" fill="$colorHex">
          <g transform="translate(-32.000000, -29.000000)">
            <rect x="0" y="0" width="264" height="110" />
          </g>
        </g>
      </g>
    </g>
    ''';
  }

  static String _buildSimpleLayer(String type, String? itemId) {
    if (itemId == null || itemId == 'nothing') return '';

    // Return simplified SVG groups for each feature type
    switch (type) {
      case 'eyes':
        return _buildEyes(itemId);
      case 'eyebrows':
        return _buildEyebrows(itemId);
      case 'mouth':
        return _buildMouth(itemId);
      default:
        return '';
    }
  }

  static String _buildEyes(String id) {
    switch (id) {
      case 'default':
        return '''
        <g id="Eyes" transform="translate(22.000000, 30.000000)">
          <circle id="Eye-Left" fill="#FFFFFF" cx="26" cy="22" r="12" />
          <circle id="Pupil-Left" fill="#1F1F1F" cx="26" cy="22" r="6" />
          <circle id="Eye-Right" fill="#FFFFFF" cx="86" cy="22" r="12" />
          <circle id="Pupil-Right" fill="#1F1F1F" cx="86" cy="22" r="6" />
        </g>
        ''';
      case 'happy':
        return '''
        <g id="Eyes" transform="translate(22.000000, 30.000000)">
          <path d="M14,23 C14,27 20,33 26,33 C32,33 38,27 38,23" fill="none" stroke="#1F1F1F" stroke-width="2" stroke-linecap="round" />
          <path d="M74,23 C74,27 80,33 86,33 C92,33 98,27 98,23" fill="none" stroke="#1F1F1F" stroke-width="2" stroke-linecap="round" />
        </g>
        ''';
      case 'wink':
        return '''
        <g id="Eyes" transform="translate(22.000000, 30.000000)">
          <circle id="Eye-Left" fill="#FFFFFF" cx="26" cy="22" r="12" />
          <circle id="Pupil-Left" fill="#1F1F1F" cx="26" cy="22" r="6" />
          <path d="M74,23 C74,27 80,33 86,33 C92,33 98,27 98,23" fill="none" stroke="#1F1F1F" stroke-width="2" stroke-linecap="round" />
        </g>
        ''';
      case 'surprised':
        return '''
        <g id="Eyes" transform="translate(22.000000, 30.000000)">
          <circle id="Eye-Left" fill="#FFFFFF" cx="26" cy="22" r="14" />
          <circle id="Pupil-Left" fill="#1F1F1F" cx="26" cy="22" r="5" />
          <circle id="Eye-Right" fill="#FFFFFF" cx="86" cy="22" r="14" />
          <circle id="Pupil-Right" fill="#1F1F1F" cx="86" cy="22" r="5" />
        </g>
        ''';
      case 'hearts':
        return '''
        <g id="Eyes" transform="translate(22.000000, 30.000000)">
          <path d="M21,17 C21,14 23,12 26,12 C29,12 31,14 31,17 C31,22 26,27 26,27 C26,27 21,22 21,17 Z" fill="#FF5353" />
          <path d="M81,17 C81,14 83,12 86,12 C89,12 91,14 91,17 C91,22 86,27 86,27 C86,27 81,22 81,17 Z" fill="#FF5353" />
        </g>
        ''';
      default:
        return _buildEyes('default');
    }
  }

  static String _buildEyebrows(String id) {
    switch (id) {
      case 'default':
        return '''
        <g id="Eyebrows" transform="translate(22.000000, 18.000000)">
          <path d="M15,6 C18,2 24,0 30,2 C32,3 33,4 34,6" fill="none" stroke="#1F1F1F" stroke-width="2.5" stroke-linecap="round" />
          <path d="M78,6 C81,2 87,0 93,2 C95,3 96,4 97,6" fill="none" stroke="#1F1F1F" stroke-width="2.5" stroke-linecap="round" />
        </g>
        ''';
      case 'angry':
        return '''
        <g id="Eyebrows" transform="translate(22.000000, 18.000000)">
          <path d="M15,8 L34,2" fill="none" stroke="#1F1F1F" stroke-width="3" stroke-linecap="round" />
          <path d="M78,2 L97,8" fill="none" stroke="#1F1F1F" stroke-width="3" stroke-linecap="round" />
        </g>
        ''';
      case 'raised_excited':
        return '''
        <g id="Eyebrows" transform="translate(22.000000, 13.000000)">
          <path d="M15,8 C18,2 24,0 34,4" fill="none" stroke="#1F1F1F" stroke-width="2.5" stroke-linecap="round" />
          <path d="M78,4 C88,0 94,2 97,8" fill="none" stroke="#1F1F1F" stroke-width="2.5" stroke-linecap="round" />
        </g>
        ''';
      case 'sad_concerned':
        return '''
        <g id="Eyebrows" transform="translate(22.000000, 18.000000)">
          <path d="M15,2 L34,8" fill="none" stroke="#1F1F1F" stroke-width="2.5" stroke-linecap="round" />
          <path d="M78,8 L97,2" fill="none" stroke="#1F1F1F" stroke-width="2.5" stroke-linecap="round" />
        </g>
        ''';
      default:
        return _buildEyebrows('default');
    }
  }

  static String _buildMouth(String id) {
    switch (id) {
      case 'default':
        return '''
        <g id="Mouth" transform="translate(30.000000, 68.000000)">
          <path d="M22,8 C28,16 38,16 44,8" fill="none" stroke="#1F1F1F" stroke-width="2" stroke-linecap="round" />
        </g>
        ''';
      case 'smile':
        return '''
        <g id="Mouth" transform="translate(30.000000, 66.000000)">
          <path d="M16,8 C24,20 42,20 50,8" fill="#FFFFFF" stroke="#1F1F1F" stroke-width="2" stroke-linecap="round" />
        </g>
        ''';
      case 'serious':
        return '''
        <g id="Mouth" transform="translate(30.000000, 72.000000)">
          <line x1="22" y1="6" x2="44" y2="6" stroke="#1F1F1F" stroke-width="2.5" stroke-linecap="round" />
        </g>
        ''';
      case 'sad':
        return '''
        <g id="Mouth" transform="translate(30.000000, 70.000000)">
          <path d="M22,14 C28,6 38,6 44,14" fill="none" stroke="#1F1F1F" stroke-width="2" stroke-linecap="round" />
        </g>
        ''';
      case 'tongue':
        return '''
        <g id="Mouth" transform="translate(30.000000, 66.000000)">
          <path d="M18,8 C24,18 42,18 48,8" fill="#FFFFFF" stroke="#1F1F1F" stroke-width="2" />
          <ellipse cx="33" cy="16" rx="5" ry="6" fill="#FF6B6B" />
        </g>
        ''';
      default:
        return _buildMouth('default');
    }
  }

  static String _buildNoseLayer() {
    return '''
    <g id="Nose" transform="translate(48.000000, 52.000000)">
      <path d="M16,8 C16,12 12,16 8,16 C4,16 0,12 0,8" fill="none" stroke="#1F1F1F" stroke-width="1.5" stroke-linecap="round" opacity="0.5" />
    </g>
    ''';
  }

  static String _buildFacialHairLayer(String? id, String colorHex) {
    if (id == null || id == 'nothing') return '';

    switch (id) {
      case 'beard_light':
        return '''
        <g id="FacialHair" transform="translate(76.000000, 140.000000)">
          <path d="M16,15 C16,28 30,35 56,35 C82,35 96,28 96,15" fill="none" stroke="$colorHex" stroke-width="3" opacity="0.4" />
        </g>
        ''';
      case 'beard_medium':
        return '''
        <g id="FacialHair" transform="translate(76.000000, 134.000000)">
          <path d="M10,15 C10,38 30,50 56,50 C82,50 102,38 102,15" fill="$colorHex" opacity="0.85" />
        </g>
        ''';
      case 'beard_majestic':
        return '''
        <g id="FacialHair" transform="translate(76.000000, 130.000000)">
          <path d="M6,15 C6,48 25,65 56,65 C87,65 106,48 106,15" fill="$colorHex" opacity="0.9" />
        </g>
        ''';
      case 'moustache_fancy':
        return '''
        <g id="FacialHair" transform="translate(96.000000, 148.000000)">
          <path d="M0,4 C8,-2 16,2 24,0 C20,8 8,10 0,4 Z" fill="$colorHex" />
          <path d="M40,4 C48,-2 56,2 64,0 C60,8 48,10 40,4 Z" fill="$colorHex" />
        </g>
        ''';
      case 'moustache_magnum':
        return '''
        <g id="FacialHair" transform="translate(96.000000, 146.000000)">
          <path d="M0,6 C10,-4 22,2 32,0 C42,2 54,-4 64,6 C54,12 42,8 32,10 C22,8 10,12 0,6 Z" fill="$colorHex" />
        </g>
        ''';
      default:
        return '';
    }
  }

  static String _buildHairLayer(String? id, String colorHex) {
    if (id == null || id == 'bald') return '';

    switch (id) {
      case 'short_flat':
        return '''
        <g id="Hair" transform="translate(65.000000, 36.000000)">
          <path d="M67,0 C100,0 125,20 128,52 L6,52 C9,20 34,0 67,0 Z" fill="$colorHex" />
        </g>
        ''';
      case 'short_round':
        return '''
        <g id="Hair" transform="translate(60.000000, 28.000000)">
          <ellipse cx="72" cy="32" rx="68" ry="36" fill="$colorHex" />
        </g>
        ''';
      case 'short_curly_hair':
        return '''
        <g id="Hair" transform="translate(58.000000, 26.000000)">
          <path d="M74,0 C112,0 140,24 140,48 C140,56 134,60 126,58 C118,56 116,48 108,44 C100,40 92,44 84,44 C76,44 68,40 60,44 C52,48 50,56 42,58 C34,60 28,56 28,48 C28,24 46,0 74,0 Z" fill="$colorHex" />
        </g>
        ''';
      case 'long_straight':
        return '''
        <g id="Hair" transform="translate(52.000000, 24.000000)">
          <path d="M80,0 C120,0 150,30 150,60 L150,120 C150,124 146,124 146,120 L146,65 C146,35 120,8 80,8 C40,8 14,35 14,65 L14,120 C14,124 10,124 10,120 L10,60 C10,30 40,0 80,0 Z" fill="$colorHex" />
        </g>
        ''';
      case 'long_curly':
        return '''
        <g id="Hair" transform="translate(48.000000, 20.000000)">
          <path d="M84,0 C128,0 158,32 158,68 C158,80 152,92 146,100 C140,108 134,120 134,132 C130,132 128,124 122,118 C116,112 110,108 110,98 C110,92 114,86 118,80 C122,74 126,66 126,56 C126,36 108,16 84,16 C60,16 42,36 42,56 C42,66 46,74 50,80 C54,86 58,92 58,98 C58,108 52,112 46,118 C40,124 38,132 34,132 C34,120 28,108 22,100 C16,92 10,80 10,68 C10,32 40,0 84,0 Z" fill="$colorHex" />
        </g>
        ''';
      case 'bob_cut':
        return '''
        <g id="Hair" transform="translate(56.000000, 26.000000)">
          <path d="M76,0 C116,0 144,28 144,60 L144,90 C140,92 136,88 136,82 L136,60 C136,34 110,8 76,8 C42,8 16,34 16,60 L16,82 C16,88 12,92 8,90 L8,60 C8,28 36,0 76,0 Z" fill="$colorHex" />
        </g>
        ''';
      case 'bun':
        return '''
        <g id="Hair">
          <g transform="translate(65.000000, 36.000000)">
            <path d="M67,0 C100,0 125,20 128,52 L6,52 C9,20 34,0 67,0 Z" fill="$colorHex" />
          </g>
          <circle cx="132" cy="26" r="20" fill="$colorHex" />
        </g>
        ''';
      case 'fro':
        return '''
        <g id="Hair" transform="translate(40.000000, 10.000000)">
          <ellipse cx="92" cy="52" rx="88" ry="56" fill="$colorHex" />
        </g>
        ''';
      case 'sides':
        return '''
        <g id="Hair" transform="translate(58.000000, 46.000000)">
          <rect x="0" y="0" width="16" height="50" rx="8" fill="$colorHex" />
          <rect x="130" y="0" width="16" height="50" rx="8" fill="$colorHex" />
          <path d="M16,0 L130,0 L130,8 L16,8 Z" fill="$colorHex" />
        </g>
        ''';
      default:
        // Fallback to short_flat for unknown styles
        return _buildHairLayer('short_flat', colorHex);
    }
  }

  static String _buildAccessoryLayer(String? id) {
    if (id == null || id == 'nothing') return '';

    switch (id) {
      case 'prescription01':
        return '''
        <g id="Accessory" transform="translate(68.000000, 104.000000)">
          <circle cx="30" cy="18" r="18" fill="none" stroke="#1F1F1F" stroke-width="3" />
          <circle cx="98" cy="18" r="18" fill="none" stroke="#1F1F1F" stroke-width="3" />
          <line x1="48" y1="18" x2="80" y2="18" stroke="#1F1F1F" stroke-width="2" />
          <line x1="12" y1="14" x2="0" y2="10" stroke="#1F1F1F" stroke-width="2" />
          <line x1="116" y1="14" x2="128" y2="10" stroke="#1F1F1F" stroke-width="2" />
        </g>
        ''';
      case 'round':
        return '''
        <g id="Accessory" transform="translate(68.000000, 104.000000)">
          <circle cx="30" cy="18" r="20" fill="none" stroke="#1F1F1F" stroke-width="2.5" />
          <circle cx="98" cy="18" r="20" fill="none" stroke="#1F1F1F" stroke-width="2.5" />
          <line x1="50" y1="16" x2="78" y2="16" stroke="#1F1F1F" stroke-width="1.5" />
        </g>
        ''';
      case 'sunglasses':
        return '''
        <g id="Accessory" transform="translate(66.000000, 102.000000)">
          <rect x="6" y="4" width="44" height="28" rx="6" fill="#1F1F1F" />
          <rect x="82" y="4" width="44" height="28" rx="6" fill="#1F1F1F" />
          <line x1="50" y1="18" x2="82" y2="18" stroke="#1F1F1F" stroke-width="2.5" />
          <line x1="6" y1="12" x2="-8" y2="8" stroke="#1F1F1F" stroke-width="2" />
          <line x1="126" y1="12" x2="140" y2="8" stroke="#1F1F1F" stroke-width="2" />
        </g>
        ''';
      case 'wayfarers':
        return '''
        <g id="Accessory" transform="translate(66.000000, 102.000000)">
          <rect x="6" y="4" width="44" height="26" rx="4" fill="none" stroke="#1F1F1F" stroke-width="3" />
          <rect x="82" y="4" width="44" height="26" rx="4" fill="none" stroke="#1F1F1F" stroke-width="3" />
          <line x1="50" y1="14" x2="82" y2="14" stroke="#1F1F1F" stroke-width="2" />
        </g>
        ''';
      case 'kurt':
        return '''
        <g id="Accessory" transform="translate(66.000000, 102.000000)">
          <circle cx="30" cy="18" r="20" fill="none" stroke="#FFFFFF" stroke-width="3" />
          <circle cx="98" cy="18" r="20" fill="none" stroke="#FFFFFF" stroke-width="3" />
          <circle cx="30" cy="18" r="16" fill="#FF4444" opacity="0.5" />
          <circle cx="98" cy="18" r="16" fill="#FF4444" opacity="0.5" />
        </g>
        ''';
      default:
        return '';
    }
  }
}
