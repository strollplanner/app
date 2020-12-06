import 'package:strollplanner_tracker/config.dart';
import 'package:strollplanner_tracker/pages/root.dart';

void main() {
  runRoot(
    config: AppConfig(
      flavorName: 'prod',
      apiBaseApiUrl: 'https://api.stroll.pl',
      appBaseApiUrl: 'https://app.stroll.pl',
    ),
  );
}
