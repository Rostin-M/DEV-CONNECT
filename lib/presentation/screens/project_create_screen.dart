import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dev_connect/data/models/project_model.dart';
import 'package:dev_connect/providers/theme_provider.dart';
import 'package:dev_connect/providers/auth_provider.dart';
import 'package:dev_connect/providers/projects_provider.dart';
import 'package:dev_connect/utils/validation_utils.dart';
import 'package:dev_connect/components/custom_text_field.dart';
import 'package:dev_connect/components/custom_chip_input.dart';
import 'package:dev_connect/components/screenshot_preview.dart';
import 'package:dev_connect/constants/image_constants.dart';

class ProjectCreationData {
  File imageFile;
  String caption;
  ProjectCreationData({required this.imageFile, this.caption = ''});
}

class ProjectCreateScreen extends StatefulWidget {
  const ProjectCreateScreen({super.key});

  @override
  State<ProjectCreateScreen> createState() => _ProjectCreateScreenState();
}

class _ProjectCreateScreenState extends State<ProjectCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _githubLinkController = TextEditingController();
  List<String> _tags = [];
  List<ProjectCreationData> _screenshots = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _githubLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_screenshots.length >= 10) {
      _showSnackBar('Límite de 10 pantallazos alcanzado.', isError: true);
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _screenshots.add(ProjectCreationData(imageFile: File(pickedFile.path)));
      });
    }
  }

  void _removeScreenshot(int index) {
    setState(() {
      _screenshots.removeAt(index);
    });
  }

  Future<void> _editCaption(int index) async {
    final originalData = _screenshots[index];
    final newCaption = await showDialog<String>(
      context: context,
      builder: (context) {
        final captionController = TextEditingController(
          text: originalData.caption,
        );
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

    if (newCaption != null) {
      setState(() {
        originalData.caption = newCaption;
      });
    }
  }

  Future<void> _publishProject() async {
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
    if (_screenshots.isEmpty) {
      _showSnackBar('Debes agregar al menos un pantallazo.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      _showSnackBar('Error: No estás autenticado.', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    final projectModel = ProjectModel(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      tags: _tags,
      githubLink: _githubLinkController.text.trim().isNotEmpty
          ? _githubLinkController.text.trim()
          : '',
      screenshots: _screenshots
          .map((s) => {'caption': s.caption, 'url': '', 'publicId': ''})
          .toList(),
      authorId: currentUser.uid,
      authorName: currentUser.displayName ?? 'Usuario Anónimo',
      authorAvatar:
          currentUser.photoURL ??
          ImageConstants.getDefaultAvatar(currentUser.displayName),
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      likes: const [],
      commentsCount: 0,
      status: 'public',
    );

    final screenshotFiles = _screenshots.map((s) => s.imageFile).toList();

    try {
      await Provider.of<ProjectsProvider>(
        context,
        listen: false,
      ).createProject(projectModel, screenshotFiles);

      _resetForm();
      _showSnackBar('¡Proyecto publicado con éxito!', isError: false);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Error al publicar: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _githubLinkController.clear();
    setState(() {
      _tags = [];
      _screenshots = [];
    });
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nuevo Proyecto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Switch(
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
            activeThumbColor: Theme.of(context).colorScheme.secondary,
            inactiveTrackColor: Theme.of(
              context,
            ).dividerColor.withValues(alpha: 0.5),
            inactiveThumbColor: Theme.of(context).hintColor,
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                labelText: 'Título del Proyecto',
                hintText: 'Agrega un título...',
                controller: _titleController,
                validator: (val) =>
                    ValidationUtils.validateMinLength(val, 5, 'El título'),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                labelText: 'Descripción',
                hintText: 'Ingresa una descripción...',
                isMultiLine: true,
                controller: _descriptionController,
                validator: (val) => ValidationUtils.validateMinLength(
                  val,
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
                'Agrega capturas de pantalla de tu proyecto',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 20),

              ScreenshotPreview(
                screenshots: _screenshots
                    .map(
                      (data) => ScreenshotData(
                        imageFile: data.imageFile,
                        caption: data.caption,
                      ),
                    )
                    .toList(),
                onRemove: _removeScreenshot,
                onEditCaption: _editCaption,
              ),

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
                  onPressed: _isLoading ? null : _publishProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    animationDuration: const Duration(milliseconds: 200),
                  ),
                  child: _isLoading
                      ? const SpinKitThreeBounce(
                          color: Colors.white,
                          size: 20.0,
                        )
                      : const Text(
                          'Publicar Proyecto',
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
