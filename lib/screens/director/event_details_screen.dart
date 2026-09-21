import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../models/event_model.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isLoadingRoster = true;
  List<dynamic> _roster = [];
  String? _rosterError;

  @override
  void initState() {
    super.initState();
    _fetchRoster();
  }

  Future<void> _fetchRoster() async {
    setState(() {
      _isLoadingRoster = true;
      _rosterError = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/director/get_event_roster.php?event_id=${widget.event.id}'),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _roster = data['data'];
            _isLoadingRoster = false;
          });
        } else {
          setState(() {
            _rosterError = data['message'];
            _isLoadingRoster = false;
          });
        }
      } else {
        setState(() {
          _rosterError = 'Failed to load roster. Status: ${response.statusCode}';
          _isLoadingRoster = false;
        });
      }
    } catch (e) {
      setState(() {
        _rosterError = 'Error loading roster: $e';
        _isLoadingRoster = false;
      });
    }
  }

  Future<void> _printQRCode() async {
    final qrData = 'GMU_EVENT_REGISTRATION:${widget.event.id}';
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  widget.event.title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Scan this QR code using the GMU Alumni App to register for the event.',
                  style: const pw.TextStyle(
                    fontSize: 14,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 30),
                pw.BarcodeWidget(
                  data: qrData,
                  barcode: pw.Barcode.qrCode(),
                  width: 250,
                  height: 250,
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  DateFormat('MMM dd, yyyy').format(widget.event.eventDate),
                  style: const pw.TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Event_QR_${widget.event.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrData = 'GMU_EVENT_REGISTRATION:${widget.event.id}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: AppConfig.primaryColor,
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(text: 'Overview & QR'),
                  Tab(text: 'Registrations'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Overview & QR
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.event.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMMM dd, yyyy - hh:mm a').format(widget.event.eventDate),
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                          ],
                        ),
                        if (widget.event.location != null && widget.event.location!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                widget.event.location!,
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Event QR Code',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Print and display this QR code at the event entrance for alumni to scan.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 200.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _printQRCode,
                          icon: const Icon(Icons.print),
                          label: const Text('Print / Save QR Code'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConfig.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tab 2: Registrations
                  _buildRosterTab(),
                ],
              ),
            ),
          ],
        ),
      ),

    );
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alumni Details', style: TextStyle(color: AppConfig.primaryColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Name', data['name']?.toString() ?? 'N/A'),
            _detailRow('USN', data['usn']?.toString() ?? 'N/A'),
            _detailRow('Branch', data['branch']?.toString() ?? 'N/A'),
            _detailRow('Batch', data['batch']?.toString() ?? 'N/A'),
            _detailRow('Phone', data['phone']?.toString() ?? 'N/A'),
            _detailRow('Position', data['current_position']?.toString() ?? 'N/A'),
            _detailRow('Institute', data['institute']?.toString() ?? 'N/A'),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildRosterTab() {
    if (_isLoadingRoster) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_rosterError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _rosterError!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchRoster,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_roster.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No registrations yet.',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: Colors.grey[100],
          child: Row(
            children: [
              Text(
                'Total Registered: ${_roster.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchRoster,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _roster.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final registration = _roster[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppConfig.secondaryColor,
                  child: Text(
                    (registration['name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: AppConfig.primaryColor),
                  ),
                ),
                title: GestureDetector(
                  onTap: () => _showStudentDetails(context, registration),
                  child: Text(
                    registration['name'] ?? 'Unknown User',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppConfig.primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(registration['usn'] ?? 'N/A'),
                    const SizedBox(height: 4),
                    Text(
                      'Registered: ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(registration['registered_at']))}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
