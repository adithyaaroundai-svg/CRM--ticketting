import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design_system/theme/app_colors.dart';
import '../models/tally_software_entry.dart';

class TallySoftwareHistoryForm extends StatefulWidget {
  final List<TallySoftwareEntry> initialEntries;
  final ValueChanged<List<TallySoftwareEntry>> onChanged;
  final String? helperText;

  const TallySoftwareHistoryForm({
    super.key,
    required this.initialEntries,
    required this.onChanged,
    this.helperText,
  });

  @override
  State<TallySoftwareHistoryForm> createState() =>
      _TallySoftwareHistoryFormState();
}

class _TallySoftwareHistoryFormState extends State<TallySoftwareHistoryForm> {
  late List<TallySoftwareEntry> _entries;
  late List<TextEditingController> _nameControllers;
  final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _nameControllers = [];
    _hydrateEntries();
  }

  List<TallySoftwareEntry> get _normalizedInitial =>
      widget.initialEntries.isEmpty
      ? [const TallySoftwareEntry()]
      : widget.initialEntries;

  void _hydrateEntries() {
    _entries = _normalizedInitial.map((entry) => entry).toList(growable: true);

    if (_nameControllers.length != _entries.length) {
      _disposeControllers();
      _nameControllers = List.generate(
        _entries.length,
        (index) => _createController(_entries[index].name),
      );
    } else {
      for (var i = 0; i < _entries.length; i++) {
        _syncControllerText(_nameControllers[i], _entries[i].name);
      }
    }
  }

  void _disposeControllers() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    _nameControllers = [];
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

  bool _listEquals(List<TallySoftwareEntry> a, List<TallySoftwareEntry> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.name != right.name ||
          left.fromDate?.toIso8601String() !=
              right.fromDate?.toIso8601String() ||
          left.toDate?.toIso8601String() != right.toDate?.toIso8601String()) {
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
  void didUpdateWidget(covariant TallySoftwareHistoryForm oldWidget) {
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
    widget.onChanged(List<TallySoftwareEntry>.from(_entries));
  }

  void _addEntry() {
    setState(() {
      _entries.add(const TallySoftwareEntry());
      _nameControllers.add(_createController(''));
    });
    _notifyParent();
  }

  void _removeEntry(int index) {
    if (_entries.length == 1) return;
    setState(() {
      _entries.removeAt(index);
      final controller = _nameControllers.removeAt(index);
      controller.dispose();
    });
    _notifyParent();
  }

  Future<void> _pickDate(int index, bool isFromDate) async {
    final currentEntry = _entries[index];
    final initialDate =
        (isFromDate ? currentEntry.fromDate : currentEntry.toDate) ??
        DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _entries[index] = isFromDate
            ? currentEntry.copyWith(fromDate: picked)
            : currentEntry.copyWith(toDate: picked);
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
            const Icon(LucideIcons.layers, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Tally Software History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.adaptiveSlate900,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Add software',
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
            style: TextStyle(fontSize: 12, color: context.adaptiveSlate500),
          ),
        ],
        const SizedBox(height: 16),
        Column(children: List.generate(_entries.length, _buildEntryCard)),
      ],
    );
  }

  Widget _buildEntryCard(int index) {
    final entry = _entries[index];
    final hasName = entry.hasName;

    return Padding(
      padding: EdgeInsets.only(bottom: index == _entries.length - 1 ? 0 : 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.adaptiveBorder),
          color: context.adaptiveCard,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Tally Software Name',
                      prefixIcon: Icon(LucideIcons.box),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _entries[index] = entry.copyWith(name: value);
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
                      tooltip: index == 0 ? null : 'Remove entry',
                      icon: const Icon(LucideIcons.trash2),
                      color: context.adaptiveError,
                    ),
                  ),
                ),
              ],
            ),
            if (hasName) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  'Valid for',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.adaptiveSlate500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'From Date',
                      icon: LucideIcons.calendar,
                      value: entry.fromDate != null
                          ? _dateFormat.format(entry.fromDate!)
                          : 'Select date',
                      onTap: () => _pickDate(index, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateButton(
                      label: 'To Date',
                      icon: LucideIcons.calendarClock,
                      value: entry.toDate != null
                          ? _dateFormat.format(entry.toDate!)
                          : 'Present',
                      onTap: () => _pickDate(index, false),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value == 'Select date' || value == 'Present';
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: context.adaptiveBorder),
        ),
        backgroundColor: AppColors.primary.withValues(alpha: 0.04),
        foregroundColor: AppColors.primary,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.adaptiveSlate500),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPlaceholder ? AppColors.primary : AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
