import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:collection/collection.dart';
import '../../../../core/design_system/design_system.dart';
import '../providers/deals_provider.dart';

class DealsTable extends ConsumerStatefulWidget {
  const DealsTable({super.key});

  @override
  ConsumerState<DealsTable> createState() => _DealsTableState();
}

class _DealsTableState extends ConsumerState<DealsTable> {
  String? _addingDateKey;
  String? _selectedDate;
  
  // Controllers for the inline add form
  final _nameController = TextEditingController();
  final _remarkController = TextEditingController();
  final _phoneController = TextEditingController();
  final _scrollController = ScrollController();
  
  // State and Controllers for the inline edit form
  String? _editingDealId;
  String? _editingField; // 'name', 'remark', 'phone'
  String? _editSelectedDate;
  final _editNameController = TextEditingController();
  final _editRemarkController = TextEditingController();
  final _editPhoneController = TextEditingController();
  
  @override
  void dispose() {
    _nameController.dispose();
    _remarkController.dispose();
    _phoneController.dispose();
    _editNameController.dispose();
    _editRemarkController.dispose();
    _editPhoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAddingDeal(String dateKey) {
    setState(() {
      _addingDateKey = dateKey;
      _selectedDate = dateKey;
      _nameController.clear();
      _remarkController.clear();
      _phoneController.clear();
    });
  }

  void _cancelAdding() {
    setState(() {
      _addingDateKey = null;
      _selectedDate = null;
    });
  }

  void _submitDeal(String dateKey) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _cancelAdding();
      return;
    }

    ref.read(dealControllerProvider.notifier).addDeal(
      name: name,
      date: _selectedDate ?? dateKey,
      remark: _remarkController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );
    _cancelAdding();
  }

  void _startEditingDeal(Deal deal, String field) {
    setState(() {
      _editingDealId = deal.id;
      _editingField = field;
      _editSelectedDate = deal.date;
      _editNameController.text = deal.name;
      _editRemarkController.text = deal.remark;
      _editPhoneController.text = deal.phoneNumber;
      _cancelAdding();
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingDealId = null;
      _editingField = null;
      _editSelectedDate = null;
    });
  }

  void _submitEdit(Deal deal) {
    final name = _editNameController.text.trim();
    
    ref.read(dealControllerProvider.notifier).updateDeal(
      id: deal.id,
      name: name.isEmpty ? deal.name : name,
      date: _editSelectedDate ?? deal.date,
      remark: _editRemarkController.text.trim(),
      phoneNumber: _editPhoneController.text.trim(),
    );
    _cancelEditing();
  }

  @override
  Widget build(BuildContext context) {
    final dealsAsync = ref.watch(dealsProvider);
    
    return dealsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading deals: $error')),
      data: (deals) {
        // Group by date (descending)
        final groupedDeals = groupBy(deals, (Deal d) => d.date);
        final sortedDates = groupedDeals.keys.toList()..sort((a, b) => b.compareTo(a));

        // Ensure we always have at least today's date to add items into if empty
        if (sortedDates.isEmpty) {
          final today = DateTime.now();
          final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          sortedDates.add(todayStr);
          groupedDeals[todayStr] = [];
        }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: constraints.maxWidth > 800 ? constraints.maxWidth : 800,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Deals',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Remark',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Phone Number',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Render Groups
          for (final date in sortedDates) ...[
            // Group Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.slate50,
                border: Border(
                  top: BorderSide(color: AppColors.slate200),
                  bottom: BorderSide(color: AppColors.slate200)
                ),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendarDays, size: 16, color: AppColors.slate500),
                  const SizedBox(width: 8),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${groupedDeals[date]?.length ?? 0} item${groupedDeals[date]?.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate400,
                    ),
                  ),
                ],
              ),
            ),
            
            // Items
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groupedDeals[date]!.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.slate200),
              itemBuilder: (context, index) {
                final deal = groupedDeals[date]![index];
                
                final isEditingName = _editingDealId == deal.id && _editingField == 'name';
                final isEditingRemark = _editingDealId == deal.id && _editingField == 'remark';
                final isEditingPhone = _editingDealId == deal.id && _editingField == 'phone';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Name Cell
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: isEditingName
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _editNameController,
                                        autofocus: true,
                                        style: const TextStyle(fontSize: 14),
                                        decoration: const InputDecoration(border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)), isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4)),
                                        onSubmitted: (_) => _submitEdit(deal),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(onTap: () => _submitEdit(deal), child: const Icon(LucideIcons.check, color: AppColors.success, size: 16)),
                                    const SizedBox(width: 8),
                                    InkWell(onTap: _cancelEditing, child: const Icon(LucideIcons.x, color: AppColors.slate400, size: 16)),
                                  ],
                                )
                              : InkWell(
                                  onTap: () => _startEditingDeal(deal, 'name'),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(child: Text(deal.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.slate900), overflow: TextOverflow.ellipsis)),
                                      const SizedBox(width: 6),
                                      const Icon(LucideIcons.pencil, size: 12, color: AppColors.slate300),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      
                      // Date Cell
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.tryParse(deal.date) ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                final newDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                if (newDate != deal.date) {
                                  ref.read(dealControllerProvider.notifier).updateDeal(
                                    id: deal.id,
                                    name: deal.name,
                                    date: newDate,
                                    remark: deal.remark,
                                    phoneNumber: deal.phoneNumber,
                                  );
                                }
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(child: Text(deal.date, style: const TextStyle(fontSize: 14, color: AppColors.slate600))),
                                const SizedBox(width: 6),
                                const Icon(LucideIcons.pencil, size: 12, color: AppColors.slate300),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Remark Cell
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: isEditingRemark
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _editRemarkController,
                                        autofocus: true,
                                        style: const TextStyle(fontSize: 14),
                                        decoration: const InputDecoration(border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)), isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4)),
                                        onSubmitted: (_) => _submitEdit(deal),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(onTap: () => _submitEdit(deal), child: const Icon(LucideIcons.check, color: AppColors.success, size: 16)),
                                    const SizedBox(width: 8),
                                    InkWell(onTap: _cancelEditing, child: const Icon(LucideIcons.x, color: AppColors.slate400, size: 16)),
                                  ],
                                )
                              : InkWell(
                                  onTap: () => _startEditingDeal(deal, 'remark'),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(child: Text(deal.remark, style: const TextStyle(fontSize: 14, color: AppColors.slate600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      const SizedBox(width: 6),
                                      const Icon(LucideIcons.pencil, size: 12, color: AppColors.slate300),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      
                      // Phone Number Cell
                      Expanded(
                        flex: 2,
                        child: isEditingPhone
                            ? Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _editPhoneController,
                                      autofocus: true,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: const InputDecoration(border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)), isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4)),
                                      onSubmitted: (_) => _submitEdit(deal),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(onTap: () => _submitEdit(deal), child: const Icon(LucideIcons.check, color: AppColors.success, size: 16)),
                                  const SizedBox(width: 8),
                                  InkWell(onTap: _cancelEditing, child: const Icon(LucideIcons.x, color: AppColors.slate400, size: 16)),
                                ],
                              )
                            : InkWell(
                                onTap: () => _startEditingDeal(deal, 'phone'),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(child: Text(deal.phoneNumber, style: const TextStyle(fontSize: 14, color: AppColors.slate600), overflow: TextOverflow.ellipsis)),
                                    const SizedBox(width: 6),
                                    const Icon(LucideIcons.pencil, size: 12, color: AppColors.slate300),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // Add Item Inline Form or Button
            if (_addingDateKey == date)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.slate200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _nameController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Deal name',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _submitDeal(date),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () async {
                          final initialDate = DateTime.tryParse(_selectedDate ?? date) ?? DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                        child: Row(
                          children: [
                            Text(
                              _selectedDate ?? date,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.slate900,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.calendarDays, size: 14, color: AppColors.slate400),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _remarkController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Remark',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _submitDeal(date),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Phone Number',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onSubmitted: (_) => _submitDeal(date),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.check, color: AppColors.success, size: 18),
                            onPressed: () => _submitDeal(date),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(LucideIcons.x, color: AppColors.slate400, size: 18),
                            onPressed: _cancelAdding,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              InkWell(
                onTap: () => _startAddingDeal(date),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.slate200),
                      bottom: BorderSide(color: AppColors.slate200),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.plus, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Add item',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                  ],
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
      },
    );
  }
}
