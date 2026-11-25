import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/cozy_theme.dart';
import '../../../../widgets/common/platform_image.dart';
import '../../../../services/api_service.dart';
import '../../../../generated/l10n/app_localizations.dart';

class EcgCaseImagePicker extends StatelessWidget {
  final XFile? selectedImage;
  final String? existingImageUrl;
  final VoidCallback? onPickImage;

  const EcgCaseImagePicker({
    super.key,
    required this.selectedImage,
    required this.existingImageUrl,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    return InkWell(
      onTap: onPickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: selectedImage == null && existingImageUrl == null
              ? palette.surface
              : palette.paperWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedImage == null && existingImageUrl == null
                ? palette.primary.withValues(alpha: 0.5)
                : palette.textSecondary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlatformImage(path: selectedImage!.path, fit: BoxFit.cover),
                    Container(color: Colors.black12),
                    const Center(
                      child: Icon(Icons.edit, color: Colors.white, size: 40),
                    )
                  ],
                ),
              )
            : (existingImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          existingImageUrl!.startsWith('http')
                              ? existingImageUrl!
                              : '${ApiService.baseUrl}$existingImageUrl',
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, _, __) => const Center(
                            child: Icon(Icons.broken_image,
                                size: 40, color: Colors.grey),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 5,
                                  color: Colors.black26,
                                )
                              ],
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 20,
                              color: CozyTheme.of(context).primary,
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CozyTheme.of(context)
                              .primary
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_upload_outlined,
                          size: 32,
                          color: CozyTheme.of(context).primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.adminEcgClickToUpload,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )),
      ),
    );
  }
}

