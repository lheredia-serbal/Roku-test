' Inicializa referencias del componente visual EpisodeItem.
sub init()
  ' Guarda contenedor horizontal principal.
  m.episodeContainer = m.top.findNode("episodeContainer")
  ' Guarda contenedor de superposición de medios del episodio.
  m.episodeMedia = m.top.findNode("episodeMedia")
  ' Guarda imagen principal del episodio.
  m.emissionImage = m.top.findNode("emissionImage")
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
  ' Setea título únicamente cuando llega un valor válido.
  if m.top.title <> invalid and m.top.title <> "" then m.episodeTitle.text = m.top.title
  ' Setea sinopsis únicamente cuando llega un valor válido.
  if m.top.synopsis <> invalid and m.top.synopsis <> "" then m.episodeSynopsis.text = m.top.synopsis
  ' Setea duración únicamente cuando llega un valor válido.
  if m.top.formattedDuration <> invalid and m.top.formattedDuration <> "" then m.episodeTime.text = m.top.formattedDuration
  ' Resuelve la URL de imagen usando getImageUrl cuando llega el objeto image.
  if m.top.image <> invalid then m.emissionImage.uri = getImageUrl(m.top.image)
  ' Muestra u oculta playImage según el flag play recibido.
  m.playImage.visible = m.top.play
  ' Recalcula layout para respetar altura de imagen cargada.
  __updateLayout()
end sub

' Ajusta posiciones y tamaños para cumplir el diseño solicitado.
sub __updateLayout()
  ' Aplica ancho total del item (100% pantalla disponible).
  m.top.width = m.top.widthContainer
  ' Ajusta ancho del layout principal.
  m.episodeContainer.width = m.top.widthContainer
  ' Calcula ancho de imagen usando scale para mantener consistencia global.
  scaledImageWidth = cint(scaleValue(230, m.scaleInfo))
  ' Fuerza ancho fijo solicitado para emissionImage con escala aplicada.
  m.emissionImage.width = scaledImageWidth
  ' Define ancho base para relación de aspecto vertical (3:4).
  aspectWidth = 3
  ' Define alto base para relación de aspecto vertical (3:4).
  aspectHeight = 4
  ' Lee ancho original enviado en el objeto image cuando existe.
  sourceWidth = invalid
  ' Lee alto original enviado en el objeto image cuando existe.
  sourceHeight = invalid
  ' Intenta usar tamaño original si llega dentro del payload image.
  if m.top.image <> invalid then
    ' Toma image.width cuando está disponible.
    if m.top.image.width <> invalid then sourceWidth = val(m.top.image.width.toStr())
    ' Toma image.height cuando está disponible.
    if m.top.image.height <> invalid then sourceHeight = val(m.top.image.height.toStr())
  end if
  ' Reemplaza relación base con la relación real solo si ya es vertical.
  if sourceWidth <> invalid and sourceHeight <> invalid and sourceWidth > 0 and sourceHeight > sourceWidth then
    ' Usa el ancho real para conservar la proporción vertical de origen.
    aspectWidth = sourceWidth
    ' Usa el alto real para conservar la proporción vertical de origen.
    aspectHeight = sourceHeight
  end if
  ' Calcula alto esperado a partir del ancho fijo y la proporción elegida.
  expectedHeight = cint((scaledImageWidth * aspectHeight) / aspectWidth)
  ' Garantiza que la imagen quede más alta que ancha.
  if expectedHeight <= m.emissionImage.width then expectedHeight = m.emissionImage.width + 1
  ' Aplica el alto final manteniendo la proporción seleccionada.
  m.emissionImage.height = expectedHeight
  ' Sincroniza tamaño del contenedor superpuesto con la imagen principal.
  m.episodeMedia.width = m.emissionImage.width
  ' Sincroniza alto del contenedor superpuesto con la imagen principal.
  m.episodeMedia.height = m.emissionImage.height
  ' Centra playImage dentro de emissionImage en eje X.
  centeredPlayX = cint((m.emissionImage.width - m.playImage.width) / 2)
  ' Centra playImage dentro de emissionImage en eje Y.
  centeredPlayY = cint((m.emissionImage.height - m.playImage.height) / 2)
  ' Aplica traslación final para que playImage quede justo en el centro de la imagen.
  m.playImage.translation = [centeredPlayX, centeredPlayY]
  ' Escala el ancho del bloque de tiempo para mantener consistencia visual.
  m.episodeTimeGroup.width = cint(scaleValue(100, m.scaleInfo))
  ' Escala el alto del bloque de tiempo para mantener consistencia visual.
  m.episodeTimeGroup.height = cint(scaleValue(30, m.scaleInfo))
  ' Escala el ancho del texto de duración para mantener consistencia visual.
  m.episodeTime.width = cint(scaleValue(100, m.scaleInfo))
  ' Escala el alto del texto de duración para mantener consistencia visual.
  m.episodeTime.height = cint(scaleValue(30, m.scaleInfo))
  ' Ubica bloque de tiempo en esquina inferior derecha de emissionImage.
  m.episodeTimeGroup.translation = [m.emissionImage.width - m.episodeTimeGroup.width, m.emissionImage.height - m.episodeTimeGroup.height]
  ' Ajusta ancho disponible para columna de texto.
  infoWidth = m.top.widthContainer - m.emissionImage.width - cint(scaleValue(350, m.scaleInfo))
  ' Evita valores negativos en resoluciones pequeñas.
  if infoWidth < cint(scaleValue(100, m.scaleInfo)) then infoWidth = cint(scaleValue(100, m.scaleInfo))
  ' Aplica ancho calculado a episodeInfo.
  m.episodeInfo.width = infoWidth
  ' Aplica ancho del texto al título.
  m.episodeTitle.width = infoWidth
  ' Aplica ancho del texto a la sinopsis.
  m.episodeSynopsis.width = infoWidth
end sub