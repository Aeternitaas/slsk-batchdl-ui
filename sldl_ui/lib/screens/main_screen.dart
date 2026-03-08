import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sldl_config.dart';
import '../providers/app_provider.dart';
import '../widgets/download_queue_widget.dart';
import '../widgets/input_panel_widget.dart';
import '../widgets/name_format_builder.dart';
import '../widgets/login_dialog.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    await provider.initialize();

    // Register callbacks for login re-prompt
    provider.onConnectionLost = () {
      if (mounted) {
        LoginDialog.show(context,
            isDismissible: true,
            errorMessage: 'Connection to Soulseek was lost. Please re-enter credentials.');
      }
    };

    // Show login dialog if no credentials are configured
    if (!provider.hasCredentials) {
      if (mounted) {
        LoginDialog.show(context, isDismissible: false);
      }
    }

    // Warn if sldl executable not found
    if (provider.sldlExecutablePath == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'sldl executable not found. Please set the path in Settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: _openSettings,
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.headphones, size: 22),
            SizedBox(width: 8),
            Text('sldl UI'),
          ],
        ),
        actions: [
          // Connection status indicator
          _ConnectionStatusChip(status: provider.connectionStatus),
          const SizedBox(width: 4),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Input area
          Container(
            color: theme.colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InputPanelWidget(
                  onSubmit: (item) {
                    final p = context.read<AppProvider>();
                    if (!p.hasCredentials) {
                      LoginDialog.show(context, isDismissible: false);
                      return;
                    }
                    p.enqueue(item);
                  },
                ),
                const SizedBox(height: 12),
                // Name format builder lives on the main screen per requirements
                _NameFormatSection(),
                const SizedBox(height: 4),
                _FileConditionsSection(),
              ],
            ),
          ),

          // Download queue
          Expanded(
            child: const DownloadQueueWidget(),
          ),
        ],
      ),
    );
  }
}

class _NameFormatSection extends StatefulWidget {
  @override
  State<_NameFormatSection> createState() => _NameFormatSectionState();
}

class _NameFormatSectionState extends State<_NameFormatSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.label_outline,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('File Name Format',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                if (provider.config.nameFormat != null &&
                    provider.config.nameFormat!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    provider.config.nameFormat!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: NameFormatBuilder(
              initialValue: provider.config.nameFormat ?? '',
              label: 'Global Name Format',
              hint: 'e.g. {artist( - )title|slsk-filename}',
              onChanged: (value) {
                provider.config.nameFormat = value.isEmpty ? null : value;
              },
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// File Conditions collapsible section
// ─────────────────────────────────────────────────────────────────────────────

class _FileConditionsSection extends StatefulWidget {
  @override
  State<_FileConditionsSection> createState() => _FileConditionsSectionState();
}

class _FileConditionsSectionState extends State<_FileConditionsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final config = provider.config;
    final theme = Theme.of(context);

    final summaryParts = <String>[];
    if (config.format != null && config.format!.isNotEmpty) {
      summaryParts.add(config.format!);
    }
    if (config.prefFormat != null && config.prefFormat!.isNotEmpty) {
      summaryParts.add('pref:${config.prefFormat}');
    }
    if (config.minBitrate != null) summaryParts.add('≥${config.minBitrate}kbps');
    if (config.maxBitrate != null) summaryParts.add('≤${config.maxBitrate}kbps');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.filter_list,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('File Conditions',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                if (summaryParts.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summaryParts.join(', '),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _FileConditionsContent(config: config),
          ),
      ],
    );
  }
}

class _FileConditionsContent extends StatelessWidget {
  final SldlConfig config;
  const _FileConditionsContent({required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _condSubLabel(context, 'Required'),
        const SizedBox(height: 6),
        _condTextField('Format', config.format,
            (v) => config.format = v.isEmpty ? null : v,
            hint: 'mp3,flac,ogg,m4a,opus,wav,aac,alac'),
        _condMinMaxRow(context, 'Bitrate (kbps)', config.minBitrate,
            config.maxBitrate,
            (v) => config.minBitrate = v, (v) => config.maxBitrate = v),
        _condMinMaxRow(context, 'Sample Rate (Hz)', config.minSamplerate,
            config.maxSamplerate,
            (v) => config.minSamplerate = v, (v) => config.maxSamplerate = v),
        _condMinMaxRow(context, 'Bit Depth', config.minBitdepth,
            config.maxBitdepth,
            (v) => config.minBitdepth = v, (v) => config.maxBitdepth = v),
        _condTextField('Length Tolerance (sec)', config.lengthTol?.toString(),
            (v) => config.lengthTol = v.isEmpty ? null : int.tryParse(v),
            keyboardType: TextInputType.number),
        const SizedBox(height: 2),
        _condToggle(context, 'Strict Title', config.strictTitle ?? false,
            (v) => config.strictTitle = v ? true : null),
        _condToggle(context, 'Strict Artist', config.strictArtist ?? false,
            (v) => config.strictArtist = v ? true : null),
        _condToggle(context, 'Strict Album', config.strictAlbum ?? false,
            (v) => config.strictAlbum = v ? true : null),
        _condToggle(context, 'Strict Conditions',
            config.strictConditions ?? false,
            (v) => config.strictConditions = v ? true : null),
        _condTextField('Banned Users', config.bannedUsers,
            (v) => config.bannedUsers = v.isEmpty ? null : v,
            hint: 'user1,user2'),
        const SizedBox(height: 8),
        _condSubLabel(context, 'Preferred'),
        const SizedBox(height: 6),
        _condTextField('Format', config.prefFormat,
            (v) => config.prefFormat = v.isEmpty ? null : v,
            hint: 'mp3'),
        _condMinMaxRow(context, 'Bitrate (kbps)', config.prefMinBitrate,
            config.prefMaxBitrate,
            (v) => config.prefMinBitrate = v, (v) => config.prefMaxBitrate = v),
        _condMinMaxRow(context, 'Sample Rate (Hz)', config.prefMinSamplerate,
            config.prefMaxSamplerate,
            (v) => config.prefMinSamplerate = v,
            (v) => config.prefMaxSamplerate = v),
        _condMinMaxRow(context, 'Bit Depth', config.prefMinBitdepth,
            config.prefMaxBitdepth,
            (v) => config.prefMinBitdepth = v,
            (v) => config.prefMaxBitdepth = v),
        _condTextField('Length Tolerance (sec)',
            config.prefLengthTol?.toString(),
            (v) => config.prefLengthTol = v.isEmpty ? null : int.tryParse(v),
            keyboardType: TextInputType.number),
        _condTextField('Preferred Banned Users', config.prefBannedUsers,
            (v) => config.prefBannedUsers = v.isEmpty ? null : v,
            hint: 'user1,user2'),
      ],
    );
  }
}

Widget _condSubLabel(BuildContext context, String text) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        )),
  );
}

Widget _condTextField(
  String label,
  String? value,
  ValueChanged<String> onChanged, {
  String? hint,
  TextInputType? keyboardType,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextFormField(
      initialValue: value ?? '',
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      keyboardType: keyboardType,
      onChanged: onChanged,
    ),
  );
}

Widget _condMinMaxRow(
  BuildContext context,
  String label,
  int? minVal,
  int? maxVal,
  ValueChanged<int?> onMin,
  ValueChanged<int?> onMax,
) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: minVal?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Min',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => onMin(v.isEmpty ? null : int.tryParse(v)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: maxVal?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Max',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => onMax(v.isEmpty ? null : int.tryParse(v)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _condToggle(
  BuildContext context,
  String label,
  bool value,
  ValueChanged<bool> onChanged,
) {
  final theme = Theme.of(context);
  return InkWell(
    onTap: () => onChanged(!value),
    borderRadius: BorderRadius.circular(4),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _ConnectionStatusChip extends StatelessWidget {
  final ConnectionStatus status;
  const _ConnectionStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (label, color, icon) = switch (status) {
      ConnectionStatus.unknown => ('Not Connected', theme.colorScheme.onSurfaceVariant, Icons.radio_button_unchecked),
      ConnectionStatus.connecting => ('Connecting…', Colors.orange, Icons.sync),
      ConnectionStatus.connected => ('Connected', Colors.green, Icons.radio_button_checked),
      ConnectionStatus.failed => ('Login Failed', theme.colorScheme.error, Icons.error_outline),
    };

    return Tooltip(
      message: 'Soulseek connection status',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}
