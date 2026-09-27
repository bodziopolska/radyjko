import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/radio_station.dart';
import '../l10n/app_strings.dart';

class LogoEditorDialog extends StatefulWidget {
  final RadioStation station;
  final String? currentLogo;

  const LogoEditorDialog({
    super.key,
    required this.station,
    this.currentLogo,
  });

  @override
  State<LogoEditorDialog> createState() => _LogoEditorDialogState();
}

class _LogoEditorDialogState extends State<LogoEditorDialog> {
  late TextEditingController _controller;
  String? _previewUrl;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentLogo ?? '');
    _previewUrl = widget.currentLogo;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updatePreview() {
    setState(() {
      _previewUrl = _controller.text;
    });
  }

  void _useClearbit() {
    if (widget.station.homepage.isNotEmpty) {
      try {
        final uri = Uri.parse(widget.station.homepage);
        if (uri.host.isNotEmpty) {
          final clearbitUrl = 'https://logo.clearbit.com/${uri.host}';
          _controller.text = clearbitUrl;
          _updatePreview();
          return;
        }
      } catch (_) {}
    }
    // JeĹ›li siÄ™ nie uda lub brak strony
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Brak poprawnego adresu strony stacji.')),
    );
  }

  Future<void> _searchGoogle() async {
    final query = Uri.encodeComponent('${widget.station.name} radio logo');
    final url = Uri.parse('https://www.google.com/search?tbm=isch&q=$query');
    // Ignorujemy canLaunchUrl, bo Android 11+ blokuje zapytania bez <queries> w manifeście
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) { debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final hasHomepage = widget.station.homepage.isNotEmpty;

    return AlertDialog(
      title: Text(strings.setStationLogo),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_previewUrl != null && _previewUrl!.isNotEmpty) ...[
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _previewUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'https://example.com/logo.png',
                labelText: strings.logoUrl,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _updatePreview,
                  tooltip: 'PodglÄ…d',
                ),
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => _updatePreview(),
            ),
            const SizedBox(height: 24),
            Text('NarzÄ™dzia wyszukiwania:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Pobierz logo ze strony stacji'),
                onPressed: hasHomepage ? _useClearbit : null,
              ),
            ),
            if (!hasHomepage)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Stacja nie udostÄ™pnia adresu WWW', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Szukaj w Google Grafika'),
                onPressed: _searchGoogle,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: Text(strings.removeLogo),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(strings.save),
        ),
      ],
    );
  }
}

