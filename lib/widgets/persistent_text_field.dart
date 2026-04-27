import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PersistentTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final int minLines;
  final bool obscureText;
  final bool enabled;
  final TextStyle? style;
  final InputDecoration? decoration;

  const PersistentTextField({
    super.key,
    required this.controller,
    this.hintText = '',
    this.maxLines = 1,
    this.minLines = 1,
    this.obscureText = false,
    this.enabled = true,
    this.style,
    this.decoration,
  });

  @override
  State<PersistentTextField> createState() => _PersistentTextFieldState();
}

class _PersistentTextFieldState extends State<PersistentTextField>
    with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _focusNode.hasFocus) {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode, // Handled internally!
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      style: widget.style,
      // Handle the keyboard showing/hiding rules internally!
      onTapOutside: (event) => FocusScope.of(context).unfocus(),
      onTap: () {
        if (_focusNode.hasFocus) {
          SystemChannels.textInput.invokeMethod('TextInput.show');
        }
      },
      decoration:
          widget.decoration ??
          InputDecoration(
            hintText: widget.hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
    );
  }
}
