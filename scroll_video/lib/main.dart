import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ReverseProxyChannel.dart';
import 'VideoList.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> videoUrls = [
    // "https://demoda-cdn-uae.s3.me-central-1.amazonaws.com/1/master.m3u8",
    // "https://demoda-cdn-uae.s3.me-central-1.amazonaws.com/2/master.m3u8",
    // "https://demoda-cdn-uae.s3.me-central-1.amazonaws.com/2/master.m3u8",
    // "https://demoda-cdn-uae.s3.me-central-1.amazonaws.com/2/master.m3u8",
    // "https://demoda-cdn-uae.s3.me-central-1.amazonaws.com/2/master.m3u8",
    // "https://demoda-cdn-uae.s3.me-central-1.amazonaws.com/2/master.m3u8",
    // "https://demoda-cdn-uae.s3.me-central-1.amazonaws.com/3/master.m3u8",
    // "https://demoda-cdn-uae.s3.me-central-1.amazonaws.com/4/master.m3u8"
  ];

  final List<String> cloudFrontVideos = [
    "https://d1nxrumakffdde.cloudfront.net/1/master.m3u8",
    "https://d1nxrumakffdde.cloudfront.net/2/master.m3u8",
    "https://d1nxrumakffdde.cloudfront.net/2/master.m3u8",
    "https://d1nxrumakffdde.cloudfront.net/2/master.m3u8",
    "https://d1nxrumakffdde.cloudfront.net/2/master.m3u8",
    "https://d1nxrumakffdde.cloudfront.net/2/master.m3u8",
    "https://d1nxrumakffdde.cloudfront.net/3/master.m3u8",
    "https://d1nxrumakffdde.cloudfront.net/4/master.m3u8",
  ];

  bool loading = false;

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Benchmark for Middle East"),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () async {
        String? url = await ReverseProxyChannel().getProxyUrl(
            "https://demoda-cdn-uae.s3.me-central-1.amazonaws.com/test/hls/41299/26a95475-54db-43ed-a3c1-284f51146873-master.m3u8");
        log("Proxy URL $url");
      }),
      body: loading
          ? const CircularProgressIndicator.adaptive()
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  MaterialButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (ctx) => VideoList(cloudFrontVideos)));
                    },
                    child: const Text("AWS CloudFront"),
                  ),
                  MaterialButton(
                    color: Colors.red[200],
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (ctx) => VideoList(videoUrls)));
                    },
                    child: const Text("AWS S3"),
                  ),
                ],
              ),
            ),
    );
  }

  getData() async {
    loading = true;
    setState(() {});
    // log("Video $videoUrls");
    try {
      final response = await http.get(
          Uri.parse("http://192.168.50.114:3055/api/explore/videos"),
          headers: {
            "deviceModel": "Pixel 5",
            "deviceUniqueId": "ddbe5d53c3874d57"
          });

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        videoUrls.clear();
        if (data["data"] != null) {
          for (var url in data["data"]) {
            // log("Index $url");
            videoUrls.add(url);
          }
        } else {
          log("Error: 'videoUrls' key not found or it contains null");
        }
      } else {
        log("Error: Failed to load data, status code: ${response.statusCode}");
      }
    } catch (e) {
      log("Exception: $e");
    } finally {
      loading = false;
      setState(() {});
    }
    // log("Video $videoUrls");
  }
}
