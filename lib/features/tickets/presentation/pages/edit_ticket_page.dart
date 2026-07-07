import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/ticket.dart';
import '../providers/ticket_provider.dart';

class EditTicketPage extends ConsumerStatefulWidget {
  final Ticket ticket;

  const EditTicketPage({super.key, required this.ticket});

  @override
  ConsumerState<EditTicketPage> createState() => _EditTicketPageState();
}

class _EditTicketPageState extends ConsumerState<EditTicketPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String? _selectedCategory;
  late String? _selectedPriority;

  final List<String> _categories = [
    'Hardware',
    'Software',
    'Billing',
    'Technical',
    'General',
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.ticket.title);
    _descriptionController = TextEditingController(
      text: widget.ticket.description,
    );
    _selectedCategory = widget.ticket.category;

    // Normalize priority for legacy values
    final rawPriority = widget.ticket.priority;
    if (rawPriority == null) {
      _selectedPriority = null;
    } else if (rawPriority == 'Normal') {
      _selectedPriority = 'Medium';
    } else if (rawPriority == 'Critical') {
      _selectedPriority = 'Urgent';
    } else if (!_priorities.contains(rawPriority)) {
      _selectedPriority = null; // Unrecognized value
    } else {
      _selectedPriority = rawPriority;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTicket() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedTicket = widget.ticket.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
      updatedAt: DateTime.now(),
    );

    final error = await ref
        .read(ticketUpdaterProvider.notifier)
        .updateTicket(updatedTicket);

    if (mounted) {
      if (error == null) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update ticket: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Edit Ticket'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Basic Information'),
                  const SizedBox(height: 16),

                  _buildLabel('Issue (Title) *'),
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration('Briefly describe the issue'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the issue title';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),
                  ResponsiveFormRow(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Category'),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: _inputDecoration('Select category'),
                            items: _categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedCategory = value),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Priority'),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedPriority,
                            decoration: _inputDecoration('Select priority'),
                            items: _priorities
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedPriority = value),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildLabel('Description'),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: _inputDecoration('Provide more details...'),
                    maxLines: 10,
                    minLines: 5,
                  ),

                  const SizedBox(height: 40),
                  AppButton(
                    label: 'Save Changes',
                    icon: LucideIcons.save,
                    onPressed: _saveTicket,
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.slate900,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.slate700,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
