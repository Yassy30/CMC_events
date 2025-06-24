import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../navigation/bottom_navigation.dart';
import '../../services/event_service.dart';
import '../../db/SupabaseConfig.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isFree = true;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _promptController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _imageUrl;
  String? _selectedCategory;
  final _eventService = EventService();

  final List<String> _categories = [
    'All Events',
    'Art & Design',
    'Sports',
    'Comptetion',
    'Culture',
    'Tech',
   
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories[0];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _promptController.dispose();
    _locationController.dispose();
    _maxAttendeesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _generateText(String prompt) async {
    try {
      final List<String> adjectives = ['Exciting', 'Fun', 'Amazing', 'Thrilling', 'Unique'];
      final List<String> eventTypes = ['Festival', 'Gathering', 'Show', 'Competition', 'Experience'];
      final Random random = Random();

      String title = prompt.trim();
      if (title.isEmpty) {
        title = '${adjectives[random.nextInt(adjectives.length)]} ${eventTypes[random.nextInt(eventTypes.length)]}';
      } else {
        title = title.split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' ');
        title = '${adjectives[random.nextInt(adjectives.length)]} $title ${eventTypes[random.nextInt(eventTypes.length)]}';
      }

      String description = 'Join us for an ${adjectives[random.nextInt(adjectives.length)].toLowerCase()} event! ';
      if (prompt.isNotEmpty) {
        description += 'This event focuses on $prompt, offering a ${adjectives[random.nextInt(adjectives.length)].toLowerCase()} time for all. ';
      }
      description += 'Expect ${['live music', 'fun activities', 'great food', 'exciting games', 'special performances'][random.nextInt(5)]} ';
      description += 'on ${DateTime.now().toString().split(' ')[0]} at a location near you. Don’t miss out!';

      return {'title': title, 'description': description};
    } catch (e) {
      print('Error generating text: $e');
      return {'title': 'Generated Event', 'description': 'No description generated'};
    }
  }

  void _showAIGeneratorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Générateur IA (100% Free)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Enter a prompt for event generation',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (_promptController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a prompt')),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  final textResult = await _generateText(_promptController.text);

                  Navigator.pop(context);

                  setState(() {
                    _titleController.text = textResult['title']!;
                    _descriptionController.text = textResult['description']!;
                  });

                  Navigator.pop(context);

                  if (textResult['title']!.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Text generated successfully!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error generating text')),
                    );
                  }
                },
                child: const Text('Generate Text'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _fetchFirstUserId() async {
    try {
      final response = await SupabaseConfig.client
          .from('users')
          .select('id')
          .limit(1)
          .maybeSingle();

      if (response != null && response['id'] != null) {
        print("the user id : ${response['id'] as String}");
        return response['id'] as String;
      }
      print('No users found in the database.');
    } catch (e) {
      print('Error fetching first user: $e');
    }
    return null;
  }

  String _mapDisplayCategoryToDatabase(String displayCategory) {
    // Map from display categories to database categories
    final Map<String, String> categoryMap = {
      'All Events': 'other',
      'Art & Design': 'art_design',
      'Sports': 'sport',
      'Competition': 'competition',
      'Culture': 'culture',
    };
    
    return categoryMap[displayCategory] ?? 'other';
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final creatorId = await _fetchFirstUserId();
    if (creatorId == null || creatorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users found. Please create a user first.')),
      );
      return;
    }

    try {
      final startDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      double? ticketPrice;
      String paymentType = 'free';
      if (!_isFree) {
        print('Price text before parsing: "${_priceController.text}"');
        final priceText = _priceController.text.trim();
        ticketPrice = double.tryParse(priceText);
        if (ticketPrice == null || ticketPrice <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid ticket price. Please enter a valid positive number.')),
          );
          return;
        }
        paymentType = 'paid';
      }

      print('Creating event with creatorId: $creatorId, paymentType: $paymentType, ticketPrice: $ticketPrice');

      // Transformez "All Events" en catégorie valide
      String dbCategory;
      if (_selectedCategory == 'All Events') {
        // Utilisez une catégorie par défaut
        dbCategory = 'other';
      } else {
        // Utilisez la fonction de mappage existante
        dbCategory = _mapDisplayCategoryToDatabase(_selectedCategory!);
      }
  
      // Utilisez dbCategory au lieu de _selectedCategory! lors de la création
      await _eventService.createEvent(
        title: _titleController.text,
        description: _descriptionController.text,
        startDate: startDate,
        location: _locationController.text,
        category: dbCategory,
        paymentType: paymentType,
        ticketPrice: ticketPrice,
        maxAttendees: int.tryParse(_maxAttendeesController.text),
        imageUrl: _imageUrl ?? 'https://via.placeholder.com/150',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (mounted) {
        print('Failed to create event: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un événement'),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showAIGeneratorDialog,
            child: const Icon(Icons.text_fields),
            heroTag: 'textGenerator',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _showImageChoiceDialog,
            child: const Icon(Icons.image),
            heroTag: 'imageChoice',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _ImagePicker(
              onImageSelected: (url) => setState(() => _imageUrl = url),
              descriptionController: _descriptionController,
              promptController: _promptController,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre de l\'événement',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un titre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                border: OutlineInputBorder(),
              ),
items: _categories.map((category) {
  return DropdownMenuItem<String>(
    value: category,
    child: Text(category),
  );
}).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Veuillez sélectionner une catégorie';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                      text: _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : '',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Heure',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                      text: _selectedTime != null
                          ? _selectedTime!.format(context)
                          : '',
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() => _selectedTime = time);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Lieu',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un lieu';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxAttendeesController,
              decoration: const InputDecoration(
                labelText: 'Nombre de places',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.people),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isEmpty) {
                  final number = int.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Veuillez entrer un nombre valide';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Événement gratuit'),
              value: _isFree,
              onChanged: (value) {
                setState(() {
                  _isFree = value;
                });
              },
            ),
            if (!_isFree) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Prix du billet',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (!_isFree) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un prix';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Veuillez entrer un nombre valide';
                    }
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _createEvent,
              child: const Text('Créer l\'événement'),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageChoiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Option'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Upload Image'),
              onTap: () {
                Navigator.pop(context);
                _showImageSourceActionSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Generate Image'),
              onTap: () {
                Navigator.pop(context);
                // Handled in _ImagePickerState
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? image = await ImagePicker().pickImage(source: source);
      if (image == null) return;

      final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = 'public/$fileName';
      final File imageFile = File(image.path);

      await SupabaseConfig.client.storage.from('eventimages').upload(path, imageFile);
      final imageUrl = SupabaseConfig.client.storage.from('eventimages').getPublicUrl(path);
      setState(() => _imageUrl = imageUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully')),
      );
    } catch (e) {
      print('Error picking/uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick or upload image.')),
      );
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image generated and uploaded successfully')),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      print('Error generating/uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate or upload image.')),
      );
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
        title: const Text('Choose Image Option'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Upload Image'),
              onTap: () {
                Navigator.pop(context);
                _showImageSourceActionSheet(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Generate Image'),
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
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
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

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() => _isUploading = true);

      final File imageFile = File(image.path);
      final String fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.png';
      final String path = 'public/$fileName';

      await SupabaseConfig.client.storage.from('eventimages').upload(path, imageFile);

      final String publicUrl = SupabaseConfig.client.storage
          .from('eventimages')
          .getPublicUrl(path);

      setState(() {
        _uploadedImageUrl = publicUrl;
        _isUploading = false;
      });

      widget.onImageSelected?.call(publicUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully')),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      print('Error picking/uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick or upload image.')),
      );
    }
  }
}