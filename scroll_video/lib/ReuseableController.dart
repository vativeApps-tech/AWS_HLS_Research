import 'package:better_player_plus/better_player_plus.dart';
import 'package:collection/collection.dart' show IterableExtension;

class ReusableVideoListController {
  final List<BetterPlayerController> _betterPlayerControllerRegistry = [];
  final List<BetterPlayerController> _usedBetterPlayerControllerRegistry = [];

  ReusableVideoListController() {
    for (int index = 0; index < 3; index++) {
      _betterPlayerControllerRegistry.add(
        BetterPlayerController(
          const BetterPlayerConfiguration(
            handleLifecycle: false,
            autoPlay: true,
            autoDispose: false,
            aspectRatio: 9 / 16,
          ),
        ),
      );
    }
  }

  BetterPlayerController? getBetterPlayerController() {
    final freeController = _betterPlayerControllerRegistry.firstWhereOrNull(
        (controller) =>
            !_usedBetterPlayerControllerRegistry.contains(controller));

    if (freeController != null) {
      _usedBetterPlayerControllerRegistry.add(freeController);
    }

    return freeController;
  }

  void freeBetterPlayerController(
      BetterPlayerController? betterPlayerController) {
    _usedBetterPlayerControllerRegistry.remove(betterPlayerController);
  }

  void dispose() {
    _betterPlayerControllerRegistry.forEach((controller) {
      controller.dispose();
    });
  }
}
