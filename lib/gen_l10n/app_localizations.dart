import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ru.dart';
import 'app_localizations_tg.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
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
    Locale('ru'),
    Locale('tg'),
  ];

  /// No description provided for @appName.
  ///
  /// In ru, this message translates to:
  /// **'manzilho'**
  String get appName;

  /// No description provided for @langTajik.
  ///
  /// In ru, this message translates to:
  /// **'Тоҷикӣ'**
  String get langTajik;

  /// No description provided for @langRussian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get langRussian;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль, оформление и уведомления'**
  String get settingsSubtitle;

  /// No description provided for @sectionLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get sectionLanguage;

  /// No description provided for @settingsLanguageHint.
  ///
  /// In ru, this message translates to:
  /// **'Интерфейс на русском или таджикском.'**
  String get settingsLanguageHint;

  /// No description provided for @sectionAccount.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get sectionAccount;

  /// No description provided for @personalData.
  ///
  /// In ru, this message translates to:
  /// **'Личные данные'**
  String get personalData;

  /// No description provided for @favorites.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get favorites;

  /// No description provided for @sectionAppearance.
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get sectionAppearance;

  /// No description provided for @themeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Тема оформления'**
  String get themeTitle;

  /// No description provided for @themeHint.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления — в шапке; тема переключается здесь.'**
  String get themeHint;

  /// No description provided for @themeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In ru, this message translates to:
  /// **'Система'**
  String get themeSystem;

  /// No description provided for @sectionNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get sectionNotifications;

  /// No description provided for @notificationCenter.
  ///
  /// In ru, this message translates to:
  /// **'Центр уведомлений'**
  String get notificationCenter;

  /// No description provided for @notificationCenterSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Сообщения и подсказки'**
  String get notificationCenterSubtitle;

  /// No description provided for @pushNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Push-уведомления'**
  String get pushNotifications;

  /// No description provided for @pushPermissionsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Разрешения системы'**
  String get pushPermissionsSubtitle;

  /// No description provided for @sectionAboutShort.
  ///
  /// In ru, this message translates to:
  /// **'О нас'**
  String get sectionAboutShort;

  /// No description provided for @aboutUs.
  ///
  /// In ru, this message translates to:
  /// **'О нас'**
  String get aboutUs;

  /// No description provided for @sectionLegal.
  ///
  /// In ru, this message translates to:
  /// **'Юридическое'**
  String get sectionLegal;

  /// No description provided for @privacyPolicy.
  ///
  /// In ru, this message translates to:
  /// **'Политика конфиденциальности'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In ru, this message translates to:
  /// **'Условия использования'**
  String get termsOfService;

  /// No description provided for @sectionAboutApp.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get sectionAboutApp;

  /// No description provided for @aboutApp.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get aboutApp;

  /// No description provided for @appVersionLine.
  ///
  /// In ru, this message translates to:
  /// **'manzilho · версия 1.0.0'**
  String get appVersionLine;

  /// No description provided for @navHome.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get navHome;

  /// No description provided for @navFavorites.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get navFavorites;

  /// No description provided for @navAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get navAdd;

  /// No description provided for @navMessages.
  ///
  /// In ru, this message translates to:
  /// **'Сообщения'**
  String get navMessages;

  /// No description provided for @navProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get navProfile;

  /// No description provided for @menuSearch.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get menuSearch;

  /// No description provided for @menuNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get menuNotifications;

  /// No description provided for @menuCompare.
  ///
  /// In ru, this message translates to:
  /// **'Сравнение'**
  String get menuCompare;

  /// No description provided for @menuSmartAssistant.
  ///
  /// In ru, this message translates to:
  /// **'Умный помощник'**
  String get menuSmartAssistant;

  /// No description provided for @menuBalance.
  ///
  /// In ru, this message translates to:
  /// **'Баланс'**
  String get menuBalance;

  /// No description provided for @menuSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get menuSettings;

  /// No description provided for @btnRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get btnRetry;

  /// No description provided for @btnFind.
  ///
  /// In ru, this message translates to:
  /// **'Найти'**
  String get btnFind;

  /// No description provided for @titleNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get titleNotifications;

  /// No description provided for @emptyNews.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет новостей.'**
  String get emptyNews;

  /// No description provided for @titleFavorites.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get titleFavorites;

  /// No description provided for @titleBalance.
  ///
  /// In ru, this message translates to:
  /// **'Баланс'**
  String get titleBalance;

  /// No description provided for @titleAccountBalance.
  ///
  /// In ru, this message translates to:
  /// **'Баланс аккаунта'**
  String get titleAccountBalance;

  /// No description provided for @labelAvailableBalance.
  ///
  /// In ru, this message translates to:
  /// **'Доступный баланс'**
  String get labelAvailableBalance;

  /// No description provided for @titleTopUpBalance.
  ///
  /// In ru, this message translates to:
  /// **'Пополнить баланс (SmartPay)'**
  String get titleTopUpBalance;

  /// No description provided for @hintCityAddress.
  ///
  /// In ru, this message translates to:
  /// **'Город, адрес, описание…'**
  String get hintCityAddress;

  /// No description provided for @homeHeroSloganPrefix.
  ///
  /// In ru, this message translates to:
  /// **'Если недвижимость, то'**
  String get homeHeroSloganPrefix;

  /// No description provided for @homeTabBuy.
  ///
  /// In ru, this message translates to:
  /// **'Купить'**
  String get homeTabBuy;

  /// No description provided for @homeTabRent.
  ///
  /// In ru, this message translates to:
  /// **'Снять'**
  String get homeTabRent;

  /// No description provided for @homeTabDaily.
  ///
  /// In ru, this message translates to:
  /// **'Посуточно'**
  String get homeTabDaily;

  /// No description provided for @homeTabEvaluate.
  ///
  /// In ru, this message translates to:
  /// **'Оценить'**
  String get homeTabEvaluate;

  /// No description provided for @homeTypeNewApt.
  ///
  /// In ru, this message translates to:
  /// **'Квартиру в новостройке'**
  String get homeTypeNewApt;

  /// No description provided for @homeTypeSecondaryApt.
  ///
  /// In ru, this message translates to:
  /// **'Квартиру вторичку'**
  String get homeTypeSecondaryApt;

  /// No description provided for @homeTypeHouse.
  ///
  /// In ru, this message translates to:
  /// **'Дом (Хавли)'**
  String get homeTypeHouse;

  /// No description provided for @homeTypeOffice.
  ///
  /// In ru, this message translates to:
  /// **'Офис'**
  String get homeTypeOffice;

  /// No description provided for @homeRoomsCategory.
  ///
  /// In ru, this message translates to:
  /// **'Комнат'**
  String get homeRoomsCategory;

  /// No description provided for @homePropertyTypePlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Выберите тип недвижимости'**
  String get homePropertyTypePlaceholder;

  /// No description provided for @homePriceUpTo.
  ///
  /// In ru, this message translates to:
  /// **'Цена до...'**
  String get homePriceUpTo;

  /// No description provided for @homeCityDistrictStreet.
  ///
  /// In ru, this message translates to:
  /// **'Город, район, улица...'**
  String get homeCityDistrictStreet;

  /// No description provided for @homeDailyDestination.
  ///
  /// In ru, this message translates to:
  /// **'Куда вы хотите поехать?'**
  String get homeDailyDestination;

  /// No description provided for @homeDailyApt.
  ///
  /// In ru, this message translates to:
  /// **'Квартиру'**
  String get homeDailyApt;

  /// No description provided for @homeDailyHouse.
  ///
  /// In ru, this message translates to:
  /// **'Дом'**
  String get homeDailyHouse;

  /// No description provided for @homeDailyGuest1.
  ///
  /// In ru, this message translates to:
  /// **'1 гость'**
  String get homeDailyGuest1;

  /// No description provided for @homeDailyGuest2.
  ///
  /// In ru, this message translates to:
  /// **'2 гостя'**
  String get homeDailyGuest2;

  /// No description provided for @homeDailyStay.
  ///
  /// In ru, this message translates to:
  /// **'Заезд — Отъезд'**
  String get homeDailyStay;

  /// No description provided for @homeEvaluateHint.
  ///
  /// In ru, this message translates to:
  /// **'Адрес или описание объекта для оценки...'**
  String get homeEvaluateHint;

  /// No description provided for @homeEvaluateComingSoon.
  ///
  /// In ru, this message translates to:
  /// **'Скоро: запрос оценки объекта.'**
  String get homeEvaluateComingSoon;

  /// No description provided for @homeTopListingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'ТОП объявления'**
  String get homeTopListingsTitle;

  /// No description provided for @homeTopListingsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Лучшие предложения от наших партнеров'**
  String get homeTopListingsSubtitle;

  /// No description provided for @homeLoadMore.
  ///
  /// In ru, this message translates to:
  /// **'Загрузить ещё'**
  String get homeLoadMore;

  /// No description provided for @homeListingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Объявления'**
  String get homeListingsTitle;

  /// No description provided for @homeListingsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Обычные объявления'**
  String get homeListingsSubtitle;

  /// No description provided for @homeRealtorsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Риелторы'**
  String get homeRealtorsTitle;

  /// No description provided for @homeRealtorsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверенные специалисты'**
  String get homeRealtorsSubtitle;

  /// No description provided for @homeAgenciesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Агентства'**
  String get homeAgenciesTitle;

  /// No description provided for @homeAgenciesSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Лучшие агентства недвижимости'**
  String get homeAgenciesSubtitle;

  /// No description provided for @homeDevelopersTitle.
  ///
  /// In ru, this message translates to:
  /// **'Застройщики'**
  String get homeDevelopersTitle;

  /// No description provided for @homeDevelopersSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Новостройки и застройщики недвижимости'**
  String get homeDevelopersSubtitle;

  /// No description provided for @homeEmptyData.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет данных.'**
  String get homeEmptyData;

  /// No description provided for @homeAllRealtors.
  ///
  /// In ru, this message translates to:
  /// **'Все риелторы'**
  String get homeAllRealtors;

  /// No description provided for @homeAllAgencies.
  ///
  /// In ru, this message translates to:
  /// **'Все агентства'**
  String get homeAllAgencies;

  /// No description provided for @homeAllDevelopers.
  ///
  /// In ru, this message translates to:
  /// **'Все застройщики'**
  String get homeAllDevelopers;

  /// No description provided for @homePromoNewBuildTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выгодная покупка новостроек'**
  String get homePromoNewBuildTitle;

  /// No description provided for @homePromoNewBuildText.
  ///
  /// In ru, this message translates to:
  /// **'Актуальные объекты от застройщиков. Спецпредложения и скидки — подберите вариант под бюджет.'**
  String get homePromoNewBuildText;

  /// No description provided for @homePromoMortgageTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ипотека на выгодных условиях'**
  String get homePromoMortgageTitle;

  /// No description provided for @homePromoMortgageText.
  ///
  /// In ru, this message translates to:
  /// **'Ставки от 14% годовых. Помощь в оформлении и одобрении — жильё в новостройках доступнее.'**
  String get homePromoMortgageText;

  /// No description provided for @homePromoRentTitle.
  ///
  /// In ru, this message translates to:
  /// **'Аренда квартир без посредников'**
  String get homePromoRentTitle;

  /// No description provided for @homePromoRentText.
  ///
  /// In ru, this message translates to:
  /// **'Проверенные объявления, быстрый отклик. Снимайте жильё в новостройках удобно и безопасно.'**
  String get homePromoRentText;

  /// No description provided for @homeNoListingsYet.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет объявлений'**
  String get homeNoListingsYet;

  /// No description provided for @homeDefaultRealtor.
  ///
  /// In ru, this message translates to:
  /// **'Риелтор'**
  String get homeDefaultRealtor;

  /// No description provided for @homeDefaultAgency.
  ///
  /// In ru, this message translates to:
  /// **'Агентство'**
  String get homeDefaultAgency;

  /// No description provided for @homeOffersCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} предложений'**
  String homeOffersCount(int count);

  /// No description provided for @homeLabelAgent.
  ///
  /// In ru, this message translates to:
  /// **'Агент'**
  String get homeLabelAgent;

  /// No description provided for @homeLabelAgencyShort.
  ///
  /// In ru, this message translates to:
  /// **'Агентство'**
  String get homeLabelAgencyShort;

  /// No description provided for @footerSupport.
  ///
  /// In ru, this message translates to:
  /// **'Служба поддержки: звоните или пишите нам.'**
  String get footerSupport;

  /// No description provided for @btnLogin.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get btnLogin;

  /// No description provided for @btnNo.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get btnNo;

  /// No description provided for @btnYes.
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get btnYes;

  /// No description provided for @favoritesLoginPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Войдите в аккаунт, чтобы видеть избранные объявления.'**
  String get favoritesLoginPrompt;

  /// No description provided for @favoritesLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить избранное'**
  String get favoritesLoadError;

  /// No description provided for @networkError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сети'**
  String get networkError;

  /// No description provided for @favoritesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет избранных объявлений.\nНажмите на сердце на карточке.'**
  String get favoritesEmpty;

  /// No description provided for @messagesLoginPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Войдите в аккаунт, чтобы видеть чаты с продавцами и покупателями.'**
  String get messagesLoginPrompt;

  /// No description provided for @authTitleLogin.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get authTitleLogin;

  /// No description provided for @authTitleRegister.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get authTitleRegister;

  /// No description provided for @authHintLogin.
  ///
  /// In ru, this message translates to:
  /// **'Введите телефон и код из SMS, чтобы войти.'**
  String get authHintLogin;

  /// No description provided for @authHintRegister.
  ///
  /// In ru, this message translates to:
  /// **'Заполните данные профиля.'**
  String get authHintRegister;

  /// No description provided for @authLabelPhone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get authLabelPhone;

  /// No description provided for @authLabelCode.
  ///
  /// In ru, this message translates to:
  /// **'Код'**
  String get authLabelCode;

  /// No description provided for @authHintSmsCode.
  ///
  /// In ru, this message translates to:
  /// **'Код из SMS'**
  String get authHintSmsCode;

  /// No description provided for @authGetCode.
  ///
  /// In ru, this message translates to:
  /// **'Получить код'**
  String get authGetCode;

  /// No description provided for @authSending.
  ///
  /// In ru, this message translates to:
  /// **'Отправка…'**
  String get authSending;

  /// No description provided for @authResendCode.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код ещё раз'**
  String get authResendCode;

  /// No description provided for @authResendCodeIn.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код ещё раз ({seconds} с)'**
  String authResendCodeIn(int seconds);

  /// No description provided for @authLabelFullName.
  ///
  /// In ru, this message translates to:
  /// **'Имя и фамилия'**
  String get authLabelFullName;

  /// No description provided for @authLabelRole.
  ///
  /// In ru, this message translates to:
  /// **'Роль'**
  String get authLabelRole;

  /// No description provided for @authRoleUser.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get authRoleUser;

  /// No description provided for @authRoleOwner.
  ///
  /// In ru, this message translates to:
  /// **'Собственник'**
  String get authRoleOwner;

  /// No description provided for @authRoleAgent.
  ///
  /// In ru, this message translates to:
  /// **'Агент'**
  String get authRoleAgent;

  /// No description provided for @authRoleAgency.
  ///
  /// In ru, this message translates to:
  /// **'Агентство'**
  String get authRoleAgency;

  /// No description provided for @authRoleDeveloper.
  ///
  /// In ru, this message translates to:
  /// **'Застройщик'**
  String get authRoleDeveloper;

  /// No description provided for @authBirthDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата рождения'**
  String get authBirthDate;

  /// No description provided for @authAgencyCodeIfAny.
  ///
  /// In ru, this message translates to:
  /// **'Код агентства (если есть)'**
  String get authAgencyCodeIfAny;

  /// No description provided for @authCompleteRegistration.
  ///
  /// In ru, this message translates to:
  /// **'Завершить регистрацию'**
  String get authCompleteRegistration;

  /// No description provided for @authErrorPhoneDigits.
  ///
  /// In ru, this message translates to:
  /// **'Введите 9 цифр номера (например 921234567).'**
  String get authErrorPhoneDigits;

  /// No description provided for @authErrorCodeDigits.
  ///
  /// In ru, this message translates to:
  /// **'Введите 4 цифры кода из SMS.'**
  String get authErrorCodeDigits;

  /// No description provided for @authErrorFullName.
  ///
  /// In ru, this message translates to:
  /// **'Укажите имя и фамилию.'**
  String get authErrorFullName;

  /// No description provided for @authErrorNoAccess.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти: ответ сервера без токена. Попробуйте позже.'**
  String get authErrorNoAccess;

  /// No description provided for @authErrorWrongCode.
  ///
  /// In ru, this message translates to:
  /// **'Неверный или просроченный код из SMS.'**
  String get authErrorWrongCode;

  /// No description provided for @authProfileLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Профиль не загрузился. Проверьте интернет и потяните экран вниз для обновления.'**
  String get authProfileLoadError;

  /// No description provided for @assistantLoginFirstSnack.
  ///
  /// In ru, this message translates to:
  /// **'Сначала войдите: откройте «Профиль», введите номер и код из SMS.'**
  String get assistantLoginFirstSnack;

  /// No description provided for @assistantRefsLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки справочников'**
  String get assistantRefsLoadError;

  /// No description provided for @assistantPolygonMinPoints.
  ///
  /// In ru, this message translates to:
  /// **'Полигон: минимум 3 точки (или очистите геозону).'**
  String get assistantPolygonMinPoints;

  /// No description provided for @assistantSaved.
  ///
  /// In ru, this message translates to:
  /// **'Сохранено'**
  String get assistantSaved;

  /// No description provided for @assistantDeleteRequestTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить заявку?'**
  String get assistantDeleteRequestTitle;

  /// No description provided for @assistantDeleteFailed.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка удаления'**
  String get assistantDeleteFailed;

  /// No description provided for @assistantRangeFrom.
  ///
  /// In ru, this message translates to:
  /// **'от'**
  String get assistantRangeFrom;

  /// No description provided for @assistantRangeTo.
  ///
  /// In ru, this message translates to:
  /// **'до'**
  String get assistantRangeTo;

  /// No description provided for @assistantSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Подбор — заявка + совпадения'**
  String get assistantSubtitle;

  /// No description provided for @assistantNotLoggedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вход не выполнен'**
  String get assistantNotLoggedTitle;

  /// No description provided for @assistantNotLoggedBody.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы сохранить заявку и искать совпадения, войдите в «Профиль» по номеру телефона и коду из SMS.'**
  String get assistantNotLoggedBody;

  /// No description provided for @assistantGoProfile.
  ///
  /// In ru, this message translates to:
  /// **'Перейти в профиль →'**
  String get assistantGoProfile;

  /// No description provided for @assistantMyRequests.
  ///
  /// In ru, this message translates to:
  /// **'Мои заявки'**
  String get assistantMyRequests;

  /// No description provided for @assistantNewRequest.
  ///
  /// In ru, this message translates to:
  /// **'Новая заявка'**
  String get assistantNewRequest;

  /// No description provided for @assistantNoRequestsYet.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет заявок. Заполните форму и нажмите «Сохранить».'**
  String get assistantNoRequestsYet;

  /// No description provided for @assistantRequestTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заявка {id}'**
  String assistantRequestTitle(int id);

  /// No description provided for @assistantStatusActive.
  ///
  /// In ru, this message translates to:
  /// **'Активна'**
  String get assistantStatusActive;

  /// No description provided for @assistantStatusPaused.
  ///
  /// In ru, this message translates to:
  /// **'Пауза'**
  String get assistantStatusPaused;

  /// No description provided for @assistantCityPrefix.
  ///
  /// In ru, this message translates to:
  /// **'Город:'**
  String get assistantCityPrefix;

  /// No description provided for @assistantNoCity.
  ///
  /// In ru, this message translates to:
  /// **'Без города'**
  String get assistantNoCity;

  /// No description provided for @assistantPointsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Точек:'**
  String get assistantPointsLabel;

  /// No description provided for @assistantOpenArrow.
  ///
  /// In ru, this message translates to:
  /// **'Открыть →'**
  String get assistantOpenArrow;

  /// No description provided for @assistantFormSection.
  ///
  /// In ru, this message translates to:
  /// **'Форма заявки'**
  String get assistantFormSection;

  /// No description provided for @assistantFieldAction.
  ///
  /// In ru, this message translates to:
  /// **'Действие'**
  String get assistantFieldAction;

  /// No description provided for @assistantIntentBuy.
  ///
  /// In ru, this message translates to:
  /// **'Покупать'**
  String get assistantIntentBuy;

  /// No description provided for @assistantIntentRent.
  ///
  /// In ru, this message translates to:
  /// **'Снимать'**
  String get assistantIntentRent;

  /// No description provided for @assistantIntentDaily.
  ///
  /// In ru, this message translates to:
  /// **'Посуточно'**
  String get assistantIntentDaily;

  /// No description provided for @assistantLabelDealType.
  ///
  /// In ru, this message translates to:
  /// **'Тип объявления'**
  String get assistantLabelDealType;

  /// No description provided for @assistantLabelPropertyType.
  ///
  /// In ru, this message translates to:
  /// **'Вид объекта'**
  String get assistantLabelPropertyType;

  /// No description provided for @assistantLabelCity.
  ///
  /// In ru, this message translates to:
  /// **'Город/Район'**
  String get assistantLabelCity;

  /// No description provided for @assistantLabelRooms.
  ///
  /// In ru, this message translates to:
  /// **'Комнаты'**
  String get assistantLabelRooms;

  /// No description provided for @assistantLabelPriceMin.
  ///
  /// In ru, this message translates to:
  /// **'Цена от'**
  String get assistantLabelPriceMin;

  /// No description provided for @assistantLabelPriceMax.
  ///
  /// In ru, this message translates to:
  /// **'Цена до'**
  String get assistantLabelPriceMax;

  /// No description provided for @assistantLabelAreaMin.
  ///
  /// In ru, this message translates to:
  /// **'Площадь м² от'**
  String get assistantLabelAreaMin;

  /// No description provided for @assistantLabelAreaMax.
  ///
  /// In ru, this message translates to:
  /// **'Площадь м² до'**
  String get assistantLabelAreaMax;

  /// No description provided for @assistantLabelLandMin.
  ///
  /// In ru, this message translates to:
  /// **'Участок сот. от'**
  String get assistantLabelLandMin;

  /// No description provided for @assistantLabelLandMax.
  ///
  /// In ru, this message translates to:
  /// **'Участок сот. до'**
  String get assistantLabelLandMax;

  /// No description provided for @assistantLabelLandType.
  ///
  /// In ru, this message translates to:
  /// **'Тип участка'**
  String get assistantLabelLandType;

  /// No description provided for @assistantLabelCommercial.
  ///
  /// In ru, this message translates to:
  /// **'Вид помещения'**
  String get assistantLabelCommercial;

  /// No description provided for @assistantLabelRentalTerm.
  ///
  /// In ru, this message translates to:
  /// **'Срок аренды'**
  String get assistantLabelRentalTerm;

  /// No description provided for @assistantSearchDaily.
  ///
  /// In ru, this message translates to:
  /// **'Искать каждый день'**
  String get assistantSearchDaily;

  /// No description provided for @assistantMapSection.
  ///
  /// In ru, this message translates to:
  /// **'Геозона на карте'**
  String get assistantMapSection;

  /// No description provided for @assistantMapHint.
  ///
  /// In ru, this message translates to:
  /// **'Включите карандаш, затем нажимайте по карте. Минимум 3 точки.'**
  String get assistantMapHint;

  /// No description provided for @assistantDrawingFinish.
  ///
  /// In ru, this message translates to:
  /// **'Закончить'**
  String get assistantDrawingFinish;

  /// No description provided for @assistantDeleteLastPoint.
  ///
  /// In ru, this message translates to:
  /// **'Удалить точку'**
  String get assistantDeleteLastPoint;

  /// No description provided for @assistantDrawingCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get assistantDrawingCancel;

  /// No description provided for @assistantMapPoint.
  ///
  /// In ru, this message translates to:
  /// **'Точка {n}: lat {lat}, lng {lng}'**
  String assistantMapPoint(int n, String lat, String lng);

  /// No description provided for @assistantUndoPoint.
  ///
  /// In ru, this message translates to:
  /// **'Отменить точку'**
  String get assistantUndoPoint;

  /// No description provided for @assistantClearPolygon.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get assistantClearPolygon;

  /// No description provided for @assistantSaving.
  ///
  /// In ru, this message translates to:
  /// **'Сохранение...'**
  String get assistantSaving;

  /// No description provided for @btnSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get btnSave;

  /// No description provided for @assistantSearching.
  ///
  /// In ru, this message translates to:
  /// **'Поиск...'**
  String get assistantSearching;

  /// No description provided for @assistantSearchMatches.
  ///
  /// In ru, this message translates to:
  /// **'Искать совпадение'**
  String get assistantSearchMatches;

  /// No description provided for @btnDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get btnDelete;

  /// No description provided for @assistantMatchResults.
  ///
  /// In ru, this message translates to:
  /// **'Результат совпадения'**
  String get assistantMatchResults;

  /// No description provided for @assistantMatchResultsForRequest.
  ///
  /// In ru, this message translates to:
  /// **'Результат совпадения (заявка {id})'**
  String assistantMatchResultsForRequest(int id);

  /// No description provided for @assistantNoMatchResults.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет результатов. Нажмите «Искать совпадение».'**
  String get assistantNoMatchResults;

  /// No description provided for @assistantTableScrollHint.
  ///
  /// In ru, this message translates to:
  /// **'Таблицу можно листать влево-вправо — все колонки прокручиваются.'**
  String get assistantTableScrollHint;

  /// No description provided for @assistantCompareHeader.
  ///
  /// In ru, this message translates to:
  /// **'То что нужно / имеется?'**
  String get assistantCompareHeader;

  /// No description provided for @assistantVariantNumber.
  ///
  /// In ru, this message translates to:
  /// **'Вариант №{n}'**
  String assistantVariantNumber(int n);

  /// No description provided for @btnOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открыть'**
  String get btnOpen;

  /// No description provided for @assistantNoPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Нет фото'**
  String get assistantNoPhoto;

  /// No description provided for @assistantLabelRoomCount.
  ///
  /// In ru, this message translates to:
  /// **'Количество комнат'**
  String get assistantLabelRoomCount;

  /// No description provided for @assistantLabelPriceSom.
  ///
  /// In ru, this message translates to:
  /// **'Цена (сомони)'**
  String get assistantLabelPriceSom;

  /// No description provided for @assistantLabelAreaM2.
  ///
  /// In ru, this message translates to:
  /// **'Площадь (м²)'**
  String get assistantLabelAreaM2;

  /// No description provided for @assistantLabelLandSot.
  ///
  /// In ru, this message translates to:
  /// **'Участок (сот.)'**
  String get assistantLabelLandSot;

  /// No description provided for @assistantLabelGeo.
  ///
  /// In ru, this message translates to:
  /// **'Геозона'**
  String get assistantLabelGeo;

  /// No description provided for @assistantPolygonSelected.
  ///
  /// In ru, this message translates to:
  /// **'Выбрано (точек: {count})'**
  String assistantPolygonSelected(int count);

  /// No description provided for @messagesChatsSection.
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get messagesChatsSection;

  /// No description provided for @listingFallbackTitle.
  ///
  /// In ru, this message translates to:
  /// **'Объявление'**
  String get listingFallbackTitle;

  /// No description provided for @messagesNoChatsYet.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет чатов. Нажмите «Написать» в объявлении.'**
  String get messagesNoChatsYet;

  /// No description provided for @messagesUserPlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get messagesUserPlaceholder;

  /// No description provided for @messagesSelectChatWide.
  ///
  /// In ru, this message translates to:
  /// **'Выберите чат слева'**
  String get messagesSelectChatWide;

  /// No description provided for @messagesSelectChatList.
  ///
  /// In ru, this message translates to:
  /// **'Выберите чат из списка'**
  String get messagesSelectChatList;

  /// No description provided for @messagesStartFromListing.
  ///
  /// In ru, this message translates to:
  /// **'Или начните переписку из объявления.'**
  String get messagesStartFromListing;

  /// No description provided for @messagesChatHeaderFallback.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get messagesChatHeaderFallback;

  /// No description provided for @messagesInputHint.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение…'**
  String get messagesInputHint;

  /// No description provided for @tooltipBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get tooltipBack;

  /// No description provided for @messagesTimeToday.
  ///
  /// In ru, this message translates to:
  /// **'сегодня, {time}'**
  String messagesTimeToday(String time);

  /// No description provided for @messagesTimeYesterday.
  ///
  /// In ru, this message translates to:
  /// **'вчера, {time}'**
  String messagesTimeYesterday(String time);

  /// No description provided for @profileCabinet.
  ///
  /// In ru, this message translates to:
  /// **'Кабинет'**
  String get profileCabinet;

  /// No description provided for @profileStatInFavorites.
  ///
  /// In ru, this message translates to:
  /// **'В избранном'**
  String get profileStatInFavorites;

  /// No description provided for @profileStatListings.
  ///
  /// In ru, this message translates to:
  /// **'Объявления'**
  String get profileStatListings;

  /// No description provided for @profileRolePrefix.
  ///
  /// In ru, this message translates to:
  /// **'Роль:'**
  String get profileRolePrefix;

  /// No description provided for @profileListingLimit.
  ///
  /// In ru, this message translates to:
  /// **'Лимит объявлений: {current} / {limit}'**
  String profileListingLimit(int current, int limit);

  /// No description provided for @profileMyListingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мои объявления'**
  String get profileMyListingsTitle;

  /// No description provided for @profileMyListingsRestricted.
  ///
  /// In ru, this message translates to:
  /// **'Управление объявлениями доступно собственникам и агентам.'**
  String get profileMyListingsRestricted;

  /// No description provided for @profileDashboardActionsHint.
  ///
  /// In ru, this message translates to:
  /// **'Действия: Изменить · Скрыть/Активировать · Обновить (раз в 14 дней) · В ТОП · В архив · Открыть'**
  String get profileDashboardActionsHint;

  /// No description provided for @tooltipRefreshList.
  ///
  /// In ru, this message translates to:
  /// **'Обновить список'**
  String get tooltipRefreshList;

  /// No description provided for @tooltipCabinet.
  ///
  /// In ru, this message translates to:
  /// **'Кабинет'**
  String get tooltipCabinet;

  /// No description provided for @tooltipAppSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки приложения'**
  String get tooltipAppSettings;

  /// No description provided for @profileBulkBumpSelected.
  ///
  /// In ru, this message translates to:
  /// **'Обновить выбранные ({count})'**
  String profileBulkBumpSelected(int count);

  /// No description provided for @profileBulkArchiveSelected.
  ///
  /// In ru, this message translates to:
  /// **'В архив выбранные ({count})'**
  String profileBulkArchiveSelected(int count);

  /// No description provided for @profileBulkRestoreSelected.
  ///
  /// In ru, this message translates to:
  /// **'Восстановить ({count})'**
  String profileBulkRestoreSelected(int count);

  /// No description provided for @profileBulkDeleteForeverSelected.
  ///
  /// In ru, this message translates to:
  /// **'Удалить навсегда ({count})'**
  String profileBulkDeleteForeverSelected(int count);

  /// No description provided for @profileTrashBack.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться'**
  String get profileTrashBack;

  /// No description provided for @profileTrashBin.
  ///
  /// In ru, this message translates to:
  /// **'Корзина ({count})'**
  String profileTrashBin(int count);

  /// No description provided for @profileTrashEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Корзина пуста.'**
  String get profileTrashEmpty;

  /// No description provided for @profileNoListings.
  ///
  /// In ru, this message translates to:
  /// **'Нет объявлений.'**
  String get profileNoListings;

  /// No description provided for @profileAddListing.
  ///
  /// In ru, this message translates to:
  /// **'Добавить объявление'**
  String get profileAddListing;

  /// No description provided for @profileSelectAll.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать все'**
  String get profileSelectAll;

  /// No description provided for @btnCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get btnCancel;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountHint.
  ///
  /// In ru, this message translates to:
  /// **'Это действие необратимо. Ваш аккаунт и данные будут удалены.'**
  String get settingsDeleteAccountHint;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In ru, this message translates to:
  /// **'Это действие необратимо. После удаления вы потеряете доступ к аккаунту и данным.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт удалён'**
  String get deleteAccountDeleted;

  /// No description provided for @deleteAccountDeleteFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить аккаунт'**
  String get deleteAccountDeleteFailed;

  /// No description provided for @tooltipRefresh.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get tooltipRefresh;

  /// No description provided for @currencySomShort.
  ///
  /// In ru, this message translates to:
  /// **'с.'**
  String get currencySomShort;

  /// No description provided for @balanceLoginPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Войдите в профиль, чтобы видеть баланс и пополнять его.'**
  String get balanceLoginPrompt;

  /// No description provided for @balanceGoToProfile.
  ///
  /// In ru, this message translates to:
  /// **'Перейти в кабинет'**
  String get balanceGoToProfile;

  /// No description provided for @balanceCharged.
  ///
  /// In ru, this message translates to:
  /// **'Баланс пополнен'**
  String get balanceCharged;

  /// No description provided for @balancePendingPayment.
  ///
  /// In ru, this message translates to:
  /// **'У вас уже есть незавершённая оплата. Ожидаем подтверждение…'**
  String get balancePendingPayment;

  /// No description provided for @balanceMinAmount.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 2 сомони'**
  String get balanceMinAmount;

  /// No description provided for @balanceNoPaymentLink.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка на оплату не получена'**
  String get balanceNoPaymentLink;

  /// No description provided for @balanceBadPaymentLink.
  ///
  /// In ru, this message translates to:
  /// **'Некорректная ссылка'**
  String get balanceBadPaymentLink;

  /// No description provided for @balanceOpenPaymentFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть оплату'**
  String get balanceOpenPaymentFailed;

  /// No description provided for @balanceCompletePaymentExternal.
  ///
  /// In ru, this message translates to:
  /// **'Завершите оплату во внешнем окне. Баланс обновится автоматически.'**
  String get balanceCompletePaymentExternal;

  /// No description provided for @balanceCreatePaymentError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка создания платежа'**
  String get balanceCreatePaymentError;

  /// No description provided for @balanceTopUpHint.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 2 сомони. Оплата картой или кошельком'**
  String get balanceTopUpHint;

  /// No description provided for @balanceAmountLabel.
  ///
  /// In ru, this message translates to:
  /// **'Сумма (сомони)'**
  String get balanceAmountLabel;

  /// No description provided for @balanceAmountHint.
  ///
  /// In ru, this message translates to:
  /// **'Например, 50'**
  String get balanceAmountHint;

  /// No description provided for @balanceProceedPay.
  ///
  /// In ru, this message translates to:
  /// **'Перейти к оплате'**
  String get balanceProceedPay;

  /// No description provided for @balanceHistoryPlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Пополнение баланса и списания за услуги будут отображаться здесь (история операций добавим позже).'**
  String get balanceHistoryPlaceholder;

  /// No description provided for @balanceCheckingPayment.
  ///
  /// In ru, this message translates to:
  /// **'Проверяем оплату…'**
  String get balanceCheckingPayment;

  /// No description provided for @listingNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Объявление не найдено.'**
  String get listingNotFound;

  /// No description provided for @listingDetailTitle.
  ///
  /// In ru, this message translates to:
  /// **'Объявление'**
  String get listingDetailTitle;

  /// No description provided for @shareDone.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться'**
  String get shareDone;

  /// No description provided for @listingPhotosCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} фото'**
  String listingPhotosCount(int count);

  /// No description provided for @listingViewsCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} просмотров'**
  String listingViewsCount(int count);

  /// No description provided for @dealForSale.
  ///
  /// In ru, this message translates to:
  /// **'Продаётся'**
  String get dealForSale;

  /// No description provided for @dealForRent.
  ///
  /// In ru, this message translates to:
  /// **'Аренда'**
  String get dealForRent;

  /// No description provided for @negotiationFixed.
  ///
  /// In ru, this message translates to:
  /// **'Не подлежит торгу'**
  String get negotiationFixed;

  /// No description provided for @negotiationOk.
  ///
  /// In ru, this message translates to:
  /// **'Торг уместен'**
  String get negotiationOk;

  /// No description provided for @sectionAboutObject.
  ///
  /// In ru, this message translates to:
  /// **'О объекте'**
  String get sectionAboutObject;

  /// No description provided for @listingDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get listingDescription;

  /// No description provided for @listingContactSection.
  ///
  /// In ru, this message translates to:
  /// **'Контакт'**
  String get listingContactSection;

  /// No description provided for @defaultAgentName.
  ///
  /// In ru, this message translates to:
  /// **'Агент'**
  String get defaultAgentName;

  /// No description provided for @listingLoginToMessage.
  ///
  /// In ru, this message translates to:
  /// **'Войдите в аккаунт, чтобы написать продавцу.'**
  String get listingLoginToMessage;

  /// No description provided for @listingChatStartFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось начать чат.'**
  String get listingChatStartFailed;

  /// No description provided for @listingWriteMessage.
  ///
  /// In ru, this message translates to:
  /// **'Написать'**
  String get listingWriteMessage;

  /// No description provided for @listingSimilar.
  ///
  /// In ru, this message translates to:
  /// **'Похожие объявления'**
  String get listingSimilar;

  /// No description provided for @listingRoomsAbbr.
  ///
  /// In ru, this message translates to:
  /// **'{n} комн.'**
  String listingRoomsAbbr(String n);

  /// No description provided for @listingFloorAbbr.
  ///
  /// In ru, this message translates to:
  /// **'{n} этаж'**
  String listingFloorAbbr(String n);

  /// No description provided for @listingTypeApartmentFallback.
  ///
  /// In ru, this message translates to:
  /// **'квартира'**
  String get listingTypeApartmentFallback;

  /// No description provided for @compareLimitReached.
  ///
  /// In ru, this message translates to:
  /// **'В сравнении уже {max} объявлений'**
  String compareLimitReached(int max);

  /// No description provided for @notificationsExpand.
  ///
  /// In ru, this message translates to:
  /// **'Развернуть'**
  String get notificationsExpand;

  /// No description provided for @menuPushSettings.
  ///
  /// In ru, this message translates to:
  /// **'Push-уведомления'**
  String get menuPushSettings;

  /// No description provided for @settingsSingular.
  ///
  /// In ru, this message translates to:
  /// **'Настройка'**
  String get settingsSingular;

  /// No description provided for @listingsLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сети'**
  String get listingsLoadError;

  /// No description provided for @listingsFailedLoad.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить'**
  String get listingsFailedLoad;

  /// No description provided for @listingsAuthorTitle.
  ///
  /// In ru, this message translates to:
  /// **'Объявления автора'**
  String get listingsAuthorTitle;

  /// No description provided for @listingsSearchTitle.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get listingsSearchTitle;

  /// No description provided for @listingsDefaultTitle.
  ///
  /// In ru, this message translates to:
  /// **'Объявления'**
  String get listingsDefaultTitle;

  /// No description provided for @listingsAuthorSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Все предложения выбранного риелтора / агентства / застройщика'**
  String get listingsAuthorSubtitle;

  /// No description provided for @listingsSearchSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Результаты по запросу «{q}»'**
  String listingsSearchSubtitle(String q);

  /// No description provided for @listingsNormalSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Обычные объявления'**
  String get listingsNormalSubtitle;

  /// No description provided for @listingsShowAllAuthors.
  ///
  /// In ru, this message translates to:
  /// **'Показать объявления всех авторов'**
  String get listingsShowAllAuthors;

  /// No description provided for @listingsEmptySearch.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено.'**
  String get listingsEmptySearch;

  /// No description provided for @listingsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Объявлений пока нет.'**
  String get listingsEmpty;

  /// No description provided for @listingsEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Загляните позже или введите запрос выше.'**
  String get listingsEmptyHint;

  /// No description provided for @specType.
  ///
  /// In ru, this message translates to:
  /// **'Тип'**
  String get specType;

  /// No description provided for @specAreaTotal.
  ///
  /// In ru, this message translates to:
  /// **'Площадь общая'**
  String get specAreaTotal;

  /// No description provided for @specAreaLiving.
  ///
  /// In ru, this message translates to:
  /// **'Площадь жилая'**
  String get specAreaLiving;

  /// No description provided for @specRooms.
  ///
  /// In ru, this message translates to:
  /// **'Комнат'**
  String get specRooms;

  /// No description provided for @specFloor.
  ///
  /// In ru, this message translates to:
  /// **'Этаж'**
  String get specFloor;

  /// No description provided for @specFloorsInBuilding.
  ///
  /// In ru, this message translates to:
  /// **'Этажей в доме'**
  String get specFloorsInBuilding;

  /// No description provided for @specYearBuilt.
  ///
  /// In ru, this message translates to:
  /// **'Год постройки'**
  String get specYearBuilt;

  /// No description provided for @specRepair.
  ///
  /// In ru, this message translates to:
  /// **'Ремонт'**
  String get specRepair;

  /// No description provided for @specCondition.
  ///
  /// In ru, this message translates to:
  /// **'Состояние'**
  String get specCondition;

  /// No description provided for @aboutScreenTitle.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get aboutScreenTitle;

  /// No description provided for @aboutTagline.
  ///
  /// In ru, this message translates to:
  /// **'Платформа недвижимости в Таджикистане: продажа, аренда, агенты и застройщики.'**
  String get aboutTagline;

  /// No description provided for @aboutVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия'**
  String get aboutVersion;

  /// No description provided for @aboutSite.
  ///
  /// In ru, this message translates to:
  /// **'Сайт'**
  String get aboutSite;

  /// No description provided for @aboutDocuments.
  ///
  /// In ru, this message translates to:
  /// **'Документы'**
  String get aboutDocuments;

  /// No description provided for @aboutPublishNote.
  ///
  /// In ru, this message translates to:
  /// **'Разместите актуальные тексты по ссылкам выше перед публикацией в Google Play и App Store.'**
  String get aboutPublishNote;

  /// No description provided for @pushHelpBody.
  ///
  /// In ru, this message translates to:
  /// **'Разрешите уведомления в системе, когда приложение спросит. Новые сообщения в чате приходят как push; токен устройства отправляется на сервер после входа.'**
  String get pushHelpBody;

  /// No description provided for @pushFallbackTitle.
  ///
  /// In ru, this message translates to:
  /// **'Уведомление'**
  String get pushFallbackTitle;

  /// No description provided for @pushOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открыть'**
  String get pushOpen;

  /// No description provided for @apiAuthRequired.
  ///
  /// In ru, this message translates to:
  /// **'Нужен вход: откройте «Профиль» и войдите по коду из SMS.'**
  String get apiAuthRequired;

  /// No description provided for @apiNetworkError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сети. Проверьте интернет и сервер.'**
  String get apiNetworkError;
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
      <String>['ru', 'tg'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ru':
      return AppLocalizationsRu();
    case 'tg':
      return AppLocalizationsTg();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
