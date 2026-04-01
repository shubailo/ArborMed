library arbormed_core;

// Models
export 'src/models/user.dart';
export 'src/models/admin_question.dart';
export 'package:core_interop/core_interop.dart' show SubjectMastery, ActivityData;
export 'src/models/question_stats.dart';
export 'src/models/performance.dart';
export 'src/models/quote.dart';
export 'src/models/quest.dart';
export 'src/models/user_history_entry.dart';

// Services
export 'src/services/api_service.dart';
export 'src/services/locale_provider.dart';
export 'src/services/notification_provider.dart';
export 'src/services/translation_service.dart';
export 'src/services/audio_provider.dart';
export 'src/services/theme_service.dart';

// Theme & UI
export 'src/theme/cozy_theme.dart';
export 'src/theme/arbor_colors.dart';
export 'src/theme/palettes/light_palette.dart';
export 'src/theme/palettes/dark_palette.dart';
export 'src/presentation/widgets/arbor_button.dart';
export 'src/presentation/widgets/cozy/cozy_progress_bar.dart';
export 'src/presentation/splash_screen.dart';
export 'src/utils/router_utils.dart';

// Database & Persistence
export 'src/database/database.dart';
export 'src/database/database_service.dart';
export 'src/database/seeding/drift_seeding_service.dart';
// Note: Individual collection exports are removed as Drift tables are accessed via AppDatabase

// Utils & Core
export 'src/utils/download_helper.dart';
export 'src/core/api_endpoints.dart';
