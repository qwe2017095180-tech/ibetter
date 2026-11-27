import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_brand.dart';
import '../../app/theme/app_colors.dart';
import '../../core/prefs/app_prefs.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';

/// 4-digit PIN entry & verification screen used by both [PasscodePage] and [AppLockGate].
class PinPadView extends StatefulWidget {
  const PinPadView({
    super.key,
    required this.title,
    required this.subtitle,
    this.errorText,
    required this.onCompleted,
  });

  final String title;
  final String subtitle;
  final String? errorText;
  final ValueChanged<String> onCompleted;

  @override
  State<PinPadView> createState() => PinPadViewState();
}

class PinPadViewState extends State<PinPadView> {
  String _digits = '';

  void clear() {
    if (mounted) setState(() => _digits = '');
  }

  void _tapDigit(String d) {
    if (_digits.length >= 4) return;
    final next = '$_digits$d';
    setState(() => _digits = next);
    if (next.length == 4) {
      final completed = next;
      Future.microtask(() => widget.onCompleted(completed));
    }
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _digits.length ? AppColors.primary : Colors.white,
                  border: Border.all(
                    color: i < _digits.length ? AppColors.primary : AppColors.textHint,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 20,
          child: widget.errorText == null
              ? null
              : Text(
                  widget.errorText!,
                  style: const TextStyle(fontSize: 13, color: AppColors.badge),
                ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 264,
          child: Column(
            children: [
              for (final row in const [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final d in row)
                        _PinKey(label: d, onTap: () => _tapDigit(d)),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 72, height: 56),
                  _PinKey(label: '0', onTap: () => _tapDigit('0')),
                  SizedBox(
                    width: 72,
                    height: 56,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(28),
                      child: InkWell(
                        key: const ValueKey('pin_backspace'),
                        borderRadius: BorderRadius.circular(28),
                        onTap: _backspace,
                        child: const Icon(
                          Icons.backspace_outlined,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PinKey extends StatelessWidget {
  const _PinKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        key: ValueKey('pin_key_$label'),
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          width: 72,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                offset: Offset(0, 2),
                blurRadius: 2,
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cold-start PIN lock wrapper placed inside [MaterialApp.router]'s builder.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  final _pinKey = GlobalKey<PinPadViewState>();
  bool? _sessionUnlocked;
  String? _error;

  void _verifyPin(String pin, String expected) {
    if (pin == expected) {
      setState(() {
        _sessionUnlocked = true;
        _error = null;
      });
    } else {
      setState(() => _error = '密码错误，请重试');
      _pinKey.currentState?.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPrefsProvider).asData?.value;
    if (prefs == null) {
      return const ColoredBox(color: AppColors.background);
    }
    _sessionUnlocked ??= !prefs.hasActivePasscode;
    if (!prefs.hasActivePasscode) {
      _sessionUnlocked = true;
      return widget.child;
    }
    if (_sessionUnlocked!) {
      return widget.child;
    }

    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 42, color: AppColors.primary),
                const SizedBox(height: 8),
                const Text(
                  AppBrand.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 18),
                PinPadView(
                  key: _pinKey,
                  title: '请输入锁屏密码',
                  subtitle: '输入 4 位数字解锁应用',
                  errorText: _error,
                  onCompleted: (pin) => _verifyPin(pin, prefs.passcode!),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PasscodeFlow {
  overview,
  verifyToChange,
  verifyToDisable,
  enterNew,
  confirmNew,
}

/// Settings -> 隐私与安全 / 密码保护 management page.
class PasscodePage extends ConsumerStatefulWidget {
  const PasscodePage({super.key});

  @override
  ConsumerState<PasscodePage> createState() => _PasscodePageState();
}

class _PasscodePageState extends ConsumerState<PasscodePage> {
  final _pinKey = GlobalKey<PinPadViewState>();
  _PasscodeFlow? _flow;
  String? _firstPin;
  String? _error;

  _PasscodeFlow _resolveFlow(AppPrefs prefs) {
    if (_flow != null) return _flow!;
    return prefs.hasActivePasscode ? _PasscodeFlow.overview : _PasscodeFlow.enterNew;
  }

  Future<void> _onPinEntered(String pin, AppPrefs prefs) async {
    final flow = _resolveFlow(prefs);
    switch (flow) {
      case _PasscodeFlow.overview:
        return;
      case _PasscodeFlow.verifyToChange:
        if (pin == prefs.passcode) {
          setState(() {
            _flow = _PasscodeFlow.enterNew;
            _error = null;
          });
          _pinKey.currentState?.clear();
        } else {
          setState(() => _error = '原密码不正确');
          _pinKey.currentState?.clear();
        }
      case _PasscodeFlow.verifyToDisable:
        if (pin == prefs.passcode) {
          await ref.read(appPrefsProvider.notifier).disablePasscode();
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('已关闭密码保护')));
          Navigator.of(context).pop();
        } else {
          setState(() => _error = '原密码不正确');
          _pinKey.currentState?.clear();
        }
      case _PasscodeFlow.enterNew:
        setState(() {
          _firstPin = pin;
          _flow = _PasscodeFlow.confirmNew;
          _error = null;
        });
        _pinKey.currentState?.clear();
      case _PasscodeFlow.confirmNew:
        if (pin == _firstPin) {
          await ref.read(appPrefsProvider.notifier).setPasscode(pin);
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('已开启密码保护')));
          Navigator.of(context).pop();
        } else {
          setState(() {
            _firstPin = null;
            _flow = _PasscodeFlow.enterNew;
            _error = '两次输入的密码不一致，请重新设置';
          });
          _pinKey.currentState?.clear();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPrefsProvider).asData?.value ?? const AppPrefs();
    final flow = _resolveFlow(prefs);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: '密码保护',
        leading: PillIconButton(
          icon: Icons.arrow_back_ios_new,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: flow == _PasscodeFlow.overview
          ? ListView(
              padding: const EdgeInsets.only(top: 12),
              children: [
                SectionCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          size: 48, color: AppColors.done),
                      const SizedBox(height: 10),
                      const Text(
                        '密码保护已开启',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '每次重新启动应用时需要输入 4 位数字密码',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  child: Material(
                    type: MaterialType.transparency,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('修改密码'),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                          onTap: () => setState(() {
                            _flow = _PasscodeFlow.verifyToChange;
                            _error = null;
                          }),
                        ),
                        const Divider(height: 1, thickness: 1, color: AppColors.divider),
                        ListTile(
                          title: const Text(
                            '关闭密码保护',
                            style: TextStyle(color: AppColors.badge),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                          onTap: () => setState(() {
                            _flow = _PasscodeFlow.verifyToDisable;
                            _error = null;
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: PinPadView(
                  key: _pinKey,
                  title: switch (flow) {
                    _PasscodeFlow.verifyToChange ||
                    _PasscodeFlow.verifyToDisable =>
                      '验证原密码',
                    _PasscodeFlow.enterNew => '设置 4 位密码',
                    _PasscodeFlow.confirmNew => '再次确认密码',
                    _PasscodeFlow.overview => '',
                  },
                  subtitle: switch (flow) {
                    _PasscodeFlow.verifyToChange => '请输入当前 4 位密码以继续修改',
                    _PasscodeFlow.verifyToDisable => '请输入当前 4 位密码以关闭保护',
                    _PasscodeFlow.enterNew => '保护你的个人习惯与打卡记录',
                    _PasscodeFlow.confirmNew => '请再次输入刚才设置的 4 位数字',
                    _PasscodeFlow.overview => '',
                  },
                  errorText: _error,
                  onCompleted: (pin) => _onPinEntered(pin, prefs),
                ),
              ),
            ),
    );
  }
}
