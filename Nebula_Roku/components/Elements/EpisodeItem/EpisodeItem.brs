' Inicializa referencias del componente visual EpisodeItem.
sub init()
  ' Guarda fondo semitransparente para estado de foco.
  m.focusBackground = m.top.findNode("focusBackground")
  ' Guarda contenedor horizontal principal.
  m.episodeContainer = m.top.findNode("episodeContainer")
  ' Guarda contenedor de superposición de medios del episodio.
  m.episodeMedia = m.top.findNode("episodeMedia")
  ' Guarda imagen principal del episodio.
  m.emissionImage = m.top.findNode("emissionImage")
  ' Guarda poster de respaldo cuando no hay imagen.
  m.imageNotFound = m.top.findNode("imageNotFound")
  ' Guarda label de título superpuesto sobre la imagen.
  m.emissionTitleOverlay = m.top.findNode("emissionTitleOverlay")
  ' Guarda ícono de play superpuesto.
  m.playImage = m.top.findNode("playImage")
  ' Guarda bloque de duración en esquina inferior derecha.
  m.episodeTimeGroup = m.top.findNode("episodeTimeGroup")
  ' Guarda label de duración del episodio.
  m.episodeTime = m.top.findNode("episodeTime")
  ' Guarda columna de información textual.
  m.episodeInfo = m.top.findNode("episodeInfo")
  ' Guarda label de título de episodio.
  m.episodeTitle = m.top.findNode("episodeTitle")
  ' Guarda label de sinopsis del episodio.
  m.episodeSynopsis = m.top.findNode("episodeSynopsis")
  ' Obtiene escala global para dimensionar como el resto de la app.
  m.scaleInfo = m.global.scaleInfo

  ' Ejecuta primera sincronización usando los campos de entrada declarados.
  onEpisodeInputChanged()
  ' Sincroniza estado visual inicial del foco.
  onFocusStateChanged()
  ' Ajusta layout inicial del item.
  __updateLayout()
end sub

' Recalcula layout cuando cambia el ancho disponible.
sub onLayoutChanged()
  ' Reaplica tamaños y posiciones dependientes del ancho.
  __updateLayout()
end sub

' Actualiza contenido visible cuando cambian los campos públicos del componente.
sub onEpisodeInputChanged()
  episodeTitle = ""
  if m.top.title <> invalid and m.top.title <> "" then episodeTitle = m.top.title
  ' Setea título tanto en la columna de información como sobre la imagen.
  m.episodeTitle.text = episodeTitle
  programTitle = ""
  if m.top.programTitle <> invalid and m.top.programTitle <> "" then programTitle = m.top.programTitle
  m.emissionTitleOverlay.text = programTitle
  ' Setea título únicamente cuando llega un valor válido.
  if m.top.title <> invalid and m.top.title <> "" then m.episodeTitle.text = m.top.title
  ' Setea sinopsis únicamente cuando llega un valor válido.
  if m.top.synopsis <> invalid and m.top.synopsis <> "" then m.episodeSynopsis.text = m.top.synopsis
  ' Setea duración únicamente cuando llega un valor válido.
  if m.top.formattedDuration <> invalid and m.top.formattedDuration <> "" then m.episodeTime.text = m.top.formattedDuration
  ' Construye uri fallback dinámico usando índice recibido desde EmissionsScreen.
  fallbackIndex = m.top.index
  if fallbackIndex = invalid or fallbackIndex < 1 then fallbackIndex = 1
  fallbackIndex = ((fallbackIndex - 1) mod 4) + 1
  fallbackUri = "pkg:/images/shared/show_image_empty_" + fallbackIndex.toStr() + ".jpg"
  ' Aplica fallback dinámico al poster de respaldo.
  if m.imageNotFound <> invalid then m.imageNotFound.uri = fallbackUri
  ' Resuelve la URL de imagen usando getImageUrl cuando llega el objeto image.
  if m.top.image <> invalid then m.emissionImage.uri = getImageUrl(m.top.image)
  ' Muestra u oculta playImage según el flag play recibido.
  m.playImage.visible = m.top.play
  ' Fuerza opacidad completa del texto de duración para evitar herencias visuales.
  m.episodeTime.opacity = 1
  ' Recalcula layout para respetar altura de imágen cargada.
  __updateLayout()
end sub

' Aplica estado visual del item cuando cambia su foco lógico.
sub onFocusStateChanged()
  if m.focusBackground = invalid then return
  m.focusBackground.visible = m.top.isFocused
end sub

' Ajusta posiciones y tamaños para cumplir el diseño solicitado.
sub __updateLayout()
  ' Calcula ancho de imagen usando scale para mantener consistencia global.
  scaledImageWidth = cint(scaleValue(180, m.scaleInfo))
  m.emissionImage.width = scaledImageWidth
  m.imageNotFound.width = scaledImageWidth
  ' Define ancho y alto base para relación de aspecto vertical (3:4).
  aspectWidth = 3
  aspectHeight = 4

  ' Calcula alto esperado a partir del ancho fijo y la proporción elegida.
  expectedHeight = cint((scaledImageWidth * aspectHeight) / aspectWidth)
  ' Garantiza que la imágen quede más alta que ancha.
  if expectedHeight <= m.emissionImage.width then expectedHeight = m.emissionImage.width + 1
  ' Aplica el alto final manteniendo la proporción seleccionada.
  m.emissionImage.height = expectedHeight
  m.imageNotFound.height = expectedHeight

  ' Sincroniza tamaño del label superpuesto para cubrir toda la imagen.
  m.emissionTitleOverlay.width = m.emissionImage.width
  m.emissionTitleOverlay.height = m.emissionImage.height
  m.emissionTitleOverlay.translation = [0, 0]

  ' Aplica traslación final para que playImage quede justo en el centro de la imagen.
  centeredPlayX = cint((m.emissionImage.width - m.playImage.width) / 2)
  centeredPlayY = cint((m.emissionImage.height - m.playImage.height) / 2)
  m.playImage.translation = [centeredPlayX, centeredPlayY]
  m.playImage.height = scaleValue(80, m.scaleInfo)
  m.playImage.width = scaleValue(80, m.scaleInfo)

  ' Setear el ancho y alto de los componentes
  m.episodeTimeGroup.width = cint(scaleValue(70, m.scaleInfo))
  m.episodeTimeGroup.height = cint(scaleValue(30, m.scaleInfo))
  ' Escala el ancho del texto de duración para mantener consistencia visual.
  m.episodeTime.width = cint(scaleValue(70, m.scaleInfo))
  ' Escala el alto del texto de duración para mantener consistencia visual.
  m.episodeTime.height = cint(scaleValue(30, m.scaleInfo))
  ' Reafirma opacidad completa del texto de duración durante cada actualización de layout.
  m.episodeTime.opacity = 1
  ' Ubica bloque de tiempo en esquina inferior derecha de emissionImage.
  m.episodeTimeGroup.translation = [m.emissionImage.width - cint(scaleValue(70, m.scaleInfo)), m.emissionImage.height - cint(scaleValue(30, m.scaleInfo))]
  ' Ajusta ancho disponible para columna de texto.
  infoWidth = m.top.widthContainer - m.emissionImage.width - cint(scaleValue(425, m.scaleInfo))
  ' Evita valores negativos en resoluciones pequeñas.
  if infoWidth < cint(scaleValue(100, m.scaleInfo)) then infoWidth = cint(scaleValue(100, m.scaleInfo))
  ' Aplica ancho del texto al título.
  m.episodeTitle.width = infoWidth
  ' Aplica ancho del texto a la sinopsis.
  m.episodeSynopsis.width = infoWidth
' Ajusta tamaño del fondo para cubrir todo el item visible.
  __syncFocusBackgroundSize()
end sub

' Sincroniza tamaño del fondo de foco para cubrir el EpisodeItem completo.
sub __syncFocusBackgroundSize()
  if m.focusBackground = invalid then return
  backgroundWidth = m.top.widthContainer
  backgroundHeight = cint(scaleValue(237, m.scaleInfo))
  if m.episodeContainer <> invalid then
    containerBounds = m.episodeContainer.boundingRect()
    if containerBounds <> invalid and containerBounds.width <> invalid and cint(containerBounds.width) > 0 then backgroundWidth = cint(containerBounds.width)
    if containerBounds <> invalid and containerBounds.height <> invalid and cint(containerBounds.height) > 0 then backgroundHeight = cint(containerBounds.height)
  end if
  m.focusBackground.width = backgroundWidth
  m.focusBackground.height = backgroundHeight
  if m.episodeContainer <> invalid then
    m.focusBackground.translation = [cint(m.episodeContainer.translation[0]), cint(m.episodeContainer.translation[1])]
  else
    m.focusBackground.translation = [0, 0]
  end if
end sub