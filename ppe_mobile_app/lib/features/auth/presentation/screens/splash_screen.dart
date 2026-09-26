import 'package:flutter/material.dart';

import '../../../../shared/widgets/labels.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/images/logo_mark.png', height: 120, semanticLabel: 'PPE SMART'),
          const SizedBox(height: 16),
          Text(context.l10n.appTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: scheme.primary)),
          const SizedBox(height: 24),
          SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: scheme.primary, strokeWidth: 3)),
        ]),
      ),
    );
  }
}
