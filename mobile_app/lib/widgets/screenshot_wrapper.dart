import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/screenshot_service.dart';

class ScreenshotWrapper extends StatefulWidget {
  final Widget child;
  final String screenName;
  final bool enabled;
  final GlobalKey? boundaryKey;

  const ScreenshotWrapper({
    super.key,
    required this.child,
    required this.screenName,
    this.enabled = true,
    this.boundaryKey,
  });

  @override
  State<ScreenshotWrapper> createState() => _ScreenshotWrapperState();
}

class _ScreenshotWrapperState extends State<ScreenshotWrapper> with SingleTickerProviderStateMixin {
  final GlobalKey _defaultBoundaryKey = GlobalKey();
  bool _isCapturing = false;
  late AnimationController _pulseController;

  GlobalKey get _activeKey => widget.boundaryKey ?? _defaultBoundaryKey;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _takeScreenshot() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    // Provide a small delay to ensure any active keyboard or transition settles down
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final bytes = await ScreenshotService.capture(_activeKey);
      
      if (bytes != null) {
        final savedFile = await ScreenshotService.saveScreenshot(bytes, widget.screenName);
        
        if (mounted && savedFile != null) {
          _showScreenshotSuccessModal(bytes, savedFile.path);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save screenshot file.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to capture screen area.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Screenshot capture flow error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _showScreenshotSuccessModal(Uint8List bytes, String filePath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => _ScreenshotPreviewModal(
        bytes: bytes,
        filePath: filePath,
        screenName: widget.screenName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    Widget mainChild = widget.child;

    // Only wrap the child with a RepaintBoundary if a custom boundaryKey wasn't supplied
    if (widget.boundaryKey == null) {
      mainChild = RepaintBoundary(
        key: _defaultBoundaryKey,
        child: widget.child,
      );
    }

    return Stack(
      children: [
        mainChild,

        
        // Floating action button overlay
        Positioned(
          bottom: 24,
          right: 24,
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withValues(
                          alpha: 0.15 + (_pulseController.value * 0.15),
                        ),
                        blurRadius: 10 + (_pulseController.value * 12),
                        spreadRadius: 2 + (_pulseController.value * 4),
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: FloatingActionButton(
                onPressed: _takeScreenshot,
                backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  LucideIcons.camera,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ),

        // Beautiful glassmorphism loader overlay
        if (_isCapturing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            color: Theme.of(context).primaryColor,
                            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          ),
                        ),
                        Icon(
                          LucideIcons.sparkles,
                          color: Theme.of(context).primaryColor,
                          size: 32,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Capturing Full Page...',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rendering full scroll layout in ultra-HD',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ScreenshotPreviewModal extends StatefulWidget {
  final Uint8List bytes;
  final String filePath;
  final String screenName;

  const _ScreenshotPreviewModal({
    required this.bytes,
    required this.filePath,
    required this.screenName,
  });

  @override
  State<_ScreenshotPreviewModal> createState() => _ScreenshotPreviewModalState();
}

class _ScreenshotPreviewModalState extends State<_ScreenshotPreviewModal> {
  bool _copied = false;

  void _copyPath() {
    Clipboard.setData(ClipboardData(text: widget.filePath));
    setState(() {
      _copied = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    
    return Container(
      height: mediaQuery.size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Slate 900
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 2),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: mediaQuery.padding.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.check,
                          color: Color(0xFF34D399),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Captured Successfully!',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Full scrollable page captured in HD',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x, color: Colors.white60),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Mock Phone Preview Card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.05),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: const Color(0xFF0F172A),
                  child: InteractiveViewer(
                    maxScale: 4.0,
                    child: Center(
                      child: Image.memory(
                        widget.bytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Saved Path Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.folder,
                      color: theme.primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SAVED FILE PATH',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.filePath,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _copyPath,
                    icon: Icon(
                      _copied ? LucideIcons.checkCircle2 : LucideIcons.copy,
                      size: 20,
                    ),
                    label: Text(
                      _copied ? 'Copied Path!' : 'Copy File Path',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _copied ? const Color(0xFF10B981) : theme.primaryColor,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 70,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(
                    LucideIcons.arrowDown,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
