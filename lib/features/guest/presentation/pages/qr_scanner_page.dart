import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class QrScannerPage extends ConsumerStatefulWidget {
  const QrScannerPage({super.key});

  @override
  ConsumerState<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends ConsumerState<QrScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  String? _errorMessage;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    cameraController.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
        backgroundColor: AppColors.darkBrown,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: cameraController,
            onDetect: _onQRCodeDetected,
          ),
          
          // Overlay with scanning frame
          _buildScanningOverlay(),
          
          // Error banner
          if (_errorMessage != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.error,
                child: Row(
                  children: [
                    const Icon(Icons.error, color: AppColors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.white),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          
          // Loading indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.white),
                    SizedBox(height: 16),
                    Text(
                      'QR code verwerken...',
                      style: TextStyle(color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.darkBrown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Richt de camera op een QR code van een restaurant menu',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.flip_camera_ios,
                  label: 'Camera wisselen',
                  onPressed: _switchCamera,
                ),
                _buildActionButton(
                  icon: Icons.image,
                  label: 'Uit galerij',
                  onPressed: _pickFromGallery,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: AppColors.mediumBrown,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 250,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: AppColors.white, size: 32),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.mediumBrown,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final String? code = barcodes.first.rawValue;
    if (code == null) return;
    
    _processQRCode(code);
  }

  Future<void> _processQRCode(String qrCode) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Stop camera while processing
      await cameraController.stop();
      
      // Parse QR code to extract restaurant/menu information
      final qrData = _parseQRCode(qrCode);
      
      if (qrData == null) {
        setState(() {
          _errorMessage = 'Ongeldige QR code. Scan een Menutri restaurant QR code.';
          _isProcessing = false;
        });
        await cameraController.start();
        return;
      }
      
      // Log scan activity
      try {
        await ApiService().logActivity(
          type: 'qr_scan',
          restaurantId: qrData['restaurant_id'],
          metadata: {'qr_code': qrCode},
        );
      } catch (e) {
        // Activity logging is optional
        print('Could not log scan activity: $e');
      }
      
      // Navigate to restaurant detail
      if (mounted) {
        context.go('/guest/restaurant/${qrData['restaurant_id']}');
      }
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Fout bij verwerken QR code: $e';
        _isProcessing = false;
      });
      await cameraController.start();
    }
  }

  Map<String, dynamic>? _parseQRCode(String qrCode) {
    try {
      // Expected format: https://menutri.app/restaurant/{id}
      // or menutri://restaurant/{id}
      // or direct restaurant ID
      
      if (qrCode.startsWith('https://menutri.app/restaurant/')) {
        final id = qrCode.split('/').last;
        return {'restaurant_id': int.parse(id)};
      }
      
      if (qrCode.startsWith('menutri://restaurant/')) {
        final id = qrCode.split('/').last;
        return {'restaurant_id': int.parse(id)};
      }
      
      // Try parsing as direct ID
      final id = int.tryParse(qrCode);
      if (id != null) {
        return {'restaurant_id': id};
      }
      
      // Check if it's a JSON format
      if (qrCode.startsWith('{') && qrCode.endsWith('}')) {
        // Try parsing as JSON (for more complex QR codes)
        // This would be implemented based on actual QR code format
        return {'restaurant_id': 1}; // Placeholder
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  void _toggleFlash() {
    setState(() {
      _flashOn = !_flashOn;
    });
    cameraController.toggleTorch();
  }

  void _switchCamera() {
    cameraController.switchCamera();
  }

  void _pickFromGallery() {
    // This would implement image picker functionality
    // For now, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR code uit galerij selecteren komt binnenkort'),
        backgroundColor: AppColors.mediumBrown,
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

// Custom overlay shape for QR scanner
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
  }) : cutOutSize = cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    Path getRightTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.right - borderRadius, rect.top)
        ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + borderRadius)
        ..lineTo(rect.right, rect.bottom);
    }

    Path getRightBottomPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.right, rect.top + borderRadius)
        ..quadraticBezierTo(rect.right, rect.top, rect.right - borderRadius, rect.top)
        ..lineTo(rect.left, rect.top);
    }

    Path getLeftBottomPath(Rect rect) {
      return Path()
        ..moveTo(rect.right, rect.bottom)
        ..lineTo(rect.left + borderRadius, rect.bottom)
        ..quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.bottom - borderRadius)
        ..lineTo(rect.left, rect.top);
    }

    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderHeightSize = height / 2;
    final cutOutWidth = cutOutSize < width ? cutOutSize : width - borderWidth;
    final cutOutHeight = cutOutSize < height ? cutOutSize : height - borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + (width - cutOutWidth) / 2 + borderWidth,
      rect.top + (height - cutOutHeight) / 2 + borderWidth,
      cutOutWidth - borderWidth * 2,
      cutOutHeight - borderWidth * 2,
    );

    final cutOutRRect = RRect.fromRectAndRadius(
      cutOutRect,
      Radius.circular(borderRadius),
    );

    final overlayPath = Path()
      ..addRect(rect)
      ..addRRect(cutOutRRect);

    return overlayPath;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderHeightSize = height / 2;
    final cutOutWidth = cutOutSize < width ? cutOutSize : width - borderWidth;
    final cutOutHeight = cutOutSize < height ? cutOutSize : height - borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + (width - cutOutWidth) / 2 + borderWidth,
      rect.top + (height - cutOutHeight) / 2 + borderWidth,
      cutOutWidth - borderWidth * 2,
      cutOutHeight - borderWidth * 2,
    );

    final cutOutRRect = RRect.fromRectAndRadius(
      cutOutRect,
      Radius.circular(borderRadius),
    );

    final overlayPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final overlayPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect),
      Path()..addRRect(cutOutRRect),
    );

    canvas.drawPath(overlayPath, overlayPaint);

    // Draw corner borders
    final borderLength = this.borderLength > cutOutWidth / 2 
        ? cutOutWidth / 2 
        : this.borderLength;
    final borderHeight = this.borderLength > cutOutHeight / 2 
        ? cutOutHeight / 2 
        : this.borderLength;

    // Top left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left, cutOutRect.top + borderHeight)
        ..lineTo(cutOutRect.left, cutOutRect.top + borderRadius)
        ..quadraticBezierTo(cutOutRect.left, cutOutRect.top, cutOutRect.left + borderRadius, cutOutRect.top)
        ..lineTo(cutOutRect.left + borderLength, cutOutRect.top),
      borderPaint,
    );

    // Top right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right - borderLength, cutOutRect.top)
        ..lineTo(cutOutRect.right - borderRadius, cutOutRect.top)
        ..quadraticBezierTo(cutOutRect.right, cutOutRect.top, cutOutRect.right, cutOutRect.top + borderRadius)
        ..lineTo(cutOutRect.right, cutOutRect.top + borderHeight),
      borderPaint,
    );

    // Bottom right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right, cutOutRect.bottom - borderHeight)
        ..lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius)
        ..quadraticBezierTo(cutOutRect.right, cutOutRect.bottom, cutOutRect.right - borderRadius, cutOutRect.bottom)
        ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom),
      borderPaint,
    );

    // Bottom left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left + borderLength, cutOutRect.bottom)
        ..lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom)
        ..quadraticBezierTo(cutOutRect.left, cutOutRect.bottom, cutOutRect.left, cutOutRect.bottom - borderRadius)
        ..lineTo(cutOutRect.left, cutOutRect.bottom - borderHeight),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}

