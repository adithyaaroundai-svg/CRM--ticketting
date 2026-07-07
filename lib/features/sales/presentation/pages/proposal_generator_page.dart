import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:typed_data';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:supabase_flutter/supabase_flutter.dart';

// Tailwind Colors Mapping
const cGray50 = Color(0xFFF9FAFB);
const cGray100 = Color(0xFFF3F4F6);
const cGray200 = Color(0xFFE5E7EB);
const cGray300 = Color(0xFFD1D5DB);
const cGray400 = Color(0xFF9CA3AF);
const cGray500 = Color(0xFF6B7280);
const cGray600 = Color(0xFF4B5563);
const cGray700 = Color(0xFF374151);
const cGray800 = Color(0xFF1F2937);
const cGray900 = Color(0xFF111827);
const cOrange50 = Color(0xFFFFF7ED);
const cOrange100 = Color(0xFFFFEDD5);
const cOrange200 = Color(0xFFFED7AA);
const cOrange600 = Color(0xFFEA580C);
const cOrange700 = Color(0xFFC2410C);
const cOrange800 = Color(0xFF9A3412);
// Add these to your Slate palette section (around line 50)
const cSlate200 = Color(0xFFE2E8F0); // Used for borders in Investment Summary
const cSlate300 = Color(0xFFCBD5E1); // Used for footer subtext

const cBlue50 = Color(0xFFEFF6FF);
const cBlue100 = Color(0xFFDBEAFE);
const cBlue200 = Color(0xFFBFDBFE);
const cBlue400 = Color(0xFF60A5FA);
const cBlue500 = Color(0xFF3B82F6);
const cBlue600 = Color(0xFF2563EB);
const cBlue700 = Color(0xFF1D4ED8);

const cGreen50 = Color(0xFFF0FDF4);
const cGreen200 = Color(0xFFBBF7D0);
const cGreen300 = Color(0xFF86EFAC);
const cGreen400 = Color(0xFF4ADE80);
const cGreen600 = Color(0xFF16A34A);
const cGreen700 = Color(0xFF15803D);

const cIndigo50 = Color(0xFFEEF2FF);
const cEmerald50 = Color(0xFFECFDF5);
const cYellow50 = Color(0xFFFEFCE8);
const cYellow300 = Color(0xFFFDE047);
const cYellow400 = Color(0xFFFACC15);

const cSlate50 = Color(0xFFF8FAFC);
const cSlate100 = Color(0xFFF1F5F9);
const cSlate600 = Color(0xFF475569);
const cSlate700 = Color(0xFF334155);
const cSlate800 = Color(0xFF1E293B);

const cPurple50 = Color(0xFFFAF5FF);
const cPurple100 = Color(0xFFF3E8FF);
const cPurple600 = Color(0xFF9333EA);
const cPurple700 = Color(0xFF7E22CE);
const cPurple800 = Color(0xFF6B21A8);

enum ProposalCardStyle { soft, solid, outline }

class ProposalProduct {
  const ProposalProduct({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.color,
    required this.style,
    this.isStrikethroughPrice = true,
  });

  final String title;
  final String subtitle;
  final double price;
  final Color color;
  final ProposalCardStyle style;
  final bool isStrikethroughPrice;

  ProposalProduct copyWith({
    String? title,
    String? subtitle,
    double? price,
    Color? color,
    ProposalCardStyle? style,
    bool? isStrikethroughPrice,
  }) {
    return ProposalProduct(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      price: price ?? this.price,
      color: color ?? this.color,
      style: style ?? this.style,
      isStrikethroughPrice: isStrikethroughPrice ?? this.isStrikethroughPrice,
    );
  }
}

class _PaymentBullet extends StatelessWidget {
  const _PaymentBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: cGray700, fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: cGray700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProposalHistoryItem {
  final String id;
  final String clientName;
  final String clientPhone;
  final String clientEmail;
  final String docNumber;
  final double totalAmount;
  final DateTime downloadedAt;

  ProposalHistoryItem({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.clientEmail,
    required this.docNumber,
    required this.totalAmount,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientName': clientName,
    'clientPhone': clientPhone,
    'clientEmail': clientEmail,
    'docNumber': docNumber,
    'totalAmount': totalAmount,
    'downloadedAt': downloadedAt.toIso8601String(),
  };

  factory ProposalHistoryItem.fromJson(Map<String, dynamic> json) => ProposalHistoryItem(
    id: json['id'],
    clientName: json['clientName'],
    clientPhone: json['clientPhone'],
    clientEmail: json['clientEmail'] ?? '',
    docNumber: json['docNumber'],
    totalAmount: json['totalAmount'].toDouble(),
    downloadedAt: DateTime.parse(json['downloadedAt']),
  );
}

class ProposalCustomPage {
  const ProposalCustomPage({
    required this.title,
    required this.description,
    required this.color,
    required this.style,
  });

  final String title;
  final String description;
  final Color color;
  final ProposalCardStyle style;

  ProposalCustomPage copyWith({
    String? title,
    String? description,
    Color? color,
    ProposalCardStyle? style,
  }) {
    return ProposalCustomPage(
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      style: style ?? this.style,
    );
  }
}

class ProposalGeneratorPage extends ConsumerStatefulWidget {
  const ProposalGeneratorPage({super.key});

  @override
  ConsumerState<ProposalGeneratorPage> createState() =>
      _ProposalGeneratorPageState();
}

class _ProposalGeneratorPageState extends ConsumerState<ProposalGeneratorPage> {
  // Strict A4 Dimensions
  static const double _pageWidth = 794;
  static const double _pageHeight = 1000;
  static const String _proposalBucket = 'voice_notes';

  bool isEditing = true;
  List<GlobalKey> _pageKeys = [];

  final clientNameCtrl = TextEditingController(text: 'ABZ BUILDERS');
  final clientPhoneCtrl = TextEditingController(text: '90374 73301');
  final clientEmailCtrl = TextEditingController(text: '');
  final docNumberCtrl = TextEditingController(text: '183/25-26');
  final licensePriceCtrl = TextEditingController(text: '22500');
  final discountPercentCtrl = TextEditingController(text: '0');
  final installationPriceCtrl = TextEditingController(text: '1000');
  final mobileAppPriceCtrl = TextEditingController(text: '4500');
  final supportDaysCtrl = TextEditingController(text: '45');
  final supportPriceCtrl = TextEditingController(text: '3000');
  String industry = 'Manufacturing';
  int _currentPreviewPage = 0;

  final List<Color> _cardPalette = const [
    cBlue600,
    cGreen600,
    cOrange600,
    cPurple600,
    cSlate700,
    cGray700,
  ];
  final List<ProposalProduct> _companyProducts = [];
  final List<ProposalCustomPage> _customPages = [];
  List<ProposalHistoryItem> _proposalHistory = [];
  bool _isLoadingHistory = false;

  final List<String> industries = [
    'Manufacturing',
    'Retail',
    'Services',
    'Trading',
    'Healthcare',
    'Education',
    'Hospitality',
    'Real Estate',
  ];

  String selectedTemplate = 'Modern Blu';

  final List<String> templates = [
    'Modern Blu',
    'Classic Green',
    'Enterprise Slate',
    'Minimalist Black',
    'Vibrant Orange',
    'Creative Purple',
  ];

  List<ProposalProduct> _defaultProducts(Map<String, double> pricing) {
    return [
      ProposalProduct(
        title: 'TallyPrime License',
        subtitle: 'Latest version + full features',
        price: pricing['lPrice'] ?? 0,
        color: cBlue600,
        style: ProposalCardStyle.soft,
      ),
      ProposalProduct(
        title: 'Professional Setup',
        subtitle: 'Installation & configuration',
        price: pricing['iPrice'] ?? 0,
        color: cGreen600,
        style: ProposalCardStyle.soft,
      ),
      ProposalProduct(
        title: '${supportDaysCtrl.text} Days Expert Support',
        subtitle: 'Phone, WhatsApp & Email',
        price: pricing['sPrice'] ?? 0,
        color: cPurple600,
        style: ProposalCardStyle.soft,
      ),
    ];
  }

  String _cardStyleLabel(ProposalCardStyle style) {
    switch (style) {
      case ProposalCardStyle.soft:
        return 'Soft';
      case ProposalCardStyle.solid:
        return 'Solid';
      case ProposalCardStyle.outline:
        return 'Outline';
    }
  }

  // --- EDITOR MODALS ---
  // (Left unchanged as they work perfectly for the UI)
  Future<void> _showProductEditor({
    ProposalProduct? existing,
    int? editIndex,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final subtitleCtrl = TextEditingController(text: existing?.subtitle ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(0) : '',
    );
    ProposalCardStyle style = existing?.style ?? ProposalCardStyle.soft;
    Color selectedColor = existing?.color ?? _cardPalette.first;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Add Product Card' : 'Edit Product Card',
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: subtitleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Subtitle',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ProposalCardStyle>(
                        value: style,
                        decoration: const InputDecoration(
                          labelText: 'Card Style',
                        ),
                        items: ProposalCardStyle.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(_cardStyleLabel(value)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null)
                            setDialogState(() => style = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _cardPalette
                              .map(
                                (color) => InkWell(
                                  onTap: () => setDialogState(
                                    () => selectedColor = color,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selectedColor == color
                                            ? cGray900
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    final subtitle = subtitleCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
                    if (title.isEmpty || subtitle.isEmpty) return;
                    final updated = ProposalProduct(
                      title: title,
                      subtitle: subtitle,
                      price: price,
                      color: selectedColor,
                      style: style,
                      isStrikethroughPrice: false,
                    );
                    setState(() {
                      if (editIndex != null)
                        _companyProducts[editIndex] = updated;
                      else
                        _companyProducts.add(updated);
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(existing == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCustomPageEditor({
    ProposalCustomPage? existing,
    int? editIndex,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descriptionCtrl = TextEditingController(
      text: existing?.description ?? '',
    );
    ProposalCardStyle style = existing?.style ?? ProposalCardStyle.soft;
    Color selectedColor = existing?.color ?? _cardPalette.first;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Add Extra Page' : 'Edit Extra Page',
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Page Title',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descriptionCtrl,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Page Content',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ProposalCardStyle>(
                        value: style,
                        decoration: const InputDecoration(
                          labelText: 'Card Style',
                        ),
                        items: ProposalCardStyle.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(_cardStyleLabel(value)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null)
                            setDialogState(() => style = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _cardPalette
                              .map(
                                (color) => InkWell(
                                  onTap: () => setDialogState(
                                    () => selectedColor = color,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selectedColor == color
                                            ? cGray900
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    final description = descriptionCtrl.text.trim();
                    if (title.isEmpty || description.isEmpty) return;
                    final updated = ProposalCustomPage(
                      title: title,
                      description: description,
                      color: selectedColor,
                      style: style,
                    );
                    setState(() {
                      if (editIndex != null)
                        _customPages[editIndex] = updated;
                      else
                        _customPages.add(updated);
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(existing == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Map<String, dynamic> _getThemeColors() {
    switch (selectedTemplate) {
      case 'Classic Green':
        return {
          'primary': cGreen700,
          'secondary': cGreen600,
          'accent': cBlue600,
          'lightBg1': cGreen50,
          'lightBg2': cEmerald50,
          'lightBorder': cGreen200,
          'headerBg': cGreen600,
        };
      case 'Enterprise Slate':
        return {
          'primary': cSlate800,
          'secondary': cSlate600,
          'accent': cBlue600,
          'lightBg1': cSlate50,
          'lightBg2': cSlate100,
          'lightBorder': cSlate600,
          'headerBg': cSlate700,
        };
      case 'Minimalist Black':
        return {
          'primary': cGray900,
          'secondary': cGray700,
          'accent': cGray600,
          'lightBg1': cGray100,
          'lightBg2': cGray200,
          'lightBorder': cGray300,
          'headerBg': cGray900,
        };
      case 'Vibrant Orange':
        return {
          'primary': cOrange700,
          'secondary': cOrange600,
          'accent': cYellow400,
          'lightBg1': cOrange50,
          'lightBg2': cOrange100,
          'lightBorder': cOrange600,
          'headerBg': cOrange700,
        };
      case 'Creative Purple':
        return {
          'primary': cPurple700,
          'secondary': cPurple600,
          'accent': cPurple800,
          'lightBg1': cPurple50,
          'lightBg2': cPurple100,
          'lightBorder': cPurple600,
          'headerBg': cPurple700,
        };
      case 'Modern Blu':
      default:
        return {
          'primary': cBlue700,
          'secondary': cBlue600,
          'accent': cGreen600,
          'lightBg1': cBlue50,
          'lightBg2': cIndigo50,
          'lightBorder': cBlue200,
          'headerBg': cBlue600,
        };
    }
  }

  Map<String, double> calculatePricing() {
    double lPrice = double.tryParse(licensePriceCtrl.text) ?? 0;
    double dPercent = double.tryParse(discountPercentCtrl.text) ?? 0;
    double iPrice = double.tryParse(installationPriceCtrl.text) ?? 0;
    double mPrice = double.tryParse(mobileAppPriceCtrl.text) ?? 0;
    double sPrice = double.tryParse(supportPriceCtrl.text) ?? 0;

    double discount = lPrice * (dPercent / 100);
    double packagePrice = lPrice - discount;
    double gst = packagePrice * 0.18;
    double total = packagePrice + gst;
    double serviceValue = lPrice + iPrice + mPrice + sPrice;
    double savings = serviceValue - packagePrice;

    return {
      'discount': discount,
      'packagePrice': packagePrice,
      'gst': gst,
      'total': total,
      'serviceValue': serviceValue,
      'savings': savings,
      'lPrice': lPrice,
      'iPrice': iPrice,
      'mPrice': mPrice,
      'sPrice': sPrice,
    };
  }

  // PROPOSAL HISTORY
  Future<void> _loadHistory() async {
    if (_isLoadingHistory) return;
    setState(() => _isLoadingHistory = true);
    try {
      final response = await Supabase.instance.client
          .from('history')
          .select()
          .order('downloaded_at', ascending: false)
          .limit(50);
      
      setState(() {
        _proposalHistory = (response as List)
            .map((e) => ProposalHistoryItem(
                  id: e['id'],
                  clientName: e['company_name'] ?? '',
                  clientPhone: e['phone_number'] ?? '',
                  clientEmail: e['email'] ?? '',
                  docNumber: e['document_number'] ?? '',
                  totalAmount: (e['total_amount'] as num?)?.toDouble() ?? 0,
                  downloadedAt: DateTime.parse(e['downloaded_at']),
                ))
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _saveToHistory() async {
    final pricing = calculatePricing();
    try {
      await Supabase.instance.client.from('history').insert({
        'company_name': clientNameCtrl.text,
        'phone_number': clientPhoneCtrl.text,
        'email': clientEmailCtrl.text,
        'document_number': docNumberCtrl.text,
        'total_amount': pricing['total'] ?? 0,
      });
      // Refresh history after saving
      await _loadHistory();
    } catch (e) {
      debugPrint('Error saving to history: $e');
    }
  }

  void _showProposalDetails(ProposalHistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.fileText, size: 24),
            const SizedBox(width: 8),
            const Expanded(child: Text('Proposal Details')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Client Name', item.clientName),
              _detailRow('Phone Number', item.clientPhone),
              _detailRow('Email', item.clientEmail),
              _detailRow('Document Number', item.docNumber),
              _detailRow('Total Amount', '₹${item.totalAmount.toStringAsFixed(2)}'),
              _detailRow('Downloaded At', DateFormat('d/M/yyyy h:mm a').format(item.downloadedAt.toLocal())),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: cGray700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(color: cGray900),
            ),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog() {
    // Refresh history when opening dialog
    _loadHistory();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(LucideIcons.history, size: 24),
                const SizedBox(width: 8),
                const Expanded(child: Text('Proposal History')),
                if (_isLoadingHistory)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    onPressed: () async {
                      await _loadHistory();
                      setDialogState(() {});
                    },
                  ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
              child: _proposalHistory.isEmpty
                  ? const Center(
                      child: Text(
                        'No proposals downloaded yet',
                        style: TextStyle(color: cGray500),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _proposalHistory.length,
                      itemBuilder: (context, index) {
                        final item = _proposalHistory[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => _showProposalDetails(item),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: cBlue600,
                                        child: Text(
                                          item.clientName.isNotEmpty
                                              ? item.clientName.substring(0, 1).toUpperCase()
                                              : '?',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.clientName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.clientPhone,
                                              style: const TextStyle(
                                                color: cGray600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '₹${item.totalAmount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: cGreen600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (item.clientEmail.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        item.clientEmail,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: cGray700,
                                        ),
                                      ),
                                    ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Doc: ${item.docNumber}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: cGray500,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('d/M/yyyy h:mm a')
                                            .format(item.downloadedAt.toLocal()),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: cGray500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  // PDF GENERATION: All pages are pre-rendered, capture is instant
  bool _isGeneratingPdf = false;
  bool _isSharingWhatsApp = false;
  Uint8List? _cachedPdfBytes;
  String? _cachedPdfKey;
  Future<Uint8List>? _inFlightPdfFuture;
  List<Uint8List>? _cachedPageImages;
  String? _cachedPageImagesKey;
  String? _cachedPdfUrl;
  String? _cachedPdfUrlKey;

  double _capturePixelRatio() {
    final deviceRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    return deviceRatio.clamp(1.0, 1.2).toDouble();
  }

  String _currentPdfFingerprint() {
    final buffer = StringBuffer()
      ..write(clientNameCtrl.text)
      ..write(clientPhoneCtrl.text)
      ..write(docNumberCtrl.text)
      ..write(licensePriceCtrl.text)
      ..write(discountPercentCtrl.text)
      ..write(installationPriceCtrl.text)
      ..write(mobileAppPriceCtrl.text)
      ..write(supportDaysCtrl.text)
      ..write(supportPriceCtrl.text)
      ..write(industry)
      ..write(selectedTemplate)
      ..write(_pageKeys.length)
      ..write(_companyProducts.length)
      ..write(_customPages.length);

    for (final product in _companyProducts) {
      buffer
        ..write('|P|')
        ..write(product.title)
        ..write(product.subtitle)
        ..write(product.price)
        ..write(product.color.toARGB32())
        ..write(product.style.index)
        ..write(product.isStrikethroughPrice ? 1 : 0);
    }

    for (final page in _customPages) {
      buffer
        ..write('|C|')
        ..write(page.title)
        ..write(page.description)
        ..write(page.color.toARGB32())
        ..write(page.style.index);
    }

    return buffer.toString();
  }

  Future<Uint8List?> _captureSinglePage(
    GlobalKey key,
    double pixelRatio,
  ) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData?.buffer.asUint8List();
  }

  Future<List<Uint8List>> _capturePageImages({
    required double pixelRatio,
    required String fingerprint,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedPageImages != null &&
        _cachedPageImagesKey == fingerprint) {
      return _cachedPageImages!;
    }

    final captureFutures = _pageKeys
        .map((key) => _captureSinglePage(key, pixelRatio))
        .toList();
    final captured = await Future.wait(captureFutures);
    final images = captured.whereType<Uint8List>().toList();
    _cachedPageImages = images;
    _cachedPageImagesKey = fingerprint;
    return images;
  }

  Future<Uint8List> _composePdfFromImages(List<Uint8List> pageImages) async {
    final pdf = pw.Document();
    for (final pageBytes in pageImages) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context ctx) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(
              color: PdfColors.grey100,
              padding: const pw.EdgeInsets.all(16),
              alignment: pw.Alignment.center,
              child: pw.FittedBox(
                fit: pw.BoxFit.contain,
                child: pw.Container(
                  width: _pageWidth,
                  height: _pageHeight,
                  color: PdfColors.white,
                  child: pw.ClipRRect(
                    horizontalRadius: 12,
                    verticalRadius: 12,
                    child: pw.Image(
                      pw.MemoryImage(pageBytes),
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return pdf.save();
  }

  Future<Uint8List> _generatePdfBytesInternal({
    bool forceRefresh = false,
  }) async {
    final fingerprint = _currentPdfFingerprint();
    if (!forceRefresh &&
        _cachedPdfBytes != null &&
        _cachedPdfKey == fingerprint) {
      return _cachedPdfBytes!;
    }

    final pixelRatio = _capturePixelRatio();
    final pageImages = await _capturePageImages(
      pixelRatio: pixelRatio,
      fingerprint: fingerprint,
      forceRefresh: forceRefresh,
    );
    if (pageImages.isEmpty) {
      throw Exception('Unable to capture proposal pages.');
    }

    final pdfBytes = await _composePdfFromImages(pageImages);
    _cachedPdfBytes = pdfBytes;
    _cachedPdfKey = fingerprint;
    if (_cachedPdfUrlKey != _cachedPdfKey) {
      _cachedPdfUrl = null;
      _cachedPdfUrlKey = null;
    }
    return pdfBytes;
  }

  Future<Uint8List> _getPdfBytes({bool forceRefresh = false}) {
    if (!forceRefresh && _inFlightPdfFuture != null) {
      return _inFlightPdfFuture!;
    }
    final future = _generatePdfBytesInternal(forceRefresh: forceRefresh);
    _inFlightPdfFuture = future;
    return future.whenComplete(() {
      if (identical(_inFlightPdfFuture, future)) {
        _inFlightPdfFuture = null;
      }
    });
  }

  // ignore: unused_element
  Future<String?> _uploadProposalPdf(Uint8List pdfBytes, String pdfKey) async {
    if (_cachedPdfUrl != null && _cachedPdfUrlKey == pdfKey) {
      return _cachedPdfUrl;
    }
    try {
      final client = Supabase.instance.client;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedClient = clientNameCtrl.text.trim().replaceAll(' ', '_');
      final fileName = 'proposal_${sanitizedClient}_$timestamp.pdf';

      await client.storage.from(_proposalBucket).uploadBinary(
            fileName,
            pdfBytes,
          );

      final publicUrl =
          client.storage.from(_proposalBucket).getPublicUrl(fileName);
      if (publicUrl.isEmpty || !publicUrl.startsWith('http')) {
        return null;
      }
      _cachedPdfUrl = publicUrl;
      _cachedPdfUrlKey = pdfKey;
      return publicUrl;
    } catch (e) {
      debugPrint('PDF upload failed: $e');
      return null;
    }
  }

  void _shareOrDownloadPdf() async {
    if (_isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);
    try {
      final pdfData = await _getPdfBytes();
      final filename = 'Proposal_${clientNameCtrl.text}.pdf';
      await Printing.sharePdf(bytes: pdfData, filename: filename);
      // Save to history after successful download
      await _saveToHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _shareOnWhatsApp() async {
    if (_isSharingWhatsApp) return;
    setState(() => _isSharingWhatsApp = true);
    try {
      final pdfData = await _getPdfBytes();
      final pricing = calculatePricing();
      final bonusDate = DateFormat(
        'd/M/yyyy',
      ).format(DateTime.now().add(const Duration(days: 5)));
      final message =
          '''Hi ${clientNameCtrl.text},

Here is your TallyPrime proposal from Sidharth IT Solutions:
- Package Price (before GST): ₹${pricing['packagePrice']!.toStringAsFixed(0)}
- GST (18%): ₹${pricing['gst']!.toStringAsFixed(0)}
- Total Investment: ₹${pricing['total']!.toStringAsFixed(0)}
- Savings vs individual services: ₹${pricing['savings']!.toStringAsFixed(0)}

Confirm by $bonusDate to reserve priority installation and extended support.

--
Sidharth IT Solutions''';

      // 1. Open WhatsApp Web IMMEDIATELY
      final uri = Uri.parse('https://web.whatsapp.com/send?text=${Uri.encodeComponent(message)}');
      final launched = await launchUrl(uri, webOnlyWindowName: '_blank');

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open WhatsApp. Please check your browser settings.')),
        );
      }
      
      // 2. Trigger PDF Download (Non-blocking)
      final filename = 'Proposal_${clientNameCtrl.text}.pdf';
      Printing.sharePdf(bytes: pdfData, filename: filename);
    } finally {
      if (mounted) setState(() => _isSharingWhatsApp = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final pricing = calculatePricing();
    final today = DateFormat('d/M/yyyy').format(DateTime.now());
    final bonusDate = DateFormat(
      'd/M/yyyy',
    ).format(DateTime.now().add(const Duration(days: 5)));
    final themeColors = _getThemeColors();

    // Fetch pages
    final pages = _buildPages(pricing, today, bonusDate, themeColors);

    // Ensure we have enough keys for all pages
    while (_pageKeys.length < pages.length) {
      _pageKeys.add(GlobalKey());
    }
    if (_pageKeys.length > pages.length) {
      _pageKeys = _pageKeys.sublist(0, pages.length);
    }

    return Scaffold(
      backgroundColor: cGray100,
      body: Column(
        children: [
          // HEADER
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: cBlue600, width: 2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 800;
                  final actionButtons = [
                    ElevatedButton.icon(
                      icon: Icon(
                        isEditing ? LucideIcons.eye : LucideIcons.edit2,
                        size: 16,
                      ),
                      label: Text(isEditing ? 'Preview Mode' : 'Edit Content'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEditing ? cGray200 : cBlue600,
                        foregroundColor: isEditing ? cGray700 : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => setState(() => isEditing = !isEditing),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(LucideIcons.history, size: 16),
                      label: const Text('History'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cGray100,
                        foregroundColor: cGray700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _showHistoryDialog,
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: _isSharingWhatsApp
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.messageCircle, size: 16),
                      label: Text(
                        _isSharingWhatsApp ? 'Opening...' : 'Share WhatsApp',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isSharingWhatsApp
                          ? null
                          : () => _shareOnWhatsApp(),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: _isGeneratingPdf
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.download, size: 16),
                      label: Text(
                        _isGeneratingPdf ? 'Generating...' : 'Download PDF',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cGreen600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isGeneratingPdf
                          ? null
                          : () => _shareOrDownloadPdf(),
                    ),
                  ];

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: cGray900),
                            onPressed: () => Navigator.of(context).canPop()
                                ? Navigator.of(context).pop()
                                : context.go('/'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Proposal Generator',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: cGray900,
                                  ),
                                ),
                                Text(
                                  'Sidharth IT Solutions',
                                  style: TextStyle(fontSize: 13, color: cGray600),
                                ),
                              ],
                            ),
                          ),
                          if (!isMobile) ...actionButtons,
                        ],
                      ),
                      if (isMobile) ...[
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: actionButtons,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1250),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 1000;
                      final clampedPage = _currentPreviewPage.clamp(
                        0,
                        pages.length - 1,
                      );

                      // All pages rendered at once for instant PDF capture
                      final allPagesHidden = ClipRect(
                        child: SizedBox(
                          width: 0,
                          height: 0,
                          child: OverflowBox(
                            alignment: Alignment.topLeft,
                            maxWidth: _pageWidth,
                            maxHeight: _pageHeight * pages.length,
                            child: Column(
                              children: List.generate(pages.length, (i) {
                                return RepaintBoundary(
                                  key: _pageKeys[i],
                                  child: SizedBox(
                                    width: _pageWidth,
                                    height: _pageHeight,
                                    child: pages[i],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      );

                      // Visible current page (no RepaintBoundary needed)
                      final currentPageView = Container(
                        width: _pageWidth,
                        height: _pageHeight,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: pages.isNotEmpty
                            ? pages[clampedPage]
                            : const Center(child: Text("No pages")),
                      );

                      final paginationControls = Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _currentPreviewPage > 0
                                  ? () => setState(() => _currentPreviewPage--)
                                  : null,
                            ),
                            Text(
                              "Page ${clampedPage + 1} of ${pages.length}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _currentPreviewPage < pages.length - 1
                                  ? () => setState(() => _currentPreviewPage++)
                                  : null,
                            ),
                          ],
                        ),
                      );

                      final editorPanel = isEditing
                          ? Container(
                              width: isNarrow ? double.infinity : 380,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cGray200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Edit Details',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildInput('Client Name', clientNameCtrl),
                                  _buildInput('Client Phone', clientPhoneCtrl),
                                  _buildInput('Client Email', clientEmailCtrl),
                                  _buildInput('Doc Number', docNumberCtrl),
                                  const Divider(height: 30),
                                  _buildInput(
                                    'License Price (₹)',
                                    licensePriceCtrl,
                                    isNumber: true,
                                  ),
                                  _buildInput(
                                    'Discount (%)',
                                    discountPercentCtrl,
                                    isNumber: true,
                                  ),
                                  _buildInput(
                                    'Installation Price (₹)',
                                    installationPriceCtrl,
                                    isNumber: true,
                                  ),
                                  _buildInput(
                                    'Support Days',
                                    supportDaysCtrl,
                                    isNumber: true,
                                  ),
                                  _buildInput(
                                    'Support Price (₹)',
                                    supportPriceCtrl,
                                    isNumber: true,
                                  ),
                                  const Divider(height: 30),
                                  _buildProductManager(themeColors),
                                  const Divider(height: 30),
                                  _buildCustomPagesManager(themeColors),
                                ],
                              ),
                            )
                          : const SizedBox.shrink();

                      if (isNarrow) {
                        return Column(
                          children: [
                            allPagesHidden,
                            if (isEditing) editorPanel,
                            if (isEditing) const SizedBox(height: 24),
                            paginationControls,
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: currentPageView,
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          allPagesHidden,
                          if (isEditing) ...[
                            editorPanel,
                            const SizedBox(width: 32),
                          ],
                          Expanded(
                            child: Column(
                              children: [
                                paginationControls,
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: currentPageView,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- REDESIGNED PAGE STRUCTURE ---
  // Split from 2 cramped pages into 3 balanced, professional pages.

  List<Widget> _buildPages(
    Map<String, double> pricing,
    String today,
    String bonusDate,
    Map<String, dynamic> theme,
  ) {
    final pages = <Widget>[
      _buildPage1_ExecutiveSummary(pricing, today, bonusDate, theme),
      _buildPage2_Deliverables(pricing, bonusDate, theme),
      _buildPage3_Closure(theme),
    ];
    pages.addAll(_customPages.map((cp) => _buildCustomContentPage(cp, theme)));
    return pages;
  }

  Widget _buildPage1_ExecutiveSummary(
    Map<String, double> pricing,
    String today,
    String bonusDate,
    Map<String, dynamic> theme,
  ) {
    return _buildPageSurface(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBlock(today, clientEmailCtrl.text, theme),
          const SizedBox(height: 40),

          // --- HERO SECTION ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme['primary'].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'OFFICIAL BUSINESS PROPOSAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: theme['primary'],
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TallyPrime Rollout for\n${clientNameCtrl.text}',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: cGray900,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'A premium implementation strategy designed for the ${industry.toLowerCase()} sector. We focus on automation, GST accuracy, and real-time business intelligence.',
                      style: const TextStyle(
                        fontSize: 15,
                        color: cGray600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              // Side Metric
              Container(
                width: 180,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme['primary'], theme['secondary']],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme['primary'].withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'TOTAL PAYABLE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${pricing['total']!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    const Text(
                      'All-inclusive Implementation',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // --- WHY THIS SOLUTION WORKS ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cSlate50,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cSlate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.lightbulb,
                      color: theme['accent'],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Why this solution works for you',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: cGray900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 40,
                  runSpacing: 20,
                  children: [
                    _buildCheckListTile(
                      'Automated GST compliance & e-Invoicing',
                      customColor: theme['accent'],
                      size: 15,
                    ),
                    _buildCheckListTile(
                      'Real-time Mobile Dashboard for CEOs',
                      customColor: theme['accent'],
                      size: 15,
                    ),
                    _buildCheckListTile(
                      'Seamless data migration from legacy systems',
                      customColor: theme['accent'],
                      size: 15,
                    ),
                    _buildCheckListTile(
                      'Priority 4-hour on-call support response',
                      customColor: theme['accent'],
                      size: 15,
                    ),
                    _buildCheckListTile(
                      'Tally features walkthrough & best practices',
                      customColor: theme['accent'],
                      size: 15,
                    ),
                    _buildCheckListTile(
                      'Basic training for staff & system handover',
                      customColor: theme['accent'],
                      size: 15,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- HORIZONTAL TRUST CARDS (Positioned below points) ---
          Row(
            children: [
              Expanded(
                child: _buildStatBadge('3,500+', 'Active Customers', theme),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildStatBadge('20 Yrs', 'Expertise', theme)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatBadge('48 Hrs', 'Go-Live Time', theme)),
            ],
          ),

          const Spacer(),

          // Footer area details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PREPARED BY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: cGray400,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Sidharth IT Solutions Sales Team',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme['secondary'],
                    ),
                  ),
                ],
              ),
              _buildPageFooter(1, 3),
            ],
          ),
        ],
      ),
    );
  }

  // Updated Stat Badge for better horizontal look
  Widget _buildStatBadge(
    String value,
    String label,
    Map<String, dynamic> theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme['lightBorder'].withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: theme['primary'],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: cGray500,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // PAGE 2: Deliverables & Investment
  Widget _buildPage2_Deliverables(
    Map<String, double> pricing,
    String bonusDate,
    Map<String, dynamic> theme,
  ) {
    final allProducts = [..._defaultProducts(pricing), ..._companyProducts];

    return _buildPageSurface(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solution Blueprint',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: theme['secondary'],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Everything included in your implementation package.',
                      style: TextStyle(fontSize: 14, color: cGray600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cYellow50,
                  border: Border.all(color: cYellow300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Valid until: $bonusDate',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cOrange700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Products Grid using Wrap to prevent overflow
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: allProducts
                .map(
                  (p) => SizedBox(
                    width: (_pageWidth - 56 - 16) / 2, // 2 columns exactly
                    child: _buildPackageItem(p),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 16),
          _buildFreeMobileCard(pricing, theme),

          const SizedBox(height: 16),
          Expanded(child: _buildInvestmentBreakdown(pricing, theme)),

          const SizedBox(height: 16),
          _buildPageFooter(2, 3),
        ],
      ),
    );
  }

  // PAGE 3: Closure & Trust
  Widget _buildPage3_Closure(Map<String, dynamic> theme) {
    return _buildPageSurface(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Implementation & Next Steps',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: theme['secondary'],
            ),
          ),
          const SizedBox(height: 24),

          _buildTrustSection(theme),

          const Spacer(),
          _buildContactFooter(theme),
          const SizedBox(height: 20),
          _buildPageFooter(3, 3),
        ],
      ),
    );
  }

  Widget _buildCustomContentPage(
    ProposalCustomPage customPage,
    Map<String, dynamic> theme,
  ) {
    return _buildPageSurface(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customPage.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: cGray900,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: customPage.color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: customPage.color.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                customPage.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: cGray800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE WIDGETS ---

  Widget _buildPageSurface({
    required Map<String, dynamic> theme,
    required Widget child,
  }) {
    return Container(
      width: _pageWidth,
      height: _pageHeight,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: const BoxDecoration(color: Colors.white),
      child: child,
    );
  }

  Widget _buildPageFooter(int current, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Doc No: ${docNumberCtrl.text}',
          style: const TextStyle(fontSize: 10, color: cGray400),
        ),
        Text(
          'Page $current of $total',
          style: const TextStyle(fontSize: 10, color: cGray400),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cGray200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        'company_logo.png', // Served from web/ folder root (like favicon.png)
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/company_logo.png', // Fallback to asset manifest
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: cGray50,
            alignment: Alignment.center,
            child: const Icon(LucideIcons.image, color: cGray300, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBlock(String today, String email, Map<String, dynamic> theme) {
    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme['lightBorder'], width: 2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildLogo(),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SIDHARTH IT SOLUTIONS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: cGray900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Kerala\'s Premier Tally Partner',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme['secondary'],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'PROPOSAL DATE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: cGray500,
                  letterSpacing: 1,
                ),
              ),
              Text(
                today,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cGray900,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cGray600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildMetricCard({
    required String label,
    required String value,
    required String caption,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: accentColor.withValues(alpha: 0.05),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cGray600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: accentColor == cGray500 ? cGray900 : accentColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(caption, style: const TextStyle(fontSize: 12, color: cGray500)),
        ],
      ),
    );
  }

  Widget _buildCheckListTile(
    String text, {
    Color? customColor,
    double size = 14,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle,
            color: customColor ?? cGreen600,
            size: size + 4,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: cGray800,
              fontSize: size,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconForProduct(String title, String subtitle) {
    final text = '${title.toLowerCase()} ${subtitle.toLowerCase()}';
    if (text.contains('license') || text.contains('software'))
      return LucideIcons.shieldCheck;
    if (text.contains('setup') || text.contains('install'))
      return LucideIcons.settings;
    if (text.contains('support') || text.contains('expert'))
      return LucideIcons.headphones;
    if (text.contains('mobile') || text.contains('app'))
      return LucideIcons.smartphone;
    if (text.contains('train') || text.contains('learn'))
      return LucideIcons.graduationCap;
    if (text.contains('data') || text.contains('migrat'))
      return LucideIcons.database;
    if (text.contains('cloud') || text.contains('server'))
      return LucideIcons.cloud;
    if (text.contains('custom') || text.contains('develop'))
      return LucideIcons.code;
    if (text.contains('device') ||
        text.contains('monitor') ||
        text.contains('desktop') ||
        text.contains('system'))
      return LucideIcons.monitor;
    if (text.contains('plan') || text.contains('subs') || text.contains('days'))
      return LucideIcons.calendarCheck;
    return LucideIcons.checkCircle2;
  }

  Widget _buildPackageItem(ProposalProduct product) {
    Color bg = product.style == ProposalCardStyle.solid
        ? product.color
        : (product.style == ProposalCardStyle.soft
              ? product.color.withValues(alpha: 0.05)
              : Colors.white);
    Color border = product.style == ProposalCardStyle.outline
        ? product.color
        : Colors.transparent;
    Color textCol = product.style == ProposalCardStyle.solid
        ? Colors.white
        : cGray900;
    Color subTextCol = product.style == ProposalCardStyle.solid
        ? Colors.white70
        : cGray600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: product.style == ProposalCardStyle.solid
                  ? Colors.white24
                  : product.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconForProduct(product.title, product.subtitle),
              color: product.style == ProposalCardStyle.solid
                  ? Colors.white
                  : product.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.subtitle,
                  style: TextStyle(fontSize: 12, color: subTextCol),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeMobileCard(
    Map<String, double> pricing,
    Map<String, dynamic> theme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cOrange200),
        gradient: const LinearGradient(colors: [cOrange50, Colors.white]),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cOrange100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.smartphone,
              color: cOrange600,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Includes Free Mobile Dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cGray900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Access live stock, receivables, and reports from your phone.',
                  style: TextStyle(fontSize: 14, color: cGray600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cOrange600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'FREE RENEWAL BENEFIT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentBreakdown(
    Map<String, double> pricing,
    Map<String, dynamic> theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cSlate50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cSlate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Final Investment Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cSlate800,
            ),
          ),
          const SizedBox(height: 16),
          _buildRow(
            'Package Base Price',
            "₹${pricing['lPrice']!.toStringAsFixed(0)}",
          ),
          if (pricing['discount']! > 0)
            _buildRow(
              'Special Package Discount',
              "- ₹${pricing['discount']!.toStringAsFixed(0)}",
              isGreen: true,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          _buildRow(
            'Taxable Value',
            "₹${pricing['packagePrice']!.toStringAsFixed(0)}",
            isBold: true,
          ),
          _buildRow('GST (18%)', "₹${pricing['gst']!.toStringAsFixed(0)}"),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme['secondary'],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount Payable',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "₹${pricing['total']!.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isStrikeout = false,
    bool isGreen = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: isGreen ? cGreen700 : cGray700,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: isGreen ? cGreen700 : (isStrikeout ? cGray400 : cGray900),
              fontWeight: isBold || isGreen ? FontWeight.bold : FontWeight.w600,
              decoration: isStrikeout
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildImplementationTimeline(Map<String, dynamic> theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deployment Timeline',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cGray900,
          ),
        ),
        const SizedBox(height: 16),
        _buildTimelineStep(
          'Day 0',
          'Remote onboarding & requirements sign-off',
          theme,
        ),
        _buildTimelineStep(
          'Day 1-2',
          'License provisioning & TallyPrime installation',
          theme,
        ),
        _buildTimelineStep(
          'Day 3-5',
          'Process walkthrough & GST configuration',
          theme,
        ),
        _buildTimelineStep(
          'Day 6',
          'Mobile dashboard training & handover',
          theme,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineStep(
    String day,
    String task,
    Map<String, dynamic> theme, {
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: theme['secondary'],
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: theme['lightBorder']),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: theme['secondary'],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task,
                  style: const TextStyle(
                    fontSize: 14,
                    color: cGray700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildPaymentInfo(Map<String, dynamic> theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme['lightBg1'],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme['lightBorder']),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Payment Terms',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cGray900,
            ),
          ),
          SizedBox(height: 16),
          _PaymentBullet(
            text:
                '50% advance required to initiate licensing and book your installation slot.',
          ),
          _PaymentBullet(
            text:
                'Balance 50% payable upon successful installation and completion of basic training.',
          ),
          _PaymentBullet(
            text:
                'This proposal pricing is valid for 14 days from the date of issue.',
          ),
          _PaymentBullet(
            text: 'We accept payments via NEFT, RTGS, UPI, or Cheque.',
          ),
        ],
      ),
    );
  }

  Widget _buildTrustSection(Map<String, dynamic> theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Why Partner With Us?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cGray900,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTrustBadge(
                LucideIcons.award,
                '20+ Years',
                'Tally Partner since 2002',
                theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTrustBadge(
                LucideIcons.users,
                'Largest Team',
                'Dedicated support desk',
                theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTrustBadge(
                LucideIcons.zap,
                'Fast Response',
                'Phone & WhatsApp support',
                theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustBadge(
    IconData icon,
    String title,
    String subtitle,
    Map<String, dynamic> theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: cGray200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme['secondary'], size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: cGray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: cGray600)),
        ],
      ),
    );
  }

  Widget _buildContactFooter(Map<String, dynamic> theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cSlate800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Ready to transform your business?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Reach out to us to confirm your order and schedule deployment.',
                  style: TextStyle(color: cSlate300, fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                '+91 93885 13999',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'sales@aroundtally.com',
                style: TextStyle(color: cSlate300, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Input builders
  Widget _buildInput(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cGray700,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  // (Remaining editor widgets like _buildProductManager and _buildCustomPagesManager go here, unchanged from your implementation)
  Widget _buildProductManager(Map<String, dynamic> themeColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Custom Products',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeColors['secondary'],
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _showProductEditor,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._companyProducts.asMap().entries.map((entry) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              entry.value.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '₹${entry.value.price.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showProductEditor(
                    existing: entry.value,
                    editIndex: entry.key,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () =>
                      setState(() => _companyProducts.removeAt(entry.key)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCustomPagesManager(Map<String, dynamic> themeColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Extra Pages',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeColors['secondary'],
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _showCustomPageEditor,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._customPages.asMap().entries.map((entry) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              entry.value.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showCustomPageEditor(
                    existing: entry.value,
                    editIndex: entry.key,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () =>
                      setState(() => _customPages.removeAt(entry.key)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
