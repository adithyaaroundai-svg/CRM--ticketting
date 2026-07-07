import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design_system/theme/app_colors.dart';
import '../models/tally_customization_entry.dart';

class TallyCustomizationsForm extends StatefulWidget {
  final List<TallyCustomizationEntry> initialEntries;
  final ValueChanged<List<TallyCustomizationEntry>> onChanged;
  final String? helperText;

  const TallyCustomizationsForm({
    super.key,
    required this.initialEntries,
    required this.onChanged,
    this.helperText,
  });

  @override
  State<TallyCustomizationsForm> createState() =>
      _TallyCustomizationsFormState();
}

class _TallyCustomizationsFormState extends State<TallyCustomizationsForm> {
  late List<TallyCustomizationEntry> _entries;
  late List<TextEditingController> _moduleControllers;
  final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _moduleControllers = [];
    _hydrateEntries();
  }

  List<TallyCustomizationEntry> get _normalizedInitial =>
      widget.initialEntries.isEmpty
      ? [const TallyCustomizationEntry()]
      : widget.initialEntries;

  void _hydrateEntries() {
    _entries = _normalizedInitial.map((entry) => entry).toList(growable: true);

    if (_moduleControllers.length != _entries.length) {
      _disposeControllers();
      _moduleControllers = List.generate(
        _entries.length,
        (index) => _createController(_entries[index].moduleName),
      );
    } else {
      for (var i = 0; i < _entries.length; i++) {
        _syncControllerText(_moduleControllers[i], _entries[i].moduleName);
      }
    }
  }

  void _disposeControllers() {
    for (final controller in _moduleControllers) {
      controller.dispose();
    }
    _moduleControllers = [];
  }

  TextEditingController _createController(String text) {
    final controller = TextEditingController(text: text);
    controller.selection = TextSelection.collapsed(offset: text.length);
    return controller;
  }

  void _syncControllerText(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }

  bool _listEquals(
    List<TallyCustomizationEntry> a,
    List<TallyCustomizationEntry> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.moduleName != right.moduleName ||
          left.lastUpdated?.toIso8601String() !=
              right.lastUpdated?.toIso8601String()) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TallyCustomizationsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasExternalChange = !_listEquals(
      widget.initialEntries,
      oldWidget.initialEntries,
    );
    final differsFromInternal = !_listEquals(widget.initialEntries, _entries);
    if (hasExternalChange && differsFromInternal) {
      _disposeControllers();
      setState(() {
        _hydrateEntries();
      });
    }
  }

  void _notifyParent() {
    widget.onChanged(List<TallyCustomizationEntry>.from(_entries));
  }

  void _addEntry() {
    setState(() {
      _entries.add(const TallyCustomizationEntry());
      _moduleControllers.add(_createController(''));
    });
    _notifyParent();
  }

  void _removeEntry(int index) {
    if (_entries.length == 1) return;
    setState(() {
      _entries.removeAt(index);
      final module = _moduleControllers.removeAt(index);
      module.dispose();
    });
    _notifyParent();
  }

  Future<void> _pickDate(int index) async {
    final currentEntry = _entries[index];
    final picked = await showDatePicker(
      context: context,
      initialDate: currentEntry.lastUpdated ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _entries[index] = currentEntry.copyWith(lastUpdated: picked);
      });
      _notifyParent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.settings,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Tally Customizations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Add customization',
              onPressed: _addEntry,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                foregroundColor: AppColors.primary,
              ),
              icon: const Icon(LucideIcons.plus),
            ),
          ],
        ),
        if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
        const SizedBox(height: 16),
        Column(children: List.generate(_entries.length, _buildEntryCard)),
      ],
    );
  }

  Widget _buildEntryCard(int index) {
    final entry = _entries[index];

    return Padding(
      padding: EdgeInsets.only(bottom: index == _entries.length - 1 ? 0 : 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _moduleControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Module Name',
                      prefixIcon: Icon(LucideIcons.package),
                    ),
                    maxLines: null,
                    onChanged: (value) {
                      setState(() {
                        _entries[index] = entry.copyWith(moduleName: value);
                      });
                      _notifyParent();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: Align(
                    alignment: Alignment.center,
                    child: IconButton(
                      onPressed: index == 0 ? null : () => _removeEntry(index),
                      tooltip: index == 0 ? null : 'Remove module',
                      icon: const Icon(LucideIcons.trash2),
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _pickDate(index),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
                backgroundColor: AppColors.primary.withValues(alpha: 0.04),
                foregroundColor: AppColors.primary,
              ),
              icon: const Icon(LucideIcons.calendarClock, size: 18),
              label: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Updated On',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  Text(
                    entry.lastUpdated != null
                        ? _dateFormat.format(entry.lastUpdated!)
                        : 'Select date',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
