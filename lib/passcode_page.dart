import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _pinStorageKey = 'app_passcode';

class PasscodePage extends StatefulWidget {
  /// if true, the user is changing an existing PIN and shows a "current PIN" step first
  final bool isChanging;

  /// Theme colors passed in from settings so everything matches
  final Color backgroundColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color cardColor;
  final Color accentColor;
  final String? fontFamily;
  final double fontSize;

  const PasscodePage({
    super.key,
    required this.isChanging,
    required this.backgroundColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.cardColor,
    required this.accentColor,
    this.fontFamily,
    required this.fontSize,
  });

  @override
  State<PasscodePage> createState() => _PasscodePageState();
}

class _PasscodePageState extends State<PasscodePage> {
  final _storage = const FlutterSecureStorage();

  // Which step we're on
  _Step _step = _Step.enterNew;

  String _currentInput = '';
  String _firstEntry = ''; // stores first PIN entry for confirmation
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _step = widget.isChanging ? _Step.verifyCurrent : _Step.enterNew;
  }

  String get _title {
    switch (_step) {
      case _Step.verifyCurrent:
        return 'Enter Current PIN';
      case _Step.enterNew:
        return 'Set New PIN';
      case _Step.confirm:
        return 'Confirm PIN';
    }
  }

  void _onDigitTap(String digit) {
    if (_currentInput.length >= 4) return;
    setState(() {
      _currentInput += digit;
      _errorMessage = null;
    });

    if (_currentInput.length == 4) {
      // Small delay so user sees the 4th dot fill before processing
      Future.delayed(const Duration(milliseconds: 150), _processFullPin);
    }
  }

  void _onDelete() {
    if (_currentInput.isEmpty) return;
    setState(() {
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _processFullPin() async {
    switch (_step) {
      case _Step.verifyCurrent:
        final stored = await _storage.read(key: _pinStorageKey);
        if (_currentInput == stored) {
          setState(() {
            _step = _Step.enterNew;
            _currentInput = '';
          });
        } else {
          setState(() {
            _errorMessage = 'Incorrect PIN. Try again.';
            _currentInput = '';
          });
        }
        break;

      case _Step.enterNew:
        setState(() {
          _firstEntry = _currentInput;
          _currentInput = '';
          _step = _Step.confirm;
        });
        break;

      case _Step.confirm:
        if (_currentInput == _firstEntry) {
          try {
            await _storage.write(key: _pinStorageKey, value: _currentInput);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Passcode saved successfully!'),
                  duration: Duration(seconds: 2),
                ),
              );
              await Future.delayed(const Duration(milliseconds: 600));
              if (mounted) Navigator.pop(context, true);
            }
          } catch (e) {
            setState(() {
              _errorMessage = 'Failed to save PIN. Please try again.';
              _currentInput = '';
            });
          }
        } else {
          setState(() {
            _errorMessage = 'PINs don\'t match. Try again.';
            _currentInput = '';
            _firstEntry = '';
            _step = _Step.enterNew;
          });
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.textColor),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          'App Passcode',
          style: TextStyle(
            color: widget.textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: widget.fontFamily,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 48),

          // Step title
          Text(
            _title,
            style: TextStyle(
              color: widget.textColor,
              fontSize: widget.fontSize + 2,
              fontWeight: FontWeight.w500,
              fontFamily: widget.fontFamily,
            ),
          ),
          const SizedBox(height: 32),

          // PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < _currentInput.length;
              return Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? widget.accentColor : Colors.transparent,
                  border: Border.all(
                    color: filled ? widget.accentColor : widget.secondaryTextColor,
                    width: 2,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Error message
          SizedBox(
            height: 24,
            child: _errorMessage != null
                ? Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: widget.fontSize - 1,
                      fontFamily: widget.fontFamily,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 32),

          // Number pad
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDigitRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildDigitRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildDigitRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Empty spacer to balance the delete button
                      const SizedBox(width: 72, height: 72),
                      _buildDigitButton('0'),
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: IconButton(
                          onPressed: _onDelete,
                          icon: Icon(
                            Icons.backspace_outlined,
                            color: widget.secondaryTextColor,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDigitRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_buildDigitButton).toList(),
    );
  }

  Widget _buildDigitButton(String digit) {
    return GestureDetector(
      onTap: () => _onDigitTap(digit),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.cardColor,
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              color: widget.textColor,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              fontFamily: widget.fontFamily,
            ),
          ),
        ),
      ),
    );
  }
}

enum _Step { verifyCurrent, enterNew, confirm }