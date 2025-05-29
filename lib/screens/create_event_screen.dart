import 'package:flutter/material.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isFree = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un événement'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _ImagePicker(),
            const SizedBox(height: 16),
            TextFormField(
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
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      // TODO: Gérer la date sélectionnée
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
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      // TODO: Gérer l'heure sélectionnée
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Lieu',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nombre de places',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.people),
              ),
              keyboardType: TextInputType.number,
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
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // TODO: Sauvegarder l'événement
                }
              },
              child: const Text('Créer l\'événement'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () {
            // TODO: Implémenter la sélection d'image
          },
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate, size: 48),
              SizedBox(height: 8),
              Text('Ajouter une image'),
            ],
          ),
        ),
      ),
    );
  }
}