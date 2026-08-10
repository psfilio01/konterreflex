// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Konterreflex';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appLanguageTitle => 'App language';

  @override
  String get appLanguageSubtitle =>
      'Applies to all app text, AI responses, and voices';

  @override
  String get languageGerman => 'German';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSaveError => 'The app language could not be saved.';

  @override
  String get privacyStorageTitle => 'Privacy & storage';

  @override
  String get privacyStorageSubtitle =>
      'Control retention and product analytics';

  @override
  String get historyDeleteTitle => 'History and data deletion';

  @override
  String get subscriptionAccessTitle => 'Subscription & access';

  @override
  String get subscriptionAccessSubtitle =>
      'Check, restore, or manage your status';

  @override
  String get signOut => 'Sign out';

  @override
  String get accountSection => 'Account';

  @override
  String get deleteAccountTitle => 'Delete account and data';

  @override
  String get deleteAccountSubtitle => 'Permanent and cannot be undone';

  @override
  String get deleteAccountDialogTitle => 'Permanently delete account?';

  @override
  String get deleteAccountDialogBody =>
      'Your profile and all personal training data will be permanently deleted. This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get deletePermanently => 'Delete permanently';

  @override
  String get deleteAccountError => 'The account could not be deleted.';

  @override
  String get homeQuestion => 'What would you like to practice?';

  @override
  String get homeTagline => 'Listen. Respond. Reflect. Repeat.';

  @override
  String get homeTrainingDescription =>
      'Practice everyday situations with confidence';

  @override
  String get realLifeTitle => 'Real-life situation';

  @override
  String get homeRealLifeDescription =>
      'Reconstruct an experience and respond again';

  @override
  String get speechChallengeTitle => 'Speech Challenge';

  @override
  String get homeSpeechChallengeDescription =>
      'Respond briefly and spontaneously to a prompt';

  @override
  String get goldenBookTitle => 'Golden Book';

  @override
  String get homeGoldenBookDescription => 'Keep strong phrases close at hand';

  @override
  String get historyTitle => 'History';

  @override
  String get onboardingTitle => 'How should we address you?';

  @override
  String get onboardingBody =>
      'After this, you will train mainly with your voice. You can change your name later.';

  @override
  String get displayNameLabel => 'First name or preferred form of address';

  @override
  String get saving => 'Saving …';

  @override
  String get continueLabel => 'Continue';

  @override
  String get profileSaveError => 'Your profile could not be saved.';

  @override
  String get privacyLoadError => 'Privacy settings could not be loaded.';

  @override
  String get voiceRecordingsTitle => 'Voice recordings';

  @override
  String get voiceRecordingsBody =>
      'By default, audio is processed only for transcription and is not stored permanently.';

  @override
  String get recordingRetentionLabel =>
      'Retention for future optional recordings';

  @override
  String get neverStore => 'Never store permanently';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get analyticsTitle => 'Allow privacy-friendly product analytics';

  @override
  String get analyticsBody =>
      'Only fixed funnel and feature events. No transcripts, audio, or phrases.';

  @override
  String get showTranscript => 'Show transcript';

  @override
  String get hideTranscript => 'Hide transcript';

  @override
  String get transcriptLabel => 'Transcript';

  @override
  String get orbReady => 'Ready';

  @override
  String get orbPreparing => 'Preparing audio';

  @override
  String get orbSpeaking => 'Konterreflex is speaking';

  @override
  String get orbListening => 'Konterreflex is listening';

  @override
  String get orbThinking => 'Konterreflex is thinking';

  @override
  String get orbComplete => 'Complete';

  @override
  String get authChecking => 'Checking sign-in';

  @override
  String get oneMoment => 'One moment …';

  @override
  String get validEmailError => 'Enter a valid email address.';

  @override
  String passwordLengthError(int count) {
    return 'The password must be at least $count characters long.';
  }

  @override
  String get passwordMismatchError => 'The passwords do not match.';

  @override
  String get authTooManyAttempts =>
      'Too many attempts in a short time. Wait a moment and try again.';

  @override
  String get authInvalidCredentials =>
      'The email address or password is incorrect.';

  @override
  String get authEmailNotConfirmed => 'Confirm your email address first.';

  @override
  String get authWeakPassword =>
      'The password is not secure enough. Use at least 8 characters.';

  @override
  String get authUserExists =>
      'An account already exists for this email address.';

  @override
  String get authSamePassword =>
      'The new password must be different from the previous one.';

  @override
  String get authProviderDisabled => 'This sign-in method is not enabled yet.';

  @override
  String get authRequestExpired =>
      'The request has expired. Start the process again.';

  @override
  String get createAccount => 'Create account';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signUpIntro =>
      'Create your Konterreflex account with email and password.';

  @override
  String get signInIntro => 'Sign in and continue your training.';

  @override
  String get emailAddress => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get passwordMinimumHint => 'At least 8 characters';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get repeatPassword => 'Repeat password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get pleaseWait => 'Please wait …';

  @override
  String get signIn => 'Sign in';

  @override
  String get or => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get needAccount => 'No account yet? Register now';

  @override
  String get signUpError => 'The account could not be created.';

  @override
  String get signInError => 'Sign-in failed.';

  @override
  String get appleSignInError => 'Sign-in with Apple failed.';

  @override
  String get googleSignInError => 'Sign-in with Google failed.';

  @override
  String get accountCreatedConfirmation =>
      'Account created. Confirm your email address, then sign in.';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get emailOnTheWay => 'Email is on its way';

  @override
  String get resetSentBody =>
      'If an account exists for this address, you will receive a link to set a new password.';

  @override
  String get resetRequestBody =>
      'Enter your email address. We will send you a secure link to set a new password.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get backToSignIn => 'Back to sign-in';

  @override
  String get resetEmailError => 'The email could not be sent.';

  @override
  String get newPassword => 'New password';

  @override
  String get newPasswordBody =>
      'Set a new password with at least 8 characters.';

  @override
  String get savePassword => 'Save password';

  @override
  String get passwordUpdateError => 'The password could not be changed.';

  @override
  String get passwordUpdated => 'Your password has been changed.';

  @override
  String voiceSceneUnknown(String code) {
    return 'The scene could not be played ($code).';
  }

  @override
  String voiceAuthExpired(String code) {
    return 'Audio authentication has expired. Sign in again ($code).';
  }

  @override
  String voiceRequestRejected(String code) {
    return 'The speech request was rejected ($code).';
  }

  @override
  String voiceTimeout(String code) {
    return 'Speech output took too long. Try again ($code).';
  }

  @override
  String voiceUnavailable(String code) {
    return 'Speech output is currently unavailable ($code).';
  }

  @override
  String voiceInvalidAudio(String code) {
    return 'The received audio data was invalid ($code).';
  }

  @override
  String voicePlaybackError(String code) {
    return 'The device could not play the audio file ($code).';
  }

  @override
  String get microphoneDisabled =>
      'Microphone access is disabled. You can allow it in Settings.';

  @override
  String get microphoneRecordingRequired =>
      'Voice recording requires microphone access.';

  @override
  String get recordingStartError => 'The recording could not be started.';

  @override
  String get responseProcessError =>
      'Your response could not be processed. Try again.';

  @override
  String get microphoneHandsFreeRequired =>
      'Hands-free mode requires microphone access.';

  @override
  String get responseNotUnderstood => 'Your response could not be understood.';

  @override
  String get playbackInterrupted => 'Playback stopped. It is your turn.';

  @override
  String get trainingTitle => 'Training';

  @override
  String get scenariosLoadError => 'The scenarios could not be loaded.';

  @override
  String get retry => 'Try again';

  @override
  String get noApprovedScenarios => 'No approved scenarios yet.';

  @override
  String get groupLabel => 'Group';

  @override
  String get trainingReady => 'Ready for the situation?';

  @override
  String get trainingStarting => 'Preparing your training …';

  @override
  String get trainingPlaying => 'Listen to the situation';

  @override
  String get trainingAnswerPrompt => 'How do you respond?';

  @override
  String get trainingRecording => 'You are speaking';

  @override
  String get trainingProcessing => 'Processing your response …';

  @override
  String get trainingFeedbackReady => 'Your feedback';

  @override
  String get trainingFollowUp => 'Your follow-up question';

  @override
  String get trainingFollowUpProcessing => 'Answering your follow-up …';

  @override
  String get trainingGoldenBookPrompt => 'Which phrase would you like to save?';

  @override
  String get trainingGoldenBookProcessing => 'Resolving the phrase …';

  @override
  String get notComplete => 'Not complete yet';

  @override
  String get allowMicrophoneSettings => 'Allow microphone in Settings';

  @override
  String get interruptPlayback => 'Stop playback';

  @override
  String savedInGoldenBook(String phrase) {
    return 'Saved in Golden Book: “$phrase”';
  }

  @override
  String get startScene => 'Start scene';

  @override
  String get recordAnswer => 'Record response';

  @override
  String get stopRecording => 'Stop recording';

  @override
  String get sendFollowUp => 'Send follow-up';

  @override
  String get sendVoiceCommand => 'Send voice command';

  @override
  String get askFollowUp => 'Ask a follow-up';

  @override
  String get savePhraseByVoice => 'Save phrase by voice';

  @override
  String get repeatScene => 'Repeat scene';

  @override
  String get retrySave => 'Try saving again';

  @override
  String get restart => 'Start again';

  @override
  String get feedbackStrengths => 'What works';

  @override
  String get feedbackNextStep => 'Next step';

  @override
  String get feedbackAlternatives => 'Natural alternatives';

  @override
  String get feedbackOverview => 'At a glance';

  @override
  String get feedbackSignalStrong => 'Handled strongly';

  @override
  String get feedbackSignalDeveloping => 'On the right track';

  @override
  String get feedbackSignalFocus => 'Sharpen and retry';

  @override
  String get feedbackDimensionPosture => 'Presence';

  @override
  String get feedbackDimensionPrecision => 'Precision';

  @override
  String get feedbackDimensionFrame => 'Framing';

  @override
  String get feedbackDimensionSocialEffect => 'Effect';

  @override
  String get feedbackDimensionNaturalness => 'Natural';

  @override
  String get feedbackDimensionEscalationFit => 'Fit';

  @override
  String get saveInGoldenBook => 'Save in Golden Book';

  @override
  String get sceneIncompleteError =>
      'The scene could not be played completely.';

  @override
  String get trainingStartError => 'The training session could not be started.';

  @override
  String get transcriptionError => 'Your response could not be transcribed.';

  @override
  String get nothingToSaveError => 'There is no response to save yet.';

  @override
  String get feedbackSaveError =>
      'Your response and feedback have not been saved completely. Try again.';

  @override
  String get followUpStartError => 'The follow-up could not be started.';

  @override
  String get followUpUnderstandError =>
      'The follow-up could not be understood.';

  @override
  String get followUpAnswerError =>
      'The follow-up could not be answered right now.';

  @override
  String get voiceCommandStartError =>
      'The voice command could not be started.';

  @override
  String get voiceCommandUnderstandError =>
      'The voice command could not be understood.';

  @override
  String get phraseSaveError => 'The phrase could not be saved.';

  @override
  String savedSpoken(String phrase) {
    return 'Saved: $phrase';
  }

  @override
  String get chooseTopic => 'Choose a topic';

  @override
  String get speechChallengeIntro =>
      'Short prompts in one flow. Your consolidated qualitative result follows at the end.';

  @override
  String get challengeSetsLoadError =>
      'The challenge sets could not be loaded.';

  @override
  String get again => 'Again';

  @override
  String get startHandsFree => 'Start hands-free';

  @override
  String get endChallenge => 'End challenge';

  @override
  String get challengeReady => 'Ready for short prompts?';

  @override
  String get listen => 'Listen';

  @override
  String get speakResponse => 'Speak your response';

  @override
  String get challengeTransitioning =>
      'Response saved · the next prompt is coming';

  @override
  String get challengeEvaluating => 'Bringing your responses together …';

  @override
  String get setComplete => 'Set complete';

  @override
  String get brieflyInterrupted => 'Briefly interrupted';

  @override
  String get challengeContinueError =>
      'The challenge could not continue right now.';

  @override
  String get promptPlaybackError => 'The prompt could not be played.';

  @override
  String get challengeLengthTitle => 'How many prompts would you like?';

  @override
  String get challengeLengthBody =>
      'Choose your session length. Feedback will not interrupt the flow.';

  @override
  String get challengeLengthCustom => 'Custom amount';

  @override
  String challengeLengthRange(int max) {
    return 'Choose between 1 and $max.';
  }

  @override
  String challengeAvailableCount(int count) {
    return '$count different prompts available';
  }

  @override
  String startChallengeWithCount(int count) {
    return 'Start challenge with $count prompts';
  }

  @override
  String challengeProgress(int current, int total) {
    return 'Prompt $current of $total';
  }

  @override
  String get challengeResultTitle => 'Your result';

  @override
  String challengeResultBody(int count) {
    return 'Consolidated feedback from $count responses.';
  }

  @override
  String challengePartialResultBody(int completed, int target) {
    return 'You completed $completed of $target prompts. Here is the consolidated result for your responses.';
  }

  @override
  String get challengeDetailsTitle => 'Response details';

  @override
  String challengePromptNumber(int number) {
    return 'Prompt $number';
  }

  @override
  String get challengeYourAnswer => 'Your response';

  @override
  String get challengeDetailAlternative => 'One natural alternative';

  @override
  String get newChallenge => 'New challenge';

  @override
  String get retryChallengeEvaluation => 'Retry result';

  @override
  String get challengeEvaluationCapacityError =>
      'Your responses are saved. AI evaluation is currently at capacity and can be retried.';

  @override
  String get challengeEvaluationError =>
      'Your responses are saved, but the consolidated result could not be created yet.';

  @override
  String get realLifeScenarioTitle => 'Your real-life situation';

  @override
  String get realLifeReadyTitle => 'What happened?';

  @override
  String get realLifeDescribingTitle => 'Tell it at your own pace';

  @override
  String get realLifeExtractingTitle => 'Understanding the situation …';

  @override
  String get realLifeConfirmTitle => 'Does this summary fit?';

  @override
  String get realLifeFollowUpTitle => 'Add only what matters';

  @override
  String get realLifeReconstructingTitle => 'Reconstructing the scene …';

  @override
  String get realLifeReplayReadyTitle => 'Ready for a second attempt?';

  @override
  String get realLifePreparingPlaybackTitle => 'Preparing scene';

  @override
  String get realLifePlayingTitle => 'Listen to the scene';

  @override
  String get realLifeResponseTitle => 'How do you respond now?';

  @override
  String get realLifeRecordingTitle => 'You are speaking';

  @override
  String get realLifeReflectingTitle => 'Reflecting on your response …';

  @override
  String get realLifeFeedbackTitle => 'Your feedback';

  @override
  String get realLifeErrorTitle => 'That did not work yet';

  @override
  String get realLifeReadyBody =>
      'Describe the setting, the people involved, and the key statement. No typing needed.';

  @override
  String get realLifeConfirmBody =>
      'Confirm the summary or add one essential detail by voice.';

  @override
  String get realLifeFeedbackBody =>
      'Repeat the scene or practice a similar variation.';

  @override
  String get settingDetail => 'Setting';

  @override
  String get participantsDetail => 'People involved';

  @override
  String get triggerStatementDetail => 'Key statement';

  @override
  String get observableToneDetail => 'Observable tone';

  @override
  String get socialTensionDetail => 'Social tension';

  @override
  String get notSure => 'Not sure';

  @override
  String get tellSituation => 'Tell the situation';

  @override
  String get finishStory => 'Finish story';

  @override
  String get confirmCreateScene => 'Looks right · Create scene';

  @override
  String get addByVoice => 'Add by voice';

  @override
  String get acceptAddition => 'Use addition';

  @override
  String get playScene => 'Play scene';

  @override
  String get answerAgain => 'Respond again';

  @override
  String get finishAnswer => 'Finish response';

  @override
  String get repeatSameScene => 'Repeat same scene';

  @override
  String get similarVariation => 'Similar variation';

  @override
  String get startOver => 'Start over';

  @override
  String get realLifeProcessError => 'The situation could not be processed.';

  @override
  String get realLifeAdditionError =>
      'The additional detail could not be processed.';

  @override
  String get realLifeReconstructError =>
      'The scene could not be reconstructed.';

  @override
  String get realLifePlaybackError =>
      'The reconstructed scene could not be played.';

  @override
  String get realLifeEvaluationError =>
      'Your response could not be evaluated completely.';

  @override
  String get realLifeVariationError =>
      'A similar variation could not be created.';

  @override
  String get microphoneSettingsDisabled =>
      'Microphone access is disabled in Settings.';

  @override
  String get microphoneFlowRequired =>
      'This voice flow requires microphone access.';

  @override
  String realLifeFollowUpTranscript(String question, String answer) {
    return 'Addition to \"$question\": $answer';
  }

  @override
  String get personalFavorite => 'Personal favorite';

  @override
  String get searchPhrases => 'Search phrases';

  @override
  String get all => 'All';

  @override
  String get noGoldenBookEntries =>
      'No matching phrases yet. Save favorites directly from your training.';

  @override
  String get goldenBookLoadError => 'Your Golden Book could not be loaded.';

  @override
  String get fromTrainingSession => 'From a training session';

  @override
  String get deleteEntry => 'Delete entry';

  @override
  String quotedPhrase(String phrase) {
    return '“$phrase”';
  }

  @override
  String get historyLoadError => 'Your history could not be loaded.';

  @override
  String get historyPrivacyBody =>
      'Only necessary session data appears here. Raw voice recordings are not stored permanently by default.';

  @override
  String get noHistoryEntries => 'No entries yet.';

  @override
  String get notCompletedSuffix => ' · not completed';

  @override
  String get manageGoldenBook => 'Manage Golden Book and delete entries';

  @override
  String get deleteEntryDialogTitle => 'Delete entry?';

  @override
  String get deleteRealLifeHistoryBody =>
      'The real-life situation and its repetitions will be permanently deleted.';

  @override
  String get deleteSessionHistoryBody =>
      'The session, responses, and associated feedback will be permanently deleted.';

  @override
  String get delete => 'Delete';

  @override
  String get toldRealLifeSituation => 'Described real-life situation';

  @override
  String get realLifeReplayHistory => 'Replay of a real-life situation';

  @override
  String get trainingSessionHistory => 'Training session';

  @override
  String get freeAccess => 'Free access';

  @override
  String get premiumConfirmed => 'Your Pro access is confirmed by the server.';

  @override
  String get freeAccessBody =>
      'Free usage and limits are configured by the server.';

  @override
  String currentPeriodUntil(String date) {
    return 'Current period until $date';
  }

  @override
  String get accessLoadError => 'Access could not be loaded.';

  @override
  String get unlockPro => 'Unlock Pro';

  @override
  String get manageSubscription => 'Manage subscription';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get refreshAccess => 'Refresh access';

  @override
  String get billingChannelMissing =>
      'No purchase channel is set up for this platform yet. You can still refresh your access.';

  @override
  String get billingError =>
      'Billing could not be completed. No access was unlocked locally.';

  @override
  String get billingDisclaimer =>
      'The available purchase method depends on the platform, region, and store rules. A successful payment screen alone does not unlock features.';

  @override
  String get routeLoadError => 'The screen could not be loaded.';

  @override
  String spokenStrength(String strength) {
    return ' Strength: $strength.';
  }
}
