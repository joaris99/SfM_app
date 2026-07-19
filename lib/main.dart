import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

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
  bool _imageMode = false;
  final List<File> _images = [];


  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> takePicture() async {
    if (_controller == null) return;

    final image = await _controller!.takePicture();

    setState(() {
      _images.add(File(image.path));
      _status = "${_images.length} images captured";
    });
  }

  Future<void> uploadImages() async {
    if (_images.isEmpty) return;

    final url = Uri.parse(
      "http://192.168.1.53:8000/upload-images",
    );

    final Size size = _controller!.value.previewSize!;



    final request = http.MultipartRequest("POST", url);

    int width = size.width.round();
    int height = size.height.round();
    request.fields["width"] = width.toString();
    request.fields["height"] = height.toString();

      for (int i = 0; i < _images.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "images",
            _images[i].path,
            filename: "image_$i.jpg",
          ),
        );
      }

    final response = await request.send();

    print(response.statusCode);
    print(await response.stream.bytesToString());

    if (response.statusCode == 200) {
      setState(() {
        _images.clear();
        _status = "Images uploaded";
      });
    }
  }

  

  Future<void> uploadVideo(
      File videoFile,
      int width,
      int height,
  ) async {
    final url = Uri.parse(
      "http://192.168.1.53:8000/upload-video",
    );

    var request = http.MultipartRequest(
      'POST',
      url,
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'video',
        videoFile.path,
        filename: 'video.mp4',
      ),
    );

    request.fields.addAll({
      'width': width.toString(),
      'height': height.toString(),
    });

    print(request.fields);

    final response = await request.send();

    print("Status: ${response.statusCode}");
    print(await response.stream.bytesToString());
  }


  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );

    _controller = CameraController(
      
      camera,
      ResolutionPreset.max, 
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
    final file = File(video.path);

    await uploadVideo(file, width, height);
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          if (_imageMode)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "${_images.length}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              _imageMode ? Icons.photo_camera : Icons.videocam,
            ),
            onPressed: () {
              setState(() {
                _imageMode = !_imageMode;
              });
            },
          ),
        ],
      ),
      body: _controller == null || !_controller!.value.isInitialized
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : CameraPreview(_controller!),
        
      floatingActionButton: _imageMode
    ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "take",
            onPressed: takePicture,
            child: const Icon(Icons.camera),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "upload",
            onPressed: _images.isEmpty ? null : uploadImages,
            child: const Icon(Icons.upload),
          ),
        ],
      )
    : FloatingActionButton(
        onPressed: _isRecording
            ? stopRecording
            : startRecording,
        child: Icon(
          _isRecording
              ? Icons.stop
              : Icons.videocam,
        ),
      ),
      
      
    );
    
    
  }
}
