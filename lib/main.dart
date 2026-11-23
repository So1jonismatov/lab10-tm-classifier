import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() => runApp(const TmClassifierApp());

class TmClassifierApp extends StatefulWidget {
  const TmClassifierApp({super.key, this.state});

  final AppState? state;

  @override
  State<TmClassifierApp> createState() => _TmClassifierAppState();
}

class _TmClassifierAppState extends State<TmClassifierApp> with WidgetsBindingObserver {
  late final AppState _state = widget.state ?? AppState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _state.load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.detached) _state.closeClassifier();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'Teach It, Ship It',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const WelcomeScreen(),
        builder: (context, child) => kIsWeb ? _PhoneFrame(child: child!) : child!,
      ),
    );
  }
}

// on a wide browser window show the app at phone size
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= 600) return child;
    final size = Size(412, mq.size.height < 915 ? mq.size.height : 915);
    return ColoredBox(
      color: const Color(0xFF1E1E1E),
      child: Center(
        child: SizedBox.fromSize(
          size: size,
          child: MediaQuery(data: mq.copyWith(size: size), child: ClipRect(child: child)),
        ),
      ),
    );
  }
}
