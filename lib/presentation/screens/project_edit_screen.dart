import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:dev_connect/providers/theme_provider.dart';
import 'package:dev_connect/utils/validation_utils.dart';
import 'package:dev_connect/components/custom_text_field.dart';
import 'package:dev_connect/components/custom_chip_input.dart';
import 'package:dev_connect/services/cloudinary_service.dart';

class ScreenshotData {
  final File imageFile;
  String caption;

  ScreenshotData({required this.imageFile, this.caption = ''});
}

class ProjectEditScreen extends StatefulWidget {
  final String projectId;

  const ProjectEditScreen({super.key, required this.projectId});

  @override
  State<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends State<ProjectEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _githubLinkController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  List<String> _tags = [];
  final List<ScreenshotData> _screenshots = [];
  List<Map<String, dynamic>> _existingScreenshots = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _githubLinkController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    try {
      final projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .get();

      if (!projectDoc.exists) {
        throw Exception('Proyecto no encontrado');
      }

      final projectData = projectDoc.data() as Map<String, dynamic>;

      setState(() {
        _titleController.text = projectData['title'] ?? '';
        _descriptionController.text = projectData['description'] ?? '';
        _githubLinkController.text = projectData['githubLink'] ?? '';
        _tags = List<String>.from(projectData['tags'] ?? []);
        _existingScreenshots = List<Map<String, dynamic>>.from(
          projectData['screenshots'] ?? [],
        );
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al cargar el proyecto: $e', isError: true);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _pickImage() async {
    if (_screenshots.length + _existingScreenshots.length >= 10) {
      _showSnackBar('Límite de 10 pantallazos alcanzado.', isError: true);
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _screenshots.add(ScreenshotData(imageFile: File(pickedFile.path)));
      });
    }
  }

  void _removeNewScreenshot(int index) {
    setState(() {
      _screenshots.removeAt(index);
    });
  }

  void _removeExistingScreenshot(int index) {
    setState(() {
      _existingScreenshots.removeAt(index);
    });
  }

  Future<void> _editNewCaption(int index) async {
    final originalData = _screenshots[index];
    final newCaption = await _showCaptionDialog(originalData.caption);

    if (newCaption != null) {
      setState(() {
        originalData.caption = newCaption;
      });
    }
  }

  Future<void> _editExistingCaption(int index) async {
    final screenshot = _existingScreenshots[index];
    final newCaption = await _showCaptionDialog(screenshot['caption'] ?? '');

    if (newCaption != null) {
      setState(() {
        _existingScreenshots[index]['caption'] = newCaption;
      });
    }
  }

  Future<String?> _showCaptionDialog(String currentCaption) async {
    final captionController = TextEditingController(text: currentCaption);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Descripción'),
          content: TextField(
            controller: captionController,
            decoration: const InputDecoration(
              hintText: 'Descripción del pantallazo',
            ),
            maxLines: 3,
            minLines: 1,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(captionController.text),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar(
        'Por favor, completa todos los campos requeridos.',
        isError: true,
      );
      return;
    }

    if (ValidationUtils.validateTags(_tags) != null) {
      _showSnackBar('Debes agregar al menos una etiqueta.', isError: true);
      return;
    }

    if (_screenshots.isEmpty && _existingScreenshots.isEmpty) {
      _showSnackBar('Debes tener al menos un pantallazo.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final List<Map<String, dynamic>> allScreenshots = [];

      allScreenshots.addAll(_existingScreenshots);

      for (var screenshot in _screenshots) {
        final uploadResult = await _cloudinaryService.uploadScreenshot(
          screenshot.imageFile,
        );
        allScreenshots.add({
          'id': FirebaseFirestore.instance.collection('projects').doc().id,
          'url': uploadResult['url']!,
          'publicId': uploadResult['publicId']!,
          'caption': screenshot.caption,
          'createdAt': Timestamp.now(),
        });
      }

      final updateData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'tags': _tags,
        'githubLink': _githubLinkController.text.trim(),
        'screenshots': allScreenshots,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .update(updateData);

      if (mounted) {
        _showSnackBar('Proyecto actualizado exitosamente', isError: false);
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al actualizar: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Proyecto')),
        body: Center(
          child: SpinKitThreeBounce(
            color: Theme.of(context).primaryColor,
            size: 30.0,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Proyecto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeProvider.toggleTheme(!isDarkMode);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                labelText: 'Título del Proyecto',
                hintText: 'Ej: App de Delivery con Flutter',
                controller: _titleController,
                validator: (value) =>
                    ValidationUtils.validateEmpty(value, 'El título'),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                labelText: 'Descripción',
                hintText: 'Describe tu proyecto...',
                isMultiLine: true,
                controller: _descriptionController,
                validator: (value) => ValidationUtils.validateMinLength(
                  value,
                  20,
                  'La descripción',
                ),
              ),
              const SizedBox(height: 20),
              CustomChipInput(
                labelText: 'Etiquetas (Tags)',
                initialTags: _tags,
                onTagsChanged: (newTags) => _tags = newTags,
                validator: ValidationUtils.validateTags,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                labelText: 'Enlace de GitHub',
                hintText: 'github.com/tu-usuario/tu-proyecto',
                isUrl: true,
                controller: _githubLinkController,
                validator: ValidationUtils.validateUrl,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 30),
              Text(
                'Pantallazos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                'Gestiona las capturas de pantalla de tu proyecto',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 20),
              if (_existingScreenshots.isNotEmpty) ...[
                Text(
                  'Pantallazos actuales',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ..._existingScreenshots.asMap().entries.map((entry) {
                  final index = entry.key;
                  final screenshot = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: CachedNetworkImage(
                                imageUrl: screenshot['url'],
                                fit: BoxFit.cover,
                                height: 200,
                                width: double.infinity,
                                placeholder: (context, url) => Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                radius: 18,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  onPressed: () =>
                                      _removeExistingScreenshot(index),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                screenshot['caption']?.isNotEmpty == true
                                    ? screenshot['caption']
                                    : 'Sin descripción',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontStyle:
                                          screenshot['caption']?.isEmpty == true
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                      color:
                                          screenshot['caption']?.isEmpty == true
                                          ? Theme.of(context).hintColor
                                          : null,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _editExistingCaption(index),
                              child: Icon(
                                Icons.edit,
                                size: 18,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30, thickness: 1),
                      ],
                    ),
                  );
                }),
              ],
              if (_screenshots.isNotEmpty) ...[
                Text(
                  'Nuevos pantallazos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ..._screenshots.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Image.file(
                                data.imageFile,
                                fit: BoxFit.cover,
                                height: 200,
                                width: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                radius: 18,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  onPressed: () => _removeNewScreenshot(index),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                data.caption.isNotEmpty
                                    ? data.caption
                                    : 'Sin descripción',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontStyle: data.caption.isEmpty
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                      color: data.caption.isEmpty
                                          ? Theme.of(context).hintColor
                                          : null,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _editNewCaption(index),
                              child: Icon(
                                Icons.edit,
                                size: 18,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30, thickness: 1),
                      ],
                    ),
                  );
                }),
              ],
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Agregar Pantallazo (Máx 10)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: _isSaving
                      ? const SpinKitThreeBounce(
                          color: Colors.white,
                          size: 20.0,
                        )
                      : const Text(
                          'Guardar Cambios',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
