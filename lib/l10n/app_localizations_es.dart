// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Deskmate';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String hoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get errorStorage =>
      'No pudimos revisar tu cuarto guardado. Vuelve a revisar para continuar con seguridad.';

  @override
  String get errorAlerts =>
      'No pudimos programar el aviso. El temporizador se recuperará cuando vuelvas.';

  @override
  String get retryCheck => 'Revisar de nuevo';

  @override
  String get restoringRoom => 'Revisando tu cuarto guardado.';

  @override
  String get errorSoundPlay =>
      'No pudimos reproducir el sonido. Elígelo otra vez en los ajustes de sonido.';

  @override
  String get errorSoundStop =>
      'No pudimos apagar el sonido. Inténtalo otra vez en los ajustes de sonido.';

  @override
  String get errorSoundStatus =>
      'No pudimos revisar el sonido. Elígelo otra vez.';

  @override
  String get stopTitle => '¿Terminar esta sesión?';

  @override
  String get stopSheetTitle => '¿Terminar\nesta sesión?';

  @override
  String get stopFocusBody =>
      'El tiempo hasta ahora queda como sesión interrumpida. No cuenta para desbloquear objetos.';

  @override
  String get stopFocusSummary =>
      'El tiempo hasta ahora queda como sesión interrumpida.';

  @override
  String get stopFocusRewardsHint => 'No cuenta para desbloquear objetos.';

  @override
  String get stopOtherBody =>
      'Las pruebas y los descansos no quedan en tu registro de enfoque.';

  @override
  String get keepGoing => 'Seguir';

  @override
  String get endSession => 'Terminar';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSubtitle => 'Crea un tiempo de enfoque a tu medida';

  @override
  String get goalTitle => 'Meta y propósito';

  @override
  String get goalEmpty => 'Define una meta y una fecha';

  @override
  String get soundDefaults => 'Sonido predeterminado';

  @override
  String get soundOff => 'Sonido apagado';

  @override
  String get alertsTitle => 'Aviso al terminar';

  @override
  String get alertsOn => 'Los avisos están activados';

  @override
  String get alertsOff => 'Te avisamos cuando se acabe el tiempo';

  @override
  String get keepScreenTitle => 'Pantalla encendida con el temporizador';

  @override
  String get keepScreenOn =>
      'La pantalla sigue encendida mientras te enfocas o descansas';

  @override
  String get keepScreenOff => 'Se apaga como siempre · el temporizador sigue';

  @override
  String get collectionTitle => 'Objetos reunidos';

  @override
  String collectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pequeños regalos',
      one: '1 pequeño regalo',
    );
    return '$_temp0';
  }

  @override
  String get quickFocusTitle => 'Enfoque corto';

  @override
  String quickFocusStart(int minutes) {
    return 'Iniciar enfoque de $minutes minutos';
  }

  @override
  String quickFocusLabel(int minutes) {
    return '$minutes min de enfoque';
  }

  @override
  String get demoButton =>
      'Prueba de 1 minuto · explora sin registro ni recompensas';

  @override
  String get soundCreditsTile => 'Fuentes y licencias de sonido';

  @override
  String get soundCreditsTitle => 'Fuentes de sonido';

  @override
  String get soundCreditsIntro =>
      'Los tres sonidos se publicaron con licencia CC0 1.0. Vienen incluidos en la app y suenan sin conexión.';

  @override
  String get close => 'Cerrar';

  @override
  String get propPlant => 'Plantita';

  @override
  String get propMug => 'Taza calientita';

  @override
  String get propLamp => 'Lámpara acogedora';

  @override
  String get collectionHeading => 'Llenando el cuarto, poco a poco';

  @override
  String get collectionSubtitle => 'Tres lugares fijos, llenos con tu enfoque.';

  @override
  String get unlockFirstFocus => 'Primer enfoque completado';

  @override
  String unlockAfterMinutes(int minutes) {
    return '$minutes min de enfoque completado en total';
  }

  @override
  String get collectionFootnote =>
      'Los objetos se colocan solos.\nLas sesiones interrumpidas, las pruebas de 1 minuto y los descansos no cuentan para desbloquear.';

  @override
  String get captionReady => 'Hora de enfocarnos juntos';

  @override
  String get captionDemoDone => 'Prueba completada';

  @override
  String get captionRestDone => 'Descanso completado';

  @override
  String get captionFocusDone => 'Enfoque completado';

  @override
  String get captionPaused => 'En pausa';

  @override
  String get captionDemo => 'Prueba de 1 minuto · sin registro';

  @override
  String get captionRest => 'Hora de descansar';

  @override
  String captionFocusing(int minutes) {
    return 'Enfoque de $minutes minutos';
  }

  @override
  String get messageFirstPlant =>
      'Un regalo por tu primer enfoque: una plantita en el escritorio.';

  @override
  String messageNewProps(String items) {
    return 'Nuevo objeto: $items';
  }

  @override
  String get messageDemoDone => 'Terminó la prueba. Gracias por acompañarnos';

  @override
  String get messageRestDone => 'Buen descanso. Volvamos con calma';

  @override
  String get messageFocusDone =>
      '¡Bien hecho! Tu enfoque se acumula en el escritorio';

  @override
  String get messagePaused => 'Está bien tomarse un momento';

  @override
  String get messageRest => 'Una taza de té, con calma';

  @override
  String get messageFocus => 'Paso a paso, escribamos juntos';

  @override
  String get randomTooltip => 'Deja que tu amigo elija el tiempo';

  @override
  String get deskTitle => 'Mi escritorio';

  @override
  String get focusSound => 'Sonidos de enfoque';

  @override
  String get todayFocus => 'Enfoque de hoy';

  @override
  String get startFocus => 'Empezar';

  @override
  String get confirm => 'Aceptar';

  @override
  String get startRest => 'Descanso de 5 min';

  @override
  String get nextFocus => 'Siguiente enfoque';

  @override
  String get resumeRest => 'Retomar descanso';

  @override
  String get resumeFocus => 'Retomar enfoque';

  @override
  String get pause => 'Pausar';

  @override
  String get endThisSession => 'Terminar esta sesión';

  @override
  String get navDesk => 'Escritorio';

  @override
  String get navRecords => 'Registro';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get recordsTitle => 'Poco a poco';

  @override
  String get recordsSubtitle => 'Los días que nos enfocamos juntos';

  @override
  String get thisMonth => 'Este mes';

  @override
  String get focusedDays => 'Días de enfoque';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get backToThisMonth => 'Volver a este mes';

  @override
  String get dayFocusDone => 'enfoque completado';

  @override
  String get today => 'Hoy';

  @override
  String dayFocusMinutes(int minutes) {
    return '$minutes min de enfoque';
  }

  @override
  String daySessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones completadas',
      one: '1 sesión completada',
    );
    return '$_temp0';
  }

  @override
  String get recordsArchived =>
      'Guardamos el total y el sello de este día.\nLos detalles se guardan para tus últimas 100 sesiones.';

  @override
  String get recordsFuture => 'Un día que llenaremos juntos.';

  @override
  String get recordsEmpty =>
      'Aún no hay registros.\n¿Empezamos con 25 minutos?';

  @override
  String sessionCompleted(int minutes) {
    return '$minutes min de enfoque completado';
  }

  @override
  String get sessionStoppedShort => 'Menos de 1 min · interrumpida';

  @override
  String sessionStopped(int minutes) {
    return '$minutes min · interrumpida';
  }

  @override
  String get goalDefaultMessage => 'Hoy también, paso a paso';

  @override
  String get saveError => 'No se pudo guardar. Inténtalo de nuevo.';

  @override
  String get deleteGoalTitle => '¿Eliminar esta meta?';

  @override
  String get deleteGoalBody =>
      'Tu registro de enfoque y tus objetos se quedan como están.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteGoalTooltip => 'Eliminar meta';

  @override
  String get back => 'Atrás';

  @override
  String get saving => 'Guardando…';

  @override
  String get goalSaving => 'Guardando tus cambios de forma segura';

  @override
  String get saveGoal => 'Guardar meta';

  @override
  String get goalSubtitle => 'Dale una pequeña razón al enfoque de hoy';

  @override
  String get preview => 'Vista previa';

  @override
  String get goalPlaceholderName => 'Mi pequeña meta';

  @override
  String get goalNameLabel => 'Meta';

  @override
  String get goalNameHint => 'Ej.: examen de certificación';

  @override
  String get goalNameRequired => 'Escribe tu meta.';

  @override
  String get goalDateLabel => 'Fecha de la meta';

  @override
  String get select => 'Elegir';

  @override
  String get goalMessageLabel => 'Una nota para mí';

  @override
  String get goalMessageHint => 'Palabras de ánimo para ti';

  @override
  String get showOnHome => 'Mostrar en inicio';

  @override
  String get showOnHomeSubtitle =>
      'Muestra tu meta en pequeño sobre el escritorio';

  @override
  String get goalChangeAnytime => 'Puedes cambiar tu meta cuando quieras';

  @override
  String get soundRainTitle => 'Lluvia afuera';

  @override
  String get soundRainSubtitle => 'Gotas que golpean suavemente la ventana';

  @override
  String get soundForestTitle => 'Brisa del bosque';

  @override
  String get soundForestSubtitle => 'Viento que pasa entre las hojas';

  @override
  String get soundFireTitle => 'Fuego cálido';

  @override
  String get soundFireSubtitle => 'Un fuego acogedor que crepita';

  @override
  String get soundSheetSubtitle => 'Elige un sonido para tu cuarto';

  @override
  String get volume => 'Volumen';

  @override
  String volumeValue(int percent) {
    return 'Volumen $percent%';
  }

  @override
  String get mute => 'Apagar sonido';

  @override
  String get unmute => 'Encender sonido';

  @override
  String get stopSoundAtEnd => 'Apagar el sonido al terminar';

  @override
  String get soundDone => 'Listo';

  @override
  String get soundPreviewError =>
      'No pudimos reproducir el sonido. Elígelo otra vez.';

  @override
  String get soundSaveError =>
      'No se pudieron guardar los ajustes. Inténtalo de nuevo.';

  @override
  String get ambienceMorning => 'por la mañana';

  @override
  String get ambienceDay => 'de día';

  @override
  String get ambienceEvening => 'al atardecer';

  @override
  String get ambienceNight => 'de noche';

  @override
  String get poseRestPaused => 'descansando con una taza de té en la mano';

  @override
  String get poseTea => 'tomando té';

  @override
  String get posePaused => 'tomando un pequeño descanso';

  @override
  String get poseWriting => 'escribiendo en su cuaderno';

  @override
  String get poseWaiting => 'esperando en el escritorio';

  @override
  String get propShortPlant => 'planta';

  @override
  String get propShortMug => 'taza';

  @override
  String get propShortLamp => 'lámpara';

  @override
  String sceneLabel(String ambience, String pose, String props) {
    return 'El escritorio $ambience. Un panda rojo $pose. Objetos obtenidos: $props';
  }

  @override
  String get navFriends => 'Amigos';

  @override
  String get friendsTitle => 'Elige un amigo';

  @override
  String get friendsSubtitle =>
      'Encuentra un amigo y una habitación que te gusten';

  @override
  String get friendCurrent => 'En uso';

  @override
  String get friendPreviewTitle => 'Cuarto del amigo';

  @override
  String get friendApply => 'Elegir este amigo';

  @override
  String get friendApplyHint => 'El amigo y la habitación cambian juntos';

  @override
  String get friendRestAnimated =>
      'Descansa con un té mientras mira por la ventana';

  @override
  String get friendAnimated => 'Animaciones de escritura y descanso';

  @override
  String get friendStill => 'Este amigo te acompaña como ilustración fija';

  @override
  String get friendRedpanda => 'Panda rojo';

  @override
  String get friendPenguin => 'Pingüino';

  @override
  String get friendOtter => 'Nutria marina';

  @override
  String get friendSquirrel => 'Ardilla';

  @override
  String get friendFennec => 'Zorro fénec';

  @override
  String get roomRedpanda => 'Un escritorio acogedor';

  @override
  String get roomPenguin => 'Un estudio de invierno';

  @override
  String get roomOtter => 'Una costa soleada';

  @override
  String get roomSquirrel => 'Un refugio en el bosque';

  @override
  String get roomFennec => 'Un estudio al atardecer';

  @override
  String get languageTitle => 'Idioma · Language';

  @override
  String get languageSheetTitle => 'Idioma · Language';

  @override
  String get languageSheetSubtitle => 'Elige el idioma de la app';

  @override
  String get followSystem => 'Usar el idioma del teléfono';

  @override
  String languageNow(String language) {
    return 'Idioma del teléfono: $language';
  }

  @override
  String get languageFallbackNote =>
      'Los idiomas del teléfono que no están en la lista se muestran en inglés';

  @override
  String languageChanged(String language) {
    return 'Idioma cambiado a $language';
  }

  @override
  String get languageNameKo => 'Coreano';

  @override
  String get languageNameEn => 'Inglés';

  @override
  String get languageNameJa => 'Japonés';

  @override
  String get languageNameEs => 'Español';

  @override
  String get recordsTabCalendar => 'Calendario';

  @override
  String get recordsTabWeek => 'Semana';

  @override
  String get recordsTabMonth => 'Mes';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String get previousWeek => 'Semana anterior';

  @override
  String get nextWeek => 'Semana siguiente';

  @override
  String get backToThisWeek => 'Volver a esta semana';

  @override
  String statsMoreThanLastWeek(String duration) {
    return '$duration más que la semana pasada';
  }

  @override
  String statsLessThanLastWeek(String duration) {
    return '$duration menos que la semana pasada';
  }

  @override
  String get statsSameAsLastWeek => 'Igual que la semana pasada';

  @override
  String statsMoreThanLastMonth(String duration) {
    return '$duration más que el mes pasado';
  }

  @override
  String statsLessThanLastMonth(String duration) {
    return '$duration menos que el mes pasado';
  }

  @override
  String get statsSameAsLastMonth => 'Igual que el mes pasado';

  @override
  String statsBestDay(String day, String duration) {
    return 'Mejor día · $day $duration';
  }

  @override
  String get statsTimeOfDay => 'Momento del día';

  @override
  String statsTopBand(String band) {
    return 'Te concentras más $band';
  }

  @override
  String get statsAverage => 'Promedio diario';

  @override
  String get statsStreak => 'Racha más larga';

  @override
  String get statsRecentMonths => 'Últimos 6 meses';

  @override
  String get statsEmptyWeek => 'Aún no hay concentración esta semana.';

  @override
  String get statsEmptyMonth => 'Aún no hay concentración este mes.';

  @override
  String hoursShort(String hours) {
    return '$hours h';
  }
}
