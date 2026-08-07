import 'package:flutter/material.dart';
import 'nesty_image.dart';

class FullScreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageGallery({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenImageGallery> createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<FullScreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;
  late List<TransformationController> _transformationControllers;
  TapDownDetails? _doubleTapDetails;
  bool _isZooming = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformationControllers = List.generate(
      widget.images.length,
      (_) => TransformationController(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _transformationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onInteractionUpdate(ScaleUpdateDetails details, int index) {
    final double scale = _transformationControllers[index].value.getMaxScaleOnAxis();
    if (scale > 1.01 && !_isZooming) {
      setState(() {
        _isZooming = true;
      });
    } else if (scale <= 1.01 && _isZooming) {
      setState(() {
        _isZooming = false;
      });
    }
  }

  void _onInteractionEnd(ScaleEndDetails details, int index) {
    final double scale = _transformationControllers[index].value.getMaxScaleOnAxis();
    if (scale <= 1.01) {
      setState(() {
        _isZooming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Image View
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            physics: _isZooming 
                ? const NeverScrollableScrollPhysics() 
                : const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final controller = _transformationControllers[index];
              return GestureDetector(
                onDoubleTapDown: (details) => _doubleTapDetails = details,
                onDoubleTap: () {
                  final double scale = controller.value.getMaxScaleOnAxis();
                  if (scale > 1.01) {
                    controller.value = Matrix4.identity();
                    setState(() {
                      _isZooming = false;
                    });
                  } else {
                    final position = _doubleTapDetails!.localPosition;
                    controller.value = Matrix4.identity()
                      ..translate(-position.dx * 1.5, -position.dy * 1.5, 0.0)
                      ..scale(2.5, 2.5, 1.0);
                    setState(() {
                      _isZooming = true;
                    });
                  }
                },
                child: InteractiveViewer(
                  transformationController: controller,
                  minScale: 1.0,
                  maxScale: 5.0,
                  onInteractionUpdate: (details) => _onInteractionUpdate(details, index),
                  onInteractionEnd: (details) => _onInteractionEnd(details, index),
                  child: Center(
                    child: NestyImage(
                      src: widget.images[index],
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              );
            },
          ),

          // Close Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.4),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ),
          ),

          // Page Indicator
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
}
