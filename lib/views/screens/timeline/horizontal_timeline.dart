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

class _HorizontalTimelineState extends State<HorizontalTimeline> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, String> _completedStageIds = {};

  final List<TimelineEvent> allEvents = [
    TimelineEvent(id: 'TKTGEN', title: 'Ticket\nGenerate'),
    TimelineEvent(id: 'MECASS', title: 'Mechanic\nAssigned'),
    TimelineEvent(id: 'ATTPRO', title: 'Attend\nProcess'),
    TimelineEvent(id: 'INVEST', title: 'Vehicle\nInvestigation'),
    TimelineEvent(id: 'ESTIMT', title: 'Estimate\nReceived'),
    TimelineEvent(id: 'ESTACC', title: 'Estimate\nAccepted'),
    TimelineEvent(id: 'REESTM', title: 'Re-estimate'),
    TimelineEvent(id: 'DELRSN', title: 'Delay\nReason'),
    TimelineEvent(id: 'WRKDON', title: 'Work\nDone'),
    TimelineEvent(id: 'FINBIL', title: 'Received\nInvoice'),
    TimelineEvent(id: 'PAYDON', title: 'Payment\nDone'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchTimelineData();
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

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '';
    try {
      DateTime parsed = DateTime.parse(dateTime);
      return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
    } catch (e) {
      return dateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!),
      );
    }

    final lastCompletedId = _completedStageIds.isNotEmpty ? _completedStageIds.keys.last : '';
    final lastCompletedIndex = allEvents.indexWhere((event) => event.id == lastCompletedId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5 ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // scroll
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(allEvents.length, (index) {
            final TimelineEvent event = allEvents[index];
            final bool isCompleted = index < lastCompletedIndex;
            final bool isCurrent = index == lastCompletedIndex;

            Color dotColor;
            Widget dotChild = const SizedBox.shrink();
            List<BoxShadow>? boxShadow;
            BoxBorder? border;

            if (isCompleted) {
              dotColor = AppColors.colGreen;
              dotChild = const Icon(Icons.check, size: 10, color: Colors.white);
            } else if (isCurrent) {
              dotColor = AppColors.colGreen;
              boxShadow = [
                BoxShadow(
                  color: AppColors.colGreen.withOpacity(0.9),
                  blurRadius: 5.0,
                  spreadRadius: 2.0,
                ),
              ];
              border = Border.all(color: AppColors.whitecol, width: 2.0);
            } else {
              dotColor = AppColors.primarycol;
            }

            final eventTime = _completedStageIds[event.id];
            final textColor = isCompleted || isCurrent ? AppColors.colGreen : AppColors.primarycol;
            final lineColor = isCompleted || isCurrent ? AppColors.colGreen : AppColors.primarycol;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Dot
                      Container(
                        width: 19, // Outer circle size (dot + border)
                        height: 19,
                        decoration: BoxDecoration(
                          color: isCurrent ? Colors.white : dotColor, // Outer color is white for running stage
                          shape: BoxShape.circle,
                          boxShadow: boxShadow,
                          border: border,
                        ),
                        child: Center(
                          child: Container(
                            width: 15, // Inner circle size
                            height: 15,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(child: dotChild),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 55),
                        child: InterText(
                          text: event.title,
                          textalign: TextAlign.center,
                          fontsize: 10,
                          fontweight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (eventTime != null)
                        Container(
                          constraints: const BoxConstraints(maxWidth: 55),
                          // child: Text(
                          //   _formatDateTime(eventTime),
                          //   textAlign: TextAlign.center,
                          //   style: const TextStyle(fontSize: 8,
                          //     color: Colors.black45,
                          //   ),
                          // ),
                        ),
                    ],
                  ),
                  if (index < allEvents.length - 1)
                    Container(
                      height: 1, // Corrected to 2 to match the design
                      width: 50,
                      margin: const EdgeInsets.only(top: 8.5, left: 1.0, right:1.0),
                      color: lineColor,
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
  final List<TimelineEvent>? subStages;
  TimelineEvent({
    required this.id,
    required this.title,
    this.time,
    this.subStages,
  });
}