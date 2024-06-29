import 'package:flutter/material.dart';

import 'VideoList.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final List<String> videoUrls = [
    "https://demoda-cdn-uae.s3.me-central-1.amazonaws.com/1/master.m3u8",
    "https://demoda-cdn-uae.s3.me-central-1.amazonaws.com/2/master.m3u8",
    "https://demoda-cdn-uae.s3.me-central-1.amazonaws.com/2/master.m3u8",
    "https://demoda-cdn-uae.s3.me-central-1.amazonaws.com/2/master.m3u8",
    "https://demoda-cdn-uae.s3.me-central-1.amazonaws.com/2/master.m3u8",
    "https://demoda-cdn-uae.s3.me-central-1.amazonaws.com/2/master.m3u8",
    "https://demoda-cdn-uae.s3.me-central-1.amazonaws.com/3/master.m3u8",
    "https://demoda-cdn-uae.s3.me-central-1.amazonaws.com/4/master.m3u8"
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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(cloudFrontVideos: cloudFrontVideos, videoUrls: videoUrls),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.cloudFrontVideos,
    required this.videoUrls,
  });

  final List<String> cloudFrontVideos;
  final List<String> videoUrls;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Benchmark for Middle East"),
      ),
      body: Center(
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
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => VideoList(videoUrls)));
              },
              child: const Text("AWS S3"),
            ),
          ],
        ),
      ),
    );
  }
}
