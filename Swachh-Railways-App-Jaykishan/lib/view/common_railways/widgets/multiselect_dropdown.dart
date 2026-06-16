import 'package:flutter/material.dart';

class MultiSelectDropdown extends StatefulWidget {
  final String label;
  final List<String> items;

  const MultiSelectDropdown({
    super.key,
    required this.label,
    required this.items,
  });

  @override
  State<MultiSelectDropdown> createState() => _MultiSelectDropdownState();
}

class _MultiSelectDropdownState extends State<MultiSelectDropdown> {
  List<String> selectedItems = [];

  void _showMultiSelectDialog() async {
    final List<String>? results = await showDialog(
      context: context,
      builder: (context) {
        final tempSelected = List<String>.from(selectedItems);
        return AlertDialog(
          title: Text('Select ${widget.label}'),
          content: SingleChildScrollView(
            child: Column(
              children: widget.items
                  .map((item) => CheckboxListTile(
                value: tempSelected.contains(item),
                title: Text(item),
                onChanged: (isChecked) {
                  setState(() {
                    if (isChecked == true) {
                      tempSelected.add(item);
                    } else {
                      tempSelected.remove(item);
                    }
                  });
                },
              ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, tempSelected),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (results != null) {
      setState(() {
        selectedItems = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _showMultiSelectDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedItems.isEmpty
                          ? 'Select ${widget.label}'
                          : selectedItems.join(', '),
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
