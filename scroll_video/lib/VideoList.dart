import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

class VideoList extends StatelessWidget {
  final List<String> videoUrls;
  const VideoList(this.videoUrls, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: videoUrls.length,
        itemBuilder: (context, index) {
          return VideoPlayerItem(videoUrl: videoUrls[index]);
        },
      ),
    );
  }
}

class VideoPlayerItem extends StatelessWidget {
  final String videoUrl;

  const VideoPlayerItem({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    BetterPlayerDataSource betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      videoUrl,
    );
    return BetterPlayerListVideoPlayer(
      betterPlayerDataSource,
      key: Key(videoUrl.hashCode.toString()),
      playFraction: 0.8,
      configuration: const BetterPlayerConfiguration(
        aspectRatio: 9 / 16,
        autoPlay: true,
        looping: true,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: true,
        ),
      ),
    );
  }
}
