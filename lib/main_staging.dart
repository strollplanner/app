import 'package:strollplanner_tracker/config.dart';
import 'package:strollplanner_tracker/pages/root.dart';

void main() {
  runRoot(
    config: AppConfig(
      flavorName: 'staging',
      apiBaseApiUrl: 'https://api.stagingstrollpl.ovh',
      appBaseApiUrl: 'https://app.stagingstrollpl.ovh',
    ),
  );
}
