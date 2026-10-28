import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/prediction_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'result_screen.dart';
import '../widgets/screenshot_wrapper.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _screenshotKey = GlobalKey();
  
  // Input controllers
  final _glucoseController = TextEditingController();
  final _bpController = TextEditingController();
  final _insulinController = TextEditingController();
  final _bmiController = TextEditingController();
  final _ageController = TextEditingController();
  final _hbA1cController = TextEditingController();
  
  // Toggles and Selectors
  int _hypertension = 0;
  int _heartDisease = 0;
  int _smoking = 0;
  int _gender = 0;

  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Show Premium Loading Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _PremiumLoadingDialog(),
      );
      
      final api = Provider.of<ApiService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      
      final request = PredictionRequest(
        glucose: double.parse(_glucoseController.text),
        bloodPressure: double.parse(_bpController.text),
        insulin: double.parse(_insulinController.text),
        bmi: double.parse(_bmiController.text),
        age: double.parse(_ageController.text),
        hbA1c: double.parse(_hbA1cController.text),
        hypertension: _hypertension,
        heartDisease: _heartDisease,
        smoking: _smoking,
        gender: _gender,
      );

      try {
        final response = await api.predict(request);
        await storage.savePrediction(response);
        
        if (!mounted) return;
        Navigator.pop(context); // Dismiss loading dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(response: response),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenshotWrapper(
      screenName: 'input_parameters',
      boundaryKey: _screenshotKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text('DiaGuard AI', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: RepaintBoundary(
                key: _screenshotKey,
                child: Container(
                  color: const Color(0xFF0F172A),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Health Parameters',
                          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please fill in your current clinical data for prediction.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 32),
                        
                        _buildSection('Vital Stats'),
                        _buildTextField(_glucoseController, 'Glucose (mg/dL)', Icons.bloodtype_outlined, 'e.g. 95'),
                        _buildTextField(_bpController, 'Blood Pressure (mmHg)', Icons.speed_outlined, 'e.g. 72'),
                        _buildTextField(_insulinController, 'Insulin (μU/mL)', Icons.vaccines_outlined, 'e.g. 80'),
                        _buildTextField(_bmiController, 'BMI (kg/m²)', Icons.monitor_weight_outlined, 'e.g. 23.0'),
                        _buildTextField(_ageController, 'Age (Years)', Icons.person_outline, 'e.g. 30'),
                        _buildTextField(_hbA1cController, 'HbA1c (%)', Icons.biotech_outlined, 'e.g. 5.2'),
                        
                        const SizedBox(height: 24),
                        _buildSection('Medical History'),
                        _buildSwitchRow('Hypertension', _hypertension == 1, (val) => setState(() => _hypertension = val ? 1 : 0)),
                        _buildSwitchRow('Heart Disease', _heartDisease == 1, (val) => setState(() => _heartDisease = val ? 1 : 0)),
                        
                        const SizedBox(height: 24),
                        _buildSection('Personal Details'),
                        _buildDropdown('Smoking History', _smoking, {
                          0: 'Never Smoked', 
                          1: 'No Information', 
                          2: 'Former Smoker',
                          3: 'Ever Smoked',
                          4: 'Currently Smoking'
                        }, (val) => setState(() => _smoking = val!)),
                        _buildDropdown('Gender', _gender, {0: 'Female', 1: 'Male'}, (val) => setState(() => _gender = val!)),
                        
                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading 
                              ? const CircularProgressIndicator(color: Colors.black)
                              : const Text('Analyze with AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        validator: (value) => value!.isEmpty ? 'Field required' : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
      ),
    );
  }

  Widget _buildSwitchRow(String label, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Switch(value: value, onChanged: onChanged, activeThumbColor: Theme.of(context).primaryColor),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, int value, Map<int, String> options, Function(int?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: value,
                isExpanded: true,
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumLoadingDialog extends StatefulWidget {
  const _PremiumLoadingDialog();

  @override
  State<_PremiumLoadingDialog> createState() => _PremiumLoadingDialogState();
}

class _PremiumLoadingDialogState extends State<_PremiumLoadingDialog> {
  int _messageIndex = 0;
  final List<String> _messages = [
    'Initializing AI engine...',
    'Analyzing clinical patterns...',
    'Running Advanced ML models...',
    'Optimizing prediction results...',
    'Generating health insights...',
  ];

  @override
  void initState() {
    super.initState();
    _startMessageCycle();
  }

  void _startMessageCycle() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Theme.of(context).primaryColor,
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                Icon(Icons.auto_awesome_rounded, color: Theme.of(context).primaryColor, size: 32),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'AI is Analyzing...',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 20,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _messages[_messageIndex],
                  key: ValueKey(_messages[_messageIndex]),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
