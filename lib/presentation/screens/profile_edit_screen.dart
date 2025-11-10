import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:dev_connect/providers/auth_provider.dart';
import 'package:dev_connect/providers/theme_provider.dart';
import 'package:dev_connect/data/models/user_model.dart';
import 'package:dev_connect/services/cloudinary_service.dart';
import 'package:dev_connect/services/firestore_service.dart';
import 'package:dev_connect/constants/image_constants.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillController = TextEditingController();

  final CloudinaryService _cloudinaryService = CloudinaryService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  UserModel? _originalProfile;
  List<String> _skills = [];
  File? _selectedImage;
  String? _currentPhotoUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  final List<String> _suggestedSkills = [
    'Flutter',
    'Dart',
    'React',
    'Angular',
    'Vue.js',
    'Node.js',
    'Python',
    'Java',
    'Kotlin',
    'Swift',
    'JavaScript',
    'TypeScript',
    'Firebase',
    'MongoDB',
    'PostgreSQL',
    'MySQL',
    'Docker',
    'Kubernetes',
    'AWS',
    'Azure',
    'Git',
    'UI/UX Design',
    'Figma',
    'Adobe XD',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_originalProfile == null) {
      _loadCurrentProfile();
    }
  }

  Future<void> _loadCurrentProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null) return;

    try {
      final profile = await _firestoreService.getUserProfile(currentUser.uid);

      if (profile != null && mounted) {
        setState(() {
          _originalProfile = profile;
          _displayNameController.text = profile.displayName;
          _bioController.text = profile.bio;
          _skills = List.from(profile.skills);
          _currentPhotoUrl = profile.photoURL;
        });
      }
    } catch (e) {
      _showSnackBar('Error al cargar el perfil: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          _showSnackBar('La imagen debe ser menor a 5MB', isError: true);
          return;
        }

        setState(() {
          _selectedImage = file;
        });
      }
    } catch (e) {
      _showSnackBar('Error al seleccionar imagen: $e', isError: true);
    }
  }

  void _addSkill() {
    final skill = _skillController.text.trim();

    if (skill.isEmpty) {
      _showSnackBar('Ingresa una habilidad', isError: true);
      return;
    }

    if (_skills.contains(skill)) {
      _showSnackBar('Esta habilidad ya está agregada', isError: true);
      return;
    }

    setState(() {
      _skills.add(skill);
      _skillController.clear();
    });
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      _showSnackBar('No hay usuario autenticado', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? newPhotoUrl = _currentPhotoUrl;

      if (_selectedImage != null) {
        setState(() => _isUploadingImage = true);

        final uploadResult = await _cloudinaryService.uploadProfileImage(
          _selectedImage!,
          folder: 'dev_connect/profiles',
        );

        newPhotoUrl = uploadResult['url'];

        setState(() => _isUploadingImage = false);
      }

      final updateData = {
        'displayName': _displayNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'skills': _skills,
        if (newPhotoUrl != null) 'photoUrl': newPhotoUrl,
      };

      final success = await authProvider.updateUserProfile(updateData);

      if (success) {
        _showSnackBar('¡Perfil actualizado exitosamente!', isError: false);

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showSnackBar('Error al actualizar el perfil', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImage = false;
        });
      }
    }
  }

  void _cancelChanges() {
    if (_hasChanges()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Descartar cambios?'),
          content: const Text(
            'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  bool _hasChanges() {
    if (_originalProfile == null) return false;

    return _displayNameController.text.trim() !=
            _originalProfile!.displayName ||
        _bioController.text.trim() != _originalProfile!.bio ||
        _skills.toString() != _originalProfile!.skills.toString() ||
        _selectedImage != null;
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancelChanges,
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              themeProvider.toggleTheme(!isDarkMode);
            },
            tooltip: isDarkMode ? 'Modo claro' : 'Modo oscuro',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _originalProfile == null
          ? Center(
              child: SpinKitThreeBounce(
                color: Theme.of(context).primaryColor,
                size: 30.0,
              ),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileImageSection(context),

                        const SizedBox(height: 32),

                        Card(
                          elevation: isDarkMode ? 2 : 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextField(
                                  controller: _displayNameController,
                                  label: 'Nombre completo',
                                  icon: Icons.person,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'El nombre es requerido';
                                    }
                                    if (value.trim().length < 3) {
                                      return 'Mínimo 3 caracteres';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                _buildReadOnlyField(
                                  label: 'Correo electrónico',
                                  value: authProvider.user?.email ?? '',
                                  icon: Icons.email,
                                ),

                                const SizedBox(height: 20),

                                _buildTextField(
                                  controller: _bioController,
                                  label: 'Biografía',
                                  icon: Icons.description,
                                  maxLines: 5,
                                  maxLength: 500,
                                  hint:
                                      'Cuéntanos sobre ti, tus intereses y experiencia...',
                                  validator: (value) {
                                    if (value != null &&
                                        value.trim().isNotEmpty &&
                                        value.trim().length < 20) {
                                      return 'Mínimo 20 caracteres para la biografía';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                Text(
                                  'Habilidades',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),

                                _buildSkillInput(context),

                                const SizedBox(height: 12),

                                _buildSkillsChips(),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _cancelChanges,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveChanges,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Guardar Cambios',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                if (_isUploadingImage)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                'Subiendo imagen...',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildProfileImageSection(BuildContext context) {
    final imageToShow = _selectedImage != null
        ? FileImage(_selectedImage!)
        : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(_currentPhotoUrl!)
                  : CachedNetworkImageProvider(
                      ImageConstants.getDefaultAvatar(
                        _originalProfile?.displayName,
                        size: 200,
                      ),
                    ))
              as ImageProvider;

    return Center(
      child: Stack(
        children: [
          Hero(
            tag: 'profile_image_${_originalProfile?.uid}',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.grey[300],
                backgroundImage: imageToShow,
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: Theme.of(context).primaryColor,
              child: InkWell(
                onTap: _isLoading ? null : _pickImage,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      initialValue: value,
      enabled: false,
      style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black87,
        ),
        prefixIcon: Icon(
          icon,
          color: isDarkMode ? Colors.white60 : Colors.black54,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDarkMode
            ? Colors.grey[800]?.withValues(alpha: 0.3)
            : Colors.grey[200],
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
      ),
    );
  }

  Widget _buildSkillInput(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _suggestedSkills.where((String option) {
          return option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          );
        });
      },
      onSelected: (String selection) {
        _skillController.text = selection;
        _addSkill();
      },
      fieldViewBuilder:
          (
            BuildContext context,
            TextEditingController controller,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            controller.text = _skillController.text;
            controller.selection = _skillController.selection;

            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Agregar habilidad',
                hintText: 'Ej: Flutter, Firebase, Python...',
                prefixIcon: const Icon(Icons.code),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () {
                    _skillController.text = controller.text;
                    _addSkill();
                  },
                  tooltip: 'Agregar',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                _skillController.text = value;
              },
              onSubmitted: (value) {
                _skillController.text = value;
                _addSkill();
              },
            );
          },
    );
  }

  Widget _buildSkillsChips() {
    if (_skills.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            'No has agregado habilidades aún',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _skills.map((skill) {
        return Chip(
          label: Text(skill),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () => _removeSkill(skill),
          backgroundColor: Theme.of(
            context,
          ).primaryColor.withValues(alpha: 0.1),
          labelStyle: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
          deleteIconColor: Theme.of(context).primaryColor,
        );
      }).toList(),
    );
  }
}
