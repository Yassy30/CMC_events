import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html if (kIsWeb) 'package:universal_html/html.dart';
import 'package:device_info_plus/device_info_plus.dart';


class ImageGeneratorScreen extends StatefulWidget {
  const ImageGeneratorScreen({super.key});



  @override
  State<ImageGeneratorScreen> createState() => _ImageGeneratorScreenState();
}

class _ImageGeneratorScreenState extends State<ImageGeneratorScreen> {


  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _descriptionFocusNode = FocusNode();
  String? _imagePath;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  

  @override
  void dispose() {
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _requestStoragePermission() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt ?? 0;

      if (sdkInt >= 33) {
        var photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          photosStatus = await Permission.photos.request();
        }
        return photosStatus.isGranted;
      } else {
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }
        return storageStatus.isGranted;
      }
    }

    return true;
  }

  Future<Uint8List> _generateImage(String description) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(400, 300);

    // Background with gradient
    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(400, 300),
      [Colors.lightBlue, Colors.white],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = gradient,
    );

    // Draw a cat if "cat" is in the description
    if (description.toLowerCase().contains('cat')) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = description.toLowerCase().contains('white') ? Colors.white : Colors.orange;

      // Head with gradient
      final headGradient = ui.Gradient.radial(
        const Offset(200, 150),
        60,
        [paint.color.withOpacity(1), paint.color.withOpacity(0.5)],
      );
      canvas.drawCircle(const Offset(200, 150), 60, Paint()..shader = headGradient);

      // Ears
      final earPaint = Paint()..color = paint.color;
      final leftEar = Path()
        ..moveTo(150, 100)
        ..lineTo(180, 130)
        ..lineTo(200, 100)
        ..close();
      final rightEar = Path()
        ..moveTo(250, 100)
        ..lineTo(220, 130)
        ..lineTo(200, 100)
        ..close();
      canvas.drawPath(leftEar, earPaint);
      canvas.drawPath(rightEar, earPaint);

      // Eyes
      canvas.drawCircle(const Offset(180, 140), 10, Paint()..color = Colors.black);
      canvas.drawCircle(const Offset(220, 140), 10, Paint()..color = Colors.black);

      // Body
      final bodyGradient = ui.Gradient.linear(
        const Offset(180, 250),
        const Offset(220, 250),
        [paint.color, paint.color.withOpacity(0.7)],
      );
      canvas.drawOval(const Rect.fromLTWH(170, 200, 60, 80), Paint()..shader = bodyGradient);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to convert image to bytes');
    final imageBytes = byteData.buffer.asUint8List();

    // Clean up
    image.dispose();

    return imageBytes;
  }

  Future<void> _saveAndDisplayImage(String description) async {
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageBytes = await _generateImage(description);

      if (kIsWeb) {
        setState(() {
          _imageBytes = imageBytes;
          _imagePath = null;
          _isLoading = false;
        });
      } else {
        bool permissionGranted = await _requestStoragePermission();
        if (!permissionGranted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied')),
          );
          return;
        }

        final tempDir = await getTemporaryDirectory();
        final fileName = 'generated_image_${DateTime.now().millisecondsSinceEpoch}.png';
        final filePath = '${tempDir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(imageBytes);

        setState(() {
          _imagePath = filePath;
          _imageBytes = null;
          _isLoading = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image generated successfully')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate image: $e')),
      );
    }
  }

  void _downloadImage() {
    if (_imageBytes == null) return;

    try {
      final base64Image = base64Encode(_imageBytes!);
      final dataUrl = 'data:image/png;base64,$base64Image';

      final anchor = html.AnchorElement(href: dataUrl)
        ..setAttribute('download', 'generated_image.png')
        ..click();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download image: $e')),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (_descriptionFocusNode.hasFocus) {
      _descriptionFocusNode.unfocus();
      return false;
    }

    if (_imagePath != null || _imageBytes != null) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exit'),
          content: const Text('Do you want to exit and discard the generated image?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Image Generator'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _descriptionController,
                focusNode: _descriptionFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Enter Image Description',
                  hintText: 'e.g., A white cat',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onSubmitted: (_) => _saveAndDisplayImage(_descriptionController.text),
              ),
              const SizedBox(height: 16),
              Center(
                child: FilledButton(
                  onPressed: _isLoading
                      ? null
                      : () => _saveAndDisplayImage(_descriptionController.text),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Generate Image'),
                ),
              ),
              const SizedBox(height: 16),
              if (_imagePath != null || _imageBytes != null) ...[
                const Text(
                  'Generated Image:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: kIsWeb
                        ? Image.memory(
                            _imageBytes!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.error_outline,
                              size: 50,
                              color: Colors.red,
                            ),
                          )
                        : Image.file(
                            File(_imagePath!),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.error_outline,
                              size: 50,
                              color: Colors.red,
                            ),
                          ),
                  ),
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: FilledButton(
                      onPressed: _downloadImage,
                      child: const Text('Download Image'),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}