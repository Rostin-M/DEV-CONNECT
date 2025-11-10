import 'package:flutter/material.dart';

const List<String> _kTechnologies = [
  'Flutter',
  'Node.js',
  'React',
  'React Native',
  'Vue.js',
  'Angular',
  'Python',
  'Django',
  'Flask',
  'Java',
  'Spring',
  'C#',
  '.NET',
  'Firebase',
  'MongoDB',
  'PostgreSQL',
  'AWS',
  'Azure',
  'Docker',
  'Kubernetes',
  'TypeScript',
  'Dart',
  'Kotlin',
  'Swift',
  'PHP',
];

class CustomChipInput extends StatefulWidget {
  final String labelText;
  final ValueChanged<List<String>> onTagsChanged;
  final List<String> initialTags;
  final String? Function(List<String>)? validator;

  const CustomChipInput({
    super.key,
    required this.labelText,
    required this.onTagsChanged,
    this.initialTags = const [],
    this.validator,
  });

  @override
  State<CustomChipInput> createState() => _CustomChipInputState();
}

class _CustomChipInputState extends State<CustomChipInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _tags = [];
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _tags.addAll(widget.initialTags);
  }

  void _addTag(String tag) {
    final cleanedTag = tag.trim().toLowerCase();
    if (cleanedTag.isNotEmpty &&
        !_tags.map((t) => t.toLowerCase()).contains(cleanedTag)) {
      setState(() {
        _tags.add(tag.trim());
        _textController.clear();
        _validate();
      });
      widget.onTagsChanged(_tags);
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _validate();
    });
    widget.onTagsChanged(_tags);
  }

  void _handleSubmitted(String value) {
    if (value.isNotEmpty) {
      _addTag(value);
      _focusNode.requestFocus();
    }
  }

  void _validate() {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(_tags);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _tags.map((tag) {
            return Chip(
              label: Text(tag),
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => _removeTag(tag),
            );
          }).toList(),
        ),
        const SizedBox(height: 8.0),

        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return _kTechnologies.where((String option) {
              return option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
            });
          },
          onSelected: (String selection) {
            _addTag(selection);
            _textController.clear();
            _focusNode.requestFocus();
          },
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
                _textController.text = textEditingController.text;
                return TextField(
                  controller: _textController,
                  focusNode: focusNode,
                  onSubmitted: _handleSubmitted,
                  decoration: InputDecoration(
                    labelText: widget.labelText,
                    hintText: 'Ej: Flutter, Node.js...',
                    errorText: _errorText,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add, color: theme.primaryColor),
                      onPressed: () => _handleSubmitted(_textController.text),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                  ),
                );
              },
        ),
      ],
    );
  }
}
