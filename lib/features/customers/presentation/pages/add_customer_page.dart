import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/tally_customization_entry.dart';
import '../../../../core/models/tally_software_entry.dart';
import '../../../../core/utils/tally_customization_utils.dart';
import '../../../../core/utils/tally_software_history_utils.dart';
import '../../../../core/widgets/tally_customizations_form.dart';
import '../../../../core/widgets/tally_software_history_form.dart';
import '../providers/customer_provider.dart';

class AddCustomerPage extends ConsumerStatefulWidget {
  const AddCustomerPage({super.key});

  @override
  ConsumerState<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends ConsumerState<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _tallyLicenseController = TextEditingController();
  final _tallySerialNoController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final List<TextEditingController> _contactPhoneControllers = [
    TextEditingController(),
  ];
  final _contactEmailController = TextEditingController();
  DateTime? _amcExpiryDate;
  DateTime? _tssExpiryDate;
  bool _isLoading = false;
  List<TallySoftwareEntry> _tallySoftwareEntries = [const TallySoftwareEntry()];
  List<TallyCustomizationEntry> _tallyCustomizationEntries = [
    const TallyCustomizationEntry(),
  ];

  @override
  void dispose() {
    _companyNameController.dispose();
    _tallyLicenseController.dispose();
    _tallySerialNoController.dispose();
    _contactPersonController.dispose();
    for (final controller in _contactPhoneControllers) {
      controller.dispose();
    }
    _contactEmailController.dispose();
    super.dispose();
  }

  void _addPhoneField() {
    setState(() {
      _contactPhoneControllers.add(TextEditingController());
    });
  }

  void _removePhoneField(int index) {
    if (_contactPhoneControllers.length == 1) return;
    setState(() {
      final controller = _contactPhoneControllers.removeAt(index);
      controller.dispose();
    });
  }

  List<String> _collectPhoneNumbers() {
    final seen = <String>{};
    final phones = <String>[];

    for (final controller in _contactPhoneControllers) {
      final value = controller.text.trim();
      if (value.isEmpty) continue;
      if (seen.add(value)) {
        phones.add(value);
      }
    }

    return phones;
  }

  String _generateApiKey() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final buffer = StringBuffer();
    for (int i = 0; i < 32; i++) {
      buffer.write(
        chars[(DateTime.now().millisecondsSinceEpoch * (i + 1)) % chars.length],
      );
    }
    return buffer.toString();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiKey = _generateApiKey();
      final client = Supabase.instance.client;
      final historyPayload = encodeTallySoftwareHistory(_tallySoftwareEntries);
      final customizationPayload = encodeTallyCustomizations(
        _tallyCustomizationEntries,
      );

      final phoneNumbers = _collectPhoneNumbers();
      final primaryPhone = phoneNumbers.isEmpty ? null : phoneNumbers.first;

      await client.from('customers').insert({
        'company_name': _companyNameController.text.trim(),
        'tally_license': _tallyLicenseController.text.trim().isEmpty
            ? null
            : _tallyLicenseController.text.trim(),
        'tally_serial_no': _tallySerialNoController.text.trim().isEmpty
            ? null
            : _tallySerialNoController.text.trim(),
        'api_key': apiKey,
        'amc_expiry_date': _amcExpiryDate?.toIso8601String(),
        'tss_expiry_date': _tssExpiryDate?.toIso8601String(),
        'contact_person': _contactPersonController.text.trim().isEmpty
            ? null
            : _contactPersonController.text.trim(),
        'contact_phone': primaryPhone,
        'contact_phone_numbers': phoneNumbers.isEmpty ? null : phoneNumbers,
        'contact_email': _contactEmailController.text.trim().isEmpty
            ? null
            : _contactEmailController.text.trim(),
        'tally_customizations': customizationPayload,
        'tally_software_history': historyPayload.isEmpty
            ? null
            : historyPayload,
      });

      if (mounted) {
        ref.invalidate(customersListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/customers');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding customer: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isAmc) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() {
        if (isAmc) {
          _amcExpiryDate = picked;
        } else {
          _tssExpiryDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentPath: '/customers/add',
      child: Scaffold(
        backgroundColor: context.adaptiveBackground,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Add New Customer',
                subtitle: 'Enter customer company details',
                onBack: () => context.go('/customers'),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: context.adaptiveBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company Information Section
                        Text(
                          'Company Information',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _companyNameController,
                          decoration: const InputDecoration(
                            labelText: 'Company Name *',
                            prefixIcon: Icon(LucideIcons.building),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Company name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ResponsiveFormRow(
                          children: [
                            TextFormField(
                              controller: _tallyLicenseController,
                              decoration: const InputDecoration(
                                labelText: 'Tally License',
                                prefixIcon: Icon(LucideIcons.key),
                              ),
                            ),
                            TextFormField(
                              controller: _tallySerialNoController,
                              decoration: const InputDecoration(
                                labelText: 'Tally Serial Number',
                                prefixIcon: Icon(LucideIcons.hash),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TallySoftwareHistoryForm(
                          initialEntries: _tallySoftwareEntries,
                          helperText:
                              'Keep a log of every Tally version the customer has used.',
                          onChanged: (entries) {
                            setState(() => _tallySoftwareEntries = entries);
                          },
                        ),
                        const SizedBox(height: 32),

                        // Contact Information Section
                        Text(
                          'Contact Information',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contactPersonController,
                          decoration: const InputDecoration(
                            labelText: 'Contact Person',
                            prefixIcon: Icon(LucideIcons.user),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ResponsiveFormRow(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Phone Numbers',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: context.adaptiveSlate900,
                                          ),
                                    ),
                                    IconButton(
                                      onPressed: _addPhoneField,
                                      icon: const Icon(LucideIcons.plus),
                                      tooltip: 'Add phone number',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                for (int i = 0;
                                    i < _contactPhoneControllers.length;
                                    i++) ...[
                                  TextFormField(
                                    controller: _contactPhoneControllers[i],
                                    decoration: InputDecoration(
                                      labelText: _contactPhoneControllers
                                                  .length ==
                                              1
                                          ? 'Phone Number'
                                          : 'Phone Number ${i + 1}',
                                      prefixIcon:
                                          const Icon(LucideIcons.phone),
                                      suffixIcon:
                                          _contactPhoneControllers.length > 1
                                              ? IconButton(
                                                  onPressed: () =>
                                                      _removePhoneField(i),
                                                  icon: const Icon(
                                                    LucideIcons.x,
                                                  ),
                                                  tooltip: 'Remove',
                                                )
                                              : null,
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                  if (i !=
                                      _contactPhoneControllers.length - 1)
                                    const SizedBox(height: 12),
                                ],
                              ],
                            ),
                            TextFormField(
                              controller: _contactEmailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(LucideIcons.mail),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final emailRegex = RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                  );
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Service Dates Section
                        Text(
                          'Service Information',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 16),
                        ResponsiveFormRow(
                          children: [
                            InkWell(
                              onTap: () => _selectDate(context, true),
                              borderRadius: BorderRadius.circular(8),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'AMC Expiry Date',
                                  prefixIcon: Icon(LucideIcons.calendar),
                                ),
                                child: Text(
                                  _amcExpiryDate != null
                                      ? '${_amcExpiryDate!.day}/${_amcExpiryDate!.month}/${_amcExpiryDate!.year}'
                                      : 'Select date',
                                  style: TextStyle(
                                    color: _amcExpiryDate != null
                                        ? context.adaptiveSlate900
                                        : context.adaptiveSlate500,
                                  ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _selectDate(context, false),
                              borderRadius: BorderRadius.circular(8),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'TSS Expiry Date',
                                  prefixIcon: Icon(LucideIcons.calendar),
                                ),
                                child: Text(
                                  _tssExpiryDate != null
                                      ? '${_tssExpiryDate!.day}/${_tssExpiryDate!.month}/${_tssExpiryDate!.year}'
                                      : 'Select date',
                                  style: TextStyle(
                                    color: _tssExpiryDate != null
                                        ? context.adaptiveSlate900
                                        : context.adaptiveSlate500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TallyCustomizationsForm(
                          initialEntries: _tallyCustomizationEntries,
                          helperText:
                              'Caputure each customization module, developer, and last updated date.',
                          onChanged: (entries) {
                            setState(
                              () => _tallyCustomizationEntries = entries,
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => context.go('/customers'),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _saveCustomer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text('Add Customer'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
