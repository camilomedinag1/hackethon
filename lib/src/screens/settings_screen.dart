import 'package:flutter/material.dart';
import '../services/locator.dart';
import 'enroll_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Gestión de usuarios',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EnrollScreen()),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Registrar rostro'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Usuarios enrolados',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FutureBuilder<Map<String, dynamic>>(
            future: ServiceLocator.recognition.readAll(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final Map<String, dynamic> db = snapshot.data ?? <String, dynamic>{};
              if (db.isEmpty) {
                return const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('No hay usuarios enrolados'),
                );
              }
              final entries = db.entries.toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final e = entries[index];
                  String? imagePath;
                  if (e.value is Map && (e.value as Map)['imagePath'] is String) {
                    imagePath = (e.value as Map)['imagePath'] as String;
                  }
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: imagePath != null ? AssetImage('') : null,
                      child: imagePath == null ? const Icon(Icons.person) : null,
                      foregroundImage: imagePath != null ? FileImage(File(imagePath)) : null,
                    ),
                    title: Text(e.key),
                    subtitle: Text(imagePath ?? 'Sin imagen guardada'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final bool? ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Eliminar usuario'),
                            content: Text('¿Deseas eliminar a "${e.key}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await ServiceLocator.recognition.deleteIdentity(e.key);
                          // Refrescar
                          (context as Element).markNeedsBuild();
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Modelo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('MobileFaceNet.tflite'),
            subtitle: const Text('Cargado desde assets/models'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}


