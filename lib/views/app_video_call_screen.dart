import 'package:agora_poc/controllers/app_video_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class VideoCallScreen extends StatelessWidget {
  final VideoCallController controller = Get.put(VideoCallController());

  VideoCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Agora Video Call"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Obx(() {
        return Stack(
          children: [
            controller.remoteUid.value != null //0917-DD92
                ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: controller.agoraEngine,
                    connection: RtcConnection(),
                    canvas: VideoCanvas(uid: controller.remoteUid.value!),
                  ),
                )
                : const Center(
                  child: Text(
                    "Waiting for a remote user to join...",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 120,
                height: 160,
                margin: const EdgeInsets.all(10),
                child:
                    controller.isCameraOff.value
                        ? Container(
                          color: Colors.black,
                          child: const Center(
                            child: Icon(
                              Icons.videocam_off,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        )
                        : AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: controller.agoraEngine,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    backgroundColor:
                        controller.isMuted.value ? Colors.red : Colors.blue,
                    onPressed: controller.toggleMute,
                    child: Icon(
                      controller.isMuted.value ? Icons.mic_off : Icons.mic,
                    ),
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.red,
                    onPressed: controller.leaveCall,
                    child: const Icon(Icons.call_end),
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.blue,
                    onPressed: controller.toggleCamera,
                    child: Icon(
                      controller.isCameraOff.value
                          ? Icons.videocam_off
                          : Icons.videocam,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: controller.isJoined.value ? null : controller.joinCall,
        child: const Icon(Icons.call),
      ),
    );
  }
}
