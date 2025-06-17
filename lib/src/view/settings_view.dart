import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _licenseText = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadLicense();
  }

  Future<void> _loadLicense() async {
    final license = await rootBundle.loadString('LICENSE');
    if (mounted) {
      setState(() {
        _licenseText = license;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: Text(
          'Settings',
          style: FluentTheme.of(context).typography.title,
        ),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      content: ScaffoldPage(
        header: const PageHeader(
          title: Text('About this app'),
        ),
        content: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: [
            const Text(
              'Gemini App for Windows',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta aplicación es un cliente de escritorio nativo para Windows que permite interactuar con la API de Gemini de Google. Fue creada por David Menéndez Acosta utilizando el framework Flutter y la librería Fluent UI para ofrecer una experiencia de usuario nativa.',
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Contact',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(FluentIcons.link),
              title: const Text('LinkedIn'),
              subtitle: const Text('Connect with me'),
              onPressed: () =>
                  _launchUrl('https://www.linkedin.com/in/davidmenendez9901/'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(FluentIcons.send),
              title: const Text('Telegram'),
              subtitle: const Text('Send me a message'),
              onPressed: () => _launchUrl('https://t.me/davidmenendez9901'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Expander(
              header: Text(
                'License',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              content: Container(
                height: 250,
                padding: const EdgeInsets.only(top: 8.0),
                child: SingleChildScrollView(
                  child: Text(_licenseText),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
} 