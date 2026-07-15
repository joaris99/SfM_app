import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.red),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _showCamera = false;
  String _status = "Ready";


  @override
  void initState() {
    super.initState();
  }


  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();

    setState(() {
      _showCamera = true;
    });
  }

  Future<void> startRecording() async {
    if (_controller == null) return;

    await _controller!.startVideoRecording();

    setState(() {
      _isRecording = true;
      _status = "Recording...";
    });
  }


  Future<void> stopRecording() async {
    if (_controller == null) return;

    final video = await _controller!.stopVideoRecording();
    final Size size = _controller!.value.previewSize!;

    int width = size.width.round();
    int height = size.height.round();

    setState(() {
      _isRecording = false;
      _status = video.path;
    });
    print("Video resolution: ${width}x$height");
    print("Video saved: ${video.path}");
  }


  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: _controller == null || !_controller!.value.isInitialized
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : CameraPreview(_controller!),
      floatingActionButton: FloatingActionButton(
        onPressed: _isRecording
            ? stopRecording
            : startRecording,
        child: Icon(
          _isRecording ? Icons.stop : Icons.videocam,
        ),
      ),
    );
    
  }


  
}
