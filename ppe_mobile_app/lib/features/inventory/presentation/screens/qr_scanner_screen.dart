import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../shared/models/inventory_models.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/labels.dart';
import '../../data/inventory_repository.dart';

/// Camera QR scanner with manual entry fallback.
///
/// * default: store scans a worker's pickup QR → verified with the backend → opens the request
///   with the token so issuing is bound to that QR (replay-protected, single use).
/// * [returnRawValue]: returns the scanned text to the caller (e.g. harness serial numbers).
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key, this.returnRawValue = false});

  final bool returnRawValue;

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates, formats: const [BarcodeFormat.qrCode, BarcodeFormat.code128]);
  final _manual = TextEditingController();
  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    _manual.dispose();
    super.dispose();
  }

  Future<void> _handle(String value) async {
    final code = value.trim();
    if (code.isEmpty || _handling) return;
    if (widget.returnRawValue) {
      Navigator.of(context).pop(code);
      return;
    }
    setState(() => _handling = true);
    await _controller.stop();
    try {
      final resolution = await ref.read(inventoryRepositoryProvider).resolveQr(code);
      if (!mounted) return;
      await _showResult(resolution);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) {
        setState(() => _handling = false);
        await _controller.start();
      }
    }
  }

  Future<void> _showResult(QrResolution r) async {
    final l = context.l10n;
    final open = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.verified_user, color: Colors.green, size: 48),
          const SizedBox(height: 8),
          Text(r.requestNo ?? '-', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          Text(r.requesterName ?? '', textAlign: TextAlign.center),
          if (r.status != null) ...[const SizedBox(height: 8), Center(child: Text(l.statusCode(r.status)))],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: r.requisitionId == null ? null : () => Navigator.pop(context, true),
            icon: const Icon(Icons.open_in_new),
            label: Text(l.openRequest),
          ),
        ]),
      ),
    );
    if (open == true && mounted && r.requisitionId != null) {
      context.pushReplacement(AppRoutes.request(r.requisitionId!, qrToken: r.token));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.scanTitle),
        actions: [
          IconButton(icon: const Icon(Icons.flash_on), onPressed: () => _controller.toggleTorch()),
          IconButton(icon: const Icon(Icons.cameraswitch_outlined), onPressed: () => _controller.switchCamera()),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: Stack(fit: StackFit.expand, children: [
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final value = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
                if (value != null) _handle(value);
              },
              errorBuilder: (context, error) => Container(
                color: Colors.black,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Text(l.cameraUnavailable, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
              ),
            ),
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            if (_handling) const ColoredBox(color: Colors.black38, child: Center(child: CircularProgressIndicator())),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Text(l.scanHint,
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 4, color: Colors.black)])),
            ),
          ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _manual,
                  decoration: InputDecoration(labelText: l.manualEntry, isDense: true, prefixIcon: const Icon(Icons.keyboard)),
                  onSubmitted: _handle,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _handling ? null : () => _handle(_manual.text), child: Text(widget.returnRawValue ? l.ok : l.verify)),
            ]),
          ),
        ),
      ]),
    );
  }
}
