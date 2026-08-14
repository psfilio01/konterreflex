import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Konterreflex'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// No description provided for @appLanguageTitle.
  ///
  /// In de, this message translates to:
  /// **'App-Sprache'**
  String get appLanguageTitle;

  /// No description provided for @appLanguageSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Gilt für alle App-Texte, KI-Antworten und Stimmen'**
  String get appLanguageSubtitle;

  /// No description provided for @languageGerman.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @languageEnglish.
  ///
  /// In de, this message translates to:
  /// **'Englisch'**
  String get languageEnglish;

  /// No description provided for @languageSaveError.
  ///
  /// In de, this message translates to:
  /// **'Die App-Sprache konnte nicht gespeichert werden.'**
  String get languageSaveError;

  /// No description provided for @privacyStorageTitle.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz & Speicherung'**
  String get privacyStorageTitle;

  /// No description provided for @privacyStorageSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Aufbewahrung und Produktanalyse steuern'**
  String get privacyStorageSubtitle;

  /// No description provided for @historyDeleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Verlauf und Daten löschen'**
  String get historyDeleteTitle;

  /// No description provided for @subscriptionAccessTitle.
  ///
  /// In de, this message translates to:
  /// **'Abo und Zugriff'**
  String get subscriptionAccessTitle;

  /// No description provided for @subscriptionAccessSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Status prüfen, wiederherstellen oder verwalten'**
  String get subscriptionAccessSubtitle;

  /// No description provided for @signOut.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get signOut;

  /// No description provided for @accountSection.
  ///
  /// In de, this message translates to:
  /// **'Konto'**
  String get accountSection;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In de, this message translates to:
  /// **'Konto und Daten löschen'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Dauerhaft und nicht rückgängig zu machen'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'Konto endgültig löschen?'**
  String get deleteAccountDialogTitle;

  /// No description provided for @deleteAccountDialogBody.
  ///
  /// In de, this message translates to:
  /// **'Dein Profil und alle persönlichen Trainingsdaten werden dauerhaft gelöscht. Das lässt sich nicht rückgängig machen.'**
  String get deleteAccountDialogBody;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @deletePermanently.
  ///
  /// In de, this message translates to:
  /// **'Endgültig löschen'**
  String get deletePermanently;

  /// No description provided for @deleteAccountError.
  ///
  /// In de, this message translates to:
  /// **'Das Konto konnte nicht gelöscht werden.'**
  String get deleteAccountError;

  /// No description provided for @homeQuestion.
  ///
  /// In de, this message translates to:
  /// **'Was möchtest du trainieren?'**
  String get homeQuestion;

  /// No description provided for @homeTagline.
  ///
  /// In de, this message translates to:
  /// **'Hören. Reagieren. Reflektieren. Wiederholen.'**
  String get homeTagline;

  /// No description provided for @homeTrainingDescription.
  ///
  /// In de, this message translates to:
  /// **'Alltagssituationen sicher durchspielen'**
  String get homeTrainingDescription;

  /// No description provided for @realLifeTitle.
  ///
  /// In de, this message translates to:
  /// **'Echte Situation'**
  String get realLifeTitle;

  /// No description provided for @savedRealLifeSituation.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Situation'**
  String get savedRealLifeSituation;

  /// No description provided for @savedRealLifeSituationsTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Situationen'**
  String get savedRealLifeSituationsTitle;

  /// No description provided for @realLifeLibraryIntro.
  ///
  /// In de, this message translates to:
  /// **'Wähle eine Situation oder lass Konterreflex passend zu deinem bisherigen Training entscheiden.'**
  String get realLifeLibraryIntro;

  /// No description provided for @randomPractice.
  ///
  /// In de, this message translates to:
  /// **'Zufällig üben'**
  String get randomPractice;

  /// No description provided for @tellNewSituation.
  ///
  /// In de, this message translates to:
  /// **'Neue Situation erzählen'**
  String get tellNewSituation;

  /// No description provided for @realLifeRandomPreparing.
  ///
  /// In de, this message translates to:
  /// **'Situation wird gewählt …'**
  String get realLifeRandomPreparing;

  /// No description provided for @realLifeLibraryLoadError.
  ///
  /// In de, this message translates to:
  /// **'Deine Situationen konnten gerade nicht geladen werden.'**
  String get realLifeLibraryLoadError;

  /// No description provided for @homeRealLifeDescription.
  ///
  /// In de, this message translates to:
  /// **'Erlebtes rekonstruieren und neu beantworten'**
  String get homeRealLifeDescription;

  /// No description provided for @speechChallengeTitle.
  ///
  /// In de, this message translates to:
  /// **'Speech Challenge'**
  String get speechChallengeTitle;

  /// No description provided for @homeSpeechChallengeDescription.
  ///
  /// In de, this message translates to:
  /// **'Kurz und spontan auf einen Impuls reagieren'**
  String get homeSpeechChallengeDescription;

  /// No description provided for @goldenBookTitle.
  ///
  /// In de, this message translates to:
  /// **'Golden Book'**
  String get goldenBookTitle;

  /// No description provided for @homeGoldenBookDescription.
  ///
  /// In de, this message translates to:
  /// **'Starke Formulierungen griffbereit sammeln'**
  String get homeGoldenBookDescription;

  /// No description provided for @historyTitle.
  ///
  /// In de, this message translates to:
  /// **'Verlauf'**
  String get historyTitle;

  /// No description provided for @onboardingTitle.
  ///
  /// In de, this message translates to:
  /// **'Wie dürfen wir dich ansprechen?'**
  String get onboardingTitle;

  /// No description provided for @onboardingBody.
  ///
  /// In de, this message translates to:
  /// **'Danach trainierst du vor allem mit deiner Stimme. Deinen Namen kannst du später ändern.'**
  String get onboardingBody;

  /// No description provided for @displayNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Vorname oder Anrede'**
  String get displayNameLabel;

  /// No description provided for @saving.
  ///
  /// In de, this message translates to:
  /// **'Wird gespeichert …'**
  String get saving;

  /// No description provided for @continueLabel.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get continueLabel;

  /// No description provided for @profileSaveError.
  ///
  /// In de, this message translates to:
  /// **'Dein Profil konnte nicht gespeichert werden.'**
  String get profileSaveError;

  /// No description provided for @privacyLoadError.
  ///
  /// In de, this message translates to:
  /// **'Datenschutzeinstellungen konnten nicht geladen werden.'**
  String get privacyLoadError;

  /// No description provided for @voiceRecordingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Sprachaufnahmen'**
  String get voiceRecordingsTitle;

  /// No description provided for @voiceRecordingsBody.
  ///
  /// In de, this message translates to:
  /// **'Standardmäßig wird Audio nur zur Transkription verarbeitet und nicht dauerhaft gespeichert.'**
  String get voiceRecordingsBody;

  /// No description provided for @recordingRetentionLabel.
  ///
  /// In de, this message translates to:
  /// **'Aufbewahrung für künftige optionale Aufnahmen'**
  String get recordingRetentionLabel;

  /// No description provided for @neverStore.
  ///
  /// In de, this message translates to:
  /// **'Nie dauerhaft speichern'**
  String get neverStore;

  /// No description provided for @dayCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{{count} Tag} other{{count} Tage}}'**
  String dayCount(int count);

  /// No description provided for @analyticsTitle.
  ///
  /// In de, this message translates to:
  /// **'Datensparsame Produktanalyse erlauben'**
  String get analyticsTitle;

  /// No description provided for @analyticsBody.
  ///
  /// In de, this message translates to:
  /// **'Nur feste Funnel- und Feature-Ereignisse. Keine Transkripte, Audiodaten oder Formulierungen.'**
  String get analyticsBody;

  /// No description provided for @showTranscript.
  ///
  /// In de, this message translates to:
  /// **'Transkript anzeigen'**
  String get showTranscript;

  /// No description provided for @hideTranscript.
  ///
  /// In de, this message translates to:
  /// **'Transkript ausblenden'**
  String get hideTranscript;

  /// No description provided for @transcriptLabel.
  ///
  /// In de, this message translates to:
  /// **'Transkript'**
  String get transcriptLabel;

  /// No description provided for @orbReady.
  ///
  /// In de, this message translates to:
  /// **'Bereit'**
  String get orbReady;

  /// No description provided for @orbPreparing.
  ///
  /// In de, this message translates to:
  /// **'Audio wird vorbereitet'**
  String get orbPreparing;

  /// No description provided for @orbSpeaking.
  ///
  /// In de, this message translates to:
  /// **'Konterreflex spricht'**
  String get orbSpeaking;

  /// No description provided for @orbListening.
  ///
  /// In de, this message translates to:
  /// **'Konterreflex hört zu'**
  String get orbListening;

  /// No description provided for @orbThinking.
  ///
  /// In de, this message translates to:
  /// **'Konterreflex denkt nach'**
  String get orbThinking;

  /// No description provided for @orbProcessingSpeech.
  ///
  /// In de, this message translates to:
  /// **'Antwort wird verarbeitet'**
  String get orbProcessingSpeech;

  /// No description provided for @orbProcessingSpeechComplete.
  ///
  /// In de, this message translates to:
  /// **'Antwort ist verarbeitet'**
  String get orbProcessingSpeechComplete;

  /// No description provided for @orbComplete.
  ///
  /// In de, this message translates to:
  /// **'Abgeschlossen'**
  String get orbComplete;

  /// No description provided for @authChecking.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung wird geprüft'**
  String get authChecking;

  /// No description provided for @oneMoment.
  ///
  /// In de, this message translates to:
  /// **'Einen Moment …'**
  String get oneMoment;

  /// No description provided for @validEmailError.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib eine gültige E-Mail-Adresse ein.'**
  String get validEmailError;

  /// No description provided for @passwordLengthError.
  ///
  /// In de, this message translates to:
  /// **'Das Passwort muss mindestens {count} Zeichen lang sein.'**
  String passwordLengthError(int count);

  /// No description provided for @passwordMismatchError.
  ///
  /// In de, this message translates to:
  /// **'Die Passwörter stimmen nicht überein.'**
  String get passwordMismatchError;

  /// No description provided for @authTooManyAttempts.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Versuche in kurzer Zeit. Bitte warte einen Moment und versuche es erneut.'**
  String get authTooManyAttempts;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In de, this message translates to:
  /// **'E-Mail-Adresse oder Passwort stimmen nicht.'**
  String get authInvalidCredentials;

  /// No description provided for @authEmailNotConfirmed.
  ///
  /// In de, this message translates to:
  /// **'Bitte bestätige zuerst deine E-Mail-Adresse.'**
  String get authEmailNotConfirmed;

  /// No description provided for @authWeakPassword.
  ///
  /// In de, this message translates to:
  /// **'Das Passwort ist nicht sicher genug. Verwende mindestens 8 Zeichen.'**
  String get authWeakPassword;

  /// No description provided for @authUserExists.
  ///
  /// In de, this message translates to:
  /// **'Für diese E-Mail-Adresse besteht bereits ein Konto.'**
  String get authUserExists;

  /// No description provided for @authSamePassword.
  ///
  /// In de, this message translates to:
  /// **'Das neue Passwort muss sich vom bisherigen unterscheiden.'**
  String get authSamePassword;

  /// No description provided for @authProviderDisabled.
  ///
  /// In de, this message translates to:
  /// **'Diese Anmeldung ist noch nicht freigeschaltet.'**
  String get authProviderDisabled;

  /// No description provided for @authRequestExpired.
  ///
  /// In de, this message translates to:
  /// **'Die Anfrage ist abgelaufen. Bitte starte den Vorgang erneut.'**
  String get authRequestExpired;

  /// No description provided for @createAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto erstellen'**
  String get createAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In de, this message translates to:
  /// **'Willkommen zurück'**
  String get welcomeBack;

  /// No description provided for @signUpIntro.
  ///
  /// In de, this message translates to:
  /// **'Erstelle dein Konterreflex-Konto mit E-Mail und Passwort.'**
  String get signUpIntro;

  /// No description provided for @signInIntro.
  ///
  /// In de, this message translates to:
  /// **'Melde dich an und setze dein Training fort.'**
  String get signInIntro;

  /// No description provided for @emailAddress.
  ///
  /// In de, this message translates to:
  /// **'E-Mail-Adresse'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get password;

  /// No description provided for @passwordMinimumHint.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 8 Zeichen'**
  String get passwordMinimumHint;

  /// No description provided for @showPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort anzeigen'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort verbergen'**
  String get hidePassword;

  /// No description provided for @repeatPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort wiederholen'**
  String get repeatPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort vergessen?'**
  String get forgotPassword;

  /// No description provided for @pleaseWait.
  ///
  /// In de, this message translates to:
  /// **'Bitte warten …'**
  String get pleaseWait;

  /// No description provided for @signIn.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get signIn;

  /// No description provided for @or.
  ///
  /// In de, this message translates to:
  /// **'oder'**
  String get or;

  /// No description provided for @continueWithGoogle.
  ///
  /// In de, this message translates to:
  /// **'Mit Google fortfahren'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In de, this message translates to:
  /// **'Mit Apple fortfahren'**
  String get continueWithApple;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In de, this message translates to:
  /// **'Du hast schon ein Konto? Anmelden'**
  String get alreadyHaveAccount;

  /// No description provided for @needAccount.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Konto? Jetzt registrieren'**
  String get needAccount;

  /// No description provided for @signUpError.
  ///
  /// In de, this message translates to:
  /// **'Das Konto konnte nicht erstellt werden.'**
  String get signUpError;

  /// No description provided for @signInError.
  ///
  /// In de, this message translates to:
  /// **'Die Anmeldung ist fehlgeschlagen.'**
  String get signInError;

  /// No description provided for @appleSignInError.
  ///
  /// In de, this message translates to:
  /// **'Die Anmeldung mit Apple ist fehlgeschlagen.'**
  String get appleSignInError;

  /// No description provided for @googleSignInError.
  ///
  /// In de, this message translates to:
  /// **'Die Anmeldung mit Google ist fehlgeschlagen.'**
  String get googleSignInError;

  /// No description provided for @accountCreatedConfirmation.
  ///
  /// In de, this message translates to:
  /// **'Konto erstellt. Bitte bestätige deine E-Mail-Adresse und melde dich danach an.'**
  String get accountCreatedConfirmation;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In de, this message translates to:
  /// **'Passwort zurücksetzen'**
  String get resetPasswordTitle;

  /// No description provided for @emailOnTheWay.
  ///
  /// In de, this message translates to:
  /// **'E-Mail ist unterwegs'**
  String get emailOnTheWay;

  /// No description provided for @resetSentBody.
  ///
  /// In de, this message translates to:
  /// **'Falls ein Konto für diese Adresse besteht, erhältst du einen Link zum Festlegen eines neuen Passworts.'**
  String get resetSentBody;

  /// No description provided for @resetRequestBody.
  ///
  /// In de, this message translates to:
  /// **'Gib deine E-Mail-Adresse ein. Wir senden dir einen sicheren Link zum Festlegen eines neuen Passworts.'**
  String get resetRequestBody;

  /// No description provided for @sendResetLink.
  ///
  /// In de, this message translates to:
  /// **'Reset-Link senden'**
  String get sendResetLink;

  /// No description provided for @backToSignIn.
  ///
  /// In de, this message translates to:
  /// **'Zurück zur Anmeldung'**
  String get backToSignIn;

  /// No description provided for @resetEmailError.
  ///
  /// In de, this message translates to:
  /// **'Die E-Mail konnte nicht gesendet werden.'**
  String get resetEmailError;

  /// No description provided for @newPassword.
  ///
  /// In de, this message translates to:
  /// **'Neues Passwort'**
  String get newPassword;

  /// No description provided for @newPasswordBody.
  ///
  /// In de, this message translates to:
  /// **'Lege ein neues Passwort mit mindestens 8 Zeichen fest.'**
  String get newPasswordBody;

  /// No description provided for @savePassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort speichern'**
  String get savePassword;

  /// No description provided for @passwordUpdateError.
  ///
  /// In de, this message translates to:
  /// **'Das Passwort konnte nicht geändert werden.'**
  String get passwordUpdateError;

  /// No description provided for @passwordUpdated.
  ///
  /// In de, this message translates to:
  /// **'Dein Passwort wurde geändert.'**
  String get passwordUpdated;

  /// No description provided for @voiceSceneUnknown.
  ///
  /// In de, this message translates to:
  /// **'Die Szene konnte nicht abgespielt werden ({code}).'**
  String voiceSceneUnknown(String code);

  /// No description provided for @voiceAuthExpired.
  ///
  /// In de, this message translates to:
  /// **'Die Audio-Anmeldung ist abgelaufen. Bitte melde dich erneut an ({code}).'**
  String voiceAuthExpired(String code);

  /// No description provided for @voiceRequestRejected.
  ///
  /// In de, this message translates to:
  /// **'Die Sprachanfrage wurde abgelehnt ({code}).'**
  String voiceRequestRejected(String code);

  /// No description provided for @voiceTimeout.
  ///
  /// In de, this message translates to:
  /// **'Die Sprachausgabe hat zu lange gebraucht. Bitte versuche es erneut ({code}).'**
  String voiceTimeout(String code);

  /// No description provided for @voiceUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Die Sprachausgabe ist gerade nicht erreichbar ({code}).'**
  String voiceUnavailable(String code);

  /// No description provided for @voiceInvalidAudio.
  ///
  /// In de, this message translates to:
  /// **'Die empfangenen Audiodaten waren ungültig ({code}).'**
  String voiceInvalidAudio(String code);

  /// No description provided for @voicePlaybackError.
  ///
  /// In de, this message translates to:
  /// **'Das Gerät konnte die Audiodatei nicht wiedergeben ({code}).'**
  String voicePlaybackError(String code);

  /// No description provided for @microphoneDisabled.
  ///
  /// In de, this message translates to:
  /// **'Mikrofonzugriff ist deaktiviert. Du kannst ihn in den Einstellungen erlauben.'**
  String get microphoneDisabled;

  /// No description provided for @microphoneRecordingRequired.
  ///
  /// In de, this message translates to:
  /// **'Ohne Mikrofonzugriff ist keine Sprachaufnahme möglich.'**
  String get microphoneRecordingRequired;

  /// No description provided for @recordingStartError.
  ///
  /// In de, this message translates to:
  /// **'Die Aufnahme konnte nicht gestartet werden.'**
  String get recordingStartError;

  /// No description provided for @responseProcessError.
  ///
  /// In de, this message translates to:
  /// **'Deine Antwort konnte nicht verarbeitet werden. Bitte versuche es erneut.'**
  String get responseProcessError;

  /// No description provided for @microphoneHandsFreeRequired.
  ///
  /// In de, this message translates to:
  /// **'Ohne Mikrofonzugriff ist kein freihändiger Ablauf möglich.'**
  String get microphoneHandsFreeRequired;

  /// No description provided for @responseNotUnderstood.
  ///
  /// In de, this message translates to:
  /// **'Deine Antwort konnte nicht verstanden werden.'**
  String get responseNotUnderstood;

  /// No description provided for @playbackInterrupted.
  ///
  /// In de, this message translates to:
  /// **'Wiedergabe unterbrochen. Du bist dran.'**
  String get playbackInterrupted;

  /// No description provided for @trainingTitle.
  ///
  /// In de, this message translates to:
  /// **'Training'**
  String get trainingTitle;

  /// No description provided for @trainingSelectingTitle.
  ///
  /// In de, this message translates to:
  /// **'Passende Situation wird gewählt'**
  String get trainingSelectingTitle;

  /// No description provided for @trainingSelectingBody.
  ///
  /// In de, this message translates to:
  /// **'Konterreflex berücksichtigt, was du zuletzt geübt hast.'**
  String get trainingSelectingBody;

  /// No description provided for @nextScenario.
  ///
  /// In de, this message translates to:
  /// **'Nächste Situation'**
  String get nextScenario;

  /// No description provided for @scenariosLoadError.
  ///
  /// In de, this message translates to:
  /// **'Die Szenarien konnten nicht geladen werden.'**
  String get scenariosLoadError;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get retry;

  /// No description provided for @noApprovedScenarios.
  ///
  /// In de, this message translates to:
  /// **'Noch keine freigegebenen Szenarien.'**
  String get noApprovedScenarios;

  /// No description provided for @groupLabel.
  ///
  /// In de, this message translates to:
  /// **'Gruppe'**
  String get groupLabel;

  /// No description provided for @trainingReady.
  ///
  /// In de, this message translates to:
  /// **'Bereit für die Situation?'**
  String get trainingReady;

  /// No description provided for @trainingStarting.
  ///
  /// In de, this message translates to:
  /// **'Training wird vorbereitet …'**
  String get trainingStarting;

  /// No description provided for @trainingPlaying.
  ///
  /// In de, this message translates to:
  /// **'Hör dir die Situation an'**
  String get trainingPlaying;

  /// No description provided for @trainingAnswerPrompt.
  ///
  /// In de, this message translates to:
  /// **'Wie antwortest du?'**
  String get trainingAnswerPrompt;

  /// No description provided for @trainingRecording.
  ///
  /// In de, this message translates to:
  /// **'Du sprichst'**
  String get trainingRecording;

  /// No description provided for @trainingProcessing.
  ///
  /// In de, this message translates to:
  /// **'Antwort wird verarbeitet …'**
  String get trainingProcessing;

  /// No description provided for @trainingFeedbackReady.
  ///
  /// In de, this message translates to:
  /// **'Dein Feedback'**
  String get trainingFeedbackReady;

  /// No description provided for @trainingFollowUp.
  ///
  /// In de, this message translates to:
  /// **'Deine Rückfrage'**
  String get trainingFollowUp;

  /// No description provided for @trainingFollowUpProcessing.
  ///
  /// In de, this message translates to:
  /// **'Rückfrage wird beantwortet …'**
  String get trainingFollowUpProcessing;

  /// No description provided for @trainingGoldenBookPrompt.
  ///
  /// In de, this message translates to:
  /// **'Welche Formulierung möchtest du speichern?'**
  String get trainingGoldenBookPrompt;

  /// No description provided for @trainingGoldenBookProcessing.
  ///
  /// In de, this message translates to:
  /// **'Formulierung wird aufgelöst …'**
  String get trainingGoldenBookProcessing;

  /// No description provided for @notComplete.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht abgeschlossen'**
  String get notComplete;

  /// No description provided for @allowMicrophoneSettings.
  ///
  /// In de, this message translates to:
  /// **'Mikrofon in Einstellungen erlauben'**
  String get allowMicrophoneSettings;

  /// No description provided for @interruptPlayback.
  ///
  /// In de, this message translates to:
  /// **'Wiedergabe unterbrechen'**
  String get interruptPlayback;

  /// No description provided for @savedInGoldenBook.
  ///
  /// In de, this message translates to:
  /// **'Im Golden Book gespeichert: „{phrase}“'**
  String savedInGoldenBook(String phrase);

  /// No description provided for @startScene.
  ///
  /// In de, this message translates to:
  /// **'Szene starten'**
  String get startScene;

  /// No description provided for @recordAnswer.
  ///
  /// In de, this message translates to:
  /// **'Antwort aufnehmen'**
  String get recordAnswer;

  /// No description provided for @stopRecording.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme beenden'**
  String get stopRecording;

  /// No description provided for @sendFollowUp.
  ///
  /// In de, this message translates to:
  /// **'Rückfrage senden'**
  String get sendFollowUp;

  /// No description provided for @sendVoiceCommand.
  ///
  /// In de, this message translates to:
  /// **'Sprachbefehl senden'**
  String get sendVoiceCommand;

  /// No description provided for @askFollowUp.
  ///
  /// In de, this message translates to:
  /// **'Rückfrage stellen'**
  String get askFollowUp;

  /// No description provided for @savePhraseByVoice.
  ///
  /// In de, this message translates to:
  /// **'Satz per Stimme speichern'**
  String get savePhraseByVoice;

  /// No description provided for @repeatScene.
  ///
  /// In de, this message translates to:
  /// **'Szene wiederholen'**
  String get repeatScene;

  /// No description provided for @retrySave.
  ///
  /// In de, this message translates to:
  /// **'Speichern erneut versuchen'**
  String get retrySave;

  /// No description provided for @restart.
  ///
  /// In de, this message translates to:
  /// **'Erneut starten'**
  String get restart;

  /// No description provided for @feedbackStrengths.
  ///
  /// In de, this message translates to:
  /// **'Das trägt'**
  String get feedbackStrengths;

  /// No description provided for @feedbackNextStep.
  ///
  /// In de, this message translates to:
  /// **'Nächster Schritt'**
  String get feedbackNextStep;

  /// No description provided for @feedbackAlternatives.
  ///
  /// In de, this message translates to:
  /// **'Natürliche Alternativen'**
  String get feedbackAlternatives;

  /// No description provided for @feedbackOverview.
  ///
  /// In de, this message translates to:
  /// **'Auf einen Blick'**
  String get feedbackOverview;

  /// No description provided for @feedbackSignalStrong.
  ///
  /// In de, this message translates to:
  /// **'Stark gelöst'**
  String get feedbackSignalStrong;

  /// No description provided for @feedbackSignalDeveloping.
  ///
  /// In de, this message translates to:
  /// **'Auf gutem Weg'**
  String get feedbackSignalDeveloping;

  /// No description provided for @feedbackSignalFocus.
  ///
  /// In de, this message translates to:
  /// **'Noch einmal schärfen'**
  String get feedbackSignalFocus;

  /// No description provided for @feedbackDimensionPosture.
  ///
  /// In de, this message translates to:
  /// **'Präsenz'**
  String get feedbackDimensionPosture;

  /// No description provided for @feedbackDimensionPrecision.
  ///
  /// In de, this message translates to:
  /// **'Präzision'**
  String get feedbackDimensionPrecision;

  /// No description provided for @feedbackDimensionFrame.
  ///
  /// In de, this message translates to:
  /// **'Rahmen'**
  String get feedbackDimensionFrame;

  /// No description provided for @feedbackDimensionSocialEffect.
  ///
  /// In de, this message translates to:
  /// **'Wirkung'**
  String get feedbackDimensionSocialEffect;

  /// No description provided for @feedbackDimensionNaturalness.
  ///
  /// In de, this message translates to:
  /// **'Natürlich'**
  String get feedbackDimensionNaturalness;

  /// No description provided for @feedbackDimensionEscalationFit.
  ///
  /// In de, this message translates to:
  /// **'Passung'**
  String get feedbackDimensionEscalationFit;

  /// No description provided for @saveInGoldenBook.
  ///
  /// In de, this message translates to:
  /// **'Im Golden Book speichern'**
  String get saveInGoldenBook;

  /// No description provided for @sceneIncompleteError.
  ///
  /// In de, this message translates to:
  /// **'Die Szene konnte nicht vollständig abgespielt werden.'**
  String get sceneIncompleteError;

  /// No description provided for @trainingStartError.
  ///
  /// In de, this message translates to:
  /// **'Die Trainingseinheit konnte nicht gestartet werden.'**
  String get trainingStartError;

  /// No description provided for @transcriptionError.
  ///
  /// In de, this message translates to:
  /// **'Deine Antwort konnte nicht transkribiert werden.'**
  String get transcriptionError;

  /// No description provided for @nothingToSaveError.
  ///
  /// In de, this message translates to:
  /// **'Es gibt noch keine Antwort zum Speichern.'**
  String get nothingToSaveError;

  /// No description provided for @feedbackSaveError.
  ///
  /// In de, this message translates to:
  /// **'Feedback und Antwort sind noch nicht vollständig gespeichert. Bitte versuche es erneut.'**
  String get feedbackSaveError;

  /// No description provided for @followUpStartError.
  ///
  /// In de, this message translates to:
  /// **'Die Rückfrage konnte nicht gestartet werden.'**
  String get followUpStartError;

  /// No description provided for @followUpUnderstandError.
  ///
  /// In de, this message translates to:
  /// **'Die Rückfrage konnte nicht verstanden werden.'**
  String get followUpUnderstandError;

  /// No description provided for @followUpAnswerError.
  ///
  /// In de, this message translates to:
  /// **'Die Rückfrage konnte gerade nicht beantwortet werden.'**
  String get followUpAnswerError;

  /// No description provided for @voiceCommandStartError.
  ///
  /// In de, this message translates to:
  /// **'Der Sprachbefehl konnte nicht gestartet werden.'**
  String get voiceCommandStartError;

  /// No description provided for @voiceCommandUnderstandError.
  ///
  /// In de, this message translates to:
  /// **'Der Sprachbefehl konnte nicht verstanden werden.'**
  String get voiceCommandUnderstandError;

  /// No description provided for @phraseSaveError.
  ///
  /// In de, this message translates to:
  /// **'Die Formulierung konnte nicht gespeichert werden.'**
  String get phraseSaveError;

  /// No description provided for @savedSpoken.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert: {phrase}'**
  String savedSpoken(String phrase);

  /// No description provided for @chooseTopic.
  ///
  /// In de, this message translates to:
  /// **'Wähle ein Thema'**
  String get chooseTopic;

  /// No description provided for @speechChallengeIntro.
  ///
  /// In de, this message translates to:
  /// **'Kurze Impulse im Flow. Deine gemeinsame qualitative Auswertung folgt am Ende.'**
  String get speechChallengeIntro;

  /// No description provided for @challengeSetsLoadError.
  ///
  /// In de, this message translates to:
  /// **'Die Challenge-Sets konnten nicht geladen werden.'**
  String get challengeSetsLoadError;

  /// No description provided for @again.
  ///
  /// In de, this message translates to:
  /// **'Noch einmal'**
  String get again;

  /// No description provided for @startHandsFree.
  ///
  /// In de, this message translates to:
  /// **'Freihändig starten'**
  String get startHandsFree;

  /// No description provided for @endChallenge.
  ///
  /// In de, this message translates to:
  /// **'Challenge beenden'**
  String get endChallenge;

  /// No description provided for @challengeReady.
  ///
  /// In de, this message translates to:
  /// **'Bereit für kurze Impulse?'**
  String get challengeReady;

  /// No description provided for @listen.
  ///
  /// In de, this message translates to:
  /// **'Hör zu'**
  String get listen;

  /// No description provided for @speakResponse.
  ///
  /// In de, this message translates to:
  /// **'Sprich deine Antwort'**
  String get speakResponse;

  /// No description provided for @challengeTransitioning.
  ///
  /// In de, this message translates to:
  /// **'Antwort gespeichert · gleich geht es weiter'**
  String get challengeTransitioning;

  /// No description provided for @challengeEvaluating.
  ///
  /// In de, this message translates to:
  /// **'Deine Antworten werden zusammengeführt …'**
  String get challengeEvaluating;

  /// No description provided for @setComplete.
  ///
  /// In de, this message translates to:
  /// **'Set abgeschlossen'**
  String get setComplete;

  /// No description provided for @brieflyInterrupted.
  ///
  /// In de, this message translates to:
  /// **'Kurz unterbrochen'**
  String get brieflyInterrupted;

  /// No description provided for @challengeContinueError.
  ///
  /// In de, this message translates to:
  /// **'Die Challenge konnte gerade nicht fortgesetzt werden.'**
  String get challengeContinueError;

  /// No description provided for @promptPlaybackError.
  ///
  /// In de, this message translates to:
  /// **'Der Impuls konnte nicht abgespielt werden.'**
  String get promptPlaybackError;

  /// No description provided for @challengeLengthTitle.
  ///
  /// In de, this message translates to:
  /// **'Wie viele Impulse möchtest du?'**
  String get challengeLengthTitle;

  /// No description provided for @challengeLengthBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle die Länge deiner Session. Während des Durchlaufs gibt es keine Unterbrechung durch Feedback.'**
  String get challengeLengthBody;

  /// No description provided for @challengeLengthCustom.
  ///
  /// In de, this message translates to:
  /// **'Eigene Anzahl'**
  String get challengeLengthCustom;

  /// No description provided for @challengeLengthRange.
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle 1 bis {max}.'**
  String challengeLengthRange(int max);

  /// No description provided for @challengeAvailableCount.
  ///
  /// In de, this message translates to:
  /// **'{count} unterschiedliche Impulse verfügbar'**
  String challengeAvailableCount(int count);

  /// No description provided for @startChallengeWithCount.
  ///
  /// In de, this message translates to:
  /// **'Challenge mit {count} Impulsen starten'**
  String startChallengeWithCount(int count);

  /// No description provided for @challengeProgress.
  ///
  /// In de, this message translates to:
  /// **'Impuls {current} von {total}'**
  String challengeProgress(int current, int total);

  /// No description provided for @challengeResultTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Auswertung'**
  String get challengeResultTitle;

  /// No description provided for @challengeResultBody.
  ///
  /// In de, this message translates to:
  /// **'Gemeinsames Feedback aus {count} Antworten.'**
  String challengeResultBody(int count);

  /// No description provided for @challengePartialResultBody.
  ///
  /// In de, this message translates to:
  /// **'Du hast {completed} von {target} Impulsen abgeschlossen. Hier ist die gemeinsame Auswertung deiner Antworten.'**
  String challengePartialResultBody(int completed, int target);

  /// No description provided for @challengeDetailsTitle.
  ///
  /// In de, this message translates to:
  /// **'Details zu deinen Antworten'**
  String get challengeDetailsTitle;

  /// No description provided for @challengePromptNumber.
  ///
  /// In de, this message translates to:
  /// **'Impuls {number}'**
  String challengePromptNumber(int number);

  /// No description provided for @challengeYourAnswer.
  ///
  /// In de, this message translates to:
  /// **'Deine Antwort'**
  String get challengeYourAnswer;

  /// No description provided for @challengeDetailAlternative.
  ///
  /// In de, this message translates to:
  /// **'Eine natürliche Alternative'**
  String get challengeDetailAlternative;

  /// No description provided for @newChallenge.
  ///
  /// In de, this message translates to:
  /// **'Neue Challenge'**
  String get newChallenge;

  /// No description provided for @retryChallengeEvaluation.
  ///
  /// In de, this message translates to:
  /// **'Auswertung erneut versuchen'**
  String get retryChallengeEvaluation;

  /// No description provided for @challengeEvaluationCapacityError.
  ///
  /// In de, this message translates to:
  /// **'Deine Antworten sind gespeichert. Die KI-Auswertung ist gerade ausgelastet und kann erneut versucht werden.'**
  String get challengeEvaluationCapacityError;

  /// No description provided for @challengeEvaluationError.
  ///
  /// In de, this message translates to:
  /// **'Deine Antworten sind gespeichert, aber die gemeinsame Auswertung konnte noch nicht erstellt werden.'**
  String get challengeEvaluationError;

  /// No description provided for @realLifeScenarioTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine echte Situation'**
  String get realLifeScenarioTitle;

  /// No description provided for @realLifeReadyTitle.
  ///
  /// In de, this message translates to:
  /// **'Was ist passiert?'**
  String get realLifeReadyTitle;

  /// No description provided for @realLifeDescribingTitle.
  ///
  /// In de, this message translates to:
  /// **'Erzähl in deinem Tempo'**
  String get realLifeDescribingTitle;

  /// No description provided for @realLifeExtractingTitle.
  ///
  /// In de, this message translates to:
  /// **'Situation wird verstanden …'**
  String get realLifeExtractingTitle;

  /// No description provided for @realLifeConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Passt diese Zusammenfassung?'**
  String get realLifeConfirmTitle;

  /// No description provided for @realLifeFollowUpTitle.
  ///
  /// In de, this message translates to:
  /// **'Ergänze nur das Wesentliche'**
  String get realLifeFollowUpTitle;

  /// No description provided for @realLifeReconstructingTitle.
  ///
  /// In de, this message translates to:
  /// **'Szene wird rekonstruiert …'**
  String get realLifeReconstructingTitle;

  /// No description provided for @realLifeReplayReadyTitle.
  ///
  /// In de, this message translates to:
  /// **'Bereit für den zweiten Versuch?'**
  String get realLifeReplayReadyTitle;

  /// No description provided for @realLifePreparingPlaybackTitle.
  ///
  /// In de, this message translates to:
  /// **'Szene wird vorbereitet'**
  String get realLifePreparingPlaybackTitle;

  /// No description provided for @realLifePlayingTitle.
  ///
  /// In de, this message translates to:
  /// **'Hör dir die Szene an'**
  String get realLifePlayingTitle;

  /// No description provided for @realLifeResponseTitle.
  ///
  /// In de, this message translates to:
  /// **'Wie antwortest du jetzt?'**
  String get realLifeResponseTitle;

  /// No description provided for @realLifeRecordingTitle.
  ///
  /// In de, this message translates to:
  /// **'Du sprichst'**
  String get realLifeRecordingTitle;

  /// No description provided for @realLifeReflectingTitle.
  ///
  /// In de, this message translates to:
  /// **'Antwort wird reflektiert …'**
  String get realLifeReflectingTitle;

  /// No description provided for @realLifePresentingFeedbackTitle.
  ///
  /// In de, this message translates to:
  /// **'Konterreflex antwortet'**
  String get realLifePresentingFeedbackTitle;

  /// No description provided for @realLifeFeedbackTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Feedback'**
  String get realLifeFeedbackTitle;

  /// No description provided for @realLifeErrorTitle.
  ///
  /// In de, this message translates to:
  /// **'Das hat noch nicht geklappt'**
  String get realLifeErrorTitle;

  /// No description provided for @realLifeReadyBody.
  ///
  /// In de, this message translates to:
  /// **'Beschreibe Ort, Beteiligte und den entscheidenden Satz. Tippen ist nicht nötig.'**
  String get realLifeReadyBody;

  /// No description provided for @realLifeConfirmBody.
  ///
  /// In de, this message translates to:
  /// **'Du kannst bestätigen oder eine wesentliche Lücke per Stimme ergänzen.'**
  String get realLifeConfirmBody;

  /// No description provided for @realLifeFeedbackBody.
  ///
  /// In de, this message translates to:
  /// **'Wiederhole die Szene oder übe eine ähnliche Variante.'**
  String get realLifeFeedbackBody;

  /// No description provided for @settingDetail.
  ///
  /// In de, this message translates to:
  /// **'Ort und Rahmen'**
  String get settingDetail;

  /// No description provided for @participantsDetail.
  ///
  /// In de, this message translates to:
  /// **'Beteiligte'**
  String get participantsDetail;

  /// No description provided for @triggerStatementDetail.
  ///
  /// In de, this message translates to:
  /// **'Entscheidender Satz'**
  String get triggerStatementDetail;

  /// No description provided for @observableToneDetail.
  ///
  /// In de, this message translates to:
  /// **'Beobachtbarer Ton'**
  String get observableToneDetail;

  /// No description provided for @socialTensionDetail.
  ///
  /// In de, this message translates to:
  /// **'Soziale Spannung'**
  String get socialTensionDetail;

  /// No description provided for @notSure.
  ///
  /// In de, this message translates to:
  /// **'Nicht sicher'**
  String get notSure;

  /// No description provided for @tellSituation.
  ///
  /// In de, this message translates to:
  /// **'Situation erzählen'**
  String get tellSituation;

  /// No description provided for @finishStory.
  ///
  /// In de, this message translates to:
  /// **'Erzählung beenden'**
  String get finishStory;

  /// No description provided for @confirmCreateScene.
  ///
  /// In de, this message translates to:
  /// **'Passt · Szene erstellen'**
  String get confirmCreateScene;

  /// No description provided for @addByVoice.
  ///
  /// In de, this message translates to:
  /// **'Per Stimme ergänzen'**
  String get addByVoice;

  /// No description provided for @acceptAddition.
  ///
  /// In de, this message translates to:
  /// **'Ergänzung übernehmen'**
  String get acceptAddition;

  /// No description provided for @playScene.
  ///
  /// In de, this message translates to:
  /// **'Szene abspielen'**
  String get playScene;

  /// No description provided for @answerAgain.
  ///
  /// In de, this message translates to:
  /// **'Neu antworten'**
  String get answerAgain;

  /// No description provided for @finishAnswer.
  ///
  /// In de, this message translates to:
  /// **'Antwort beenden'**
  String get finishAnswer;

  /// No description provided for @repeatSameScene.
  ///
  /// In de, this message translates to:
  /// **'Gleiche Szene wiederholen'**
  String get repeatSameScene;

  /// No description provided for @similarVariation.
  ///
  /// In de, this message translates to:
  /// **'Ähnliche Variante'**
  String get similarVariation;

  /// No description provided for @startOver.
  ///
  /// In de, this message translates to:
  /// **'Neu beginnen'**
  String get startOver;

  /// No description provided for @realLifeProcessError.
  ///
  /// In de, this message translates to:
  /// **'Die Situation konnte nicht verarbeitet werden.'**
  String get realLifeProcessError;

  /// No description provided for @realLifeAdditionError.
  ///
  /// In de, this message translates to:
  /// **'Die Ergänzung konnte nicht verarbeitet werden.'**
  String get realLifeAdditionError;

  /// No description provided for @realLifeReconstructError.
  ///
  /// In de, this message translates to:
  /// **'Die Szene konnte nicht rekonstruiert werden.'**
  String get realLifeReconstructError;

  /// No description provided for @realLifePlaybackError.
  ///
  /// In de, this message translates to:
  /// **'Die rekonstruierte Szene konnte nicht abgespielt werden.'**
  String get realLifePlaybackError;

  /// No description provided for @realLifeEvaluationError.
  ///
  /// In de, this message translates to:
  /// **'Deine Antwort konnte nicht vollständig ausgewertet werden.'**
  String get realLifeEvaluationError;

  /// No description provided for @realLifeVariationError.
  ///
  /// In de, this message translates to:
  /// **'Eine ähnliche Variante konnte nicht erstellt werden.'**
  String get realLifeVariationError;

  /// No description provided for @microphoneSettingsDisabled.
  ///
  /// In de, this message translates to:
  /// **'Mikrofonzugriff ist in den Einstellungen deaktiviert.'**
  String get microphoneSettingsDisabled;

  /// No description provided for @microphoneFlowRequired.
  ///
  /// In de, this message translates to:
  /// **'Für diesen Sprachfluss wird Mikrofonzugriff benötigt.'**
  String get microphoneFlowRequired;

  /// No description provided for @realLifeFollowUpTranscript.
  ///
  /// In de, this message translates to:
  /// **'Ergänzung zu \"{question}\": {answer}'**
  String realLifeFollowUpTranscript(String question, String answer);

  /// No description provided for @personalFavorite.
  ///
  /// In de, this message translates to:
  /// **'Persönlicher Favorit'**
  String get personalFavorite;

  /// No description provided for @searchPhrases.
  ///
  /// In de, this message translates to:
  /// **'Formulierungen durchsuchen'**
  String get searchPhrases;

  /// No description provided for @all.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get all;

  /// No description provided for @noGoldenBookEntries.
  ///
  /// In de, this message translates to:
  /// **'Noch keine passenden Formulierungen. Speichere Favoriten direkt aus deinem Training.'**
  String get noGoldenBookEntries;

  /// No description provided for @goldenBookLoadError.
  ///
  /// In de, this message translates to:
  /// **'Dein Golden Book konnte nicht geladen werden.'**
  String get goldenBookLoadError;

  /// No description provided for @fromTrainingSession.
  ///
  /// In de, this message translates to:
  /// **'Aus einer Trainingseinheit'**
  String get fromTrainingSession;

  /// No description provided for @deleteEntry.
  ///
  /// In de, this message translates to:
  /// **'Eintrag löschen'**
  String get deleteEntry;

  /// No description provided for @quotedPhrase.
  ///
  /// In de, this message translates to:
  /// **'„{phrase}“'**
  String quotedPhrase(String phrase);

  /// No description provided for @historyLoadError.
  ///
  /// In de, this message translates to:
  /// **'Dein Verlauf konnte nicht geladen werden.'**
  String get historyLoadError;

  /// No description provided for @historyPrivacyBody.
  ///
  /// In de, this message translates to:
  /// **'Hier siehst du nur notwendige Sitzungsdaten. Gesprochene Rohaufnahmen werden standardmäßig nicht dauerhaft gespeichert.'**
  String get historyPrivacyBody;

  /// No description provided for @noHistoryEntries.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einträge.'**
  String get noHistoryEntries;

  /// No description provided for @notCompletedSuffix.
  ///
  /// In de, this message translates to:
  /// **' · nicht abgeschlossen'**
  String get notCompletedSuffix;

  /// No description provided for @manageGoldenBook.
  ///
  /// In de, this message translates to:
  /// **'Golden Book verwalten und Einträge löschen'**
  String get manageGoldenBook;

  /// No description provided for @deleteEntryDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'Eintrag löschen?'**
  String get deleteEntryDialogTitle;

  /// No description provided for @deleteRealLifeHistoryBody.
  ///
  /// In de, this message translates to:
  /// **'Die echte Situation und zugehörige Wiederholungen werden dauerhaft gelöscht.'**
  String get deleteRealLifeHistoryBody;

  /// No description provided for @deleteSessionHistoryBody.
  ///
  /// In de, this message translates to:
  /// **'Die Sitzung, Antworten und das zugehörige Feedback werden dauerhaft gelöscht.'**
  String get deleteSessionHistoryBody;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @toldRealLifeSituation.
  ///
  /// In de, this message translates to:
  /// **'Erzählte echte Situation'**
  String get toldRealLifeSituation;

  /// No description provided for @realLifeReplayHistory.
  ///
  /// In de, this message translates to:
  /// **'Wiederholung einer echten Situation'**
  String get realLifeReplayHistory;

  /// No description provided for @trainingSessionHistory.
  ///
  /// In de, this message translates to:
  /// **'Trainingseinheit'**
  String get trainingSessionHistory;

  /// No description provided for @freeAccess.
  ///
  /// In de, this message translates to:
  /// **'Kostenloser Zugriff'**
  String get freeAccess;

  /// No description provided for @premiumConfirmed.
  ///
  /// In de, this message translates to:
  /// **'Dein Pro-Zugriff ist serverseitig bestätigt.'**
  String get premiumConfirmed;

  /// No description provided for @freeAccessBody.
  ///
  /// In de, this message translates to:
  /// **'Freie Nutzung und Grenzen werden serverseitig konfiguriert.'**
  String get freeAccessBody;

  /// No description provided for @currentPeriodUntil.
  ///
  /// In de, this message translates to:
  /// **'Aktueller Zeitraum bis {date}'**
  String currentPeriodUntil(String date);

  /// No description provided for @accessLoadError.
  ///
  /// In de, this message translates to:
  /// **'Der Zugriff konnte nicht geladen werden.'**
  String get accessLoadError;

  /// No description provided for @unlockPro.
  ///
  /// In de, this message translates to:
  /// **'Pro freischalten'**
  String get unlockPro;

  /// No description provided for @manageSubscription.
  ///
  /// In de, this message translates to:
  /// **'Abo verwalten'**
  String get manageSubscription;

  /// No description provided for @restorePurchases.
  ///
  /// In de, this message translates to:
  /// **'Käufe wiederherstellen'**
  String get restorePurchases;

  /// No description provided for @refreshAccess.
  ///
  /// In de, this message translates to:
  /// **'Zugriff aktualisieren'**
  String get refreshAccess;

  /// No description provided for @billingChannelMissing.
  ///
  /// In de, this message translates to:
  /// **'Für diese Plattform ist noch kein Kaufkanal eingerichtet. Du kannst deinen Zugriff trotzdem aktualisieren.'**
  String get billingChannelMissing;

  /// No description provided for @billingError.
  ///
  /// In de, this message translates to:
  /// **'Die Abrechnung konnte nicht abgeschlossen werden. Es wurde kein Zugriff lokal freigeschaltet.'**
  String get billingError;

  /// No description provided for @billingDisclaimer.
  ///
  /// In de, this message translates to:
  /// **'Der verfügbare Kaufweg hängt von Plattform, Region und Store-Regeln ab. Ein erfolgreicher Bezahlbildschirm allein schaltet keine Funktionen frei.'**
  String get billingDisclaimer;

  /// No description provided for @routeLoadError.
  ///
  /// In de, this message translates to:
  /// **'Die Ansicht konnte nicht geladen werden.'**
  String get routeLoadError;

  /// No description provided for @spokenStrength.
  ///
  /// In de, this message translates to:
  /// **' Stärke: {strength}.'**
  String spokenStrength(String strength);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
