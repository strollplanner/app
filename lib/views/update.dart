import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:strollplanner_tracker/config.dart';
import 'package:strollplanner_tracker/services/gql.dart';

class UpdatePage extends StatefulWidget {
  final Widget child;

  UpdatePage(this.child);

  static Widget build(Widget child) {
    if (Platform.isAndroid) {
      return UpdatePage(child);
    }

    return child;
  }

  @override
  State<UpdatePage> createState() => _UpdatePageState(this);
}

class AndroidRelease {
  final String tag;
  final String url;

  AndroidRelease(this.tag, this.url);

  factory AndroidRelease.fromJson(Map<String, dynamic> json) {
    return AndroidRelease(json["tag"], json["url"]);
  }
}

enum UpdateStatus {
  checking,
  downloading,
  install,
  done,
}

class _UpdatePageState extends State<UpdatePage> {
  final UpdatePage widget;

  UpdateStatus status = UpdateStatus.checking;
  String toInstall;
  double downloadProgress = 0.0;

  // For dev
  final bool _forceInstall = false;

  _UpdatePageState(this.widget);

  bool shouldRun() {
    var releaseTag = AppConfig.of(context).releaseTag;
    return releaseTag != "" || _forceInstall;
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldRun()) {
      return widget.child;
    }

    switch (status) {
      case UpdateStatus.done:
        return widget.child;
      case UpdateStatus.checking:
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Checking for update...",
                  style: Theme.of(context).textTheme.headline5),
              SizedBox(height: 60),
              CircularProgressIndicator()
            ]);
      case UpdateStatus.downloading:
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Update available",
                  style: Theme.of(context).textTheme.headline5),
              SizedBox(height: 30),
              Text("Downloading..."),
              SizedBox(height: 30),
              CircularProgressIndicator(value: downloadProgress, backgroundColor: Colors.grey[300])
            ]);
      case UpdateStatus.install:
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Update ready for install",
                  style: Theme.of(context).textTheme.headline5),
              SizedBox(height: 60),
              ElevatedButton(
                onPressed: install,
                style: ElevatedButton.styleFrom(padding: EdgeInsets.all(15)),
                child: Text(
                  "INSTALL",
                  style: new TextStyle(
                    fontSize: 20.0,
                  ),
                ),
              )
            ]);
    }
  }

  void checkForUpdate() async {
    if (!shouldRun()) {
      return;
    }

    print("Check update");

    setState(() {
      this.status = UpdateStatus.checking;
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

    if (_forceInstall ||
        (res.data != null &&
            res.data.tag != AppConfig.of(context).releaseTag)) {
      await download(res.data);
    } else {
      setState(() {
        this.status = UpdateStatus.done;
      });
    }
  }

  Future _downloadFile(String url, String to) async {
    setState(() {
      this.status = UpdateStatus.downloading;
      this.downloadProgress = 0;
    });

    var completer = new Completer();

    var httpClient = http.Client();
    var request = new http.Request('GET', Uri.parse(url));
    var response = httpClient.send(request);

    List<List<int>> chunks = new List();
    int downloaded = 0;

    response.asStream().listen((http.StreamedResponse r) {
      r.stream.listen((List<int> chunk) {
        setState(() {
          this.downloadProgress = downloaded / r.contentLength;
        });

        chunks.add(chunk);
        downloaded += chunk.length;
      }, onDone: () async {
        setState(() {
          this.downloadProgress = 1;
        });

        // Save the file
        File file = new File(to);
        final Uint8List bytes = Uint8List(r.contentLength);
        int offset = 0;
        for (List<int> chunk in chunks) {
          bytes.setRange(offset, offset + chunk.length, chunk);
          offset += chunk.length;
        }
        await file.writeAsBytes(bytes);
        completer.complete();
      });
    });

    return completer.future;
  }

  Future download(AndroidRelease data) async {
    Directory directory = await getTemporaryDirectory();
    var to = "${directory.path}/strollplanner-${data.tag}.apk";

    if (_forceInstall || !await File(to).exists()) {
      print("Downloading ${data.url}");

      await _downloadFile(data.url, to);
    }

    setState(() {
      this.status = UpdateStatus.install;
      this.toInstall = to;
    });
  }

  Future install() async {
    await OpenFile.open(toInstall);
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      checkForUpdate();
    });
  }
}
