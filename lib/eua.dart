import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';



class MyApp extends StatelessWidget {
  final bool eulaAccepted;
  const MyApp({super.key, required this.eulaAccepted});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EULA Gate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: eulaAccepted ? const HomeScreen() : const EulaScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EulaScreen extends StatefulWidget {
  const EulaScreen({super.key});

  @override
  State<EulaScreen> createState() => _EulaScreenState();
}

class _EulaScreenState extends State<EulaScreen> {
  bool _agree = false;
  bool _loading = false;

  Future<void> _accept() async {
    if (!_agree) {
      _showMustAgreeDialog();
      return;
    }
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('eula_accepted', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showMustAgreeDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Consent required'),
        content: const Text(
          'To use this app, you must accept the terms of the End User License Agreement (EULA).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _decline() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('You declined the terms'),
        content: const Text(
          'You cannot use the app without accepting the EULA. '
              'You may close the app or go back and accept the terms.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('End User License Agreement (EULA)'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Terms of Use (EULA)',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '1. Acceptance of Terms\n'
                            'By using this application, you acknowledge that you have read, understood, and agree to be bound by this End User License Agreement (EULA). '
                            'If you do not agree, you may not use the application.\n',
                      ),
                      SizedBox(height: 8),
                      Text(
                        '2. Zero Tolerance for Objectionable Content and Abusive Users\n'
                            'This app enforces a zero-tolerance policy for:\n'
                            '- harassment, threats, hate speech, or bullying;\n'
                            '- violent, sexually explicit, shocking, or discriminatory content;\n'
                            '- spam, fraud, or attempts to circumvent moderation.\n'
                            'Violations may result in content removal and/or access restrictions or account bans without prior notice.',
                      ),
                      SizedBox(height: 8),
                      Text(
                        '3. User Conduct\n'
                            'You agree to comply with applicable laws and regulations, respect other users, and refrain from actions that may cause harm or disrupt the service.',
                      ),
                      SizedBox(height: 8),
                      Text(
                        '4. Content and Moderation\n'
                            'We reserve the right to remove content and restrict access in case of policy violations and to report information to competent authorities when required by law.',
                      ),
                      SizedBox(height: 8),
                      Text(
                        '5. Limitation of Liability\n'
                            'The app is provided “as is.” The developer is not liable for indirect damages arising from the use or inability to use the app.',
                      ),
                      SizedBox(height: 8),
                      Text(
                        '6. Changes to Terms\n'
                            'These terms may be updated periodically. Continuing to use the app after an update constitutes acceptance of the revised terms.',
                      ),
                      SizedBox(height: 8),
                      Text(
                        '7. Contact\n'
                            'For questions or to report objectionable content or abusive users, contact: support@example.com.',
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _agree,
                    onChanged: (v) => setState(() => _agree = v ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'I have read and accept the EULA, including the zero-tolerance policy for objectionable content and abusive behavior.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : _decline,
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _loading ? null : _accept,
                      child: _loading
                          ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Welcome! Terms accepted.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                // Test reset button to simulate first launch again
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('eula_accepted');
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const EulaScreen()),
                        (route) => false,
                  );
                }
              },
              child: const Text('Reset acceptance (test)'),
            ),
          ],
        ),
      ),
    );
  }
}