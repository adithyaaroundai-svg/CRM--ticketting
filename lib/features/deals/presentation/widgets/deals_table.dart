import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:collection/collection.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/design_system/widgets/glass_card.dart';
import '../providers/deals_provider.dart';

class DealsTable extends ConsumerStatefulWidget {
  const DealsTable({super.key});

  @override
  ConsumerState<DealsTable> createState() => _DealsTableState();
}

class _DealsTableState extends ConsumerState<DealsTable> {
  String? _addingDateKey;
  String? _selectedDate;

  final _nameController = TextEditingController();
  final _remarkController = TextEditingController();
  final _phoneController = TextEditingController();
  final _scrollController = ScrollController();

  String? _editingDealId;
  String? _editingField;
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

  void _cancelAdding() => setState(() { _addingDateKey = null; _selectedDate = null; });

  void _submitDeal(String dateKey) {
    final name = _nameController.text.trim();
    if (name.isEmpty) { _cancelAdding(); return; }
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

  void _cancelEditing() => setState(() { _editingDealId = null; _editingField = null; _editSelectedDate = null; });

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
    final gc = GlassColors.of(context, ref);
    final dealsAsync = ref.watch(dealsProvider);

    return dealsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (deals) {
        final groupedDeals = groupBy(deals, (Deal d) => d.date);
        final sortedDates = groupedDeals.keys.toList()..sort((a, b) => b.compareTo(a));

        if (sortedDates.isEmpty) {
          final today = DateTime.now();
          final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          sortedDates.add(todayStr);
          groupedDeals[todayStr] = [];
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: gc.isGlass
                ? ImageFilter.blur(sigmaX: 16, sigmaY: 16)
                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              decoration: BoxDecoration(
                color: gc.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: gc.border),
                gradient: gc.isGlass
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.04),
                        ],
                      )
                    : null,
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
                              decoration: BoxDecoration(
                                color: gc.isGlass
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : gc.surface,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(flex: 3, child: _headerText('Deals', gc)),
                                  Expanded(flex: 2, child: _headerText('Date', gc)),
                                  Expanded(flex: 3, child: _headerText('Remark', gc)),
                                  Expanded(flex: 2, child: _headerText('Phone Number', gc)),
                                ],
                              ),
                            ),

                            for (final date in sortedDates) ...[
                              // Group Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: gc.surfaceHeader,
                                  border: Border(
                                    top: BorderSide(color: gc.border),
                                    bottom: BorderSide(color: gc.border),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.calendarDays, size: 16, color: gc.onSurfaceMuted),
                                    const SizedBox(width: 8),
                                    Text(date, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: gc.onSurface)),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${groupedDeals[date]?.length ?? 0} item${groupedDeals[date]?.length == 1 ? '' : 's'}',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: gc.onSurfaceFaint),
                                    ),
                                  ],
                                ),
                              ),

                              // Deal rows
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: groupedDeals[date]!.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: gc.border),
                                itemBuilder: (context, index) {
                                  final deal = groupedDeals[date]![index];
                                  final isEditingName = _editingDealId == deal.id && _editingField == 'name';
                                  final isEditingRemark = _editingDealId == deal.id && _editingField == 'remark';
                                  final isEditingPhone = _editingDealId == deal.id && _editingField == 'phone';

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    color: gc.isGlass ? Colors.transparent : gc.surface,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 16),
                                            child: isEditingName
                                                ? _editRow(controller: _editNameController, gc: gc, onSubmit: () => _submitEdit(deal), onCancel: _cancelEditing)
                                                : _cellTap(onTap: () => _startEditingDeal(deal, 'name'), text: deal.name, bold: true, gc: gc),
                                          ),
                                        ),
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
                                                  final nd = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                                  if (nd != deal.date) {
                                                    ref.read(dealControllerProvider.notifier).updateDeal(
                                                      id: deal.id, name: deal.name, date: nd, remark: deal.remark, phoneNumber: deal.phoneNumber,
                                                    );
                                                  }
                                                }
                                              },
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(child: Text(deal.date, style: TextStyle(fontSize: 14, color: gc.onSurfaceMuted))),
                                                  const SizedBox(width: 6),
                                                  Icon(LucideIcons.pencil, size: 12, color: gc.onSurfaceFaint),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 16),
                                            child: isEditingRemark
                                                ? _editRow(controller: _editRemarkController, gc: gc, onSubmit: () => _submitEdit(deal), onCancel: _cancelEditing)
                                                : _cellTap(onTap: () => _startEditingDeal(deal, 'remark'), text: deal.remark, bold: false, gc: gc),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: isEditingPhone
                                              ? _editRow(controller: _editPhoneController, gc: gc, onSubmit: () => _submitEdit(deal), onCancel: _cancelEditing)
                                              : _cellTap(onTap: () => _startEditingDeal(deal, 'phone'), text: deal.phoneNumber, bold: false, gc: gc),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              // Add item row
                              if (_addingDateKey == date)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: gc.isGlass ? Colors.transparent : gc.surface,
                                    border: Border(top: BorderSide(color: gc.border)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: TextField(
                                          controller: _nameController,
                                          autofocus: true,
                                          style: TextStyle(fontSize: 14, color: gc.onSurface),
                                          decoration: InputDecoration(
                                            hintText: 'Deal name',
                                            hintStyle: TextStyle(color: gc.onSurfaceFaint),
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
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.tryParse(_selectedDate ?? date) ?? DateTime.now(),
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
                                              Text(_selectedDate ?? date, style: TextStyle(fontSize: 14, color: gc.onSurface)),
                                              const SizedBox(width: 4),
                                              Icon(LucideIcons.calendarDays, size: 14, color: gc.onSurfaceFaint),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: TextField(
                                          controller: _remarkController,
                                          style: TextStyle(fontSize: 14, color: gc.onSurface),
                                          decoration: InputDecoration(
                                            hintText: 'Remark',
                                            hintStyle: TextStyle(color: gc.onSurfaceFaint),
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
                                                style: TextStyle(fontSize: 14, color: gc.onSurface),
                                                decoration: InputDecoration(
                                                  hintText: 'Phone',
                                                  hintStyle: TextStyle(color: gc.onSurfaceFaint),
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
                                              icon: Icon(LucideIcons.x, color: gc.onSurfaceFaint, size: 18),
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
                                    decoration: BoxDecoration(
                                      color: gc.isGlass ? Colors.transparent : gc.surface,
                                      border: Border(
                                        top: BorderSide(color: gc.border),
                                        bottom: BorderSide(color: gc.border),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.plus, size: 16, color: gc.primary),
                                        const SizedBox(width: 8),
                                        Text('Add item', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: gc.primary)),
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
            ),
          ),
        );
      },
    );
  }

  Widget _headerText(String label, GlassColors gc) {
    return Text(
      label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: gc.onSurfaceFaint, letterSpacing: 0.5),
    );
  }

  Widget _cellTap({required VoidCallback onTap, required String text, required bool bold, required GlassColors gc}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
                color: bold ? gc.onSurface : gc.onSurfaceMuted,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 6),
          Icon(LucideIcons.pencil, size: 12, color: gc.onSurfaceFaint),
        ],
      ),
    );
  }

  Widget _editRow({
    required TextEditingController controller,
    required GlassColors gc,
    required VoidCallback onSubmit,
    required VoidCallback onCancel,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(fontSize: 14, color: gc.onSurface),
            decoration: InputDecoration(
              border: UnderlineInputBorder(borderSide: BorderSide(color: gc.primary)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
            onSubmitted: (_) => onSubmit(),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(onTap: onSubmit, child: const Icon(LucideIcons.check, color: AppColors.success, size: 16)),
        const SizedBox(width: 8),
        InkWell(onTap: onCancel, child: Icon(LucideIcons.x, color: gc.onSurfaceFaint, size: 16)),
      ],
    );
  }
}
