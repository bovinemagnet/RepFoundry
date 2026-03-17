import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/generated/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _gitHubUrl = 'https://github.com/bovinemagnet/RepFoundry';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.aboutScreenTitle)),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.data?.version ?? '1.0.0';
          final buildNumber = snapshot.data?.buildNumber ?? '';
          final versionDisplay =
              buildNumber.isNotEmpty ? '$version+$buildNumber' : version;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              // App icon and name
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.aboutAppName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.aboutVersion(versionDisplay),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        s.aboutDescription,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),

              // Author
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(s.aboutAuthorLabel),
                subtitle: Text(s.aboutAuthor),
              ),

              // GitHub
              ListTile(
                leading: const Icon(Icons.code),
                title: Text(s.aboutGitHub),
                subtitle: const Text(_gitHubUrl),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openUrl(_gitHubUrl),
              ),

              const Divider(),

              // Features
              _SectionHeader(title: s.aboutFeatures),
              _FeatureTile(
                icon: Icons.cloud_off,
                text: s.aboutFeatureOffline,
              ),
              _FeatureTile(
                icon: Icons.monitor_heart_outlined,
                text: s.aboutFeatureHeartRate,
              ),
              _FeatureTile(
                icon: Icons.library_books_outlined,
                text: s.aboutFeatureTemplates,
              ),
              _FeatureTile(
                icon: Icons.trending_up,
                text: s.aboutFeatureProgress,
              ),
              _FeatureTile(
                icon: Icons.file_download_outlined,
                text: s.aboutFeatureExport,
              ),
              _FeatureTile(
                icon: Icons.directions_run,
                text: s.aboutFeatureCardio,
              ),

              const Divider(),

              // Built with
              ListTile(
                leading: const Icon(Icons.build_outlined),
                title: Text(s.aboutBuiltWith),
              ),

              // Licences
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(s.aboutViewLicences),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: s.aboutAppName,
                  applicationVersion: versionDisplay,
                  applicationIcon: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.fitness_center,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
