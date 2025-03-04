import 'package:collapsible/collapsible.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:saber/components/settings/settings_color.dart';
import 'package:saber/components/settings/settings_dropdown.dart';
import 'package:saber/components/settings/settings_selection.dart';
import 'package:saber/components/settings/settings_switch.dart';

import 'package:saber/components/settings/nextcloud_profile.dart';
import 'package:saber/components/settings/app_info.dart';
import 'package:saber/components/settings/update_manager.dart';
import 'package:saber/components/theming/adaptive_alert_dialog.dart';
import 'package:saber/components/theming/adaptive_toggle_buttons.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/locales.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/i18n/strings.g.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();

  static Future<bool?> showResetDialog({
    required BuildContext context,
    required IPref pref,
    required String prefTitle,
  }) async {
    if (pref.value == pref.defaultValue) return null;
    return await showDialog(
      context: context,
      builder: (context) => AdaptiveAlertDialog(
        title: Text(t.settings.reset.title),
        content: Text(prefTitle),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              pref.value = pref.defaultValue;
              Navigator.of(context).pop(true);
            },
            child: Text(t.settings.reset.button),
          ),
        ],
      ),
    );
  }
}

abstract class _SettingsPrefs {
  static final appTheme = TransformedPref(
    Prefs.appTheme,
    (ThemeMode value) => value.index,
    (int value) => ThemeMode.values[value],
  );

  static final platform = TransformedPref(
    Prefs.platform,
    (TargetPlatform value) => value.index,
    (int value) => TargetPlatform.values[value],
  );

  static final shouldAlwaysAlertForUpdates = TransformedPref(
    Prefs.updatesToIgnore,
    (int value) => value <= 0,
    (bool value) => value ? 0 : 1,
  );

  static final editorToolbarAlignment = TransformedPref(
    Prefs.editorToolbarAlignment,
    (AxisDirection value) => value.index,
    (int value) => AxisDirection.values[value],
  );
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    Prefs.locale.addListener(onChanged);
    UpdateManager.status.addListener(onChanged);
    super.initState();
  }

  void onChanged() {
    setState(() {});
  }

  static final bool usesMaterialByDefault = () {
    if (defaultTargetPlatform == TargetPlatform.iOS) return false;
    if (defaultTargetPlatform == TargetPlatform.macOS) return false;
    return true;
  }();

  static const cupertinoDirectionIcons = [
    CupertinoIcons.arrow_up_to_line,
    CupertinoIcons.arrow_right_to_line,
    CupertinoIcons.arrow_down_to_line,
    CupertinoIcons.arrow_left_to_line,
  ];
  static const materialDirectionIcons = [
    Icons.north,
    Icons.east,
    Icons.south,
    Icons.west,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final platform = Theme.of(context).platform;
    final cupertino = platform == TargetPlatform.iOS
        || platform == TargetPlatform.macOS;

    final bool requiresManualUpdates = FlavorConfig.appStore == null;

    final IconData materialIcon = () {
      if (defaultTargetPlatform == TargetPlatform.linux) return FontAwesomeIcons.linux;
      if (defaultTargetPlatform == TargetPlatform.windows) return FontAwesomeIcons.windows;
      return Icons.android;
    }();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            collapsedHeight: kToolbarHeight,
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                t.home.titles.settings,
                style: TextStyle(color: colorScheme.onBackground),
              ),
              centerTitle: cupertino,
              titlePadding: EdgeInsetsDirectional.only(
                start: cupertino ? 0 : 16,
                bottom: 16,
              ),
            ),
            actions: [
              if (UpdateManager.status.value != UpdateStatus.upToDate) IconButton(
                tooltip: t.home.tooltips.showUpdateDialog,
                icon: const Icon(Icons.system_update),
                onPressed: () {
                  UpdateManager.showUpdateDialog(context, userTriggered: true);
                },
              ),
            ],
          ),
          SliverSafeArea(sliver: SliverToBoxAdapter(
            child: Column(children: [
              const NextcloudProfile(),
              const Padding(
                padding: EdgeInsets.all(8),
                child: AppInfo(),
              ),
              ExpansionTile(
                initiallyExpanded: true,
                leading: const Icon(Icons.app_settings_alt),
                title: Text(t.settings.prefCategories.general),
                shape: Border.all(color: Colors.transparent),
                children: [
                  SettingsDropdown(
                    title: t.settings.prefLabels.locale,
                    icon: cupertino ? CupertinoIcons.globe : Icons.language,
                    pref: Prefs.locale,
                    options: [
                      ToggleButtonsOption("", Text(t.settings.systemLanguage)),
                      ...AppLocaleUtils.supportedLocales.map((locale) {
                        final String localeCode = locale.toLanguageTag();
                        String? localeName = localeNames[localeCode];
                        assert(localeName != null, "Missing locale name for $localeCode");
                        return ToggleButtonsOption(
                          localeCode,
                          Text(localeName ?? localeCode),
                        );
                      }),
                    ],
                  ),
                  SettingsSelection(
                    title: t.settings.prefLabels.appTheme,
                    iconBuilder: (i) {
                      if (i == ThemeMode.system.index) return Icons.brightness_auto;
                      if (i == ThemeMode.light.index) return Icons.light_mode;
                      if (i == ThemeMode.dark.index) return Icons.dark_mode;
                      return null;
                    },
                    pref: _SettingsPrefs.appTheme,
                    optionsWidth: 60,
                    options: [
                      ToggleButtonsOption(ThemeMode.system.index, Icon(Icons.brightness_auto, semanticLabel: t.settings.themeModes.system)),
                      ToggleButtonsOption(ThemeMode.light.index, Icon(Icons.light_mode, semanticLabel: t.settings.themeModes.light)),
                      ToggleButtonsOption(ThemeMode.dark.index, Icon(Icons.dark_mode, semanticLabel: t.settings.themeModes.dark)),
                    ],
                  ),
                  SettingsSelection(
                    title: t.settings.prefLabels.platform,
                    iconBuilder: (i) {
                      if (platform == TargetPlatform.iOS) return Icons.apple;
                      if (platform == TargetPlatform.macOS) return Icons.apple;
                      return materialIcon;
                    },
                    pref: _SettingsPrefs.platform,
                    optionsWidth: 60,
                    options: [
                      ToggleButtonsOption(
                        () {
                          if (usesMaterialByDefault) return defaultTargetPlatform.index;
                          return TargetPlatform.android.index;
                        }(),
                        Icon(materialIcon, semanticLabel: "Material"),
                      ),
                      ToggleButtonsOption(
                        () {
                          if (!usesMaterialByDefault) return defaultTargetPlatform.index;
                          return TargetPlatform.iOS.index;
                        }(),
                        const Icon(Icons.apple, semanticLabel: "Cupertino"),
                      ),
                    ],
                  ),
                  SettingsColor(
                    title: t.settings.prefLabels.customAccentColor,
                    icon: Icons.colorize,
                    pref: Prefs.accentColor,
                  ),
                  SettingsSwitch(
                    title: t.settings.prefLabels.hyperlegibleFont,
                    subtitle: t.settings.prefDescriptions.hyperlegibleFont,
                    iconBuilder: (b) {
                      if (b) return cupertino ? CupertinoIcons.textformat : Icons.font_download;
                      return cupertino ? CupertinoIcons.textformat_alt : Icons.font_download_off;
                    },
                    pref: Prefs.hyperlegibleFont,
                  ),
                  if (requiresManualUpdates) ...[
                    SettingsSwitch(
                      title: t.settings.prefLabels.shouldCheckForUpdates,
                      icon: Icons.system_update,
                      pref: Prefs.shouldCheckForUpdates,
                      afterChange: (_) => setState(() {}),
                    ),
                    Collapsible(
                      collapsed: !Prefs.shouldCheckForUpdates.value,
                      axis: CollapsibleAxis.vertical,
                      child: SettingsSwitch(
                        title: t.settings.prefLabels.shouldAlwaysAlertForUpdates,
                        icon: Icons.system_security_update_warning,
                        pref: _SettingsPrefs.shouldAlwaysAlertForUpdates,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
              ExpansionTile(
                initiallyExpanded: true,
                leading: const Icon(Icons.display_settings),
                title: Text(t.settings.prefCategories.layout),
                shape: Border.all(color: Colors.transparent),
                children: [
                  SettingsSelection(
                    title: t.settings.prefLabels.editorToolbarAlignment,
                    subtitle: t.settings.axisDirections[_SettingsPrefs.editorToolbarAlignment.value],
                    iconBuilder: (num i) {
                      if (i is! int || i >= materialDirectionIcons.length) return null;
                      return cupertino ? cupertinoDirectionIcons[i] : materialDirectionIcons[i];
                    },
                    pref: _SettingsPrefs.editorToolbarAlignment,
                    optionsWidth: 60,
                    options: [
                      for (final AxisDirection direction in AxisDirection.values)
                        ToggleButtonsOption(
                          direction.index,
                          Icon(
                            cupertino ? cupertinoDirectionIcons[direction.index] : materialDirectionIcons[direction.index],
                            semanticLabel: t.settings.axisDirections[direction.index],
                          ),
                        ),
                    ],
                    afterChange: (_) => setState(() {}),
                  ),
                  SettingsSwitch(
                    title: t.settings.prefLabels.editorToolbarShowInFullscreen,
                    icon: cupertino ? CupertinoIcons.fullscreen : Icons.fullscreen,
                    pref: Prefs.editorToolbarShowInFullscreen,
                  ),
                  SettingsSwitch(
                    title: t.settings.prefLabels.editorAutoInvert,
                    subtitle: t.settings.prefDescriptions.editorAutoInvert,
                    iconBuilder: (b) {
                      return b ? Icons.invert_colors_on : Icons.invert_colors_off;
                    },
                    pref: Prefs.editorAutoInvert,
                  ),
                  SettingsSwitch(
                    title: t.settings.prefLabels.editorPromptRename,
                    subtitle: t.settings.prefDescriptions.editorPromptRename,
                    iconBuilder: (b) {
                      if (b) return cupertino ? CupertinoIcons.keyboard : Icons.keyboard;
                      return cupertino ? CupertinoIcons.keyboard_chevron_compact_down : Icons.keyboard_hide;
                    },
                    pref: Prefs.editorPromptRename,
                  ),
                  SettingsSwitch(
                    title: t.settings.prefLabels.hideHomeBackgrounds,
                    subtitle: t.settings.prefDescriptions.hideHomeBackgrounds,
                    iconBuilder: (b) {
                      if (b) return cupertino ? CupertinoIcons.photo : Icons.photo;
                      return cupertino ? CupertinoIcons.photo_fill : Icons.photo_library;
                    },
                    pref: Prefs.hideHomeBackgrounds,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              ExpansionTile(
                initiallyExpanded: true,
                leading: const Icon(Icons.brush),
                title: Text(t.settings.prefCategories.writing),
                shape: Border.all(color: Colors.transparent),
                children: [
                  SettingsSwitch(
                    title: t.settings.prefLabels.preferGreyscale,
                    subtitle: t.settings.prefDescriptions.preferGreyscale,
                    iconBuilder: (b) {
                      return b ? Icons.monochrome_photos : Icons.enhance_photo_translate;
                    },
                    pref: Prefs.preferGreyscale,
                  ),
                  SettingsSelection(
                    title: t.settings.prefLabels.editorStraightenLines,
                    subtitle: (){
                      if (Prefs.editorStraightenDelay.value == 0) return t.settings.straightenDelay.off;
                      return "${Prefs.editorStraightenDelay.value}ms";
                    }(),
                    iconBuilder: (num i) {
                      return (i <= 0) ? Icons.gesture : Icons.straighten;
                    },
                    pref: Prefs.editorStraightenDelay,
                    options: [
                      ToggleButtonsOption(0, Text(t.settings.straightenDelay.off)),
                      ToggleButtonsOption(500, Text(t.settings.straightenDelay.regular)),
                      ToggleButtonsOption(1000, Text(t.settings.straightenDelay.slow)),
                    ],
                  ),
                  SettingsSelection(
                    title: t.settings.prefLabels.maxImageSize,
                    subtitle: t.settings.prefDescriptions.maxImageSize,
                    icon: Icons.photo_size_select_large,
                    pref: Prefs.maxImageSize,
                    options: const <ToggleButtonsOption<double>>[
                      ToggleButtonsOption(500, Text("500")),
                      ToggleButtonsOption(1000, Text("1000")),
                      ToggleButtonsOption(2000, Text("2000")),
                    ],
                  ),
                  SettingsSwitch(
                    title: t.settings.prefLabels.autoClearWhiteboardOnExit,
                    subtitle: t.settings.prefDescriptions.autoClearWhiteboardOnExit,
                    icon: Icons.cleaning_services,
                    pref: Prefs.autoClearWhiteboardOnExit,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ]),
          )),
        ],
      ),
    );
  }

  @override
  void dispose() {
    Prefs.locale.removeListener(onChanged);
    UpdateManager.status.removeListener(onChanged);
    super.dispose();
  }
}
