import 'package:strollplanner_tracker/config.dart';
import 'package:strollplanner_tracker/pages/root.dart';

void main() {
  runRoot(
    config: AppConfig.init(
      flavorName: 'prod',
      basePlatformUrl: 'https://stroll.pl',
    ),
  );
}
