import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/all_models.dart';
import '../../../repositories/mandal_repository.dart';
import '../../../services/offline_db_helper.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final MandalRepository _repository = MandalRepository();
  final ImagePicker _picker = ImagePicker();
  String _selectedCategory = 'All';
  bool _isUploading = false;

  final List<String> _categories = [
    'All',
    'Festival',
    'Garba',
    'Aarti',
    'Pooja',
    'Decoration',
  ];

  // Default fallback sample images if database has no media yet
  final List<Map<String, String>> _sampleImages = [
    {
      'title': 'महाआरती सोहळा (Maha Aarti)',
      'category': 'Aarti',
      'url': 'https://images.unsplash.com/photo-1601614749377-622f67ec1656?w=600&q=80',
    },
    {
      'title': 'गरबा रास रंग (Garba Night)',
      'category': 'Garba',
      'url': 'https://images.unsplash.com/photo-1576487247299-e22132d7b43b?w=600&q=80',
    },
    {
      'title': 'देवी आगमन सोहळा (Devi Aagman)',
      'category': 'Festival',
      'url': 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&q=80',
    },
    {
      'title': 'भव्य मंडप सजावट (Decoration)',
      'category': 'Decoration',
      'url': 'https://images.unsplash.com/photo-1609137144822-094396cb4d5a?w=600&q=80',
    },
  ];

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final bytes = await pickedFile.readAsBytes();
      final base64String = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$base64String';

      setState(() => _isUploading = false);

      if (!mounted) return;

      // Show title and category dialog before final save
      _showSaveMediaDialog(dataUrl, bytes);
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting photo: $e'),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    }
  }

  void _showSaveMediaDialog(String dataUrl, List<int> imageBytes) {
    final titleController = TextEditingController(text: 'नवरात्र उत्सव २०२६');
    String chosenCategory = 'Festival';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.add_photo_alternate, color: AppColors.primaryMaroon),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.tr('छायाचित्र जतन करा', 'Save Photo Details'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo Preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Image.memory(
                          imageBytes as dynamic,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title Input
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('छायाचित्र शीर्षक / नाव', 'Photo Caption / Title'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.title, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: chosenCategory,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('प्रवर्ग / Category', 'Category'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.category, size: 20),
                      ),
                      items: [
                        'Festival',
                        'Garba',
                        'Aarti',
                        'Pooja',
                        'Decoration',
                      ].map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => chosenCategory = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppStrings.tr('रद्द करा', 'Cancel'), style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final newMedia = GalleryMediaModel(
                      id: OfflineDbHelper.generateId(),
                      mandalId: _repository.mandalProfile.id,
                      mediaType: 'image',
                      category: chosenCategory,
                      title: titleController.text.trim().isNotEmpty
                          ? titleController.text.trim()
                          : 'नवरात्र उत्सव छायाचित्र',
                      fileUrl: dataUrl,
                      uploadedAt: DateTime.now().toIso8601String(),
                    );

                    await _repository.addGalleryMedia(newMedia);

                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }

                    setState(() {});

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppStrings.tr(
                              'छायाचित्र यशस्वीरित्या जतन झाले आणि गॅलरीमध्ये जोडले गेले!',
                              'Photo saved permanently and added to gallery!',
                            ),
                          ),
                          backgroundColor: Colors.green[700],
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text(AppStrings.tr('जतन करा', 'Save Photo')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMediaSourceSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.tr('छायाचित्र निवडा', 'Select Media Source'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primaryMaroon.withAlpha(20), shape: BoxShape.circle),
                    child: const Icon(Icons.photo_library, color: AppColors.primaryMaroon),
                  ),
                  title: Text(AppStrings.tr('फोटो आल्बम / गॅलरी', 'Photo Gallery / Album')),
                  subtitle: Text(AppStrings.tr('मोबाईल गॅलरीमधून फोटो निवडा', 'Pick photo from phone storage')),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.brightGold.withAlpha(40), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: AppColors.primaryMaroon),
                  ),
                  title: Text(AppStrings.tr('कॅमेरा (Camera)', 'Take a New Photo')),
                  subtitle: Text(AppStrings.tr('कॅमेराने थेट नवीन फोटो काढा', 'Capture live festival moments')),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullImagePreview(dynamic mediaItem) {
    final String title = mediaItem is GalleryMediaModel ? mediaItem.title : (mediaItem['title'] ?? '');
    final String category = mediaItem is GalleryMediaModel ? mediaItem.category : (mediaItem['category'] ?? '');
    final String fileUrl = mediaItem is GalleryMediaModel ? mediaItem.fileUrl : (mediaItem['url'] ?? '');
    final String? id = mediaItem is GalleryMediaModel ? mediaItem.id : null;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            category,
                            style: const TextStyle(fontSize: 12, color: AppColors.primaryMaroon, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (id != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed),
                        tooltip: 'Delete Photo',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: ctx,
                            builder: (c) => AlertDialog(
                              title: Text(AppStrings.tr('छायाचित्र हटवायचे आहे का?', 'Delete Photo?')),
                              content: Text(AppStrings.tr('हे छायाचित्र कायमचे हटवले जाईल.', 'This photo will be permanently deleted.')),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('रद्द करा')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('हटवा (Delete)', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _repository.deleteGalleryMedia(id);
                            if (ctx.mounted) Navigator.pop(ctx);
                            setState(() {});
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Photo deleted successfully')),
                              );
                            }
                          }
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              // Image display
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 460),
                  color: Colors.black,
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 3.5,
                    child: Center(
                      child: _buildMediaImage(fileUrl, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaImage(String fileUrl, {BoxFit fit = BoxFit.cover}) {
    if (fileUrl.startsWith('data:image') || (fileUrl.length > 200 && !fileUrl.startsWith('http'))) {
      try {
        final clean = fileUrl.contains(',') ? fileUrl.split(',').last : fileUrl;
        final bytes = base64Decode(clean);
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (ctx, err, stack) => const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 36),
          ),
        );
      } catch (e) {
        return const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 36));
      }
    } else if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return Image.network(
        fileUrl,
        fit: fit,
        errorBuilder: (ctx, err, stack) => const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 36),
        ),
      );
    } else {
      return const Center(child: Icon(Icons.image, color: Colors.grey, size: 36));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final int crossAxisCount = screenWidth > 1100 ? 4 : (screenWidth > 700 ? 3 : 2);

    final uploadedMedia = _repository.galleryMedia;
    final bool hasUploaded = uploadedMedia.isNotEmpty;

    // Filter media items
    final List<dynamic> displayItems = [];
    if (hasUploaded) {
      if (_selectedCategory == 'All') {
        displayItems.addAll(uploadedMedia);
      } else {
        displayItems.addAll(
          uploadedMedia.where((m) => m.category.toLowerCase() == _selectedCategory.toLowerCase()),
        );
      }
    } else {
      // Fallback sample images
      if (_selectedCategory == 'All') {
        displayItems.addAll(_sampleImages);
      } else {
        displayItems.addAll(
          _sampleImages.where((s) => s['category']!.toLowerCase() == _selectedCategory.toLowerCase()),
        );
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top action bar
            Row(
              children: [
                const Icon(Icons.photo_library, color: AppColors.primaryMaroon, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.tr('गॅलरी आणि उत्सव छायाचित्रे', 'Gallery & Festival Media'),
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        AppStrings.tr('एकूण ${displayItems.length} छायाचित्रे', 'Total ${displayItems.length} photos'),
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _showMediaSourceSelector,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: Text(
                    isMobile ? AppStrings.tr('अपलोड', 'Upload') : AppStrings.tr('फोटो अपलोड करा', 'Upload Media'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cat),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      selectedColor: AppColors.primaryMaroon,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryMaroon : AppColors.borderLight,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Media Grid
            if (displayItems.isEmpty)
              Container(
                height: 220,
                width: double.infinity,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 10),
                    Text(
                      AppStrings.tr('कोणतेही छायाचित्र आढळले नाही', 'No photos in this category'),
                      style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayItems.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: isMobile ? 10 : 14,
                  mainAxisSpacing: isMobile ? 10 : 14,
                  childAspectRatio: isMobile ? 1.05 : 1.25,
                ),
                itemBuilder: (context, index) {
                  final item = displayItems[index];
                  final String title = item is GalleryMediaModel ? item.title : item['title'];
                  final String category = item is GalleryMediaModel ? item.category : item['category'];
                  final String url = item is GalleryMediaModel ? item.fileUrl : item['url'];

                  return InkWell(
                    onTap: () => _showFullImagePreview(item),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildMediaImage(url),
                            // Category Tag Top Left
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(160),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  category,
                                  style: const TextStyle(color: AppColors.brightGold, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            // Bottom Caption
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.transparent, Colors.black87],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
