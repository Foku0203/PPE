import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Safety posters shown as an auto-advancing, swipeable banner at the top of the home screen.
const promoBanners = [
  'assets/images/banners/banner_1_cover.jpg',
  'assets/images/banners/banner_2_ppe.jpg',
  'assets/images/banners/banner_3_fire.jpg',
];

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key, this.images = promoBanners, this.interval = const Duration(seconds: 5)});

  final List<String> images;
  final Duration interval;

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  // Start far from 0 so the user can swipe backwards from the first slide (infinite loop).
  static const _loopBase = 1000;

  late final PageController _controller = PageController(initialPage: widget.images.length * _loopBase);
  Timer? _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.images.length < 2) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    });
  }

  /// Pause auto-advance while the user is dragging, resume a full interval after they let go.
  bool _onScroll(ScrollNotification n) {
    if (n is ScrollStartNotification && n.dragDetails != null) _timer?.cancel();
    if (n is ScrollEndNotification) _startTimer();
    return false;
  }

  void _open(int index) {
    _timer?.cancel();
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => _PosterViewer(images: widget.images, initial: index)))
        .then((_) => _startTimer());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = widget.images.length;
    return Column(children: [
      AspectRatio(
        aspectRatio: 16 / 10,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: ScrollConfiguration(
              // Allow mouse drag too, so the web build can be swiped like a phone.
              behavior: ScrollConfiguration.of(context).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (page) => setState(() => _current = page % count),
                itemBuilder: (context, page) {
                  final index = page % count;
                  return GestureDetector(onTap: () => _open(index), child: _Poster(asset: widget.images[index]));
                },
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _current ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == _current ? scheme.primary : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ]),
    ]);
  }
}

/// Whole poster on a plain theme-colored backdrop, so square and tall posters fit a wide banner uncropped.
class _Poster extends StatelessWidget {
  const _Poster({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }
}

/// Full-screen, pinch-to-zoom viewer so the poster text is readable.
class _PosterViewer extends StatelessWidget {
  const _PosterViewer({required this.images, required this.initial});

  final List<String> images;
  final int initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, leading: const CloseButton()),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
        child: PageView(
          controller: PageController(initialPage: initial),
          children: [
            for (final asset in images)
              InteractiveViewer(maxScale: 4, child: Center(child: Image.asset(asset, fit: BoxFit.contain))),
          ],
        ),
      ),
    );
  }
}
