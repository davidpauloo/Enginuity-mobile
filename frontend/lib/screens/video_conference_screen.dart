import 'package:chat_app/screens/joinwithcode_screen.dart';
import 'package:chat_app/screens/new_meeting_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class VideoConferenceScreen extends StatelessWidget {
  const VideoConferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 50, 0, 0),
            child: ElevatedButton.icon(
              onPressed: () {
                Get.to(NewMeeting());
              },
              icon: Icon(Icons.add),
              label: Text('New Meeting'),
              style: ElevatedButton.styleFrom(
                  fixedSize: Size(300, 30),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white),
            ),
          ),
          const Divider(
            thickness: 1,
            height: 50,
            indent: 20,
            endIndent: 20,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: OutlinedButton.icon(
              onPressed: () {
                Get.to(JoinWithCode());
              },
              icon: Icon(Icons.margin),
              label: Text("Join with a code"),
              style: OutlinedButton.styleFrom(
                  fixedSize: Size(300, 30),
                  side: BorderSide(color: Colors.indigo)),
            ),
          ),
          SizedBox(height: 60),
          Image.asset('assets/video_conf_flat_design.png')
        ],
      ),
    );
  }
}
