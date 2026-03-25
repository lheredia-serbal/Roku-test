sub init() ' Inicializa referencias y configuración base del componente mínimo sin animaciones.
  m.debugSearchInput = m.top.findNode("debugSearchInput") ' Referencia al input visible renombrado.
  m.debugSearchKeyboard = m.top.findNode("debugSearchKeyboard") ' Referencia al teclado virtual renombrado.
  m.debugKeyboardBackground = m.top.findNode("debugKeyboardBackground") ' Referencia al fondo del teclado renombrado.
  m.scaleInfo = m.global.scaleInfo ' Información de escalado para layout responsivo.
  m.currentSearchText = "" ' Estado persistido del texto para evitar pérdidas al salir de foco.

  m.debugSearchInput.width = m.scaleInfo.width - 150 ' Mismo ancho usado en SearchScreen original.
  m.debugSearchInput.translation = scaleSize([50, 50], m.scaleInfo) ' Mismo posicionamiento del input original.
  m.debugSearchInput.maxTextLength = 255 ' Límite estándar de caracteres.
  m.debugSearchInput.hintTextColor = m.global.colors.LIGHT_GRAY ' Color del hint igual al original.

  m.keyboardDefaultWidth = scaleValue(1120, m.scaleInfo) ' Ancho fallback si keyboard aún no reporta bounds.
  m.keyboardDefaultHeight = scaleValue(320, m.scaleInfo) ' Alto fallback si keyboard aún no reporta bounds.
  m.debugSearchKeyboard.showTextEditBox = false ' Oculta TextEditBox interno para usar solo el input externo.

  m.debugSearchInput.observeField("hasFocus", "onSearchInputFocusChanged") ' Muestra/oculta teclado al cambiar foco del input.
  m.debugSearchInput.observeField("textEditBox", "onDebugSearchInputTextChanged") ' Persiste texto aun cuando el foco cambia fuera del input.

  __applyTranslations() ' Carga textos traducidos del input.
  __hideKeyboard() ' Inicializa teclado completamente oculto.
end sub

sub initFocus() ' Gestiona entrada/salida de foco de la pantalla.
  if m.top.onFocus then ' Ejecuta al activar pantalla.
    __applyTranslations() ' Reaplica traducciones por si cambió idioma.
    m.top.setFocus(true) ' Garantiza cadena de foco activa en el contenedor.
    __restoreSearchInputText() ' Restaura el texto persistido en el input.
    if m.debugSearchKeyboard <> invalid then m.debugSearchKeyboard.observeField("textEditBox", "onTextBoxManagment") ' Sincroniza teclado interno con input visible.
    m.debugSearchInput.setFocus(true) ' Coloca foco inicial en el input.
  else ' Ejecuta al desactivar pantalla.
    __restoreSearchInputText() ' Conserva texto visible al perder foco.
    __hideKeyboard() ' Oculta teclado de forma inmediata al salir de pantalla.
  end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean ' Maneja teclas relevantes para input+teclado.
  if key = KeyButtons().BACK and press and m.debugSearchKeyboard <> invalid and m.debugSearchKeyboard.visible then ' Permite cerrar teclado con BACK.
    __hideKeyboard() ' Oculta teclado inmediatamente.
    if m.debugSearchInput <> invalid then m.debugSearchInput.setFocus(true) ' Devuelve foco al input.
    return true ' Marca evento como procesado.
  end if

  if key = KeyButtons().OK and press and m.debugSearchInput <> invalid and m.debugSearchInput.isInFocusChain() then ' Abre teclado al pulsar OK en input.
    __showKeyboard() ' Muestra teclado y transfiere foco.
    return true ' Marca evento como procesado.
  end if

  if key = KeyButtons().DOWN and press and m.debugSearchInput <> invalid and m.debugSearchInput.isInFocusChain() then ' Evita que DOWN saque el foco y limpie visualmente el TextEditBox.
    __restoreSearchInputText() ' Reafirma el valor persistido antes de consumir la tecla.
    return true ' Consume DOWN porque esta pantalla de debug no tiene un destino de foco inferior.
  end if

  return false ' Deja pasar otras teclas a componentes superiores.
end function

sub onSearchInputFocusChanged() ' Reacciona al foco del input para mostrar/ocultar teclado.
  if m.debugSearchInput = invalid then return ' Sale si no existe input.
  if m.debugSearchInput.hasFocus() then ' Si input gana foco.
    __showKeyboard() ' Muestra teclado.
  else ' Si input pierde foco.
    __captureCurrentSearchText() ' Captura el último texto antes de ocultar teclado o perder estado visual.
    __hideKeyboard() ' Oculta teclado sin animación.
    __restoreSearchInputText() ' Restaura el texto persistido inmediatamente para evitar que se limpie al perder foco.
  end if
end sub

sub onTextBoxManagment() ' Sincroniza contenido del teclado interno con el input visible.
  if m.debugSearchKeyboard = invalid or m.debugSearchInput = invalid then return ' Evita errores sin referencias válidas.
  if m.debugSearchKeyboard.textEditBox = invalid then return ' Espera a que exista TextEditBox interno.
  m.debugSearchInput.cursorPosition = m.debugSearchKeyboard.textEditBox.cursorPosition ' Replica posición del cursor.
  m.debugSearchInput.text = m.debugSearchKeyboard.textEditBox.text ' Replica texto actual.
  m.debugSearchInput.active = m.debugSearchKeyboard.textEditBox.active ' Replica estado activo.
  m.currentSearchText = m.debugSearchInput.text ' Persiste texto para restauración posterior.
end sub

sub onDebugSearchInputTextChanged() ' Persiste el texto visible del input en cada cambio de valor.
  if m.debugSearchInput = invalid then return ' Sale si no existe input.
  m.currentSearchText = m.debugSearchInput.text ' Guarda el texto para evitar pérdidas al mover foco.
end sub

sub restoreFocus() ' API usada por MainScene para restaurar foco al volver.
  if m.debugSearchInput <> invalid then m.debugSearchInput.setFocus(true) ' Foco siempre vuelve al input en esta versión mínima.
end sub

sub __applyTranslations() ' Aplica hint traducido.
  if m.global.i18n = invalid or m.debugSearchInput = invalid then return ' Evita errores sin i18n/input.
  m.debugSearchInput.hintText = i18n_t(m.global.i18n, "search.noResultsDefaultSearch") ' Reutiliza la misma clave de SearchScreen.
end sub

sub __showKeyboard() ' Muestra teclado sin animación y conserva estado de texto.
  if m.debugSearchKeyboard = invalid or m.debugSearchInput = invalid then return ' Sale si falta teclado o input.
  __captureCurrentSearchText() ' Sincroniza cache antes de mostrar teclado para mantener continuidad de texto.

  keyboardWidth = m.keyboardDefaultWidth ' Inicia con ancho fallback.
  keyboardHeight = m.keyboardDefaultHeight ' Inicia con alto fallback.
  keyboardBounds = m.debugSearchKeyboard.boundingRect() ' Lee dimensiones reales cuando existen.
  if keyboardBounds <> invalid then ' Usa dimensiones reales si son válidas.
    if keyboardBounds.width <> invalid and keyboardBounds.width > 0 then keyboardWidth = keyboardBounds.width ' Reemplaza ancho fallback.
    if keyboardBounds.height <> invalid and keyboardBounds.height > 0 then keyboardHeight = keyboardBounds.height ' Reemplaza alto fallback.
  end if

  keyboardX = int((m.scaleInfo.width - keyboardWidth) / 2) ' Centra horizontalmente el teclado.
  if keyboardX < 0 then keyboardX = 0 ' Evita coordenadas negativas.
  keyboardY = m.scaleInfo.height - keyboardHeight ' Pega teclado al borde inferior.
  if keyboardY < 0 then keyboardY = 0 ' Evita coordenadas negativas.

  m.debugSearchKeyboard.visible = true ' Muestra teclado inmediatamente.
  m.debugSearchKeyboard.translation = [keyboardX, keyboardY] ' Posiciona teclado final visible.
  m.debugSearchKeyboard.opacity = 1.0 ' Fuerza opacidad completa sin fade.

  if m.debugKeyboardBackground <> invalid then ' Sincroniza fondo opaco del teclado.
    m.debugKeyboardBackground.visible = true ' Muestra fondo inmediatamente.
    m.debugKeyboardBackground.translation = [0, keyboardY] ' Posiciona fondo al mismo alto del teclado.
    m.debugKeyboardBackground.width = m.scaleInfo.width ' Hace fondo a ancho completo.
    m.debugKeyboardBackground.height = keyboardHeight ' Ajusta altura al teclado.
    m.debugKeyboardBackground.opacity = 1.0 ' Opacidad completa del fondo.
  end if

  if m.debugSearchKeyboard.textEditBox <> invalid then ' Sincroniza estado previo en el teclado interno.
    m.debugSearchKeyboard.textEditBox.text = m.currentSearchText ' Restaura texto persistido.
    m.debugSearchKeyboard.textEditBox.cursorPosition = m.debugSearchInput.cursorPosition ' Restaura posición de cursor.
  end if

  m.debugSearchKeyboard.setFocus(true) ' Pasa foco al teclado para escritura inmediata.
end sub

sub __hideKeyboard() ' Oculta teclado de forma inmediata y sin animaciones.
  if m.debugSearchKeyboard = invalid then return ' Sale si no existe teclado.
  __captureCurrentSearchText() ' Captura el contenido más reciente antes de ocultar el teclado.
  m.debugSearchKeyboard.visible = false ' Oculta teclado inmediatamente.
  m.debugSearchKeyboard.translation = [0, m.scaleInfo.height] ' Deja teclado fuera de pantalla.
  m.debugSearchKeyboard.opacity = 0.0 ' Deja teclado transparente.

  if m.debugKeyboardBackground <> invalid then ' Ajusta también el fondo de teclado.
    m.debugKeyboardBackground.visible = false ' Oculta fondo inmediatamente.
    m.debugKeyboardBackground.translation = [0, m.scaleInfo.height] ' Oculta fondo fuera de pantalla.
    m.debugKeyboardBackground.opacity = 0.0 ' Vuelve fondo transparente.
  end if
end sub

sub __restoreSearchInputText() ' Recompone el texto visible del input.
  if m.debugSearchInput = invalid then return ' Sale si no existe input.
  if m.currentSearchText = invalid then m.currentSearchText = "" ' Garantiza valor string válido.
  m.debugSearchInput.text = m.currentSearchText ' Restaura texto persistido.
  m.debugSearchInput.cursorPosition = m.currentSearchText.len() ' Cursor al final del texto restaurado.
end sub

sub __captureCurrentSearchText() ' Centraliza la captura del texto actual para evitar pérdidas entre cambios de foco.
  if m.currentSearchText = invalid then m.currentSearchText = "" ' Garantiza variable de cache inicializada.
  if m.debugSearchKeyboard <> invalid and m.debugSearchKeyboard.visible and m.debugSearchKeyboard.textEditBox <> invalid then ' Solo usa teclado cuando realmente está visible y activo.
    m.currentSearchText = m.debugSearchKeyboard.textEditBox.text ' Guarda el valor real escrito en teclado.
  else if m.debugSearchInput <> invalid then ' Fallback al valor visible del input cuando no hay textEditBox.
    m.currentSearchText = m.debugSearchInput.text ' Guarda el valor visible del input.
  end if
end sub
