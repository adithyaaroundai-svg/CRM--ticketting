import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

class CreateTicketDialog extends ConsumerStatefulWidget {
  final bool isSupport;
  final bool postToChat;

  const CreateTicketDialog({
    super.key,
    this.isSupport = false,
    this.postToChat = true,
  });

  @override
  ConsumerState<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends ConsumerState<CreateTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _newCustomerNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  TextEditingController? _customerFieldController;
  String? _pendingCustomerName;

  static const _uuid = Uuid();

  bool _isUrgent = false;
  static const _defaultCategory = 'Technical';
  String? _selectedCustomerId;
  bool _isSubmitting = false;
  bool _showQuickCustomerForm = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _newCustomerNameController.dispose();
    _phoneNumberController.dispose();
    _customerFieldController = null;
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

  Future<void> _createTicket({bool assignToSelf = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_showQuickCustomerForm && (_selectedCustomerId == null || _selectedCustomerId!.isEmpty)) {
      return;
    }

    setState(() => _isSubmitting = true);

    final container = ProviderScope.containerOf(context, listen: false);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ticketCreator = ref.read(ticketCreatorProvider.notifier);
    final currentUser = ref.read(authProvider);
    bool success = false;
    Ticket? createdTicket;
    Ticket? ticketToReturn;
    String? senderId;
    String? senderName;
    String? senderRole;
    String? senderAvatarUrl;
    String companyName = 'Company';
    String? chatContent;

    // Capture user data before async operations
    senderId = currentUser?.id;
    senderName = currentUser?.fullName;
    senderRole = currentUser?.role;
    senderAvatarUrl = currentUser?.avatarUrl;
    final currentUserId = currentUser?.id;
    final username = currentUser?.username;

    try {
      String? customerId = _selectedCustomerId;

      if (_showQuickCustomerForm) {
        final newCustomer = await _createCustomerFromQuickForm();
        if (newCustomer == null) {
          setState(() => _isSubmitting = false);
          return;
        }
        customerId = newCustomer.id;
        companyName = newCustomer.companyName;
      } else {
        final value = _customerFieldController?.text.trim();
        if (value != null && value.isNotEmpty) {
          companyName = value;
        }
      }

      if (customerId == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      final subject = _subjectController.text.trim();
      final phoneNumber = _phoneNumberController.text.trim();
      String creatorIdentifier = 'Unknown';
      if (currentUserId != null && currentUserId.trim().isNotEmpty) {
        creatorIdentifier = currentUserId;
      } else {
        if (username != null && username.trim().isNotEmpty) {
          creatorIdentifier = username;
        }
      }

      final nowUtc = DateTime.now().toUtc();
      final ticket = Ticket(
        ticketId: _uuid.v4(), // Generated locally
        customerId: customerId,
        title: subject,
        description: subject,
        contactPhone: phoneNumber.isNotEmpty ? phoneNumber : null,
        status: 'New',
        priority: _isUrgent ? 'Urgent' : 'Medium',
        category: _defaultCategory,
        createdAt: nowUtc,
        updatedAt: nowUtc,
        createdBy: creatorIdentifier,
        assignedTo: assignToSelf ? currentUser?.id : null,
      );

      createdTicket = await ticketCreator.createTicket(ticket);

      if (createdTicket == null) {
        success = false;
      } else {
        ticketToReturn = createdTicket;
        success = true;

        chatContent = [
          'Company: $companyName',
          'Issue: $subject',
          'TicketID: ${ticketToReturn!.ticketId}',
        ].join('\n');

        ref.invalidate(rawTicketsStreamProvider);
        ref.invalidate(rawAllTicketsStreamProvider);
      }
    } catch (e) {
      print('=== Ticket Creation Error ===');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');
      success = false;
    } finally {
      if (mounted && !success) {
        setState(() => _isSubmitting = false);
      }
    }

    // Post to chat before closing to ensure it happens
    print('=== Chat Post Debug ===');
    print('success: $success');
    print('postToChat: ${widget.postToChat}');
    print('senderId: $senderId');
    print('senderName: $senderName');
    print('senderRole: $senderRole');
    print('chatContent: $chatContent');
    
    if (success && widget.postToChat &&
        senderId != null &&
        senderName != null &&
        senderRole != null &&
        chatContent != null) {
      try {
        print('Attempting to post to chat...');
        await _sendTicketToChatDirect(
          container: container,
          senderId: senderId,
          senderName: senderName,
          senderRole: senderRole,
          content: chatContent,
          senderAvatarUrl: senderAvatarUrl,
        );
        print('Chat post successful, invalidating providers...');
        container.invalidate(chatStreamProvider('support-chat'));
        container.invalidate(chatUnreadCountProvider);
        print('Providers invalidated.');
      } catch (error) {
        print('Chat post failed: $error');
        messenger?.showSnackBar(
          SnackBar(
            content: Text('Ticket created, but chat post failed: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else if (!success) {
      // Ticket creation actually failed — show error and keep dialog open
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Failed to create ticket. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Close the dialog only on success
    if (mounted) {
      rootNavigator.pop(ticketToReturn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersListProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = math.max(520.0, math.min(screenWidth - 72, 860.0));

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
                            'Create New Ticket',
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

                      // Customer selector
                      Row(
                        children: [
                          const Text(
                            'Customer *',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message:
                                _showQuickCustomerForm ? 'Back to customer search' : 'New customer',
                            child: IconButton(
                              icon: Icon(
                                _showQuickCustomerForm
                                    ? LucideIcons.search
                                    : LucideIcons.userPlus,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  final nextIsQuick = !_showQuickCustomerForm;
                                  _showQuickCustomerForm = nextIsQuick;
                                  _selectedCustomerId = null;
                                  _customerFieldController?.clear();
                                  _pendingCustomerName = null;
                                  _newCustomerNameController.clear();
                                  if (nextIsQuick) {
                                    _phoneNumberController.clear();
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (!_showQuickCustomerForm)
                        customersAsync.when(
                          data: (customers) => LayoutBuilder(
                            builder: (context, constraints) => Autocomplete<Customer>(
                              displayStringForOption: (option) => option.companyName,
                              optionsBuilder: (text) {
                                if (text.text.isEmpty) {
                                  return const Iterable<Customer>.empty();
                                }
                                return customers.where((option) =>
                                    option.companyName
                                        .toLowerCase()
                                        .contains(text.text.toLowerCase()));
                              },
                              onSelected: (selection) {
                                setState(() {
                                  _selectedCustomerId = selection.id;
                                  _customerFieldController?.text = selection.companyName;
                                  final phone = selection.primaryPhone;
                                  if (phone != null) {
                                    _phoneNumberController.text = phone;
                                  }
                                });
                              },
                              fieldViewBuilder:
                                  (context, controller, focusNode, onFieldSubmitted) {
                                _customerFieldController ??= controller;
                                if (_pendingCustomerName != null) {
                                  controller.text = _pendingCustomerName!;
                                  _pendingCustomerName = null;
                                }
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: _inputDecoration(
                                    hint: 'Search customer...',
                                    suffixIcon: const Icon(LucideIcons.search, size: 16),
                                  ),
                                  onChanged: (value) {
                                    if (value.isEmpty) {
                                      setState(() {
                                        _selectedCustomerId = null;
                                        _phoneNumberController.clear();
                                      });
                                    }
                                  },
                                  onFieldSubmitted: (_) => onFieldSubmitted(),
                                  validator: (_) {
                                    if (_showQuickCustomerForm) return null;
                                    if (_selectedCustomerId == null ||
                                        _selectedCustomerId!.isEmpty) {
                                      return 'Please select a customer from the list';
                                    }
                                    return null;
                                  },
                                );
                              },
                              optionsViewBuilder: (context, onSelected, options) {
                                final optionList = options.toList();
                                final hasResults = optionList.isNotEmpty;
                                final rows = hasResults ? optionList.length : 1;
                                final maxHeight = hasResults
                                    ? math.min(420.0, rows * 76.0)
                                    : 120.0;

                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4,
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      height: maxHeight,
                                      width: constraints.maxWidth,
                                      child: hasResults
                                          ? ListView.separated(
                                              padding: EdgeInsets.zero,
                                              itemCount: optionList.length,
                                              physics: const BouncingScrollPhysics(),
                                              separatorBuilder: (_, __) =>
                                                  const Divider(height: 1, thickness: 0.5),
                                              itemBuilder: (context, index) {
                                                final option = optionList[index];
                                                return ListTile(
                                                  title: Text(option.companyName),
                                                  subtitle:
                                                      Text(option.contactPerson ?? 'No contact name'),
                                                  trailing: option.isAmcActive
                                                      ? const Chip(
                                                          label: Text('AMC Active'),
                                                          backgroundColor: AppColors.success,
                                                          labelStyle: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                          ),
                                                        )
                                                      : const Chip(
                                                          label: Text('AMC Expired'),
                                                          backgroundColor: AppColors.error,
                                                          labelStyle: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                  onTap: () => onSelected(option),
                                                );
                                              },
                                            )
                                          : const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(16),
                                                child: Text(
                                                  'No customers match your search',
                                                  style: TextStyle(color: AppColors.slate500),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text('Error loading customers'),
                        ),

                      if (_showQuickCustomerForm)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _newCustomerNameController,
                                decoration: _inputDecoration(
                                  label: 'Customer Name',
                                  prefixIcon: const Icon(LucideIcons.user),
                                ),
                                validator: (value) {
                                  if (!_showQuickCustomerForm) return null;
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Customer name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Phone number will be collected using the field below.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slate500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showQuickCustomerForm = false;
                                      _newCustomerNameController.clear();
                                    });
                                  },
                                  child: const Text('Cancel New Customer'),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 14),
                      const Text(
                        'Subject / Description *',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _subjectController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: _inputDecoration(
                          hint: 'Describe the problem...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a subject or description';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),
                      const Text(
                        'Phone Number',
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
                          hint: 'Enter caller phone number',
                          prefixIcon: const Icon(LucideIcons.phone, size: 16),
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (_showQuickCustomerForm && trimmed.isEmpty) {
                            return 'Phone number is required for new customers';
                          }
                          if (trimmed.isEmpty) {
                            return null;
                          }
                          if (trimmed.length < 6) {
                            return 'Enter a valid phone number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Checkbox(
                            value: _isUrgent,
                            onChanged: (value) {
                              setState(() => _isUrgent = value ?? false);
                            },
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Mark as urgent',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate900,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
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
                          const SizedBox(width: 10),
                          FilledButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _createTicket(assignToSelf: false),
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
                            child: const Text(
                              'Push to Unclaimed',
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

  Future<Customer?> _createCustomerFromQuickForm() async {
    final name = _newCustomerNameController.text.trim();
    final phone = _phoneNumberController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      return null;
    }

    try {
      final response = await Supabase.instance.client
          .from('customers')
          .insert({
            'company_name': name,
            'contact_phone': phone,
            'contact_phone_numbers': [phone],
            'api_key': _generateTempApiKey(),
          })
          .select()
          .single();

      final newCustomer = Customer.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      ref.invalidate(customersListProvider);

      if (mounted) {
        setState(() {
          _showQuickCustomerForm = false;
          _selectedCustomerId = newCustomer.id;
          _pendingCustomerName = newCustomer.companyName;
          _newCustomerNameController.clear();
          _phoneNumberController.text = phone;
        });
      }

      return newCustomer;
    } catch (e, stack) {
      print('=== Quick Customer Creation Error ===');
      print('Error: $e');
      print('StackTrace: $stack');
      return null;
    }
  }

  String _generateTempApiKey() {
    final raw = _uuid.v4();
    return raw.replaceAll('-', '').toUpperCase();
  }

  Future<void> _sendTicketToChatDirect({
    required ProviderContainer container,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
    String? senderAvatarUrl,
  }) async {
    print('=== _sendTicketToChatDirect ===');
    print('senderId: $senderId');
    print('senderName: $senderName');
    print('senderRole: $senderRole');
    print('content: $content');
    try {
      await container.read(chatRepositoryProvider).sendMessage(
            senderId: senderId,
            senderName: senderName,
            senderRole: senderRole,
            content: content,
            senderAvatarUrl: senderAvatarUrl,
          );
      print('Chat message sent successfully');
    } catch (e) {
      print('Error sending chat message: $e');
      rethrow;
    }
  }
}

