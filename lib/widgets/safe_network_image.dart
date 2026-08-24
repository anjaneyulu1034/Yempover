import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Loads remote images via HTTP with retries. Avoids noisy image-service
/// exceptions when S3 or the network drops the connection mid-request.
class SafeNetworkImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int maxRetries;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.maxRetries = 2,
  });

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  static const _requestTimeout = Duration(seconds: 20);

  Uint8List? _bytes;
  bool _failed = false;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _bytes = null;
      _failed = false;
      _attempt = 0;
      _load();
    }
  }

  Future<void> _load() async {
    final trimmed = widget.url.trim();
    if (trimmed.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    try {
      final response = await http
          .get(Uri.parse(trimmed))
          .timeout(_requestTimeout);
      if (!mounted) return;

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        setState(() {
          _bytes = response.bodyBytes;
          _failed = false;
        });
        return;
      }
    } catch (_) {
      // Retry below.
    }

    if (!mounted) return;
    if (_attempt < widget.maxRetries) {
      _attempt++;
      final delayMs = 400 * _attempt;
      await Future<void>.delayed(Duration(milliseconds: delayMs));
      if (mounted) await _load();
      return;
    }

    setState(() {
      _bytes = null;
      _failed = true;
    });
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _defaultError() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported,
        size: (widget.height != null && widget.height! < 120) ? 32 : 64,
        color: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return widget.errorWidget ?? _defaultError();
    }
    if (_bytes == null) {
      return widget.placeholder ?? _defaultPlaceholder();
    }
    return Image.memory(
      _bytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      gaplessPlayback: true,
    );
  }
}
