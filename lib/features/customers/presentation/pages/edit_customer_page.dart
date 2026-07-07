import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/tally_customization_entry.dart';
import '../../../../core/models/tally_software_entry.dart';
import '../../../../core/utils/tally_customization_utils.dart';
import '../../../../core/utils/tally_software_history_utils.dart';
import '../../../../core/widgets/tally_customizations_form.dart';
import '../../../../core/widgets/tally_software_history_form.dart';
import '../providers/customer_provider.dart';

class EditCustomerPage extends ConsumerStatefulWidget {
  final String customerId;

  const EditCustomerPage({super.key, required this.customerId});

  @override
  ConsumerState<EditCustomerPage> createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends ConsumerState<EditCustomerPage> {
  final _formKey = GlobalKey<FormState>();

  // 1. Company & Ownership
  final _companyNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final List<TextEditingController> _contactPhoneControllers = [
    TextEditingController(),
  ];
  final _contactEmailController = TextEditingController();
  final _secretEmailController = TextEditingController();

  // 2. Accounting Personnel
  final _accountantNameController = TextEditingController();
  final _accountantPhoneController = TextEditingController();
  final _accountantEmailController = TextEditingController();

  // 3. Tally & Compliance Info
  final _tallyLicenseController = TextEditingController();
  final _tallySerialNoController = TextEditingController();
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
    _contactPersonController.dispose();
    for (final controller in _contactPhoneControllers) {
      controller.dispose();
    }
    _contactEmailController.dispose();
    _secretEmailController.dispose();

    _accountantNameController.dispose();
    _accountantPhoneController.dispose();
    _accountantEmailController.dispose();

    _tallyLicenseController.dispose();
    _tallySerialNoController.dispose();
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

  void _setPhoneControllers(List<String> numbers) {
    for (final controller in _contactPhoneControllers) {
      controller.dispose();
    }
    _contactPhoneControllers.clear();

    if (numbers.isEmpty) {
      _contactPhoneControllers.add(TextEditingController());
    } else {
      for (final phone in numbers) {
        _contactPhoneControllers.add(TextEditingController(text: phone));
      }
    }
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

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    final customer = await ref.read(customerProvider(widget.customerId).future);
    if (customer != null && mounted) {
      setState(() {
        // 1. Company & Ownership
        _companyNameController.text = customer.companyName;
        _contactPersonController.text = customer.contactPerson ?? '';
        _setPhoneControllers(customer.phoneNumbers);
        _contactEmailController.text = customer.contactEmail ?? '';
        _secretEmailController.text = customer.secretEmail ?? '';

        // 2. Accounting Personnel
        _accountantNameController.text = customer.accountantName ?? '';
        _accountantPhoneController.text = customer.accountantPhone ?? '';
        _accountantEmailController.text = customer.accountantEmail ?? '';

        // 3. Tally & Compliance Info
        _tallyLicenseController.text = customer.tallyLicense ?? '';
        _tallySerialNoController.text = customer.tallySerialNo ?? '';
        _amcExpiryDate = customer.amcExpiryDate;
        _tssExpiryDate = customer.tssExpiryDate;

        _tallyCustomizationEntries = parseTallyCustomizations(
          customer.tallyCustomizations,
        );

        _tallySoftwareEntries = parseTallySoftwareHistory(
          customer.tallySoftwareHistory,
        );
      });
    }
  }

  Future<void> _updateCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final client = Supabase.instance.client;

      final customizationsJson = encodeTallyCustomizations(
        _tallyCustomizationEntries,
      );
      final historyPayload = encodeTallySoftwareHistory(_tallySoftwareEntries);

      final phoneNumbers = _collectPhoneNumbers();
      final primaryPhone = phoneNumbers.isEmpty ? null : phoneNumbers.first;

      final updates = {
        // 1. Company & Ownership
        'company_name': _companyNameController.text.trim(),
        'contact_person': _contactPersonController.text.trim().isEmpty
            ? null
            : _contactPersonController.text.trim(),
        'contact_phone': primaryPhone,
        'contact_phone_numbers': phoneNumbers.isEmpty ? null : phoneNumbers,
        'contact_email': _contactEmailController.text.trim().isEmpty
            ? null
            : _contactEmailController.text.trim(),
        'secret_email': _secretEmailController.text.trim().isEmpty
            ? null
            : _secretEmailController.text.trim(),

        // 2. Accounting Personnel
        'accountant_name': _accountantNameController.text.trim().isEmpty
            ? null
            : _accountantNameController.text.trim(),
        'accountant_phone': _accountantPhoneController.text.trim().isEmpty
            ? null
            : _accountantPhoneController.text.trim(),
        'accountant_email': _accountantEmailController.text.trim().isEmpty
            ? null
            : _accountantEmailController.text.trim(),

        // 3. Tally & Compliance Info
        'tally_license': _tallyLicenseController.text.trim().isEmpty
            ? null
            : _tallyLicenseController.text.trim(),
        'tally_serial_no': _tallySerialNoController.text.trim().isEmpty
            ? null
            : _tallySerialNoController.text.trim(),
        'amc_expiry_date': _amcExpiryDate?.toIso8601String(),
        'tss_expiry_date': _tssExpiryDate?.toIso8601String(),
        'tally_customizations': customizationsJson,
        'tally_software_history': historyPayload.isEmpty
            ? null
            : historyPayload,
      };

      final response = await client
          .from('customers')
          .update(updates)
          .eq('id', widget.customerId)
          .select();

      if (response.isEmpty) {
        throw Exception(
          'Failed to update customer. You may not have permission or the record does not exist.',
        );
      }

      if (mounted) {
        ref.invalidate(customerProvider(widget.customerId));
        ref.invalidate(customersListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.push('/customer/${widget.customerId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating customer: $e'),
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
      initialDate: isAmc
          ? _amcExpiryDate ?? DateTime.now()
          : _tssExpiryDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
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
      currentPath: '/customer/${widget.customerId}/edit',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Edit Customer',
                subtitle: 'Update customer information',
                onBack: () => context.push('/customer/${widget.customerId}'),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Company & Ownership Section
                        Text(
                          '1. Company & Ownership',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 24),
                        TallySoftwareHistoryForm(
                          initialEntries: _tallySoftwareEntries,
                          helperText:
                              'Document the customer’s Tally upgrades over time.',
                          onChanged: (entries) =>
                              setState(() => _tallySoftwareEntries = entries),
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
                        TextFormField(
                          controller: _contactPersonController,
                          decoration: const InputDecoration(
                            labelText: 'Contact Person (Owner)',
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
                                      'Contact Phone Numbers',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: AppColors.textPrimary,
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
                                labelText: 'Contact Email (Login)',
                                prefixIcon: Icon(LucideIcons.mail),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _secretEmailController,
                          decoration: const InputDecoration(
                            labelText: 'Secret Email (Recovery)',
                            prefixIcon: Icon(LucideIcons.lock),
                            helperText:
                                'Used for password recovery if main email is lost',
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 32),

                        // 2. Accounting Personnel Section
                        Text(
                          '2. Accounting Personnel',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _accountantNameController,
                          decoration: const InputDecoration(
                            labelText: 'Accountant Name',
                            prefixIcon: Icon(LucideIcons.userCheck),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ResponsiveFormRow(
                          children: [
                            TextFormField(
                              controller: _accountantPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Accountant Phone',
                                prefixIcon: Icon(LucideIcons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            TextFormField(
                              controller: _accountantEmailController,
                              decoration: const InputDecoration(
                                labelText: 'Accountant Email',
                                prefixIcon: Icon(LucideIcons.mail),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 32),

                        // 3. Tally & Compliance Info Section
                        Text(
                          '3. Tally & Compliance Info',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
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
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
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
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
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
                              'Capture each customization module, developer, and last updated date.',
                          onChanged: (entries) {
                            setState(() {
                              _tallyCustomizationEntries = entries;
                            });
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
                                  : () => context.go(
                                      '/customer/${widget.customerId}',
                                    ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _updateCustomer,
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
                                  : const Text('Update Customer'),
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
