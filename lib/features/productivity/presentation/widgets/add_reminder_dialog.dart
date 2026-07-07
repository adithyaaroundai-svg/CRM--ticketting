import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../domain/entities/reminder.dart';
import '../providers/reminder_provider.dart';

class AddReminderDialog extends ConsumerStatefulWidget {
  const AddReminderDialog({super.key});

  @override
  ConsumerState<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends ConsumerState<AddReminderDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _companyController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _showActiveReminders = false;

  // Default date = today, time = null (user must pick)
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _showActiveReminders ? 'Active Reminders' : 'Create Reminder',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: Icon(
                          _showActiveReminders ? LucideIcons.plus : LucideIcons.list,
                          size: 16,
                        ),
                        label: Text(_showActiveReminders ? 'New' : 'View Active'),
                        onPressed: () {
                          setState(() {
                            _showActiveReminders = !_showActiveReminders;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: _showActiveReminders ? _buildActiveRemindersList() : _buildCreateForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRemindersList() {
    final reminders = ref.watch(remindersProvider);
    final active = reminders.where((r) => !r.isCompleted && !r.isTriggered).toList()
      ..sort((a, b) => a.remindAt.compareTo(b.remindAt));

    if (active.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text('No active reminders.', style: TextStyle(color: AppColors.slate500)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: active.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final r = active[index];
        final timeFmt = DateFormat('MMM d, yyyy HH:mm').format(r.remindAt);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(r.companyName, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.notes.isNotEmpty) Text(r.notes),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(LucideIcons.clock, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(timeFmt, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(LucideIcons.checkCircle, color: AppColors.success),
            tooltip: 'Mark as completed',
            onPressed: () {
              ref.read(remindersProvider.notifier).completeReminder(r.id);
            },
          ),
        );
      },
    );
  }

  Widget _buildCreateForm() {
    final customersAsync = ref.watch(customersListProvider);
    final today = DateTime.now();
    final isToday = _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;
    final dateLabel =
        isToday ? 'Today' : DateFormat('MMM d, yyyy').format(_selectedDate);

    return SingleChildScrollView(
      child: FormBuilder(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Company autocomplete ─────────────────────────────────
            customersAsync.when(
              data: (customers) {
                final uniqueCompanyNames = customers
                    .map((c) => c.companyName)
                    .where((name) => name.isNotEmpty)
                    .toSet()
                    .toList();

                return Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return uniqueCompanyNames.take(5);
                    }
                    return uniqueCompanyNames.where((name) => name
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    _companyController.text = selection;
                  },
                  fieldViewBuilder: (context, textEditingController,
                      focusNode, onFieldSubmitted) {
                    textEditingController.addListener(() {
                      _companyController.text = textEditingController.text;
                    });
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Company Name (Select or type custom)',
                        border: OutlineInputBorder(),
                        hintText: 'Start typing a company...',
                      ),
                      onFieldSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxHeight: 200, maxWidth: 432),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(option),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => const Text('Error loading customers'),
            ),

            const SizedBox(height: 16),

            // ── Phone number ─────────────────────────────────────────
            FormBuilderTextField(
              name: 'phoneNumber',
              decoration: const InputDecoration(
                labelText: 'Phone Number / Contact Info',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // ── Date + Time pickers ──────────────────────────────────
            Row(
              children: [
                // Date
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon:
                            Icon(LucideIcons.calendar, size: 18),
                      ),
                      child: Text(
                        dateLabel,
                        style: const TextStyle(color: AppColors.slate900),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Time
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(LucideIcons.clock, size: 18),
                      ),
                      child: Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'Select time',
                        style: TextStyle(
                          color: _selectedTime != null
                              ? AppColors.slate900
                              : AppColors.slate400,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Notes ────────────────────────────────────────────────
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any extra context...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            // ── Actions ──────────────────────────────────────────────
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 16,
              overflowSpacing: 16,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _saveReminder,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Reminder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveReminder() {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time for the reminder.')),
      );
      return;
    }

    final remindAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (remindAt.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Selected time is in the past. Please choose a future time.')),
      );
      return;
    }

    _formKey.currentState?.save();

    final companyName = _companyController.text.trim().isNotEmpty
        ? _companyController.text.trim()
        : 'Unknown Company';

    final phoneNumber =
        _formKey.currentState?.value['phoneNumber']?.toString() ?? '';

    setState(() => _isLoading = true);

    final reminder = Reminder(
      id: const Uuid().v4(),
      companyName: companyName,
      phoneNumber: phoneNumber,
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
      remindAt: remindAt,
    );

    ref.read(remindersProvider.notifier).addReminder(reminder);
    Navigator.of(context).pop();
  }
}
