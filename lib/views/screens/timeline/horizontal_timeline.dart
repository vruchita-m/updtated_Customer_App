import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:service_mitra/config/colors/colors.dart';
import 'package:service_mitra/views/widegts/inter_text.dart';

class HorizontalTimeline extends StatefulWidget {
  final String complaintNo;
  const HorizontalTimeline({Key? key, required this.complaintNo}) : super(key: key);

  @override
  _HorizontalTimelineState createState() => _HorizontalTimelineState();
}

class _HorizontalTimelineState extends State<HorizontalTimeline> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, String> _completedStageIds = {};

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  final List<TimelineEvent> allEvents = [
    TimelineEvent(id: 'TKTGEN', title: 'Ticket\nGenerate'),
    TimelineEvent(id: 'MECASS', title: 'Mechanic\nAssigned'),
    TimelineEvent(id: 'ATTPRO', title: 'Attend\nProcess'),
    TimelineEvent(id: 'INVEST', title: 'Vehicle\nInvestigation'),
    TimelineEvent(id: 'ESTIMT', title: 'Estimate\nReceived'),
    TimelineEvent(id: 'ESTACC', title: 'Estimate\nAccepted'),
    TimelineEvent(id: 'REESTM', title: 'Re-\nestimate'),
    TimelineEvent(id: 'DELRSN', title: 'Delay\nReason'),
    TimelineEvent(id: 'WRKDON', title: 'Work\nDone'),
    TimelineEvent(id: 'FINBIL', title: 'Received\nInvoice'),
    TimelineEvent(id: 'PAYDON', title: 'Payment\nDone'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchTimelineData();

    // Initialize glow animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _fetchTimelineData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://13.62.55.246:8000/get-timeline/?ticket_id=${widget.complaintNo}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status_flags'] is List && data['created_at'] is List &&
            data['status_flags'].length == data['created_at'].length) {
          final statusFlags = List<String>.from(data['status_flags']);
          final createdAt = List<String>.from(data['created_at']);
          setState(() {
            _completedStageIds = Map.fromIterables(statusFlags, createdAt);
            _isLoading = false;
          });
        } else {
          throw Exception("Mismatched or invalid API data structure");
        }
      } else {
        setState(() {
          _errorMessage = "Failed to load timeline.";
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = "An error occurred. Check your connection.";
        _isLoading = false;
      });
    }
  }

  double getDotSize(bool isCompleted, bool isCurrent) {
    // Blue/pending dots smaller
    if (!isCompleted && !isCurrent) return 16; // <-- This is the line that sets the size of the blue dot
    return 16; // Completed or current dots
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!));

    final lastCompletedId = _completedStageIds.isNotEmpty ? _completedStageIds.keys.last : '';
    final lastCompletedIndex = allEvents.indexWhere((event) => event.id == lastCompletedId);

    return Padding(
      padding: const EdgeInsets.only(top: 1, bottom: 28), // extra top for glow
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(allEvents.length, (index) {
            final TimelineEvent event = allEvents[index];
            final bool isCompleted = index < lastCompletedIndex;
            final bool isCurrent = index == lastCompletedIndex;

            Color dotColor;
            Widget dotChild = const SizedBox.shrink();

            if (isCompleted) {
              dotColor = AppColors.colGreen;
              dotChild = const Icon(Icons.check, size: 12, color: Colors.white);
            } else if (isCurrent) {
              dotColor = AppColors.colGreen;
            } else {
              dotColor = AppColors.primarycol;
            }

            final textColor = isCompleted || isCurrent ? AppColors.colGreen : AppColors.primarycol;
            final lineColor = isCompleted || isCurrent ? AppColors.colGreen : AppColors.primarycol;

            double dotSize = getDotSize(isCompleted, isCurrent);

            return SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Dot with glow animation for current stage
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          isCurrent
                              ? AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) {
                              return Container(
                                width: dotSize,
                                height: dotSize,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.whitecol, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.colGreen.withOpacity(0.5),
                                      blurRadius: _glowAnimation.value,
                                      spreadRadius: _glowAnimation.value / 2,
                                    ),
                                  ],
                                ),
                                child: Center(child: dotChild),
                              );
                            },
                          )
                              : Container(
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(child: dotChild),
                          ),
                        ],
                      ),
                      // Line after dot
                      Expanded(
                        child: Container(
                          height: 2,
                          color: (index == allEvents.length - 1) ? Colors.transparent : lineColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Stage name left-aligned under dot
                  InterText(
                    text: event.title,
                    textalign: TextAlign.start,
                    fontsize: 11,
                    fontweight: FontWeight.w600,
                    color: textColor,
                    maxLines: 2,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class TimelineEvent {
  final String id;
  final String title;
  final String? time;
  TimelineEvent({
    required this.id,
    required this.title,
    this.time,
  });
}
