import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../db/SupabaseConfig.dart';
import 'dart:math';

class _ImagePicker extends StatefulWidget {
  final Function(String)? onImageSelected;
  final TextEditingController descriptionController;
  final TextEditingController promptController;

  const _ImagePicker({
    this.onImageSelected,
    required this.descriptionController,
    required this.promptController,
  });

  @override
  State<_ImagePicker> createState() => _ImagePickerState();
}

class _ImagePickerState extends State<_ImagePicker> {
  final ImagePicker _picker = ImagePicker();
  String? _uploadedImageUrl;
  bool _isUploading = false;

  Future<ui.Image> _generatePlaceholderImage(String text) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(400, 200);

    // Draw a random background color
    final Random random = Random();
    final color = Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1.0,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = color,
    );

    // Draw text
    final textPainter = TextPainter(
      text: TextSpan(
        text: text.length > 20 ? '${text.substring(0, 20)}...' : text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(
      canvas,
      const Offset(10, 10),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    return img;
  }

  Future<void> _generateAndUploadImage() async {
    final description = widget.descriptionController.text.isNotEmpty
        ? widget.descriptionController.text
        : widget.promptController.text.isNotEmpty
            ? widget.promptController.text
            : 'Event Image';

    setState(() => _isUploading = true);

    try {
      // Generate the placeholder image
      final image = await _generatePlaceholderImage(description);

      // Convert ui.Image to byte data
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to convert image to bytes');
      final imageBytes = byteData.buffer.asUint8List();

      // Upload to Supabase
      final fileName = 'generated_event_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = 'public/$fileName';
      await SupabaseConfig.client.storage.from('eventimages').uploadBinary(path, imageBytes);

      // Get the public URL
      final imageUrl = SupabaseConfig.client.storage.from('eventimages').getPublicUrl(path);

      setState(() {
        _uploadedImageUrl = imageUrl;
        _isUploading = false;
      });

      widget.onImageSelected?.call(imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image générée et téléchargée avec succès')),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      print('Erreur lors de la génération/téléchargement de l\'image : $e');
      if (mounted) {
        String errorMessage = 'Échec de la génération ou du téléchargement de l\'image';
        if (e.toString().contains('bucket')) {
          errorMessage = 'Problème avec le stockage des images. Veuillez contacter l\'administrateur.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage(ImageSource? source) async {
    setState(() => _isUploading = true);

    try {
      XFile? image;
      String fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.png';
      String path = 'public/$fileName';

      // Use file_picker for web and desktop platforms, image_picker for mobile
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform

 == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
        // Use file_picker for desktop and web
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.single.bytes != null) {
          // For web, use bytes directly
          final bytes = result.files.single.bytes!;
          await SupabaseConfig.client.storage.from('eventimages').uploadBinary(path, bytes);
        } else if (result != null && result.files.single.path != null) {
          // For desktop, use file path
          image = XFile(result.files.single.path!);
        } else {
          setState(() => _isUploading = false);
          return; // User canceled the picker
        }
      } else {
        // Use image_picker for mobile
        if (source == null) {
          setState(() => _isUploading = false);
          return;
        }
        image = await _picker.pickImage(source: source);
        if (image == null) {
          setState(() => _isUploading = false);
          return;
        }
      }

      // If image is available (desktop or mobile), upload it
      if (image != null) {
        final file = File(image.path);
        await SupabaseConfig.client.storage.from('eventimages').upload(path, file);
      }

      // Get the public URL
      final publicUrl = SupabaseConfig.client.storage.from('eventimages').getPublicUrl(path);

      setState(() {
        _uploadedImageUrl = publicUrl;
        _isUploading = false;
      });

      widget.onImageSelected?.call(publicUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image téléchargée avec succès')),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      print('Erreur lors de la sélection/téléchargement de l\'image : $e');
      if (mounted) {
        String errorMessage = 'Échec de la sélection ou du téléchargement de l\'image';
        if (e.toString().contains('bucket')) {
          errorMessage = 'Problème avec le stockage des images. Veuillez contacter l\'administrateur.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageChoiceDialog(context),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: _isUploading
            ? const Center(child: CircularProgressIndicator())
            : _uploadedImageUrl != null
                ? Image.network(
                    _uploadedImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.error_outline, size: 50, color: Colors.red),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.add_photo_alternate, size: 50),
                  ),
      ),
    );
  }

  void _showImageChoiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une option d\'image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Télécharger une image'),
              onTap: () {
                Navigator.pop(context);
                _showImageSourceActionSheet(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Générer une image'),
              onTap: () {
                Navigator.pop(context);
                _generateAndUploadImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    // Show different options based on platform
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
      // For desktop and web, directly trigger file picker
      _pickAndUploadImage(null); // ImageSource is not needed for file_picker
    } else {
      // For mobile, show gallery/camera options
      showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Caméra'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      );
    }
  }
}