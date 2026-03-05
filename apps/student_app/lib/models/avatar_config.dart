import 'dart:convert';

/// Represents the user's avatar configuration.
/// Mirrors the JSONB `avatar_config` column in the `users` table.
class AvatarConfig {
  final int version;
  final AvatarPalette palette;
  final Map<String, String?> layers;
  final AvatarState state;

  const AvatarConfig({
    this.version = 1,
    this.palette = const AvatarPalette(),
    this.layers = const {
      'hair': null,
      'eyes': 'default',
      'eyebrows': 'default',
      'mouth': 'default',
      'facial_hair': null,
      'outfit': 'blazer_tshirt',
      'accessory': null,
    },
    this.state = const AvatarState(),
  });

  /// Default avatar config for new users
  static const AvatarConfig defaultConfig = AvatarConfig();

  AvatarConfig copyWith({
    int? version,
    AvatarPalette? palette,
    Map<String, String?>? layers,
    AvatarState? state,
  }) {
    return AvatarConfig(
      version: version ?? this.version,
      palette: palette ?? this.palette,
      layers: layers ?? Map.from(this.layers),
      state: state ?? this.state,
    );
  }

  /// Update a single layer slot
  AvatarConfig withLayer(String slot, String? itemId) {
    final newLayers = Map<String, String?>.from(layers);
    newLayers[slot] = itemId;
    return copyWith(layers: newLayers);
  }

  /// Update palette skin tone
  AvatarConfig withSkinTone(String tone) {
    return copyWith(palette: palette.copyWith(skin: tone));
  }

  /// Update palette hair color
  AvatarConfig withHairColor(String color) {
    return copyWith(palette: palette.copyWith(hair: color));
  }

  factory AvatarConfig.fromJson(Map<String, dynamic> json) {
    final v = json['v'] as int? ?? 1;

    // Future-proof: if version is unknown, use defaults
    if (v > 1) return AvatarConfig.defaultConfig;

    return AvatarConfig(
      version: v,
      palette: json['palette'] != null
          ? AvatarPalette.fromJson(json['palette'])
          : const AvatarPalette(),
      layers: json['layers'] != null
          ? (json['layers'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v is Map ? v['id'] as String? : null),
            )
          : AvatarConfig.defaultConfig.layers,
      state: json['state'] != null
          ? AvatarState.fromJson(json['state'])
          : const AvatarState(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'v': version,
      'palette': palette.toJson(),
      'layers': layers.map((k, v) => MapEntry(k, {'id': v})),
      'state': state.toJson(),
      'ext': {},
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory AvatarConfig.fromJsonString(String jsonString) {
    return AvatarConfig.fromJson(jsonDecode(jsonString));
  }
}

class AvatarPalette {
  final String skin;
  final String hair;
  final String outfit;

  const AvatarPalette({
    this.skin = 'peach',
    this.hair = 'black',
    this.outfit = 'blue01',
  });

  AvatarPalette copyWith({String? skin, String? hair, String? outfit}) {
    return AvatarPalette(
      skin: skin ?? this.skin,
      hair: hair ?? this.hair,
      outfit: outfit ?? this.outfit,
    );
  }

  factory AvatarPalette.fromJson(Map<String, dynamic> json) {
    return AvatarPalette(
      skin: json['skin'] as String? ?? 'peach',
      hair: json['hair'] as String? ?? 'black',
      outfit: json['outfit'] as String? ?? 'blue01',
    );
  }

  Map<String, dynamic> toJson() => {
        'skin': skin,
        'hair': hair,
        'outfit': outfit,
      };
}

class AvatarState {
  final String pose;
  final String expression;

  const AvatarState({
    this.pose = 'idle_front',
    this.expression = 'neutral',
  });

  factory AvatarState.fromJson(Map<String, dynamic> json) {
    return AvatarState(
      pose: json['pose'] as String? ?? 'idle_front',
      expression: json['expression'] as String? ?? 'neutral',
    );
  }

  Map<String, dynamic> toJson() => {
        'pose': pose,
        'expression': expression,
      };
}
