import 'package:chat_app/video_conference.dart'; // Ensure this points to your refactored file
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class JoinWithCode extends StatelessWidget {
  TextEditingController _controller = TextEditingController();

  // Define your Agora App ID and a temporary token for testing
  // FOR PRODUCTION, YOU MUST GENERATE TOKENS SECURELY ON YOUR SERVER!
  final String appId = "265217e9cd844c46b4e95ff0161b8861"; // Your Agora App ID
  final String tempToken =
      "007eJxTYLgRsfLV81euYUfvLnSNW/SgQ7vI1GYTE6t3TdmKJxVrulIUGIzMTI0MzVMtk1MsTEySTcySTFItTdPSDAzNDJMsLMwMhbncMhoCGRmkHtYzMTJAIIjPyeCal56ZV5pZUsnAAAAnRCD1"; // Your Agora Temporary Token

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
              "assets/join_with_code.png",
              fit: BoxFit.cover,
              height: 100,
            ),
            SizedBox(height: 20),
            Text(
              "Enter meeting code below",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
              child: Card(
                color: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Example : abc-efg-dhi"),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Pass the entered meeting code as the channelName
                Get.to(() => VideoConference(
                      channelName: _controller.text,
                      token: tempToken,
                      appId: appId,
                    ));
              },
              child: Text("Join"),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.indigo,
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
