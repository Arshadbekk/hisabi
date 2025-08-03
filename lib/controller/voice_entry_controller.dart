// lib/controllers/auto_listen_controller.dart

import 'package:get/get.dart';
import 'package:hisabi/controller/transaxtion_controller.dart' show AddTransactionController, PaymentType;
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';
import '../models/category_model.dart';

/// Model for a parsed command
class ParsedVoice {
  final double amount;
  final String categoryName;
  final DateTime date;

  ParsedVoice({
    required this.amount,
    required this.categoryName,
    required this.date,
  });
}

class AutoListenController extends GetxController {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AddTransactionController _addCtrl =
      Get.find<AddTransactionController>();

  /// true when waiting for the user to say “hey hisabi”
  var waitingForWake = true.obs;

  /// true when capturing the actual command after wake-word
  var capturingCommand = false.obs;

  /// last recognized transcript
  var lastWords = ''.obs;

  /// Expose capturingCommand so UI can use vc.isListening
  RxBool get isListening => capturingCommand;

  /// RegExp to match commands like:
  /// “add 5 for groceries” or
  /// “add expense 12.50 for utilities on August 3”
  static final _cmdRegEx = RegExp(
    r'add\s+'                    // “add ”
    r'(?:expense\s+)?'           // optional “expense ”
    r'(\d+(?:\.\d+)?)'           // group(1)=amount
    r'(?:\s*[A-Za-z]{2,3})?'     // optional currency code
    r'\s*(?:for\s+)?'            // optional “for ”
    r'([A-Za-z ]+?)'             // group(2)=category
    r'(?:\s+on\s+(.+))?'         // optional “on <date>” → group(3)
    r'$',
    caseSensitive: false,
    multiLine: false,
    dotAll: false,
  );

  @override
  void onInit() {
    super.onInit();
    _startHotwordListening();
  }

  /// Listen indefinitely for “hey hisabi”
  Future<void> _startHotwordListening() async {
    bool ok = await _speech.initialize(
      onStatus: (_) {},
      onError: (err) => print('Speech error: $err'),
    );
    if (!ok) {
      Get.snackbar('Error', 'Speech recognition unavailable');
      return;
    }

    waitingForWake.value = true;
    lastWords.value = '';

    _speech.listen(
      onResult: _onHotwordResult,
      listenFor: const Duration(hours: 1),
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
      cancelOnError: true,
    );
  }

  void _onHotwordResult(stt.SpeechRecognitionResult val) {
    final text = val.recognizedWords.toLowerCase();
    lastWords.value = text;

    if (waitingForWake.value && text.contains('hey hisabi')) {
      // Wake-word detected
      waitingForWake.value = false;
      _speech.stop();
      _startCommandCapture();
    }
  }

  /// After wake-word, listen ~4s for the actual “add…” command
  Future<void> _startCommandCapture() async {
    capturingCommand.value = true;
    lastWords.value = '';

    await _speech.listen(
      onResult: (res) => lastWords.value = res.recognizedWords,
      listenFor: const Duration(seconds: 4),
      partialResults: true,
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: true,
    );

    // Wait then stop
    await Future.delayed(const Duration(seconds: 4));
    await _speech.stop();
    capturingCommand.value = false;

    final spoken = lastWords.value.trim();
    if (spoken.isEmpty) {
      Get.snackbar('No command heard', 'Try: “add 5 for Grocery”');
      _restartHotword();
      return;
    }

    final cmd = _parseCommand(spoken);
    if (cmd == null) {
      Get.snackbar('Couldn’t understand', 'Say: “add 5 for Grocery”');
      _restartHotword();
      return;
    }

    await _applyCommand(cmd);
    _restartHotword();
  }

  ParsedVoice? _parseCommand(String input) {
    final m = _cmdRegEx.firstMatch(input);
    if (m == null) return null;

    final amount = double.tryParse(m.group(1)!) ?? 0.0;
    var cat = m.group(2)!.trim();
    cat = cat[0].toUpperCase() + cat.substring(1);

    DateTime date = DateTime.now();
    if (m.group(3) != null) {
      try {
        date = DateFormat.yMMMMd().parse(m.group(3)!);
      } catch (_) {}
    }

    return ParsedVoice(amount: amount, categoryName: cat, date: date);
  }

  Future<void> _applyCommand(ParsedVoice cmd) async {
    // find matching category or default
    var category = _addCtrl.categories.firstWhereOrNull(
      (c) => c.name.toLowerCase() == cmd.categoryName.toLowerCase(),
    );
    category ??= _addCtrl.categories.firstWhere((c) => c.id == 'other');

    _addCtrl.amountController.text = cmd.amount.toString();
    _addCtrl.titleController.text  = cmd.categoryName;
    _addCtrl.selectedCat.value     = category;
    _addCtrl.selectedDate.value    = cmd.date;
    _addCtrl.paymentType.value     = PaymentType.cash;

    final confirmed = await Get.defaultDialog<bool>(
      title: 'Confirm Transaction',
      middleText:
          'Amount: ${cmd.amount}\nCategory: ${category.name}\nDate: ${DateFormat.yMMMd().format(cmd.date)}',
      textConfirm: 'Save',
      textCancel: 'Cancel',
    );
    if (confirmed == true) {
      await _addCtrl.addTransaction();
      Get.snackbar('Saved', 'Transaction added.');
    }
  }

  void _restartHotword() {
    Future.delayed(const Duration(milliseconds: 500), _startHotwordListening);
  }

  @override
  void onClose() {
    _speech.stop();
    super.onClose();
  }
}
