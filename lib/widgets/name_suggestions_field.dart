import 'package:flutter/material.dart';

class NameSuggestionsField extends StatefulWidget {
  final TextEditingController controller;
  final List<String> existingNames;
  final String label;
  final TextInputType? keyboardType;

  const NameSuggestionsField({
    super.key,
    required this.controller,
    required this.existingNames,
    required this.label,
    this.keyboardType,
  });

  @override
  State<NameSuggestionsField> createState() => _NameSuggestionsFieldState();
}

class _NameSuggestionsFieldState extends State<NameSuggestionsField> {
  List<String> _suggestions = [];

  void _updateSuggestions(String text) {
    final query = text.trim();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final matches = widget.existingNames
        .where((n) => n.isNotEmpty && n.contains(query))
        .toSet()
        .take(5)
        .toList();
    setState(() => _suggestions = matches);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onListen);
    super.dispose();
  }

  void _onListen() {
    if (!mounted) return;
    _updateSuggestions(widget.controller.text);
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onListen);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(labelText: widget.label),
          keyboardType: widget.keyboardType,
          onChanged: _updateSuggestions,
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _suggestions.map((name) {
              return GestureDetector(
                onTap: () {
                  widget.controller.text = name;
                  widget.controller.selection = TextSelection.collapsed(offset: name.length);
                  setState(() => _suggestions = []);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF3B82F6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, size: 12, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 4),
                      Text(name, style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
