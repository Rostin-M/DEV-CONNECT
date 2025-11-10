class ValidationUtils {
  static String? validateEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName no puede estar vacío.';
    }
    return null;
  }

  static String? validateMinLength(
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value != null && value.length < minLength) {
      return '$fieldName debe tener al menos $minLength caracteres.';
    }
    return null;
  }

  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El enlace de GitHub es requerido.';
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAbsolutePath ||
        !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return 'Ingresa un enlace de GitHub válido.';
    }
    return null;
  }

  static String? validateTags(List<String> tags) {
    if (tags.isEmpty) {
      return 'Debes agregar al menos una etiqueta (Tag).';
    }
    return null;
  }
}
