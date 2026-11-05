import 'l10n/app_localizations.dart';

/// A fixed, locally bundled catalogue. App names follow their store branding;
/// only the category and description change with the selected language.
class OurApp {
  const OurApp({
    required this.packageName,
    required this.name,
    required this.icon,
    required this.category,
    required this.description,
  });

  final String packageName, name, icon;
  final String Function(AppLocalizations) category, description;
}

final ourApps = List<OurApp>.unmodifiable([
  OurApp(
    packageName: 'com.dayround.app',
    name: 'LOOPET',
    icon: 'assets/apps/loopet.png',
    category: (l10n) => l10n.ourAppsLoopetCategory,
    description: (l10n) => l10n.ourAppsLoopetDescription,
  ),
  OurApp(
    packageName: 'com.sobra.app.sobra_app',
    name: 'Sobrita',
    icon: 'assets/apps/sobrita.png',
    category: (l10n) => l10n.ourAppsSobritaCategory,
    description: (l10n) => l10n.ourAppsSobritaDescription,
  ),
  OurApp(
    packageName: 'com.randomfocus.app',
    name: 'RandomFocus',
    icon: 'assets/apps/randomfocus.png',
    category: (l10n) => l10n.ourAppsRandomFocusCategory,
    description: (l10n) => l10n.ourAppsRandomFocusDescription,
  ),
  OurApp(
    packageName: 'com.casewen.multi_calc',
    name: 'MultiCal',
    icon: 'assets/apps/multical.png',
    category: (l10n) => l10n.ourAppsMultiCalCategory,
    description: (l10n) => l10n.ourAppsMultiCalDescription,
  ),
]);
