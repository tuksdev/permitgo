// lib/screens/applications_timeline.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services.dart';
import '../pages/application.dart'; // ApplicationFormScreen
//import 'payment.dart'; // PaymentScreen
import '../pages/certification.dart'; // MayorsPermitPage
import 'dart:async';

class ApplicationModel {
  final int applicationId;
  final String businessName;
  final String applicationType; // 'New Application' | 'Renewal' ...
  final String status; // e.g. 'Draft','Pending Review','Ready for Payment','Payment Received','Completed','Approved'
  final String? date; // optional ISO string or display date
  final double progress; // 0.0 - 1.0

  ApplicationModel({
    required this.applicationId,
    required this.businessName,
    required this.applicationType,
    required this.status,
    this.date,
    required this.progress,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> j) {
    // Defensive parsing — adapt to your backend JSON shape
    final rawStatus = (j['status'] ?? '').toString();
    double mapProgress(String s) {
      switch (s) {
        case 'Draft':
          return 0.1;
        case 'Pending Review':
        case 'Ready for Tax Assessment':
          return 0.35;
        case 'Ready for Payment':
        case 'Pay to the Treasury Office':
          return 0.6;
        case 'Payment Received':
        case 'Payment Confirmed':
          return 0.9;
        case 'Completed':
          return 1.0;
        default:
          return 0.2;
      }
    }

    return ApplicationModel(
      applicationId: int.tryParse(j['application_id']?.toString() ?? '') ?? (j['application_id'] is int ? j['application_id'] : 0),
      businessName: j['businessName']?.toString() ?? j['business_name']?.toString() ?? 'Unknown Business',
      applicationType: j['application_type']?.toString() ?? 'Unknown',
      status: rawStatus,
      date: j['application_date']?.toString() ?? j['date_paid']?.toString(),
      progress: mapProgress(rawStatus),
    );
  }
}

class ApplicationsTimelineWidget extends StatefulWidget {
  final String? userId; // optional; will read from SharedPreferences if null
  const ApplicationsTimelineWidget({Key? key, this.userId}) : super(key: key);

  @override
  State<ApplicationsTimelineWidget> createState() => _ApplicationsTimelineWidgetState();
}

class _ApplicationsTimelineWidgetState extends State<ApplicationsTimelineWidget> {
  bool _loading = true;
  String? _error;
  List<ApplicationModel> _apps = [];
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    try {
      if (widget.userId != null) {
        _userId = widget.userId;
      } else {
        final prefs = await SharedPreferences.getInstance();
        _userId = prefs.getString('user_id');
      }

      if (_userId == null) {
        setState(() {
          _error = 'User not logged in.';
          _loading = false;
        });
        return;
      }
      await _loadApplications();
    } catch (e) {
      setState(() {
        _error = 'Initialization error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadApplications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ApiService.fetchUserApplications(_userId!);
      // ApiService.fetchUserApplications returns List<dynamic> or throws
      List<ApplicationModel> items = raw.map<ApplicationModel>((item) {
        if (item is Map<String, dynamic>) return ApplicationModel.fromJson(item);
        return ApplicationModel.fromJson(Map<String, dynamic>.from(item));
      }).toList();

      // Sort newest first by applicationId or date if you prefer
      items.sort((a, b) => b.applicationId.compareTo(a.applicationId));

      setState(() {
        _apps = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onContinue(ApplicationModel app) {
    // Map status to destination
    final status = app.status;
    Widget dest;
    if (status == 'Draft' || status == 'Pending Review' || status == 'Ready for Tax Assessment' || status == 'Pending Documents') {
      dest = ApplicationFormScreen(applicationId: app.applicationId.toString());
    } else if (status == 'Payment Received' || status == 'Payment Confirmed' || status == 'Completed') {
      dest = MayorsPermitPage(applicationId: app.applicationId.toString());
    } else {
      // fallback
      dest = ApplicationFormScreen(applicationId: app.applicationId.toString());
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => dest));
  }

  Widget _buildCard(ApplicationModel a) {
    final color = (a.status == 'Payment Confirmed' || a.status == 'Completed')
        ? Colors.green
        : (a.status == 'Pay to the Treasury Office' || a.status == 'Ready for Payment')
            ? Colors.red
            : Colors.blueGrey;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: title + type
            Row(
              children: [
                Icon(Icons.storefront, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${a.businessName}  •  ${a.applicationType}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Text('#${a.applicationId}', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            // Status + Date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(a.status, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                if (a.date != null)
                  Text(a.date!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            LinearProgressIndicator(
              value: a.progress,
              backgroundColor: Colors.grey[300],
              color: color,
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            // Buttons row
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _onContinue(a),
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1A2B47)),
                  child: Text(a.progress >= 1.0 ? 'View' : 'Continue'),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () {
                    // Quick refresh single app (reload overall list)
                    _loadApplications();
                  },
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A2B47)));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadApplications,
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1A2B47)),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No applications yet', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplicationFormScreen())),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1A2B47)),
              child: const Text('Start New Application'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      color: const Color(0xFF1A2B47),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _apps.length,
        itemBuilder: (_, i) => _buildCard(_apps[i]),
      ),
    );
  }
}
