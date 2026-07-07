import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

/// Enterprise-style text field with refined styling
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final int? maxLines;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final bool readOnly;
  final String? helperText;
  final bool showBorder;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onClear,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.focusNode,
    this.onTap,
    this.readOnly = false,
    this.helperText,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      maxLines: maxLines,
      focusNode: focusNode,
      onTap: onTap,
      readOnly: readOnly,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.slate900,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        helperText: helperText,
        hintStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.slate400,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.slate600,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.slate500,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: AppColors.slate400)
            : null,
        suffixIcon:
            suffix ??
            (onClear != null &&
                    controller != null &&
                    controller!.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 16),
                    onPressed: onClear,
                    color: AppColors.slate400,
                  )
                : null),
        filled: true,
        fillColor: enabled ? Colors.white : AppColors.slate50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: showBorder
              ? const BorderSide(color: AppColors.border, width: 1.5)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: showBorder
              ? const BorderSide(color: AppColors.border, width: 1.5)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
      ),
    );
  }
}

/// Enterprise search bar with refined styling and animations
class AppSearchBar extends StatefulWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final Duration debounceDuration;
  final TextEditingController? controller;
  final bool autofocus;
  final bool elevated;

  const AppSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.controller,
    this.autofocus = false,
    this.elevated = true,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late TextEditingController _controller;
  bool _showClear = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _showClear = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _showClear = _controller.text.isNotEmpty;
    });
  }

  void _onClear() {
    _controller.clear();
    widget.onChanged?.call('');
    setState(() {
      _showClear = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isFocused ? AppColors.primary : AppColors.border,
          width: _isFocused ? 2 : 1.5,
        ),
        boxShadow: widget.elevated
            ? [
                BoxShadow(
                  color: _isFocused
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.shadowLight,
                  blurRadius: _isFocused ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: TextField(
          controller: _controller,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.slate900,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              color: AppColors.slate400,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              LucideIcons.search,
              color: _isFocused ? AppColors.primary : AppColors.slate400,
              size: 20,
            ),
            suffixIcon: _showClear
                ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 16),
                    onPressed: _onClear,
                    color: AppColors.slate400,
                    splashRadius: 18,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}
