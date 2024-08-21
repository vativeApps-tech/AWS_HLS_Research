import 'dart:async';
import 'dart:developer';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'ReuseableController.dart';
import 'ReverseProxyChannel.dart';

class VideoList extends StatefulWidget {
  final List<String> videoUrls;
  const VideoList(
    this.videoUrls, {
    super.key,
  });

  @override
  State<VideoList> createState() => _VideoListState();
}

class _VideoListState extends State<VideoList> {
  ReusableVideoListController videoListController =
      ReusableVideoListController();
  int lastMilli = DateTime.now().millisecondsSinceEpoch;
  bool _canBuildVideo = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final now = DateTime.now();
          final timeDiff = now.millisecondsSinceEpoch - lastMilli;
          if (notification is ScrollUpdateNotification) {
            final pixelsPerMilli = notification.scrollDelta! / timeDiff;
            if (pixelsPerMilli.abs() > 1) {
              _canBuildVideo = false;
            } else {
              _canBuildVideo = true;
            }
            lastMilli = DateTime.now().millisecondsSinceEpoch;
          }

          if (notification is ScrollEndNotification) {
            _canBuildVideo = true;
            lastMilli = DateTime.now().millisecondsSinceEpoch;
          }

          // print("[VideoList] can build: $_canBuildVideo");

          return true;
        },
        child: PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: widget.videoUrls.length,
          itemBuilder: (context, index) {
            return VideoPlayerItem(
              videoUrl: widget.videoUrls[1],
              videoListController: videoListController,
              canBuildVideo: _checkCanBuildVideo,
            );
          },
        ),
      ),
    );
  }

  bool _checkCanBuildVideo() {
    return _canBuildVideo;
  }
}

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;

  final ReusableVideoListController? videoListController;
  final Function? canBuildVideo;

  const VideoPlayerItem({
    super.key,
    required this.videoUrl,
    required this.videoListController,
    required this.canBuildVideo,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  BetterPlayerController? controller;
  StreamController<BetterPlayerController?>
      betterPlayerControllerStreamController = StreamController.broadcast();
  bool _initialized = false;
  Timer? _timer;
  @override
  void dispose() {
    betterPlayerControllerStreamController.close();
    super.dispose();
  }

  Future<void> _setupController() async {
    log("Video URL ${widget.videoUrl}");
    if (controller == null) {
      controller = widget.videoListController!.getBetterPlayerController();
      if (controller != null) {
        String? proxyUrl;

        try {
          proxyUrl = await ReverseProxyChannel().getProxyUrl(widget.videoUrl);
        } on PlatformException catch (e) {
          print("Failed to get proxy URL: '${e.message}'.");
        }

        if (proxyUrl == null || proxyUrl.isEmpty) {
          print("Using original URL due to proxy failure.");
          proxyUrl = widget.videoUrl; // Fallback to original URL
        }

        print("[VideoList] Load: ${widget.videoUrl}");
        controller!.setupDataSource(BetterPlayerDataSource.network(
            proxyUrl ?? widget.videoUrl,
            videoFormat: BetterPlayerVideoFormat.hls,
            useAsmsAudioTracks: true,
            useAsmsTracks: true,
            cacheConfiguration: const BetterPlayerCacheConfiguration()));
        if (!betterPlayerControllerStreamController.isClosed) {
          betterPlayerControllerStreamController.add(controller);
        }
        controller!.addEventsListener(onPlayerEvent);
      }
    }
  }

//    void _setupController() async {
//   if (controller == null) {
//     controller = widget.videoListController!.getBetterPlayerController();
//     if (controller != null) {
//       print("[VideoList] Load: ${widget.videoUrl}");

//       // Fetch the proxy URL from the native platform
//       final ReverseProxyChannel reverseProxyChannel = ReverseProxyChannel();
//       String? proxyUrl = await reverseProxyChannel.getProxyUrl(widget.videoUrl);
//       log("ProxyUrl --------- $proxyUrl");

//       if (proxyUrl != null) {
//         controller!.setupDataSource(BetterPlayerDataSource.network(
//             proxyUrl,
//             videoFormat: BetterPlayerVideoFormat.hls,
//             useAsmsAudioTracks: true,
//             useAsmsTracks: true,
//             cacheConfiguration:
//                 const BetterPlayerCacheConfiguration(useCache: true)));
//       } else {
//         print("Failed to retrieve proxy URL. Loading original URL.");
//         controller!.setupDataSource(BetterPlayerDataSource.network(
//             widget.videoUrl,
//             videoFormat: BetterPlayerVideoFormat.hls,
//             useAsmsAudioTracks: true,
//             useAsmsTracks: true,
//             cacheConfiguration:
//                 const BetterPlayerCacheConfiguration(useCache: true)));
//       }

//       if (!betterPlayerControllerStreamController.isClosed) {
//         betterPlayerControllerStreamController.add(controller);
//       }
//       controller!.addEventsListener(onPlayerEvent);
//     }
//   }
// }

  void _freeController() {
    if (!_initialized) {
      _initialized = true;
      return;
    }
    if (controller != null && _initialized) {
      controller!.removeEventsListener(onPlayerEvent);
      widget.videoListController!.freeBetterPlayerController(controller);
      controller!.pause();
      controller = null;
      if (!betterPlayerControllerStreamController.isClosed) {
        betterPlayerControllerStreamController.add(null);
      }
      _initialized = false;
    }
  }

  void onPlayerEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
      // videoListData!.lastPosition = event.parameters!["progress"] as Duration?;
    }
    if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
      // if (videoListData!.lastPosition != null) {
      // controller!.seekTo(videoListData!.lastPosition!);
      // }
      // if (videoListData!.wasPlaying!) {
      // controller!.play();
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    BetterPlayerDataSource betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.videoUrl,
    );
    return Container(
      color: Colors.black,
      child: VisibilityDetector(
        key: Key(hashCode.toString() + DateTime.now().toString()),
        onVisibilityChanged: (info) {
          if (!widget.canBuildVideo!()) {
            _timer?.cancel();
            _timer = null;
            _timer = Timer(Duration(milliseconds: 500), () {
              if (info.visibleFraction >= 0.6) {
                _setupController();
              } else {
                _freeController();
              }
            });
            return;
          }
          if (info.visibleFraction >= 0.6) {
            _setupController();
          } else {
            _freeController();
          }
        },
        child: StreamBuilder<BetterPlayerController?>(
          stream: betterPlayerControllerStreamController.stream,
          builder: (context, snapshot) {
            return AspectRatio(
              aspectRatio: 9 / 16,
              child: controller != null
                  ? BetterPlayer(
                      controller: controller!,
                    )
                  : Container(
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  @override
  void deactivate() {
    // if (controller != null) {
    //   videoListData!.wasPlaying = controller!.isPlaying();
    // }
    _initialized = true;
    super.deactivate();
  }
}
