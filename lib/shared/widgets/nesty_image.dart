import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NestyImage extends StatelessWidget {
  final String src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const NestyImage({
    super.key,
    required this.src,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final cleanSrc = src.trim();
    if (cleanSrc.isEmpty || cleanSrc.contains('[truncated]') || cleanSrc.contains('[base64_truncated]')) {
      return _buildError();
    }

    // Check if it's base64 encoded image
    if (cleanSrc.startsWith('data:image') || cleanSrc.contains('base64,')) {
      try {
        String base64Data = cleanSrc.contains('base64,') 
            ? cleanSrc.split('base64,')[1] 
            : cleanSrc;
        base64Data = base64Data.trim().replaceAll(RegExp(r'\s+'), '');
        // Fix base64 padding if needed
        while (base64Data.length % 4 != 0) {
          base64Data += '=';
        }
        final decodedBytes = base64Decode(base64Data);
        return Image.memory(
          decodedBytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildError(),
        );
      } catch (e) {
        return _buildError();
      }
    }

    // Check if it's a web URL
    final bool isNetwork = cleanSrc.startsWith('http://') || cleanSrc.startsWith('https://');
    if (isNetwork) {
      return CachedNetworkImage(
        imageUrl: cleanSrc,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
        errorWidget: (context, url, error) => errorWidget ?? _buildError(),
      );
    }

    // Otherwise, treat as local file path
    try {
      final file = File(cleanSrc);
      if (!file.existsSync()) {
        return _buildError();
      }
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildError(),
      );
    } catch (e) {
      return _buildError();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9CA3AF)),
        ),
      ),
    );
  }

  Widget _buildError() {
    return errorWidget ?? Container(
      width: width,
      height: height,
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF), size: 24),
      ),
    );
  }
}
