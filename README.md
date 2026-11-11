# ORION AI — Independent Android Agent

ORION is a phone-first Android assistant project with a hybrid architecture: local-first operation and optional cloud intelligence.

## Current implementation status

**Foundation scaffold committed. Not yet a complete autonomous agent.**

Implemented in this foundation:
- Flutter Android application shell with a futuristic dark interface.
- Persian chat UI.
- Local conversation persistence using SharedPreferences.
- Honest offline baseline command responses (status, greeting, memory).
- GitHub Actions workflow to generate Android platform files when needed, analyze, test, build a release APK, and upload it as an artifact.

Not implemented yet:
- A real on-device language model.
- A cloud-model adapter or secure credential storage.
- Voice input/output.
- Android Accessibility/notification integrations.
- WhatsApp/Telegram integrations or autonomous background task execution.

## Architecture

- **Presentation:** Flutter / Material 3.
- **Local memory:** SharedPreferences for the initial conversation store; migrate to SQLite when structured memory arrives.
- **Local AI:** adapter to be selected and integrated after device RAM/CPU/Android version are known. Current target test device: Samsung Galaxy A15 (SM-A155F/DSN), Android 16, One UI 8.5, 8 GB physical RAM (4 GB RAM Plus is virtual memory and is not counted as physical RAM).
- **Cloud AI:** optional provider adapter; credentials must be kept in Android Keystore-backed secure storage and must never be committed.
- **Agent runtime:** planner → permission check → tool execution → result verification.
- **Safety:** confirmation gate for sending messages, deleting data, purchases, and other sensitive actions.

## Build from a phone

No local Android SDK is required for the cloud build:
1. Open the repository on GitHub.
2. Switch to branch `orion-v1-foundation`.
3. Open **Actions**.
4. Select **ORION Android APK** and tap **Run workflow** (or wait for a push-triggered run).
5. When the workflow succeeds, open the run and download the `orion-android-apk` artifact.

The workflow runs `flutter analyze`, `flutter test`, and `flutter build apk --release`. A successful build has not yet been observed; check the Actions run before installing.

## Next engineering milestones

1. Confirm Android version, RAM, and CPU; choose a compatible quantized local model.
2. Implement the local inference adapter and model download/import flow.
3. Add optional cloud provider configuration with secure credential storage.
4. Replace the baseline responder with a planner that emits typed tool calls.
5. Add Android integrations incrementally, each behind explicit runtime permissions and confirmation policies.
6. Add voice and scheduled tasks only after foreground execution is reliable.

## Privacy

Conversation history is stored locally by the app. Do not enter passwords, one-time codes, or other secrets into chat. Cloud inference is not active in this foundation.
