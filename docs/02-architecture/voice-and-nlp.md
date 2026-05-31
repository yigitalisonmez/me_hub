# Voice And NLP

Voice commands combine speech recognition, command parsing, and a local TFLite
model.

## Related Code

- `lib/core/widgets/voice_command_sheet.dart`
- `lib/core/services/voice_command_service.dart`
- `lib/core/services/command_parser.dart`
- `lib/core/services/nlp_intent_service.dart`
- `assets/ml/zen_flow_v2.tflite`
- `assets/ml/vocab.txt`
- `assets/ml/labels.txt`
- `assets/ml/entities.json`

## Flow

```text
Mic tap -> VoiceCommandSheet -> SpeechToText -> NLP/Parser -> Parsed command -> Feature action
```

The parser includes regex fallback behavior. Treat this area as sensitive
because it touches permissions, async UI, and feature actions.

## Change Checklist

- Keep regex fallback behavior working if the TFLite model fails.
- Avoid executing a command without user confirmation unless the UI clearly
  supports it.
- Keep diagnostic logging on `debugPrint`; do not reintroduce production
  `print` calls.
- Update examples here when adding command types.

## Live Audit Notes

- Production `print` calls were removed from Voice/NLP during the release
  cleanup.
- `CommandType.startTimer` currently shows a success message but does not start
  `TimerProvider`.
- Several parsed command types return "not yet implemented".
- iOS microphone and speech recognition usage text exists in
  `ios/Runner/Info.plist`.
