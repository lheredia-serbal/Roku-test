' Inicialización del componente SearchScreen.
sub init()
  ' Referencio el nodo del input de búsqueda principal.
  m.searchInput = m.top.findNode("searchInput")
  ' Referencio el nodo del teclado en pantalla.
  m.searchKeyboard = m.top.findNode("searchKeyboard")

  ' Referencio la animación que muestra el teclado.
  m.keyboardShowAnimation = m.top.findNode("keyboardShowAnimation")
  ' Referencio la animación que oculta el teclado.
  m.keyboardHideAnimation = m.top.findNode("keyboardHideAnimation")
  ' Referencio el interpolador de traducción para mostrar teclado.
  m.keyboardShowTranslationInterpolator = m.top.findNode("keyboardShowTranslationInterpolator")
  ' Referencio el interpolador de traducción para ocultar teclado.
  m.keyboardHideTranslationInterpolator = m.top.findNode("keyboardHideTranslationInterpolator")

  ' Obtengo la información de escala global de la app.
  m.scaleInfo = m.global.scaleInfo

  ' Seteo el ancho del input para ocupar todo el ancho de pantalla.
  m.searchInput.width = m.scaleInfo.width
  ' Seteo la posición del input en la esquina superior izquierda.
  m.searchInput.translation = [0, 0]
  ' Defino el largo máximo de texto permitido en el input.
  m.searchInput.maxTextLength = 255
  ' Defino el color del texto de ayuda del input.
  m.searchInput.hintTextColor = m.global.colors.LIGHT_GRAY

  ' Defino un ancho por defecto para el teclado si no hay medidas reales aún.
  m.keyboardDefaultWidth = scaleValue(1120, m.scaleInfo)
  ' Defino una altura por defecto para el teclado si no hay medidas reales aún.
  m.keyboardDefaultHeight = scaleValue(320, m.scaleInfo)

  ' Posiciono inicialmente el teclado fuera de pantalla (debajo).
  m.searchKeyboard.translation = [0, m.scaleInfo.height]
  ' Inicio el teclado totalmente transparente.
  m.searchKeyboard.opacity = 0.0
  ' Inicio el teclado invisible.
  m.searchKeyboard.visible = false
  ' Evito que el teclado dibuje su propio TextEditBox interno.
  m.searchKeyboard.showTextEditBox = false

  ' Observo cambios de foco del input para mostrar/ocultar teclado.
  m.searchInput.observeField("hasFocus", "onSearchInputFocusChanged")
  ' Observo cambios del TextEditBox interno del teclado para sincronizar texto.
  m.searchKeyboard.observeField("textEditBox", "onKeyboardTextChanged")
  ' Observo el estado de animación de ocultar teclado para limpiar estado final.
  m.keyboardHideAnimation.observeField("state", "onKeyboardHideAnimationStateChanged")
end sub

' Inicializa foco cuando la pantalla se vuelve activa.
sub initFocus()
  ' Si la pantalla recibió foco.
  if m.top.onFocus then
    ' Aplico textos traducidos del input.
    __applyTranslations()
    ' Aseguro foco en el nodo top para cadena de foco correcta.
    m.top.setFocus(true)
    ' Enfoco el input para disparar la lógica de teclado.
    m.searchInput.setFocus(true)
  else
    ' Si pierde foco, oculto teclado sin animación.
    __hideKeyboard(false)
  end if
end sub

' Muestra/oculta teclado cuando cambia el foco del input.
sub onSearchInputFocusChanged()
  ' Si el input no existe, no hago nada.
  if m.searchInput = invalid then return

  ' Si el input tiene foco, muestro teclado.
  if m.searchInput.hasFocus() then
    ' Muestro teclado animado.
    __showKeyboard()
  else
    ' Si el input pierde foco, oculto teclado animado.
    __hideKeyboard(true)
  end if
end sub

' Sincroniza el texto y cursor del teclado con el input visible.
sub onKeyboardTextChanged()
  ' Si falta teclado o input, salgo.
  if m.searchKeyboard = invalid or m.searchInput = invalid then return

  ' Copio la posición de cursor desde el TextEditBox interno del teclado.
  m.searchInput.cursorPosition = m.searchKeyboard.textEditBox.cursorPosition
  ' Copio el texto desde el TextEditBox interno del teclado.
  m.searchInput.text = m.searchKeyboard.textEditBox.text
  ' Copio el estado activo del TextEditBox interno del teclado.
  m.searchInput.active = m.searchKeyboard.textEditBox.active
end sub

' Maneja eventos de control remoto para navegación/foco.
function onKeyEvent(key as String, press as Boolean) as Boolean
  ' Ignoro evento de key down y manejo solo key up.
  if press then return false

  ' Si presionan BACK con teclado visible, cierro teclado y retorno foco al input.
  if key = KeyButtons().BACK and m.searchKeyboard <> invalid and m.searchKeyboard.visible then
    ' Oculto teclado con animación.
    __hideKeyboard(true)
    ' Retorno foco al input.
    m.searchInput.setFocus(true)
    ' Indico que el evento fue manejado.
    return true
  end if

  ' Si el input está en foco y presionan OK, muestro teclado.
  if m.searchInput <> invalid and m.searchInput.isInFocusChain() and key = KeyButtons().OK then
    ' Muestro teclado animado.
    __showKeyboard()
    ' Indico que el evento fue manejado.
    return true
  end if

  ' Si no coincide ningún caso, no manejo el evento.
  return false
end function

' Calcula posición final del teclado centrado y pegado al borde inferior.
sub __updateKeyboardTranslations()
  ' Inicio ancho con valor por defecto.
  keyboardWidth = m.keyboardDefaultWidth
  ' Inicio alto con valor por defecto.
  keyboardHeight = m.keyboardDefaultHeight

  ' Leo bounds reales del teclado para posicionamiento preciso.
  keyboardBounds = m.searchKeyboard.boundingRect()
  ' Si hay bounds válidos.
  if keyboardBounds <> invalid then
    ' Si width de bounds es válido y positivo, uso ese ancho real.
    if keyboardBounds.width <> invalid and keyboardBounds.width > 0 then keyboardWidth = keyboardBounds.width
    ' Si height de bounds es válido y positivo, uso ese alto real.
    if keyboardBounds.height <> invalid and keyboardBounds.height > 0 then keyboardHeight = keyboardBounds.height
  end if

  ' Calculo coordenada X para centrar teclado horizontalmente.
  keyboardX = int((m.scaleInfo.width - keyboardWidth) / 2)
  ' Evito X negativa.
  if keyboardX < 0 then keyboardX = 0

  ' Calculo coordenada Y para pegar teclado al borde inferior.
  keyboardY = m.scaleInfo.height - keyboardHeight
  ' Evito Y negativa.
  if keyboardY < 0 then keyboardY = 0

  ' Defino posición visible final del teclado.
  m.keyboardVisibleTranslation = [keyboardX, keyboardY]
  ' Defino posición oculta del teclado fuera de pantalla hacia abajo.
  m.keyboardHiddenTranslation = [keyboardX, m.scaleInfo.height]

  ' Aplico estas posiciones a los keyframes de animación.
  __configureKeyboardAnimations()
end sub

' Configura los keyframes de animación del teclado.
sub __configureKeyboardAnimations()
  ' Si existe interpolador de mostrar.
  if m.keyboardShowTranslationInterpolator <> invalid then
    ' Seteo keyframes para subir teclado desde oculto hasta visible.
    m.keyboardShowTranslationInterpolator.keyValue = [m.keyboardHiddenTranslation, m.keyboardVisibleTranslation]
  end if

  ' Si existe interpolador de ocultar.
  if m.keyboardHideTranslationInterpolator <> invalid then
    ' Seteo keyframes para bajar teclado desde visible hasta oculto.
    m.keyboardHideTranslationInterpolator.keyValue = [m.keyboardVisibleTranslation, m.keyboardHiddenTranslation]
  end if
end sub

' Muestra el teclado con animación ascendente.
sub __showKeyboard()
  ' Si teclado no existe, salgo.
  if m.searchKeyboard = invalid then return

  ' Detengo animación de ocultado por seguridad.
  m.keyboardHideAnimation.control = "stop"
  ' Hago visible el teclado antes de animar.
  m.searchKeyboard.visible = true
  ' Recalculo posiciones por si cambió tamaño real del teclado.
  __updateKeyboardTranslations()

  ' Ubico teclado en posición oculta inicial para animar entrada.
  m.searchKeyboard.translation = m.keyboardHiddenTranslation
  ' Inicio teclado transparente para fade in.
  m.searchKeyboard.opacity = 0.0

  ' Sincronizo texto actual del input al teclado.
  m.searchKeyboard.textEditBox.text = m.searchInput.text
  ' Sincronizo cursor actual del input al teclado.
  m.searchKeyboard.textEditBox.cursorPosition = m.searchInput.cursorPosition

  ' Inicio animación de mostrar.
  m.keyboardShowAnimation.control = "start"
  ' Paso foco al teclado para escribir inmediatamente.
  m.searchKeyboard.setFocus(true)
end sub

' Oculta el teclado con animación descendente.
sub __hideKeyboard(withAnimation as Boolean)
  ' Si teclado no existe, salgo.
  if m.searchKeyboard = invalid then return

  ' Detengo animación de mostrar por seguridad.
  m.keyboardShowAnimation.control = "stop"

  ' Si hay que ocultar animado.
  if withAnimation then
    ' Solo arranco animación si teclado está visible.
    if m.searchKeyboard.visible then
      ' Inicio animación de ocultar.
      m.keyboardHideAnimation.control = "start"
    end if
  else
    ' Si no hay animación, detengo ocultado.
    m.keyboardHideAnimation.control = "stop"
    ' Marco teclado invisible.
    m.searchKeyboard.visible = false
    ' Reubico teclado debajo de pantalla.
    m.searchKeyboard.translation = [0, m.scaleInfo.height]
    ' Dejo teclado transparente.
    m.searchKeyboard.opacity = 0.0
  end if
end sub

' Al finalizar la animación de ocultar, deja el teclado invisible.
sub onKeyboardHideAnimationStateChanged()
  ' Si faltan nodos necesarios, salgo.
  if m.keyboardHideAnimation = invalid or m.searchKeyboard = invalid then return

  ' Cuando la animación termina.
  if m.keyboardHideAnimation.state = "stopped" then
    ' Oculto teclado definitivamente.
    m.searchKeyboard.visible = false
    ' Lo dejo fuera de pantalla abajo.
    m.searchKeyboard.translation = [0, m.scaleInfo.height]
    ' Lo dejo transparente.
    m.searchKeyboard.opacity = 0.0
  end if
end sub

' Aplica traducciones del placeholder del input.
sub __applyTranslations()
  ' Si no hay diccionario i18n, salgo.
  if m.global.i18n = invalid then return

  ' Aplico hint text usando la clave solicitada por negocio.
  m.searchInput.hintText = i18n_t(m.global.i18n, "search.noResultsDefaultSearch")
end sub