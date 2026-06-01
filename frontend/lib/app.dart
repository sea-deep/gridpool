import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:frontend/router/app_router.dart';
import 'package:frontend/theme/app_theme.dart';

class GridpoolApp extends ConsumerWidget {
  const GridpoolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(routerProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightScheme = lightDynamic ?? AppTheme.fallbackLightScheme;
        final darkScheme = darkDynamic ?? AppTheme.fallbackDarkScheme;

        return MaterialApp.router(
          title: 'Gridpool',
          theme: AppTheme.themeFromScheme(lightScheme),
          darkTheme: AppTheme.themeFromScheme(darkScheme),
          themeMode: ThemeMode.system,
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
