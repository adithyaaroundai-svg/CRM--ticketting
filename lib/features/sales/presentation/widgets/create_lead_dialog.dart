import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

class CreateLeadDialog extends ConsumerStatefulWidget {
  const CreateLeadDialog({super.key});

  @override
  ConsumerState<CreateLeadDialog> createState() => _CreateLeadDialogState();
}

class _CreateLeadDialogState extends ConsumerState<CreateLeadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _followUpDateController = TextEditingController();
  final _otherSourceController = TextEditingController();

  String? _selectedStatus;
  String? _selectedOwner;
  String? _selectedSource;
  String? _selectedDemoNeeded;
  bool _isSubmitting = false;

  final List<String> _statusOptions = [
    'New',
    'Contacted',
    'Qualified',
    'Proposal',
    'Negotiation',
    'Won',
    'Lost',
  ];

  final List<String> _sourceOptions = [
    'Tally',
    'Online',
    'Incoming call',
    'STP',
    'Existing Customer',
    'Other Customer referral',
    'Other',
  ];

  @override
  void dispose() {
    _customerNameController.dispose();
    _companyNameController.dispose();
    _phoneNumberController.dispose();
    _descriptionController.dispose();
    _followUpDateController.dispose();
    _otherSourceController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    String? hint,
    String? label,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      hintStyle: TextStyle(color: AppColors.slate400),
      border: _outlineBorder(AppColors.slate300),
      enabledBorder: _outlineBorder(AppColors.slate300),
      focusedBorder: _outlineBorder(AppColors.primary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  OutlineInputBorder _outlineBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: 1.2),
    );
  }

  Future<void> _createLead() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final container = ProviderScope.containerOf(context, listen: false);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final currentUser = ref.read(authProvider);

    // Capture user data before async operations
    final senderId = currentUser?.id;
    final senderName = currentUser?.fullName;
    final senderRole = currentUser?.role;
    final senderAvatarUrl = currentUser?.avatarUrl;

    try {
      final sourceValue = _selectedSource == 'Other'
          ? _otherSourceController.text.trim()
          : _selectedSource;

      final leadData = {
        'customer_name': _customerNameController.text.trim().isNotEmpty
            ? _customerNameController.text.trim()
            : null,
        'company_name': _companyNameController.text.trim(),
        'phone_number': _phoneNumberController.text.trim(),
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'follow_up_date': _followUpDateController.text.trim().isNotEmpty
            ? _followUpDateController.text.trim()
            : null,
        'status': _selectedStatus,
        'owner': _selectedOwner ?? currentUser?.fullName ?? 'Unassigned',
        'source': sourceValue,
        'demo_needed': _selectedDemoNeeded,
        'created_by': currentUser?.id,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      await Supabase.instance.client.from('leads').insert(leadData);

      // Prepare chat content if demo is needed
      String? chatContent;
      if (_selectedDemoNeeded == 'Yes') {
        chatContent = [
          '🎯 New Lead (Demo Requested)',
          'Company: ${leadData['company_name']}',
          if (leadData['customer_name'] != null) 'Customer: ${leadData['customer_name']}',
          'Phone: ${leadData['phone_number']}',
          if (leadData['status'] != null) 'Status: ${leadData['status']}',
          if (leadData['source'] != null) 'Source: ${leadData['source']}',
          'Owner: ${leadData['owner']}',
          if (leadData['description'] != null) 'Description: ${leadData['description']}',
          if (leadData['follow_up_date'] != null) 'Follow Up: ${leadData['follow_up_date']}',
        ].join('\n');
      }

      // Close dialog immediately
      if (mounted) {
        rootNavigator.pop(true);
      }

      // Send to chat after closing (if demo needed)
      if (chatContent != null &&
          senderId != null &&
          senderName != null &&
          senderRole != null) {
        try {
          await container.read(chatRepositoryProvider).sendMessage(
                senderId: senderId,
                senderName: senderName,
                senderRole: senderRole,
                content: chatContent,
                senderAvatarUrl: senderAvatarUrl,
              );
          container.invalidate(chatStreamProvider('support-chat'));
          container.invalidate(chatUnreadCountProvider);
        } catch (error) {
          messenger?.showSnackBar(
            SnackBar(
              content: Text('Lead created, but chat post failed: $error'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        messenger?.showSnackBar(
          SnackBar(
            content: Text('Error creating lead: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _selectFollowUpDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      _followUpDateController.text = picked.toIso8601String().split('T')[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentsAsync = ref.watch(agentsListProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = math.max(280.0, math.min(screenWidth - 72, 860.0));

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
        child: Material(
          elevation: 12,
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth),
            child: Container(
              width: dialogWidth,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Create New Lead',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate900,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.x, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // 2-Column Grid Layout
                      ResponsiveFormRow(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                // Customer Name
                                const Text(
                                  'Customer Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _customerNameController,
                                  decoration: _inputDecoration(
                                    hint: 'Enter customer name',
                                    prefixIcon: const Icon(LucideIcons.user, size: 16),
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Company Name
                                const Text(
                                  'Company Name *',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _companyNameController,
                                  decoration: _inputDecoration(
                                    hint: 'Enter company name',
                                    prefixIcon: const Icon(LucideIcons.building, size: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Company name is required';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 14),

                                // Phone Number
                                const Text(
                                  'Phone Number *',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _phoneNumberController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _inputDecoration(
                                    hint: 'Enter phone number',
                                    prefixIcon: const Icon(LucideIcons.phone, size: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Phone number is required';
                                    }
                                    if (value.trim().length < 6) {
                                      return 'Enter a valid phone number';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 14),

                                // Follow Up Date
                                const Text(
                                  'Follow Up Date',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _followUpDateController,
                                  readOnly: true,
                                  decoration: _inputDecoration(
                                    hint: 'Select follow up date',
                                    prefixIcon: const Icon(LucideIcons.calendar, size: 16),
                                    suffixIcon: const Icon(LucideIcons.calendar, size: 16),
                                  ),
                                  onTap: _selectFollowUpDate,
                                ),

                                const SizedBox(height: 14),

                                // Status
                                const Text(
                                  'Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _selectedStatus,
                                  decoration: _inputDecoration(
                                    hint: 'Select status',
                                    prefixIcon: const Icon(LucideIcons.tag, size: 16),
                                  ),
                                  items: _statusOptions.map((String status) {
                                    return DropdownMenuItem<String>(
                                      value: status,
                                      child: Text(status),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedStatus = newValue;
                                    });
                                  },
                                ),
                            ],
                          ),

                          // Right Column
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                // Owner
                                const Text(
                                  'Owner',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                agentsAsync.when(
                                  data: (agents) {
                                    final allowedOwnerIds = {
                                      '0a5aeeb8-9544-4dc8-920f-e26c192b0dd3',
                                      '1f4d7758-12ba-43eb-9e47-cc0c95b740b8',
                                      '5a06a8df-97f1-4dbf-bc13-9724a3c779c1',
                                      '14db36db-0cb9-44ef-8032-d9610b3bc797',
                                      'd8aa6435-9e02-4bab-9acc-ae1f5f3d6a1c',
                                      'b77b3738-4dfc-4515-a1fd-d6fb170423f4',
                                    };
                                    final ownerOptions = agents
                                        .where((a) => allowedOwnerIds.contains(a['id']?.toString()))
                                        .map<String>((a) {
                                          return (a['full_name'] ?? a['username'] ?? '').toString();
                                        })
                                        .toList();
                                    return DropdownButtonFormField<String>(
                                      value: _selectedOwner,
                                      decoration: _inputDecoration(
                                        hint: 'Select owner',
                                        prefixIcon: const Icon(LucideIcons.userCheck, size: 16),
                                      ),
                                      items: ownerOptions.map((String owner) {
                                        return DropdownMenuItem<String>(
                                          value: owner,
                                          child: Text(owner),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedOwner = newValue;
                                        });
                                      },
                                    );
                                  },
                                  loading: () => const LinearProgressIndicator(),
                                  error: (_, __) => const Text('Error loading agents'),
                                ),

                                const SizedBox(height: 14),

                                // Source of Enquiry
                                const Text(
                                  'Source of Enquiry',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _selectedSource,
                                  decoration: _inputDecoration(
                                    hint: 'Select source',
                                    prefixIcon: const Icon(LucideIcons.globe, size: 16),
                                  ),
                                  items: _sourceOptions.map((String source) {
                                    return DropdownMenuItem<String>(
                                      value: source,
                                      child: Text(source),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedSource = newValue;
                                      if (newValue != 'Other') {
                                        _otherSourceController.clear();
                                      }
                                    });
                                  },
                                ),

                                if (_selectedSource == 'Other') ...[
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Specify Source',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      color: AppColors.slate900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _otherSourceController,
                                    decoration: _inputDecoration(
                                      hint: 'Enter source details',
                                      prefixIcon: const Icon(LucideIcons.edit, size: 16),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 14),

                                // Demo Needed
                                const Text(
                                  'Demo Needed',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _selectedDemoNeeded,
                                  decoration: _inputDecoration(
                                    hint: 'Select option',
                                    prefixIcon: const Icon(LucideIcons.play, size: 16),
                                  ),
                                  items: const [
                                    DropdownMenuItem<String>(
                                      value: 'Yes',
                                      child: Text('Yes'),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'No',
                                      child: Text('No'),
                                    ),
                                  ],
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedDemoNeeded = newValue;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Description (Full Width)
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: _inputDecoration(
                          hint: 'Enter lead description',
                        ),
                      ),

                      const SizedBox(height: 24),
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        spacing: 10,
                        overflowSpacing: 10,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppColors.slate600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          FilledButton(
                            onPressed: _isSubmitting ? null : _createLead,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save Lead',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
