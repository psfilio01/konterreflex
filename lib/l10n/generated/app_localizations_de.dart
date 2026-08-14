// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Konterreflex';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get appLanguageTitle => 'App-Sprache';

  @override
  String get appLanguageSubtitle =>
      'Gilt für alle App-Texte, KI-Antworten und Stimmen';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get languageSaveError =>
      'Die App-Sprache konnte nicht gespeichert werden.';

  @override
  String get privacyStorageTitle => 'Datenschutz & Speicherung';

  @override
  String get privacyStorageSubtitle =>
      'Aufbewahrung und Produktanalyse steuern';

  @override
  String get historyDeleteTitle => 'Verlauf und Daten löschen';

  @override
  String get subscriptionAccessTitle => 'Abo und Zugriff';

  @override
  String get subscriptionAccessSubtitle =>
      'Status prüfen, wiederherstellen oder verwalten';

  @override
  String get signOut => 'Abmelden';

  @override
  String get accountSection => 'Konto';

  @override
  String get deleteAccountTitle => 'Konto und Daten löschen';

  @override
  String get deleteAccountSubtitle =>
      'Dauerhaft und nicht rückgängig zu machen';

  @override
  String get deleteAccountDialogTitle => 'Konto endgültig löschen?';

  @override
  String get deleteAccountDialogBody =>
      'Dein Profil und alle persönlichen Trainingsdaten werden dauerhaft gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get deletePermanently => 'Endgültig löschen';

  @override
  String get deleteAccountError => 'Das Konto konnte nicht gelöscht werden.';

  @override
  String get homeQuestion => 'Was möchtest du trainieren?';

  @override
  String get homeTagline => 'Hören. Reagieren. Reflektieren. Wiederholen.';

  @override
  String get homeTrainingDescription =>
      'Alltagssituationen sicher durchspielen';

  @override
  String get realLifeTitle => 'Echte Situation';

  @override
  String get savedRealLifeSituation => 'Gespeicherte Situation';

  @override
  String get savedRealLifeSituationsTitle => 'Deine Situationen';

  @override
  String get realLifeLibraryIntro =>
      'Wähle eine Situation oder lass Konterreflex passend zu deinem bisherigen Training entscheiden.';

  @override
  String get randomPractice => 'Zufällig üben';

  @override
  String get tellNewSituation => 'Neue Situation erzählen';

  @override
  String get realLifeRandomPreparing => 'Situation wird gewählt …';

  @override
  String get realLifeLibraryLoadError =>
      'Deine Situationen konnten gerade nicht geladen werden.';

  @override
  String get homeRealLifeDescription =>
      'Erlebtes rekonstruieren und neu beantworten';

  @override
  String get speechChallengeTitle => 'Speech Challenge';

  @override
  String get homeSpeechChallengeDescription =>
      'Kurz und spontan auf einen Impuls reagieren';

  @override
  String get goldenBookTitle => 'Golden Book';

  @override
  String get homeGoldenBookDescription =>
      'Starke Formulierungen griffbereit sammeln';

  @override
  String get historyTitle => 'Verlauf';

  @override
  String get onboardingTitle => 'Wie dürfen wir dich ansprechen?';

  @override
  String get onboardingBody =>
      'Danach trainierst du vor allem mit deiner Stimme. Deinen Namen kannst du später ändern.';

  @override
  String get displayNameLabel => 'Vorname oder Anrede';

  @override
  String get saving => 'Wird gespeichert …';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get profileSaveError => 'Dein Profil konnte nicht gespeichert werden.';

  @override
  String get privacyLoadError =>
      'Datenschutzeinstellungen konnten nicht geladen werden.';

  @override
  String get voiceRecordingsTitle => 'Sprachaufnahmen';

  @override
  String get voiceRecordingsBody =>
      'Standardmäßig wird Audio nur zur Transkription verarbeitet und nicht dauerhaft gespeichert.';

  @override
  String get recordingRetentionLabel =>
      'Aufbewahrung für künftige optionale Aufnahmen';

  @override
  String get neverStore => 'Nie dauerhaft speichern';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '$count Tag',
    );
    return '$_temp0';
  }

  @override
  String get analyticsTitle => 'Datensparsame Produktanalyse erlauben';

  @override
  String get analyticsBody =>
      'Nur feste Funnel- und Feature-Ereignisse. Keine Transkripte, Audiodaten oder Formulierungen.';

  @override
  String get showTranscript => 'Transkript anzeigen';

  @override
  String get hideTranscript => 'Transkript ausblenden';

  @override
  String get transcriptLabel => 'Transkript';

  @override
  String get orbReady => 'Bereit';

  @override
  String get orbPreparing => 'Audio wird vorbereitet';

  @override
  String get orbSpeaking => 'Konterreflex spricht';

  @override
  String get orbListening => 'Konterreflex hört zu';

  @override
  String get orbThinking => 'Konterreflex denkt nach';

  @override
  String get orbComplete => 'Abgeschlossen';

  @override
  String get authChecking => 'Anmeldung wird geprüft';

  @override
  String get oneMoment => 'Einen Moment …';

  @override
  String get validEmailError => 'Bitte gib eine gültige E-Mail-Adresse ein.';

  @override
  String passwordLengthError(int count) {
    return 'Das Passwort muss mindestens $count Zeichen lang sein.';
  }

  @override
  String get passwordMismatchError => 'Die Passwörter stimmen nicht überein.';

  @override
  String get authTooManyAttempts =>
      'Zu viele Versuche in kurzer Zeit. Bitte warte einen Moment und versuche es erneut.';

  @override
  String get authInvalidCredentials =>
      'E-Mail-Adresse oder Passwort stimmen nicht.';

  @override
  String get authEmailNotConfirmed =>
      'Bitte bestätige zuerst deine E-Mail-Adresse.';

  @override
  String get authWeakPassword =>
      'Das Passwort ist nicht sicher genug. Verwende mindestens 8 Zeichen.';

  @override
  String get authUserExists =>
      'Für diese E-Mail-Adresse besteht bereits ein Konto.';

  @override
  String get authSamePassword =>
      'Das neue Passwort muss sich vom bisherigen unterscheiden.';

  @override
  String get authProviderDisabled =>
      'Diese Anmeldung ist noch nicht freigeschaltet.';

  @override
  String get authRequestExpired =>
      'Die Anfrage ist abgelaufen. Bitte starte den Vorgang erneut.';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get welcomeBack => 'Willkommen zurück';

  @override
  String get signUpIntro =>
      'Erstelle dein Konterreflex-Konto mit E-Mail und Passwort.';

  @override
  String get signInIntro => 'Melde dich an und setze dein Training fort.';

  @override
  String get emailAddress => 'E-Mail-Adresse';

  @override
  String get password => 'Passwort';

  @override
  String get passwordMinimumHint => 'Mindestens 8 Zeichen';

  @override
  String get showPassword => 'Passwort anzeigen';

  @override
  String get hidePassword => 'Passwort verbergen';

  @override
  String get repeatPassword => 'Passwort wiederholen';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get pleaseWait => 'Bitte warten …';

  @override
  String get signIn => 'Anmelden';

  @override
  String get or => 'oder';

  @override
  String get continueWithGoogle => 'Mit Google fortfahren';

  @override
  String get continueWithApple => 'Mit Apple fortfahren';

  @override
  String get alreadyHaveAccount => 'Du hast schon ein Konto? Anmelden';

  @override
  String get needAccount => 'Noch kein Konto? Jetzt registrieren';

  @override
  String get signUpError => 'Das Konto konnte nicht erstellt werden.';

  @override
  String get signInError => 'Die Anmeldung ist fehlgeschlagen.';

  @override
  String get appleSignInError => 'Die Anmeldung mit Apple ist fehlgeschlagen.';

  @override
  String get googleSignInError =>
      'Die Anmeldung mit Google ist fehlgeschlagen.';

  @override
  String get accountCreatedConfirmation =>
      'Konto erstellt. Bitte bestätige deine E-Mail-Adresse und melde dich danach an.';

  @override
  String get resetPasswordTitle => 'Passwort zurücksetzen';

  @override
  String get emailOnTheWay => 'E-Mail ist unterwegs';

  @override
  String get resetSentBody =>
      'Falls ein Konto für diese Adresse besteht, erhältst du einen Link zum Festlegen eines neuen Passworts.';

  @override
  String get resetRequestBody =>
      'Gib deine E-Mail-Adresse ein. Wir senden dir einen sicheren Link zum Festlegen eines neuen Passworts.';

  @override
  String get sendResetLink => 'Reset-Link senden';

  @override
  String get backToSignIn => 'Zurück zur Anmeldung';

  @override
  String get resetEmailError => 'Die E-Mail konnte nicht gesendet werden.';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get newPasswordBody =>
      'Lege ein neues Passwort mit mindestens 8 Zeichen fest.';

  @override
  String get savePassword => 'Passwort speichern';

  @override
  String get passwordUpdateError =>
      'Das Passwort konnte nicht geändert werden.';

  @override
  String get passwordUpdated => 'Dein Passwort wurde geändert.';

  @override
  String voiceSceneUnknown(String code) {
    return 'Die Szene konnte nicht abgespielt werden ($code).';
  }

  @override
  String voiceAuthExpired(String code) {
    return 'Die Audio-Anmeldung ist abgelaufen. Bitte melde dich erneut an ($code).';
  }

  @override
  String voiceRequestRejected(String code) {
    return 'Die Sprachanfrage wurde abgelehnt ($code).';
  }

  @override
  String voiceTimeout(String code) {
    return 'Die Sprachausgabe hat zu lange gebraucht. Bitte versuche es erneut ($code).';
  }

  @override
  String voiceUnavailable(String code) {
    return 'Die Sprachausgabe ist gerade nicht erreichbar ($code).';
  }

  @override
  String voiceInvalidAudio(String code) {
    return 'Die empfangenen Audiodaten waren ungültig ($code).';
  }

  @override
  String voicePlaybackError(String code) {
    return 'Das Gerät konnte die Audiodatei nicht wiedergeben ($code).';
  }

  @override
  String get microphoneDisabled =>
      'Mikrofonzugriff ist deaktiviert. Du kannst ihn in den Einstellungen erlauben.';

  @override
  String get microphoneRecordingRequired =>
      'Ohne Mikrofonzugriff ist keine Sprachaufnahme möglich.';

  @override
  String get recordingStartError =>
      'Die Aufnahme konnte nicht gestartet werden.';

  @override
  String get responseProcessError =>
      'Deine Antwort konnte nicht verarbeitet werden. Bitte versuche es erneut.';

  @override
  String get microphoneHandsFreeRequired =>
      'Ohne Mikrofonzugriff ist kein freihändiger Ablauf möglich.';

  @override
  String get responseNotUnderstood =>
      'Deine Antwort konnte nicht verstanden werden.';

  @override
  String get playbackInterrupted => 'Wiedergabe unterbrochen. Du bist dran.';

  @override
  String get trainingTitle => 'Training';

  @override
  String get trainingSelectingTitle => 'Passende Situation wird gewählt';

  @override
  String get trainingSelectingBody =>
      'Konterreflex berücksichtigt, was du zuletzt geübt hast.';

  @override
  String get nextScenario => 'Nächste Situation';

  @override
  String get scenariosLoadError =>
      'Die Szenarien konnten nicht geladen werden.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get noApprovedScenarios => 'Noch keine freigegebenen Szenarien.';

  @override
  String get groupLabel => 'Gruppe';

  @override
  String get trainingReady => 'Bereit für die Situation?';

  @override
  String get trainingStarting => 'Training wird vorbereitet …';

  @override
  String get trainingPlaying => 'Hör dir die Situation an';

  @override
  String get trainingAnswerPrompt => 'Wie antwortest du?';

  @override
  String get trainingRecording => 'Du sprichst';

  @override
  String get trainingProcessing => 'Antwort wird verarbeitet …';

  @override
  String get trainingFeedbackReady => 'Dein Feedback';

  @override
  String get trainingFollowUp => 'Deine Rückfrage';

  @override
  String get trainingFollowUpProcessing => 'Rückfrage wird beantwortet …';

  @override
  String get trainingGoldenBookPrompt =>
      'Welche Formulierung möchtest du speichern?';

  @override
  String get trainingGoldenBookProcessing => 'Formulierung wird aufgelöst …';

  @override
  String get notComplete => 'Noch nicht abgeschlossen';

  @override
  String get allowMicrophoneSettings => 'Mikrofon in Einstellungen erlauben';

  @override
  String get interruptPlayback => 'Wiedergabe unterbrechen';

  @override
  String savedInGoldenBook(String phrase) {
    return 'Im Golden Book gespeichert: „$phrase“';
  }

  @override
  String get startScene => 'Szene starten';

  @override
  String get recordAnswer => 'Antwort aufnehmen';

  @override
  String get stopRecording => 'Aufnahme beenden';

  @override
  String get sendFollowUp => 'Rückfrage senden';

  @override
  String get sendVoiceCommand => 'Sprachbefehl senden';

  @override
  String get askFollowUp => 'Rückfrage stellen';

  @override
  String get savePhraseByVoice => 'Satz per Stimme speichern';

  @override
  String get repeatScene => 'Szene wiederholen';

  @override
  String get retrySave => 'Speichern erneut versuchen';

  @override
  String get restart => 'Erneut starten';

  @override
  String get feedbackStrengths => 'Das trägt';

  @override
  String get feedbackNextStep => 'Nächster Schritt';

  @override
  String get feedbackAlternatives => 'Natürliche Alternativen';

  @override
  String get feedbackOverview => 'Auf einen Blick';

  @override
  String get feedbackSignalStrong => 'Stark gelöst';

  @override
  String get feedbackSignalDeveloping => 'Auf gutem Weg';

  @override
  String get feedbackSignalFocus => 'Noch einmal schärfen';

  @override
  String get feedbackDimensionPosture => 'Präsenz';

  @override
  String get feedbackDimensionPrecision => 'Präzision';

  @override
  String get feedbackDimensionFrame => 'Rahmen';

  @override
  String get feedbackDimensionSocialEffect => 'Wirkung';

  @override
  String get feedbackDimensionNaturalness => 'Natürlich';

  @override
  String get feedbackDimensionEscalationFit => 'Passung';

  @override
  String get saveInGoldenBook => 'Im Golden Book speichern';

  @override
  String get sceneIncompleteError =>
      'Die Szene konnte nicht vollständig abgespielt werden.';

  @override
  String get trainingStartError =>
      'Die Trainingseinheit konnte nicht gestartet werden.';

  @override
  String get transcriptionError =>
      'Deine Antwort konnte nicht transkribiert werden.';

  @override
  String get nothingToSaveError => 'Es gibt noch keine Antwort zum Speichern.';

  @override
  String get feedbackSaveError =>
      'Feedback und Antwort sind noch nicht vollständig gespeichert. Bitte versuche es erneut.';

  @override
  String get followUpStartError =>
      'Die Rückfrage konnte nicht gestartet werden.';

  @override
  String get followUpUnderstandError =>
      'Die Rückfrage konnte nicht verstanden werden.';

  @override
  String get followUpAnswerError =>
      'Die Rückfrage konnte gerade nicht beantwortet werden.';

  @override
  String get voiceCommandStartError =>
      'Der Sprachbefehl konnte nicht gestartet werden.';

  @override
  String get voiceCommandUnderstandError =>
      'Der Sprachbefehl konnte nicht verstanden werden.';

  @override
  String get phraseSaveError =>
      'Die Formulierung konnte nicht gespeichert werden.';

  @override
  String savedSpoken(String phrase) {
    return 'Gespeichert: $phrase';
  }

  @override
  String get chooseTopic => 'Wähle ein Thema';

  @override
  String get speechChallengeIntro =>
      'Kurze Impulse im Flow. Deine gemeinsame qualitative Auswertung folgt am Ende.';

  @override
  String get challengeSetsLoadError =>
      'Die Challenge-Sets konnten nicht geladen werden.';

  @override
  String get again => 'Noch einmal';

  @override
  String get startHandsFree => 'Freihändig starten';

  @override
  String get endChallenge => 'Challenge beenden';

  @override
  String get challengeReady => 'Bereit für kurze Impulse?';

  @override
  String get listen => 'Hör zu';

  @override
  String get speakResponse => 'Sprich deine Antwort';

  @override
  String get challengeTransitioning =>
      'Antwort gespeichert · gleich geht es weiter';

  @override
  String get challengeEvaluating => 'Deine Antworten werden zusammengeführt …';

  @override
  String get setComplete => 'Set abgeschlossen';

  @override
  String get brieflyInterrupted => 'Kurz unterbrochen';

  @override
  String get challengeContinueError =>
      'Die Challenge konnte gerade nicht fortgesetzt werden.';

  @override
  String get promptPlaybackError =>
      'Der Impuls konnte nicht abgespielt werden.';

  @override
  String get challengeLengthTitle => 'Wie viele Impulse möchtest du?';

  @override
  String get challengeLengthBody =>
      'Wähle die Länge deiner Session. Während des Durchlaufs gibt es keine Unterbrechung durch Feedback.';

  @override
  String get challengeLengthCustom => 'Eigene Anzahl';

  @override
  String challengeLengthRange(int max) {
    return 'Bitte wähle 1 bis $max.';
  }

  @override
  String challengeAvailableCount(int count) {
    return '$count unterschiedliche Impulse verfügbar';
  }

  @override
  String startChallengeWithCount(int count) {
    return 'Challenge mit $count Impulsen starten';
  }

  @override
  String challengeProgress(int current, int total) {
    return 'Impuls $current von $total';
  }

  @override
  String get challengeResultTitle => 'Deine Auswertung';

  @override
  String challengeResultBody(int count) {
    return 'Gemeinsames Feedback aus $count Antworten.';
  }

  @override
  String challengePartialResultBody(int completed, int target) {
    return 'Du hast $completed von $target Impulsen abgeschlossen. Hier ist die gemeinsame Auswertung deiner Antworten.';
  }

  @override
  String get challengeDetailsTitle => 'Details zu deinen Antworten';

  @override
  String challengePromptNumber(int number) {
    return 'Impuls $number';
  }

  @override
  String get challengeYourAnswer => 'Deine Antwort';

  @override
  String get challengeDetailAlternative => 'Eine natürliche Alternative';

  @override
  String get newChallenge => 'Neue Challenge';

  @override
  String get retryChallengeEvaluation => 'Auswertung erneut versuchen';

  @override
  String get challengeEvaluationCapacityError =>
      'Deine Antworten sind gespeichert. Die KI-Auswertung ist gerade ausgelastet und kann erneut versucht werden.';

  @override
  String get challengeEvaluationError =>
      'Deine Antworten sind gespeichert, aber die gemeinsame Auswertung konnte noch nicht erstellt werden.';

  @override
  String get realLifeScenarioTitle => 'Deine echte Situation';

  @override
  String get realLifeReadyTitle => 'Was ist passiert?';

  @override
  String get realLifeDescribingTitle => 'Erzähl in deinem Tempo';

  @override
  String get realLifeExtractingTitle => 'Situation wird verstanden …';

  @override
  String get realLifeConfirmTitle => 'Passt diese Zusammenfassung?';

  @override
  String get realLifeFollowUpTitle => 'Ergänze nur das Wesentliche';

  @override
  String get realLifeReconstructingTitle => 'Szene wird rekonstruiert …';

  @override
  String get realLifeReplayReadyTitle => 'Bereit für den zweiten Versuch?';

  @override
  String get realLifePreparingPlaybackTitle => 'Szene wird vorbereitet';

  @override
  String get realLifePlayingTitle => 'Hör dir die Szene an';

  @override
  String get realLifeResponseTitle => 'Wie antwortest du jetzt?';

  @override
  String get realLifeRecordingTitle => 'Du sprichst';

  @override
  String get realLifeReflectingTitle => 'Antwort wird reflektiert …';

  @override
  String get realLifeFeedbackTitle => 'Dein Feedback';

  @override
  String get realLifeErrorTitle => 'Das hat noch nicht geklappt';

  @override
  String get realLifeReadyBody =>
      'Beschreibe Ort, Beteiligte und den entscheidenden Satz. Tippen ist nicht nötig.';

  @override
  String get realLifeConfirmBody =>
      'Du kannst bestätigen oder eine wesentliche Lücke per Stimme ergänzen.';

  @override
  String get realLifeFeedbackBody =>
      'Wiederhole die Szene oder übe eine ähnliche Variante.';

  @override
  String get settingDetail => 'Ort und Rahmen';

  @override
  String get participantsDetail => 'Beteiligte';

  @override
  String get triggerStatementDetail => 'Entscheidender Satz';

  @override
  String get observableToneDetail => 'Beobachtbarer Ton';

  @override
  String get socialTensionDetail => 'Soziale Spannung';

  @override
  String get notSure => 'Nicht sicher';

  @override
  String get tellSituation => 'Situation erzählen';

  @override
  String get finishStory => 'Erzählung beenden';

  @override
  String get confirmCreateScene => 'Passt · Szene erstellen';

  @override
  String get addByVoice => 'Per Stimme ergänzen';

  @override
  String get acceptAddition => 'Ergänzung übernehmen';

  @override
  String get playScene => 'Szene abspielen';

  @override
  String get answerAgain => 'Neu antworten';

  @override
  String get finishAnswer => 'Antwort beenden';

  @override
  String get repeatSameScene => 'Gleiche Szene wiederholen';

  @override
  String get similarVariation => 'Ähnliche Variante';

  @override
  String get startOver => 'Neu beginnen';

  @override
  String get realLifeProcessError =>
      'Die Situation konnte nicht verarbeitet werden.';

  @override
  String get realLifeAdditionError =>
      'Die Ergänzung konnte nicht verarbeitet werden.';

  @override
  String get realLifeReconstructError =>
      'Die Szene konnte nicht rekonstruiert werden.';

  @override
  String get realLifePlaybackError =>
      'Die rekonstruierte Szene konnte nicht abgespielt werden.';

  @override
  String get realLifeEvaluationError =>
      'Deine Antwort konnte nicht vollständig ausgewertet werden.';

  @override
  String get realLifeVariationError =>
      'Eine ähnliche Variante konnte nicht erstellt werden.';

  @override
  String get microphoneSettingsDisabled =>
      'Mikrofonzugriff ist in den Einstellungen deaktiviert.';

  @override
  String get microphoneFlowRequired =>
      'Für diesen Sprachfluss wird Mikrofonzugriff benötigt.';

  @override
  String realLifeFollowUpTranscript(String question, String answer) {
    return 'Ergänzung zu \"$question\": $answer';
  }

  @override
  String get personalFavorite => 'Persönlicher Favorit';

  @override
  String get searchPhrases => 'Formulierungen durchsuchen';

  @override
  String get all => 'Alle';

  @override
  String get noGoldenBookEntries =>
      'Noch keine passenden Formulierungen. Speichere Favoriten direkt aus deinem Training.';

  @override
  String get goldenBookLoadError =>
      'Dein Golden Book konnte nicht geladen werden.';

  @override
  String get fromTrainingSession => 'Aus einer Trainingseinheit';

  @override
  String get deleteEntry => 'Eintrag löschen';

  @override
  String quotedPhrase(String phrase) {
    return '„$phrase“';
  }

  @override
  String get historyLoadError => 'Dein Verlauf konnte nicht geladen werden.';

  @override
  String get historyPrivacyBody =>
      'Hier siehst du nur notwendige Sitzungsdaten. Gesprochene Rohaufnahmen werden standardmäßig nicht dauerhaft gespeichert.';

  @override
  String get noHistoryEntries => 'Noch keine Einträge.';

  @override
  String get notCompletedSuffix => ' · nicht abgeschlossen';

  @override
  String get manageGoldenBook => 'Golden Book verwalten und Einträge löschen';

  @override
  String get deleteEntryDialogTitle => 'Eintrag löschen?';

  @override
  String get deleteRealLifeHistoryBody =>
      'Die echte Situation und zugehörige Wiederholungen werden dauerhaft gelöscht.';

  @override
  String get deleteSessionHistoryBody =>
      'Die Sitzung, Antworten und das zugehörige Feedback werden dauerhaft gelöscht.';

  @override
  String get delete => 'Löschen';

  @override
  String get toldRealLifeSituation => 'Erzählte echte Situation';

  @override
  String get realLifeReplayHistory => 'Wiederholung einer echten Situation';

  @override
  String get trainingSessionHistory => 'Trainingseinheit';

  @override
  String get freeAccess => 'Kostenloser Zugriff';

  @override
  String get premiumConfirmed => 'Dein Pro-Zugriff ist serverseitig bestätigt.';

  @override
  String get freeAccessBody =>
      'Freie Nutzung und Grenzen werden serverseitig konfiguriert.';

  @override
  String currentPeriodUntil(String date) {
    return 'Aktueller Zeitraum bis $date';
  }

  @override
  String get accessLoadError => 'Der Zugriff konnte nicht geladen werden.';

  @override
  String get unlockPro => 'Pro freischalten';

  @override
  String get manageSubscription => 'Abo verwalten';

  @override
  String get restorePurchases => 'Käufe wiederherstellen';

  @override
  String get refreshAccess => 'Zugriff aktualisieren';

  @override
  String get billingChannelMissing =>
      'Für diese Plattform ist noch kein Kaufkanal eingerichtet. Du kannst deinen Zugriff trotzdem aktualisieren.';

  @override
  String get billingError =>
      'Die Abrechnung konnte nicht abgeschlossen werden. Es wurde kein Zugriff lokal freigeschaltet.';

  @override
  String get billingDisclaimer =>
      'Der verfügbare Kaufweg hängt von Plattform, Region und Store-Regeln ab. Ein erfolgreicher Bezahlbildschirm allein schaltet keine Funktionen frei.';

  @override
  String get routeLoadError => 'Die Ansicht konnte nicht geladen werden.';

  @override
  String spokenStrength(String strength) {
    return ' Stärke: $strength.';
  }
}
