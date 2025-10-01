import 'package:chat_app/video_conference.dart'; // Ensure this points to your refactored file
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
// If you want copy to clipboard functionality, uncomment and import:
// import 'package:flutter/services.dart';
// import 'package:fluttertoast/fluttertoast.dart'; // For showing toast messages

class NewMeeting extends StatefulWidget {
  NewMeeting({Key? key}) : super(key: key);

  @override
  _NewMeetingState createState() => _NewMeetingState();
}

class _NewMeetingState extends State<NewMeeting> {
  String _meetingCode = "abcdfgqw";

  // Define your Agora App ID and a temporary token for testing
  // FOR PRODUCTION, YOU MUST GENERATE TOKENS SECURELY ON YOUR SERVER!
  final String appId = "265217e9cd844c46b4e95ff0161b8861"; // Your Agora App ID
  final String tempToken =
      "007eJxTYPgi/NxI77pj3c7cG7PnlHVZLb5U8nrj8u81Sw64d3mKB8sqMBgZmRoZmqdaJqdYmJgkm5glmaRamqalGRiaGSZZWJgZKt9zzWgIZGTouTmXlZEBAkF8TgbXvPTMvNLMkkoGBgBfPiKZ"; // Your Agora Temporary Token

  @override
  void initState() {
    var uuid = Uuid();
    _meetingCode = uuid.v1().substring(0, 8); // Generate a unique code
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: InkWell(
                child: Icon(Icons.arrow_back_ios_new_sharp, size: 35),
                onTap: Get.back,
              ),
            ),
            SizedBox(height: 50),
            Image.asset(
              "assets/new_meeting.png",
              fit: BoxFit.cover,
              height: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              "Your Meeting Code:",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
              child: Card(
                  color: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.link),
                    title: SelectableText(
                      _meetingCode,
                      style: const TextStyle(fontWeight: FontWeight.w300),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        // Uncomment and import 'package:flutter/services.dart'; for this
                        // Clipboard.setData(ClipboardData(text: _meetingCode));
                        // Uncomment and import 'package:fluttertoast/fluttertoast.dart'; for this
                        // Fluttertoast.showToast(msg: "Copied to clipboard!");
                        debugPrint(
                            "Meeting code copied: $_meetingCode"); // For debugging
                      },
                    ),
                  )),
            ),
            const Divider(thickness: 1, height: 40, indent: 20, endIndent: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Implement share invite functionality (e.g., using share_plus package)
                debugPrint("Share invite pressed"); // For debugging
              },
              icon: const Icon(Icons.arrow_drop_down),
              label: const Text("Share invite"),
              style: ElevatedButton.styleFrom(
                fixedSize: Size(300, 30),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                // Start the video call using the generated meeting code
                Get.to(() => VideoConference(
                      channelName: _meetingCode,
                      token: tempToken,
                      appId: appId,
                    ));
              },
              icon: const Icon(Icons.video_call),
              label: const Text("Start Call"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.indigo,
                side: const BorderSide(color: Colors.indigo),
                fixedSize: const Size(300, 30),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
