import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:replicate_json/replicate_json.dart';
import 'package:image_downloader/image_downloader.dart';

void main() => runApp(const MaterialApp(home: MyImageWidget()));

class MyImageWidget extends StatefulWidget {
  const MyImageWidget({Key? key}) : super(key: key);

  @override
  _MyImageWidgetState createState() => _MyImageWidgetState();
}

class _MyImageWidgetState extends State<MyImageWidget> {
  String? _imageUrl;
  String? _errorMessage;
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  late SharedPreferences _prefs;
  double _sharpness = 10;
  String _selectedAspectRatio = "1152*896"; // Default aspect ratio
  int _selectedImageCount = 1; // Default number of images

  List<String> aspectRatios = [
    "704*1408",
    "704*1344",
    "768*1344",
    "768*1280",
    "832*1216",
    "832*1152",
    "896*1152",
    "896*1088",
    "960*1088",
    "960*1024",
    "1024*1024",
    "1024*960",
    "1088*960",
    "1088*896",
    "1152*896",
    "1152*832",
    "1216*832",
    "1280*768",
    "1344*768",
    "1344*704",
    "1408*704",
    "1472*704",
    "1536*640",
    "1600*640",
    "1664*576",
    "1728*576"
    // ... (add other aspect ratios)
  ];

  @override
  void initState() {
    super.initState();
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    String? savedApiUrl = _prefs.getString('apiUrl');
    if (savedApiUrl != null) {
      _urlController.text = savedApiUrl;
    }
  }

  Future<void> _saveSettings() async {
    String apiUrl = _urlController.text.trim();
    if (apiUrl.isNotEmpty) {
      await _prefs.setString('apiUrl', apiUrl);
    }
  }

  Future<void> _generateImage(String query, int sharpness) async {
    String? apiUrl = _urlController.text.trim();
    await _saveSettings();

    setState(() {
      _imageUrl = null;
      _errorMessage = null;
    });

    try {
      String modelVersion =
          "a7e8fa2f96b01d02584de2b3029a8452b9bf0c8fa4127a6d1cfd406edfad54fb"; // model version for replicate api
      String apiKey = "r8_dsunejV07OOUQ5Tx1JHUPMkm9FJCJrj1SDXF2";
         // "r8_WwCeTN4uC2wTXEcH4r50xflbTIkB4eF1gwgTz"; // replace with your api key

      List<String> imageUrls = [];

      for (int i = 0; i < _selectedImageCount; i++) {
        Map<String, Object> input = {
          "prompt": query,
          "image_number": i + 1,
          // ... (other input parameters)
        };

        String jsonString = await createAndGetJson(modelVersion, apiKey, input);
        var responseJson = jsonDecode(jsonString);

        String pngLink = responseJson['output'][0];
        imageUrls.add(pngLink);

        // Download the image
        await _downloadImage(pngLink);
      }

      setState(() {
        _imageUrl = imageUrls.first; // Only showing the first generated image
      });

      // Navigate to the new screen with the generated images
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageDisplayScreen(imageUrls: imageUrls),
        ),
      );
    } catch (e) {
      setState(() {
        print(e);
        _errorMessage = 'Failed to generate image: $e';
      });
    }
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      var imageId = await ImageDownloader.downloadImage(imageUrl);
      if (imageId == null) {
        throw Exception("Failed to download image");
      }
    } catch (error) {
      print("Image download failed: $error");
    }
  }

  Future<void> _showSettingsDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Enter API URL',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _generateImage(_queryController.text.trim(), _sharpness.toInt());
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
//yo
  @override
  void dispose() {
    _imageUrl = null;
    _errorMessage = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Price X Saha'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                _showSettingsDialog();
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _queryController,
                decoration: const InputDecoration(
                  labelText: 'Enter Query',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sharpness: $_sharpness',
                style: const TextStyle(fontSize: 16),
              ),
              Slider(
                value: _sharpness,
                min: 0,
                max: 30,
                divisions: 30,
                onChanged: (newValue) {
                  setState(() {
                    _sharpness = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Aspect Ratio: $_selectedAspectRatio',
                style: const TextStyle(fontSize: 16),
              ),
              DropdownButton<String>(
                value: _selectedAspectRatio,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedAspectRatio = newValue;
                    });
                  }
                },
                items: aspectRatios.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Number of Images: $_selectedImageCount',
                style: const TextStyle(fontSize: 16),
              ),
              Slider(
                value: _selectedImageCount.toDouble(),
                min: 1,
                max: 8,
                divisions: 7,
                onChanged: (newValue) {
                  setState(() {
                    _selectedImageCount = newValue.toInt();
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  String query = _queryController.text.trim();
                  if (query.isNotEmpty) {
                    _generateImage(query, _sharpness.toInt());
                  }
                },
                child: const Text('Generate'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: _imageUrl != null
                      ? Image.network(_imageUrl!)
                      : _errorMessage != null
                          ? Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            )
                          : const CircularProgressIndicator(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImageDisplayScreen extends StatelessWidget {
  final List<String> imageUrls;

  const ImageDisplayScreen({Key? key, required this.imageUrls}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Generated Images'),
        ),
        body: ListView(
          children: imageUrls.map((url) => Image.network(url)).toList(),
        ),
      ),
    );
  }
}

//test 2