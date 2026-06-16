import 'package:flutter/material.dart';

class CommonMultiSelectDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> items;
  final List<String> selectedItems;
  final Function(List<String>) onSelect;
  final bool enabled;

  const CommonMultiSelectDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.selectedItems,
    required this.onSelect,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          InkWell(
            onTap: !enabled
                ? null
                : () async {
              List<String> tempSelected = List.from(selectedItems);

              final List<String>? result = await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(label),
                  content: StatefulBuilder(
                    builder: (context, setDialogState) {
                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: items.map((item) {
                            final isSelected =
                            tempSelected.contains(item);

                            return CheckboxListTile(
                              value: isSelected,
                              title: Text(item),
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    tempSelected.add(item);
                                  } else {
                                    tempSelected.remove(item);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, null),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, tempSelected),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );

              if (result != null) {
                onSelect(result);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: !enabled ? Colors.grey[200] : null,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      selectedItems.isEmpty
                          ? hint
                          : selectedItems.join(', '),
                      style: TextStyle(
                        color: selectedItems.isEmpty
                            ? Colors.grey
                            : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (enabled) const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
