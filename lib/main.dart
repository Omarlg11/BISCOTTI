import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const BiscuitInfoApp());
}

class BiscuitInfoApp extends StatelessWidget {
  const BiscuitInfoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BISCOTTI Recognized',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  String? _biscuitInfo;
  bool _isAnalyzing = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _biscuitInfo = null;
        });
      }
    } catch (e) {
      _showError("Erreur lors de la prise de photo: $e");
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _biscuitInfo = null;
        });
      }
    } catch (e) {
      _showError("Erreur lors de la sélection de l'image: $e");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _analyzeImage() async {
    if (_image == null) {
      _showError('Veuillez sélectionner une image.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _biscuitInfo = "Analyse en cours...";
    });

    try {
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final requestBody = {
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": "Décris seulment les  biscuit sinon donne 'ce n'est pas un biscuit'  . Donne le nom, la marque, le prix exactes au maroc SUE MARJANE.MA EN DIRHAMS(DH) ,desription aussi mais plus courtes possible , et  elimine les etoils  "
              },
              {
                "type": "image_url",
                "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
              }
            ]
          }
        ],
        "max_tokens": 300
      };

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer  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',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('La requête a pris trop de temps');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices']?[0]['message']?['content'];
        if (content != null && content is String) {
          setState(() {
            _biscuitInfo = content.trim();
          });
        } else {
          throw FormatException('Format de réponse invalide');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error']?['message'] ?? 'Erreur inconnue');
      }
    } on FormatException catch (e) {
      _showError("Erreur de format : ${e.message}");
    } on TimeoutException catch (e) {
      _showError("Délai d'attente dépassé : ${e.message}");
    } catch (e) {
      _showError("Erreur : $e");
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BISCOTTI Recognized'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _image != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _image!,
                        fit: BoxFit.contain,
                      ),
                    )
                        : Center(
                      child: Text(
                        'Aucune image sélectionnée',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Prendre une photo'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galerie'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAnalyzing ? null : _analyzeImage,
                      child: _isAnalyzing
                          ? const CircularProgressIndicator()
                          : const Text('Analyser'),
                    ),
                  ),
                ],
              ),
            ),
            if (_biscuitInfo != null) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _biscuitInfo!,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
