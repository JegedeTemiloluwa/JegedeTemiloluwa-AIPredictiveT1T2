import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prediction_model.dart';
import 'package:intl/intl.dart';
import '../widgets/screenshot_wrapper.dart';

class ResultScreen extends StatefulWidget {
  final PredictionResponse response;
  final bool fromHistory;

  const ResultScreen({
    super.key, 
    required this.response, 
    this.fromHistory = false,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GlobalKey _screenshotKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ScreenshotWrapper(
      screenName: 'result_details',
      boundaryKey: _screenshotKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text('AI Analysis Result', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(widget.fromHistory ? Icons.arrow_back : Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          child: RepaintBoundary(
            key: _screenshotKey,
            child: Container(
              color: const Color(0xFF0F172A),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildDiagnosisCard(context),
                  const SizedBox(height: 24),
                  _buildConfidenceSection(context),
                  const SizedBox(height: 24),
                  _buildRecommendationCard(context),
                  if (widget.response.scientificDisclaimer != null && widget.response.scientificDisclaimer!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildDisclaimerCard(context),
                  ],
                  const SizedBox(height: 16),
                  if (widget.response.modelVersion != null)
                    Text(
                      'Model: ${widget.response.modelVersion}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11),
                    ),
                  const SizedBox(height: 32),
                  if (!widget.fromHistory)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosisCard(BuildContext context) {
    Color statusColor;
    IconData icon;
    
    switch (widget.response.diagnosis) {
      case 'Healthy': 
        statusColor = Colors.greenAccent; 
        icon = Icons.check_circle_outline;
        break;
      case 'At Risk': 
        statusColor = Colors.orangeAccent; 
        icon = Icons.warning_amber_rounded;
        break;
      default: 
        statusColor = Colors.redAccent; 
        icon = Icons.dangerous_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withValues(alpha: 0.2), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 80, color: statusColor),
          const SizedBox(height: 24),
          Text(
            widget.response.diagnosis,
            style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: statusColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Stage: ${widget.response.stage}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing date: ${DateFormat('MMMM dd, yyyy').format(widget.response.timestamp)}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Confidence Level',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...widget.response.confidence.entries.map((e) => _buildConfidenceBar(context, e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar(BuildContext context, String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              Text('${value.toStringAsFixed(1)}%', style: TextStyle(color: Theme.of(context).primaryColor)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              color: value > 50 ? Theme.of(context).primaryColor : Colors.white.withValues(alpha: 0.2),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              Text(
                'Recommendation',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.response.recommendation,
            style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: Colors.amber.withValues(alpha: 0.7), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clinical Note',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.response.scientificDisclaimer!,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
