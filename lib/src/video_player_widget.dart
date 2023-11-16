import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_with_controls/src/helper/format_duration.dart';

class VideoPlayerWithControls extends StatefulWidget {
  final double? videoHeight;
  final double? iconSize;
  final Color? videoProgressPlayedColor;
  final String videoUrl;
  final Color? iconColor;
  final Color? loadingColor;
  final int? skipVideoUptoSec;
  final Color? videoProgressBgColor;
  final Color? videoProgressBufferColor;
  final Color? borderColor;

  const VideoPlayerWithControls(
      {Key? key,
      this.videoProgressPlayedColor = Colors.red,
      required this.videoUrl,
      this.iconColor = Colors.white,
      this.loadingColor = Colors.red,
      this.skipVideoUptoSec = 5,
      this.videoProgressBgColor = Colors.grey,
      this.videoProgressBufferColor = Colors.white24,
      this.iconSize = 100,
      this.borderColor = Colors.grey,
      this.videoHeight = 200})
      : super(key: key);

  @override
  State<VideoPlayerWithControls> createState() =>
      _VideoPlayerWithControlsState();
}

class _VideoPlayerWithControlsState extends State<VideoPlayerWithControls> {
  late VideoPlayerController _controller;
  bool isVideoLoading = true;
  bool showControls = false;
  bool showPlayButton = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          isVideoLoading = false;
        });
      });
  }

  void resetTimer() {
    setState(() {
      showControls = true;
    });

    // Hide the text after 3 seconds of inactivity
    if (_controller.value.isPlaying) {
      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          showControls = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isVideoLoading == true
        ? Container(
            height: widget.videoHeight!,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: widget.borderColor!)),
            child: Center(
              child: CircularProgressIndicator(color: widget.loadingColor),
            ))
        : !_controller.value.isInitialized
            ? SizedBox()
            : GestureDetector(
                onTap: resetTimer,
                onLongPress: resetTimer,
                child: Container(
                    height: widget.videoHeight!,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Center(
                            child: VideoPlayer(_controller),
                          ),
                          skipSeconds(context),
                          showInitialPauseButton(iconSize: widget.iconSize!),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              videoProgressIndicator(),
                              otherControls(false)
                            ],
                          )
                        ],
                      ),
                    )),
              );
  }

  skipSeconds(context) {
    return Container(
      child: Row(
        children: [
          InkWell(
            onTap: resetTimer,
            onDoubleTap: () => setState(() {
              skipExactly(widget.skipVideoUptoSec!);
            }),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width * 0.1,
            ),
          ),
          InkWell(
            onTap: resetTimer,
            onDoubleTap: resetTimer,
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width * 0.1,
            ),
          ),
          InkWell(
            onTap: resetTimer,
            onDoubleTap: () => setState(() {
              skipExactly(widget.skipVideoUptoSec!);
            }),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width * 0.1,
            ),
          )
        ],
      ),
    );
  }

  skipExactly(int seconds) {
    if (_controller.value.isInitialized) {
      final newPosition =
          Duration(seconds: _controller.value.position.inSeconds + seconds);
      _controller.seekTo(newPosition);
    }
  }

  showInitialPauseButton({required double iconSize}) {
    return Visibility(
      visible: showPlayButton,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            color: Colors.black.withOpacity(0.5),
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _controller.play();
                  showPlayButton = false;
                  // showControls = true;
                });
                resetTimer();
              },
              icon: Icon(
                Icons.play_circle_outline_outlined,
                size: iconSize,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  videoProgressIndicator() {
    return VideoProgressIndicator(_controller,
        allowScrubbing: true,
        colors: VideoProgressColors(
            bufferedColor: widget.videoProgressBufferColor!,
            playedColor: widget.videoProgressPlayedColor!));
  }

  otherControls(isFullScreen) {
    return Visibility(
      visible: showControls,
      child: Row(
        children: [
          playPauseButton(),
          videoDuration(),
          const Spacer(),
          fullScreenButton(isFullScreen)
        ],
      ),
    );
  }

  playPauseButton() {
    return ValueListenableBuilder(
        valueListenable: _controller,
        builder: (context, value, child) {
          return IconButton(
            onPressed: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
              resetTimer();
            },
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: widget.iconColor!,
            ),
          );
        });
  }

  videoDuration() {
    return ValueListenableBuilder(
        valueListenable: _controller,
        builder: (context, value, child) {
          return Text(
            '${formatDuration(_controller.value.position)} / ${formatDuration(_controller.value.duration)}',
            style: TextStyle(color: widget.iconColor!),
          );
        });
  }

  fullScreenButton(isFullScreen) {
    return IconButton(
        onPressed: () {
          SystemChrome.setPreferredOrientations([
            !isFullScreen
                ? DeviceOrientation.landscapeRight
                : DeviceOrientation.portraitUp
          ]);
          !isFullScreen ? goFullScreen(context) : Navigator.pop(context);
          !isFullScreen
              ? SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive)
              : SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          resetTimer();
        },
        icon: Icon(
          Icons.fullscreen,
          color: widget.iconColor,
        ));
  }

  void goFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return WillPopScope(
            onWillPop: () async {
              SystemChrome.setPreferredOrientations(
                  [DeviceOrientation.portraitUp]);
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              Navigator.pop(context);
              return true;
            },
            child: Scaffold(
                body: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  color: Colors.black,
                  child: Center(
                    child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller)),
                  ),
                ),
                skipSeconds(context),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [videoProgressIndicator(), otherControls(true)],
                )
              ],
            )),
          );
        },
      ),
    );
  }
}
