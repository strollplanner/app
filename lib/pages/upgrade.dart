import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:strollplanner_tracker/config.dart';
import 'package:strollplanner_tracker/services/gql.dart';

class UpgradePage extends StatefulWidget {
  final Widget child;

  UpgradePage(this.child);

  static Widget build(Widget child) {
    if (Platform.isAndroid) {
      return UpgradePage(child);
    }

    return child;
  }

  @override
  State<UpgradePage> createState() => _UpgradePageState(this);
}

class AndroidRelease {
  final String tag;
  final String url;

  AndroidRelease(this.tag, this.url);

  factory AndroidRelease.fromJson(Map<String, dynamic> json) {
    return AndroidRelease(json["tag"], json["url"]);
  }
}

class _UpgradePageState extends State<UpgradePage> {
  final UpgradePage widget;

  bool ok = false;
  bool updating = false;
  String updatingStatus = "";

  _UpgradePageState(this.widget);

  bool shouldRun() {
    var releaseTag = AppConfig.of(context).releaseTag;
    return releaseTag != "";
  }

  @override
  Widget build(BuildContext context) {
    if (ok || !shouldRun()) {
      return widget.child;
    }

    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(updating ? "Update in progress..." : "Checking for update..."),
          updatingStatus != null ? Text(updatingStatus) : null,
          SizedBox(height: 30),
          CircularProgressIndicator()
        ]);
  }

  void checkForUpdate() async {
    if (!shouldRun()) {
      return;
    }

    print("Check update");

    setState(() {
      this.ok = false;
      this.updating = false;
      this.updatingStatus = "";
    });

    var res = await request(
        AppConfig.of(context),
        """
    query {
      r: latestAndroidRelease {
        tag
        url
      }
    }
    """,
        (m) => AndroidRelease.fromJson(m["r"]));

    if (res.data == null || res.data.tag == AppConfig.of(context).releaseTag) {
      setState(() {
        this.ok = true;
      });
      return;
    }

    setState(() {
      this.updating = true;
    });

    await doUpdate(res.data);

    setState(() {
      this.updating = false;
    });
  }

  Future doUpdate(AndroidRelease data) async {
    Directory directory = await getTemporaryDirectory();
    var to = "${directory.path}/strollplanner-${data.tag}.apk";

    if (!await File(to).exists()) {
      setState(() {
        this.updatingStatus = "Downloading...";
      });
      await _downloadFile(data.url, to);
    }

    setState(() {
      this.updatingStatus = "Installing...";
    });
    OpenFile.open(to);
  }

  Future<File> _downloadFile(String url, String to) async {
    http.Client client = new http.Client();
    var req = await client.get(Uri.parse(url));
    var bytes = req.bodyBytes;
    File file = new File(to);
    await file.writeAsBytes(bytes);
    return file;
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      checkForUpdate();
    });
  }
}
