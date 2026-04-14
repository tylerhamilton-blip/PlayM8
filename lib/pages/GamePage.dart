import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

class Gamepage extends StatefulWidget {
  final String videoUrl;
  final String gameName;
  const Gamepage({required this.videoUrl,required this.gameName, Key? key}) : super(key: key);

  @override
  State<Gamepage> createState() => _GamepageState();
}

class _GamepageState extends State<Gamepage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {}); // refresh when ready
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Center(
          child:Text(widget.gameName,
            style:
                TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white
            )
          )
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.redAccent,
      ),
      backgroundColor: Colors.black,
      body: _controller.value.isInitialized
          ? Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
          // Overlay buttons
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () {
                _controller.pause(); // pause before exit
                Navigator.pop(context); // exit the page
              },
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            child: IconButton(
              icon: Icon(
                _controller.value.isPlaying
                    ? Icons.pause_circle
                    : Icons.play_circle,
                color: Colors.redAccent,
                size: 50,
              ),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
            ),
          ),
        ],
      )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
