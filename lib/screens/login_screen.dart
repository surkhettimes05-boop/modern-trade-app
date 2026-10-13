import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../main.dart';
import '../widgets/common.dart';
import '../widgets/google_sign_in_web_button.dart' as google_web;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _otpSent = false;
  bool _busy = false;
  bool _closing = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = AppScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    state.clearGoogleAuthError();
    try {
      if (!_otpSent) {
        if (!RegExp(r'^(\+977)?9[6-9]\d{8}$').hasMatch(_phone.text.trim())) {
          throw const ApiException('Enter a valid Nepal mobile number');
        }
        await state.requestOtp(_phone.text.trim());
        setState(() => _otpSent = true);
      } else {
        if (_otp.text.trim().length != 6) {
          throw const ApiException('Enter the 6-digit OTP');
        }
        if (state.pendingGoogleLinkToken != null) {
          await state.linkGoogleWithOtp(
            _phone.text.trim(),
            _otp.text.trim(),
          );
        } else {
          await state.verifyOtp(_phone.text.trim(), _otp.text.trim());
        }
        if (mounted) Navigator.pop(context, true);
      }
    } catch (exception) {
      if (mounted) setState(() => _error = userMessage(exception));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startGoogleSignIn() async {
    final state = AppScope.of(context);
    setState(() => _error = null);
    state.clearGoogleAuthError();
    try {
      await state.startGoogleSignIn();
      if (mounted && state.isSignedIn) Navigator.pop(context, true);
    } catch (exception) {
      if (mounted) setState(() => _error = userMessage(exception));
    }
  }

  Future<void> _cancelGoogleLink() async {
    final state = AppScope.of(context);
    await state.cancelGoogleLink();
    if (!mounted) return;
    setState(() {
      _otpSent = false;
      _phone.clear();
      _otp.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final linkingGoogle = state.pendingGoogleLinkToken != null;

    if (state.isSignedIn && !_closing) {
      _closing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context, true);
      });
    }

    final visibleError = _error ?? state.googleAuthError;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(child: NovaLogo()),
                  const SizedBox(height: 34),
                  Text(
                    _otpSent
                        ? 'Enter your code'
                        : linkingGoogle
                            ? 'Verify your mobile'
                            : 'Welcome back',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _otpSent
                        ? 'We sent a 6-digit code to ${_phone.text}.'
                        : linkingGoogle
                            ? 'Verify your Nepal number once to connect ${state.pendingGoogleEmail ?? 'your Google account'} to the same Pasalho orders and loyalty account.'
                            : 'Sign in to checkout, view orders and keep your Pasalho account in sync.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  if (!linkingGoogle && !_otpSent && state.googleSignInConfigured) ...[
                    if (kIsWeb && state.googleSignInReady)
                      Center(child: google_web.renderButton())
                    else if (!kIsWeb)
                      OutlinedButton.icon(
                        onPressed: state.googleSignInReady &&
                                !state.googleAuthBusy &&
                                !_busy
                            ? _startGoogleSignIn
                            : null,
                        icon: state.googleAuthBusy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'G',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                        label: Text(
                          state.googleAuthBusy
                              ? 'Signing in...'
                              : 'Continue with Google',
                        ),
                      ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 22),
                  ],
                  if (!_otpSent)
                    TextField(
                      controller: _phone,
                      autofocus: linkingGoogle || !state.googleSignInConfigured,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Mobile number',
                        hintText: '98XXXXXXXX',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        helperText: linkingGoogle
                            ? 'Your verified number keeps Google on the same customer account.'
                            : null,
                      ),
                    )
                  else
                    TextField(
                      controller: _otp,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onSubmitted: (_) => _submit(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 9),
                      decoration:
                          const InputDecoration(labelText: 'One-time password'),
                    ),
                  if (visibleError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      visibleError,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _busy || state.googleAuthBusy ? null : _submit,
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _otpSent
                                ? linkingGoogle
                                    ? 'Verify & connect Google'
                                    : 'Verify and sign in'
                                : linkingGoogle
                                    ? 'Send verification code'
                                    : 'Continue with mobile',
                          ),
                  ),
                  if (_otpSent)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _otpSent = false;
                                _otp.clear();
                                _error = null;
                              }),
                      child: const Text('Change phone number'),
                    ),
                  if (linkingGoogle)
                    TextButton(
                      onPressed: _busy ? null : _cancelGoogleLink,
                      child: const Text('Use another sign-in method'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
