import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return MyHomePage();
          } else {
            return MyHomePage();
          }
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class GreetingMessage extends StatefulWidget {
  final Function(String) onCardClicked;

  GreetingMessage({required this.onCardClicked});

  @override
  _GreetingMessageState createState() => _GreetingMessageState();
}

class _GreetingMessageState extends State<GreetingMessage> {
  bool isDropdownOpen = false;

  void toggleDropdown() {
    setState(() {
      isDropdownOpen = !isDropdownOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: toggleDropdown,
            child: Row(
              children: [
                Text(
                  'Sam',
                  style: GoogleFonts.comfortaa(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 33,
                ),
              ],
            ),
          ),
          Visibility(
            visible: isDropdownOpen,
            child: Container(
              margin: const EdgeInsets.only(top: 5),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color:
                    const Color.fromARGB(255, 226, 234, 238).withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.assistant,
                    color: Color.fromARGB(255, 92, 161, 196),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Smart Assistant Module',
                    style: GoogleFonts.comfortaa(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 70),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.blue, Colors.red],
              tileMode: TileMode.mirror,
            ).createShader(bounds),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: Text(
                    'Hello,',
                    style: GoogleFonts.comfortaa(
                      fontSize: 40,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: Text(
                    'how can I assist you today ?',
                    style: GoogleFonts.comfortaa(
                      fontSize: 40,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          SuggestionCards(onCardClicked: widget.onCardClicked),
        ],
      ),
    );
  }
}

class SuggestionCards extends StatelessWidget {
  final Function(String) onCardClicked;

  SuggestionCards({required this.onCardClicked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildSuggestionCard(
            icon: Icons.computer_outlined,
            text: 'Compare Samsung vs Apple ecosystem.',
            onTap: () => onCardClicked('Compare Samsung vs Apple ecosystem'),
          ),
          const SizedBox(width: 16),
          _buildSuggestionCard(
            icon: Icons.cloud_outlined,
            text: 'Weather in Bangalore',
            onTap: () => onCardClicked('Weather in Bangalore'),
          ),
          const SizedBox(width: 16),
          _buildSuggestionCard(
            icon: Icons.kitchen_outlined,
            text: 'Recipe with what\'s in my kitchen',
            onTap: () => onCardClicked('Recipe with what\'s in my kitchen'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 230,
        height: 200,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: GoogleFonts.comfortaa(
                      fontSize: 16, fontWeight: FontWeight.w700),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(icon, size: 24),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  int _selectedIndex = 0;
  bool _showGreeting = true;
  bool _isListening = false;

  void _sendMessage(String text, {bool isUser = true}) {
    setState(() {
      if (_showGreeting && isUser) {
        _showGreeting = false;
      }
      _messages.add({'text': text, 'isuser': isUser ? 'true' : 'false'});
      _controller.clear();
    });
    if (isUser) {
      _sendTextInput(text);
    }
  }

  void _sendTextInput(String text) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/process-text'),
      body: {'text': text},
    );

    if (response.statusCode == 200) {
      setState(() {
        _messages.add({'text': response.body, 'isuser': 'false'});
        _showGreeting = false;
      });
    } else {
      // Handle error
    }
  }

  void _startListening() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceInputPage(sendMessage: _sendMessage),
      ),
    );
    // TODO: Start listening to voice input
  }

  void _openSection(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            padding: const EdgeInsets.all(10),
            child: _selectedIndex == 0 ? AboutSection() : HelpSection(),
          ),
        );
      },
    );
  }

  void _clearChatHistory() {
    setState(() {
      _messages.clear();
      _showGreeting = true;
    });
  }

  void _handleCardClick(String cardText) {
    _sendMessage(cardText, isUser: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
                _openSection(index);
              },
              labelType: NavigationRailLabelType.none,
              backgroundColor:
                  const Color.fromARGB(255, 226, 234, 238).withOpacity(0.6),
              extended: true,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: ElevatedButton.icon(
                      onPressed: _clearChatHistory,
                      icon: const Icon(Icons.add),
                      label: Padding(
                        padding: const EdgeInsets.only(left: 9.0),
                        child: Text(
                          'New chat',
                          style: GoogleFonts.outfit(fontSize: 20),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 206, 215, 224),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            vertical: 18.0, horizontal: 18.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(
                    Icons.info_outlined,
                  ),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9.0),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        'About',
                        style: GoogleFonts.outfit(
                          fontSize: 27,
                        ),
                      ),
                    ),
                  ),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.help_outline),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9.0),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        'Help',
                        style: GoogleFonts.outfit(
                          fontSize: 27,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              useIndicator: false,
            ),
          ),
          const VerticalDivider(
            thickness: 0,
            width: 1,
          ),
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                children: [
                  if (_showGreeting)
                    GreetingMessage(onCardClicked: _handleCardClick),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        var message = _messages[index];
                        final isUserMessage = message['isuser'] == 'true';

                        const double messageSpacing = 11;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: isUserMessage
                                      ? MediaQuery.of(context).size.width * 0.5
                                      : MediaQuery.of(context).size.width * 0.7,
                                ),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isUserMessage
                                      ? const Color.fromARGB(255, 207, 217, 220)
                                          .withOpacity(0.3)
                                      : const Color.fromARGB(255, 226, 234, 238)
                                          .withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 5, right: 10),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: isUserMessage
                                            ? const Color.fromARGB(
                                                255, 191, 214, 225)
                                            : const Color.fromARGB(
                                                255, 191, 214, 225),
                                        child: Icon(
                                          isUserMessage
                                              ? Icons.account_circle_outlined
                                              : Icons.assistant,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 5),
                                        child: Text(
                                          message['text'].toString(),
                                          style: GoogleFonts.getFont(
                                            'Varela Round',
                                            fontSize: 19,
                                          ),
                                          softWrap: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: messageSpacing),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color:
                                      const Color.fromARGB(255, 226, 234, 238)
                                          .withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(35.0),
                                ),
                                child: TextField(
                                  controller: _controller,
                                  decoration: InputDecoration(
                                    hintText: 'Enter a prompt here',
                                    hintStyle: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w300,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(35.0),
                                    ),
                                  ),
                                  onSubmitted: (value) {
                                    _sendMessage(value, isUser: true);
                                    _controller.clear();
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: IconButton(
                                  icon: const Icon(Icons.send),
                                  iconSize: 27,
                                  onPressed: () => _sendMessage(
                                      _controller.text,
                                      isUser: true),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: IconButton(
                            icon: const Icon(Icons.mic),
                            iconSize: 34,
                            onPressed: _startListening,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'About',
                  style: GoogleFonts.getFont(
                    'Outfit',
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Text(
            'SAM - virtual assistant is designed to assist you with various tasks and answer your questions. Whether you need help with productivity, information retrieval, or just want to chat, I\'m here to assist! Here are some key features:\n\n',
            style: GoogleFonts.getFont(
              'Varela Round',
              fontSize: 19,
            ),
          ),
          const SizedBox(
            height: 1,
          ),
          Card(
            child: ListTile(
              leading: SvgPicture.asset('assets/google-gemini-icon.svg',
                  width: 28.0, height: 29.0),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Leveraging Gemini 1.5-Flash Technology',
                    style: GoogleFonts.getFont(
                      'Varela Round',
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'This technology enables SAM to understand and generate human-like text, making it capable of answering a wide range of queries, providing useful information, and even engaging in friendly conversations.',
                    style: GoogleFonts.getFont(
                      'Varela Round',
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.chat,
                color: Color.fromARGB(255, 99, 143, 181),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    ' Natural Language Interaction',
                    style: GoogleFonts.getFont(
                      'Varela Round',
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    ' Communicate with me using natural language. Type your queries or use voice input\n for a more conversational experience.',
                    style: GoogleFonts.getFont(
                      'Varela Round',
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: SvgPicture.asset('assets/translate.svg',
                  width: 25.0, height: 25.0),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    ' Text Translation',
                    style: GoogleFonts.getFont(
                      'Varela Round',
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    " SAM's text translation feature enables users to translate text between various \n languages effortlessly. Whether you need to translate a message, or \n any other text, SAM provides accurate and quick translations. This functionality \n supports numerous languages.",
                    style: GoogleFonts.getFont(
                      'Varela Round',
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.task,
                color: Color.fromARGB(255, 131, 213, 140),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    ' Task Automation',
                    style: GoogleFonts.getFont(
                      'Varela Round',
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    ' Need to send Whatsapp messages, get directions to a location, or find the latest \n news? Just ask, and I\'ll handle everything for you.',
                    style: GoogleFonts.getFont(
                      'Varela Round',
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.code,
                size: 26.5,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    ' Code Generation',
                    style: GoogleFonts.getFont(
                      'Varela Round',
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    ' Generate code snippets or entire scripts based on your input. Whether you\'re a\n developer looking for a quick solution to a coding problem or a beginner learning\n to code, get instant and accurate code suggestions. Simply input your\n requirements or ask a coding-related question, and I will generate the appropriate\n code.',
                    style: GoogleFonts.getFont(
                      'Varela Round',
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.forum,
                color: Color.fromARGB(255, 227, 141, 137),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    ' Friendly Conversations',
                    style: GoogleFonts.getFont(
                      'Varela Round',
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    ' Beyond functionality, I\'m here to chat! Share your thoughts, ask for jokes, or\n discuss interesting topics.',
                    style: GoogleFonts.getFont(
                      'Varela Round',
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HelpSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Help',
                  style: GoogleFonts.getFont(
                    'Outfit',
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 13.8),
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ExpansionTile(
            leading: const Icon(
              Icons.headset_mic_outlined,
              color: Color.fromARGB(255, 56, 54, 54),
            ),
            title: Text(
              ' How do I use voice input?',
              style: GoogleFonts.getFont(
                'Varela Round',
                fontSize: 19,
              ),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '       Click the microphone icon to start voice input. Speak your command or queries, and I\'ll\n       process it accordingly.',
                  style: GoogleFonts.getFont(
                    'Varela Round',
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(
              Icons.lightbulb_outline,
              color: Color.fromARGB(255, 56, 54, 54),
            ),
            title: Text(
              ' Can I ask for recommendations?',
              style: GoogleFonts.getFont(
                'Varela Round',
                fontSize: 19,
              ),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '    Absolutely! Whether it\'s movie recommendations, book suggestions, or travel             \n    destinations, feel free to ask.',
                  style: GoogleFonts.getFont(
                    'Varela Round',
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(
              Icons.keyboard_alt_outlined,
              color: Color.fromARGB(255, 56, 54, 54),
            ),
            title: Text(
              ' What commands can I use?',
              style: GoogleFonts.getFont(
                'Varela Round',
                fontSize: 19,
              ),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '         You can ask about the weather, perform calculations, get recommendations, and more. \n         Feel free to experiment!',
                  style: GoogleFonts.getFont(
                    'Varela Round',
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(
              Icons.chat_bubble_outline,
              color: Color.fromARGB(255, 56, 54, 54),
            ),
            title: Text(
              ' How do I interact with the virtual assistant?',
              style: GoogleFonts.getFont(
                'Varela Round',
                fontSize: 19,
              ),
            ),
            children: <Widget>[
              ListTile(
                title: Text(
                  '        Type your message in the input box and hit Send or use the microphone icon for \n        voice input.',
                  style: GoogleFonts.getFont(
                    'Varela Round',
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(
              Icons.search,
              color: Color.fromARGB(255, 56, 54, 54),
            ),
            title: Text(
              ' How do I find information about specific topics?',
              style: GoogleFonts.getFont(
                'Varela Round',
                fontSize: 19,
              ),
            ),
            children: <Widget>[
              ListTile(
                title: Text(
                  "       Just provide a query, and I\'ll search the web or provide relevant details.",
                  style: GoogleFonts.getFont(
                    'Varela Round',
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VoiceInputPage extends StatelessWidget {
  final Function(String, {bool isUser}) sendMessage;

  VoiceInputPage({required this.sendMessage});

  @override
  Widget build(BuildContext context) {
    timeDilation = 2.0; // Slows down animation

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Voice Input',
          style: GoogleFonts.getFont(
            'Outfit',
            fontSize: 30,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () {
            print('Microphone tapped');
            // TODO: Implement voice input logic
            sendMessage('Voice command processed', isUser: false);
            Navigator.pop(context);
          },
          child: AnimatedMicIcon(),
        ),
      ),
    );
  }
}

class AnimatedMicIcon extends StatefulWidget {
  @override
  _AnimatedMicIconState createState() => _AnimatedMicIconState();
}

class _AnimatedMicIconState extends State<AnimatedMicIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isListening = false;
  final String backendUrl = 'http://127.0.0.1:5000';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _toggleListening() async {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _controller.repeat(reverse: true);
        _sendListeningRequest();
      } else {
        _controller.stop();
        _controller.reset();
        _sendListeningRequest();
      }
    });
  }

  void _sendListeningRequest() async {
    final response = await http.post(Uri.parse('$backendUrl/toggle-listening'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final message = data['message'];
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleListening,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (_isListening)
                      BoxShadow(
                        color: Colors.black,
                        spreadRadius: _animation.value * 4,
                        blurRadius: 4,
                        offset: const Offset(0, 0),
                      ),
                  ],
                ),
                child: Icon(
                  Icons.mic,
                  size: 200 * _animation.value,
                  color: _isListening ? Colors.white : Colors.grey,
                ),
              );
            },
          ),
          const SizedBox(height: 70),
          AnimatedOpacity(
            opacity: _isListening ? 1.0 : 0.0,
            duration: const Duration(microseconds: 200),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                  fontSize: _isListening ? 24 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45),
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(_isListening ? "Listening..." : ""),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
