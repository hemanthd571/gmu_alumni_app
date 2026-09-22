import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class FeedbackScreen extends StatefulWidget {
  final String mode; // 'text', 'video', 'audio'
  final File? mediaFile;
  final int? eventId;

  const FeedbackScreen({
    Key? key,
    required this.mode,
    this.mediaFile,
    this.eventId,
  }) : super(key: key);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  
  late stt.SpeechToText _speech;
  bool _isListening = false;
  int _activeQuestion = 0; // 1, 2, or 3
  
  int _rating = 0; // Added rating state
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _listen(int questionNumber, TextEditingController controller) async {
    if (!_isListening) {
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            setState(() => _errorMessage = "Microphone permission is permanently denied. Please enable it in Settings.");
            await openAppSettings();
          } else {
            setState(() => _errorMessage = "Microphone permission is required to use speech-to-text.");
          }
          return;
        }
      }

      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'notListening' || val == 'done') {
            setState(() {
              _isListening = false;
              _activeQuestion = 0;
            });
          }
        },
        onError: (val) {
          setState(() {
            _isListening = false;
            _activeQuestion = 0;
          });
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _activeQuestion = questionNumber;
          _errorMessage = null;
        });
        
        String currentText = controller.text;
        if (currentText.isNotEmpty && !currentText.endsWith(' ')) {
          currentText += ' ';
        }

        String lastRecognized = "";

        _speech.listen(
          listenMode: stt.ListenMode.dictation,
          onResult: (val) {
            if (val.recognizedWords.isNotEmpty) {
              setState(() {
                if (lastRecognized.isNotEmpty && !val.recognizedWords.startsWith(lastRecognized)) {
                   currentText = currentText + lastRecognized + " ";
                }
                lastRecognized = val.recognizedWords;
                String newText = currentText + val.recognizedWords;
                controller.text = newText;
                controller.selection = TextSelection.fromPosition(TextPosition(offset: newText.length));
              });
            }
          },
          pauseFor: const Duration(seconds: 15),
          listenFor: const Duration(minutes: 3),
        );
      } else {
        setState(() => _errorMessage = "Speech recognition is not available on this device.");
      }
    } else {
      setState(() {
        _isListening = false;
        _activeQuestion = 0;
      });
      _speech.stop();
    }
  }

  Future<void> _submitFeedback() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (_rating == 0) {
      setState(() {
        _errorMessage = 'Please provide a star rating.';
      });
      return;
    }

    if (widget.mode == 'text' && _feedbackController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please provide your feedback.';
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      setState(() {
        _errorMessage = 'You must be logged in to submit feedback.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> feedbackData = {
        'mode': widget.mode,
      };

      if (widget.mode == 'text') {
        feedbackData['question_1'] = 'General Feedback';
        feedbackData['answer_1'] = _feedbackController.text.trim();
      }
      
      final String feedbackJson = jsonEncode(feedbackData);

      FormData formData = FormData.fromMap({
        'user_id': user.id,
        'rating': _rating,
        'feedback_text': feedbackJson,
        if (widget.eventId != null) 'event_id': widget.eventId,
      });

      if (widget.mediaFile != null) {
        String filename = widget.mode == 'video' ? 'video.mp4' : 'audio.m4a';
        formData.files.add(MapEntry(
          'video',
          await MultipartFile.fromFile(widget.mediaFile!.path, filename: filename),
        ));
      }

      print('Submitting formData: ${formData.fields}');

      final response = await ApiService.post('/feedback/submit.php', data: formData, includeAuth: false);

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        authProvider.markFeedbackSubmitted();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you! Your feedback has been submitted.'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/home');
        }
      } else {
        setState(() {
          _errorMessage = response.data['message'] ?? 'Failed to submit feedback.';
        });
      }
    } catch (e) {
      String errorMsg = 'An error occurred. Please try again later.';
      if (e is DioException) {
        if (e.response != null) {
          if (e.response?.data is Map && e.response?.data['message'] != null) {
            errorMsg = e.response?.data['message'];
          } else {
            errorMsg = 'Server error (${e.response?.statusCode}). Please check upload limits if sending video.';
          }
        } else {
          errorMsg = 'Connection error: ${e.message}';
        }
      } else {
        errorMsg = 'Unknown error: $e';
      }
      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 40,
          ),
          onPressed: () {
            setState(() {
              _rating = index + 1;
            });
          },
        );
      }),
    );
  }

  Widget _buildQuestionCard(String question, TextEditingController controller, int qNumber) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: null,
              minLines: 4,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: 'Type here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSuccessCard(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your thoughts have been recorded.\nPlease provide your overall rating below.',
            style: TextStyle(fontSize: 15, color: Color(0xFF2E7D32), height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Your Feedback'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'We value your insights!',
              style: TextStyle(
                fontSize: 26, 
                fontWeight: FontWeight.w800, 
                color: AppConfig.primaryColor,
                fontFamily: 'Georgia',
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (widget.mode == 'text') ...[
              const Text(
                'Please share your thoughts below to help us improve.',
                style: TextStyle(fontSize: 16, color: Color(0xFF666666), letterSpacing: 0.2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildQuestionCard('Your Feedback', _feedbackController, 1),
              const SizedBox(height: 32),
            ] else if (widget.mode == 'video') ...[
              const SizedBox(height: 12),
              _buildMediaSuccessCard('Video Attached Successfully!', Icons.video_camera_back),
              const SizedBox(height: 40),
            ] else if (widget.mode == 'audio') ...[
              const SizedBox(height: 12),
              _buildMediaSuccessCard('Audio Attached Successfully!', Icons.mic),
              const SizedBox(height: 40),
            ],
            
            const Text(
              'How would you rate your overall experience?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildStarRating(),
            
            const SizedBox(height: 40),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.green.shade50,
                child: Text(
                  _successMessage!,
                  style: TextStyle(color: Colors.green.shade900),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ElevatedButton(
                onPressed: _isLoading ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Feedback',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
