import 'package:flutter/material.dart';
import 'package:laze/data/repositories/device/device_settings_repository.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/core/ui/controller_page.dart';
import 'package:laze/presentation/core/ui/cta_button.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

const String _desktopDownloadUrl =
    'https://lazecontroller.vercel.app/#download';
const String _websiteShortLabel = 'lazecontroller.vercel.app';

/// First-run onboarding — explains the desktop dependency, network
/// requirement, and core controls. Can be re-opened from settings via
/// [OnboardingScreen.replay] which suppresses the persistence write
/// and pops back to the previous screen on completion.
class OnboardingScreen extends StatefulWidget {
  /// When true, finishing/skipping pops back to the caller and does NOT
  /// flip the persisted first-launch flag.
  final bool replay;

  const OnboardingScreen({super.key, this.replay = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.desktop_windows_outlined,
      title: 'Install Laze Desktop',
      description:
          'To control your computer, Laze needs the desktop app running on your laptop or desktop.',
      showDownloadLink: true,
    ),
    _OnboardingPageData(
      icon: Icons.wifi,
      title: 'Use the same Wi-Fi',
      description:
          'Your phone and computer must be connected to the same local network so Laze can find your device.',
    ),
    _OnboardingPageData(
      icon: Icons.touch_app_outlined,
      title: 'Control your mouse',
      description:
          'Use your phone as a full-screen touchpad to move the cursor, click, right-click, and scroll.',
    ),
    _OnboardingPageData(
      icon: Icons.keyboard_alt_outlined,
      title: 'More controls',
      description:
          'Use the keyboard, volume controls, custom shortcuts, gestures, and sensitivity settings from your phone.',
    ),
    _OnboardingPageData(
      icon: Icons.rocket_launch_outlined,
      title: 'Ready to connect',
      description:
          'Open Laze Desktop on your computer, then search for it from the mobile app.',
      ctaLabel: 'FIND MY COMPUTER',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage == _pages.length - 1;

  Future<void> _completeOnboarding() async {
    if (!widget.replay) {
      final repo =
          Provider.of<DeviceSettingsRepository>(context, listen: false);
      await repo.setOnboardingCompleted(true);
    }
    if (!mounted) return;
    if (widget.replay) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  void _nextPage() {
    if (_isLastPage) {
      _completeOnboarding();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openDownloadLink() async {
    final uri = Uri.parse(_desktopDownloadUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      final appColors = Theme.of(context).extension<AppColors>()!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open the download page'),
          backgroundColor: appColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scale = Theme.of(context).extension<DesignScale>()!;

    return ControllerPage(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(
            currentPage: _currentPage,
            totalPages: _pages.length,
            isReplay: widget.replay,
            onSkip: _completeOnboarding,
            appColors: appColors,
            scale: scale,
          ),
          SizedBox(height: scale.spaceXl),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) => _OnboardingPage(
                data: _pages[i],
                appColors: appColors,
                scale: scale,
                onDownload: _openDownloadLink,
              ),
            ),
          ),
          SizedBox(height: scale.spaceLg),
          _PageDots(
            count: _pages.length,
            current: _currentPage,
            appColors: appColors,
          ),
          SizedBox(height: Dimens.spacing.xl),
          CtaButton(
            text: _isLastPage
                ? (_pages[_currentPage].ctaLabel ?? 'GET STARTED')
                : 'NEXT',
            onPressed: _nextPage,
          ),
          SizedBox(height: Dimens.spacing.lg),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final bool showDownloadLink;
  final String? ctaLabel;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    this.showDownloadLink = false,
    this.ctaLabel,
  });
}

class _TopBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isReplay;
  final VoidCallback onSkip;
  final AppColors appColors;
  final DesignScale scale;

  const _TopBar({
    required this.currentPage,
    required this.totalPages,
    required this.isReplay,
    required this.onSkip,
    required this.appColors,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == totalPages - 1;
    final actionLabel = isReplay ? 'CLOSE' : 'SKIP';
    final showAction = isReplay || !isLast;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showAction)
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: appColors.textMuted,
              padding: EdgeInsets.symmetric(
                horizontal: scale.spaceLg,
                vertical: scale.spaceSm,
              ),
            ),
            child: Text(
              actionLabel,
              style: TextStyle(
                fontSize: Dimens.text.small,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          )
        else
          const SizedBox(height: 36),
      ],
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final AppColors appColors;
  final DesignScale scale;
  final VoidCallback onDownload;

  const _OnboardingPage({
    required this.data,
    required this.appColors,
    required this.scale,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: scale.space2xl),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: appColors.surface_2,
              borderRadius: BorderRadius.circular(Dimens.radius.medium),
              border: Border.all(color: appColors.divider, width: 1),
            ),
            alignment: Alignment.center,
            child: Icon(
              data.icon,
              color: appColors.primary,
              size: 56,
            ),
          ),
          SizedBox(height: scale.space2xl),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Dimens.spacing.lg),
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: appColors.text,
                fontSize: Dimens.text.header,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
          SizedBox(height: Dimens.spacing.lg),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Dimens.spacing.xl),
            child: Text(
              data.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: appColors.textMuted,
                fontSize: Dimens.text.body,
                height: 1.45,
              ),
            ),
          ),
          if (data.showDownloadLink) ...[
            SizedBox(height: scale.spaceXl),
            TextButton.icon(
              onPressed: onDownload,
              icon: Icon(Icons.download, color: appColors.primary, size: 20),
              label: Text(
                'Download desktop app',
                style: TextStyle(
                  color: appColors.primary,
                  fontSize: Dimens.text.small,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: appColors.primary,
                ),
              ),
            ),
            SizedBox(height: scale.spaceXs),
            Text(
              'or visit the website $_websiteShortLabel',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: appColors.textMuted,
                fontSize: Dimens.text.label,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;
  final AppColors appColors;

  const _PageDots({
    required this.count,
    required this.current,
    required this.appColors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final selected = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: selected ? 24 : 8,
          decoration: BoxDecoration(
            color: selected ? appColors.primary : appColors.divider,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
