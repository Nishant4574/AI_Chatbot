import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];

  ChatUser currentuser = ChatUser(id: "0", firstName: 'User');
  ChatUser geminiUser = ChatUser(
      id: "1",
      firstName: "",
      profileImage: "https://cdn.pixabay.com/photo/2022/07/02/12/23/bot-7297229_1280.png");

  @override
  Widget build(BuildContext context) {MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark
    ),
  );
    return Scaffold(appBar: AppBar(title: Center(child: Text("CHATBOT",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),))),

        body: Container(
            color: Colors.white54,
            child: _buildUI()));
  }

  Widget _buildUI() {
    return DashChat(
      inputOptions: InputOptions(
        trailing: [
          IconButton(
            onPressed: _sendMediaMessage,
            icon: Icon(Icons.image),
          )
        ],
      ),
      currentUser: currentuser,
      onSend: _sendMessage,
      messages: messages,
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });

    try {
      String question = chatMessage.text;
      List<Uint8List>? image;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        image = [File(chatMessage.medias!.first.url).readAsBytesSync()];
      }

      gemini.streamGenerateContent(question, images: image).listen((event) {
        String response = event.content?.parts?.fold(
            "", (previous, current) => "$previous ${current.text}") ??
            "";

        if (messages.isNotEmpty && messages.first.user.id == geminiUser.id) {
          setState(() {
            messages[0] = ChatMessage(
              user: geminiUser,
              createdAt: messages[0].createdAt,
              text: messages[0].text + response,
              medias: messages[0].medias,
            );
          });
        } else {
          ChatMessage message = ChatMessage(
            user: geminiUser,
            createdAt: DateTime.now(),
            text: response,
          );
          setState(() {
            messages = [message, ...messages];
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentuser,
        createdAt: DateTime.now(),
        text: "Describe this picture?",
        medias: [
          ChatMedia(url: file.path, fileName: file.name, type: MediaType.image)
        ],
      );
      _sendMessage(chatMessage);
    }
  }
}
