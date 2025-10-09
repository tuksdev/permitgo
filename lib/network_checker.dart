import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkChecker extends StatefulWidget {
  final Widget child;
  const NetworkChecker({super.key, required this.child});

  @override
  State<NetworkChecker> createState() => _NetworkCheckerState();
}

class _NetworkCheckerState extends State<NetworkChecker> {
  bool _isOffline = false;
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((status) {
      setState(() {
        _isOffline = (status == ConnectivityResult.none);
      });
    });

    // Check initial state
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    var status = await _connectivity.checkConnectivity();
    setState(() {
      _isOffline = (status == ConnectivityResult.none);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child, // ✅ Your app continues normally (navigation works)
        if (_isOffline)
          Positioned.fill( // 👈 Overlay on top, doesn't block routes
            child: IgnorePointer( // Allow navigation gestures but show popup
              ignoring: true,
              child: Container(
                color: Colors.black45,
              ),
            ),
          ),
        if (_isOffline)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Card(
                color: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.wifi_off, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "You are offline. Please check your internet connection.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
