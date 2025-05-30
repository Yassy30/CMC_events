import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../navigation/bottom_navigation.dart';
import '../../services/event_service.dart';
import '../../db/SupabaseConfig.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this import

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

  final List<String> _categories = ['sport', 'culture', 'competition', 'other'];

final String huggingFaceApiToken = dotenv.env['HF_API_TOKEN'] ?? 'default_token';
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
    final url = Uri.parse('https://api-inference.huggingface.co/models/distilgpt2');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $huggingFaceApiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': 'Generate a title and description for an event based on this prompt: $prompt',
          'parameters': {'max_length': 100},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String generatedText = data[0]['generated_text'];
        // Basic parsing; adjust based on model output
        List<String> parts = generatedText.split('\n');
        String title = parts.length > 0 ? parts[0].trim() : 'Generated Event';
        String description = parts.length > 1 ? parts[1].trim() : 'No description generated';
        return {'title': title, 'description': description};
      } else {
        print('Text generation failed: ${response.statusCode}');
        return {'title': '', 'description': ''};
      }
    } catch (e) {
      print('Error generating text: $e');
      return {'title': '', 'description': ''};
    }
  }

  Future<String?> _generateImage(String prompt) async {
    final url = Uri.parse('https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-2-1');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $huggingFaceApiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': prompt,
        }),
      );

      if (response.statusCode == 200) {
        final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.png';
        final storageResponse = await SupabaseConfig.client.storage
            .from('event_images')
            .uploadBinary(fileName, response.bodyBytes);

        if (storageResponse.isNotEmpty) {
          final imageUrl = SupabaseConfig.client.storage
              .from('event_images')
              .getPublicUrl(fileName);
          return imageUrl;
        } else {
          print('Failed to upload image to Supabase');
          return null;
        }
      } else {
        print('Image generation failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error generating image: $e');
      return null;
    }
  }

  void _showAIGeneratorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Générateur IA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Description pour la génération',
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
                      const SnackBar(content: Text('Veuillez entrer une description')),
                    );
                    return;
                  }

                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  // Generate text and image
                  final textResult = await _generateText(_promptController.text);
                  final imageUrl = await _generateImage(_promptController.text);

                  // Close loading dialog
                  Navigator.pop(context);

                  // Update form fields
                  setState(() {
                    _titleController.text = textResult['title']!;
                    _descriptionController.text = textResult['description']!;
                    _imageUrl = imageUrl;
                  });

                  // Close the dialog
                  Navigator.pop(context);

                  // Show success or error message
                  if (textResult['title']!.isNotEmpty && imageUrl != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contenu généré avec succès !')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erreur lors de la génération du contenu')),
                    );
                  }
                },
                child: const Text('Générer'),
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

      print('Creating event with creatorId: $creatorId');
      await _eventService.createEvent(
        title: _titleController.text,
        description: _descriptionController.text,
        creatorId: creatorId,
        startDate: startDate,
        location: _locationController.text,
        category: _selectedCategory!,
        paymentType: _isFree ? 'free' : 'paid',
        maxAttendees: int.tryParse(_maxAttendeesController.text),
        imageUrl: _imageUrl ?? 'https://placeholder.com/event-image.jpg',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAIGeneratorDialog,
        child: const Icon(Icons.auto_awesome),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _ImagePicker(
              onImageSelected: (url) => setState(() => _imageUrl = url),
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
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category[0].toUpperCase() + category.substring(1)),
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
                if (value != null && value.isNotEmpty) {
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
}

class _ImagePicker extends StatelessWidget {
  final Function(String)? onImageSelected;

  const _ImagePicker({this.onImageSelected});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_CreateEventScreenState>();
    final imageUrl = state?._imageUrl;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.error, size: 50),
              ),
            )
          : Center(
              child: IconButton(
                icon: const Icon(Icons.add_photo_alternate, size: 50),
                onPressed: () {
                  // Optionally implement manual image picking here
                },
              ),
            ),
    );
  }
}