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
  ' Fuerza opacidad completa del texto de duración para evitar herencias visuales.
  m.episodeTime.opacity = 1
  ' Recalcula layout para respetar altura de imágen cargada.
  __updateLayout()
end sub

' Ajusta posiciones y tamaños para cumplir el diseño solicitado.
sub __updateLayout()
  ' Calcula ancho de imagen usando scale para mantener consistencia global.
  scaledImageWidth = cint(scaleValue(180, m.scaleInfo))
  m.emissionImage.width = scaledImageWidth
  ' Define ancho y alto base para relación de aspecto vertical (3:4).
  aspectWidth = 3
  aspectHeight = 4

  ' Calcula alto esperado a partir del ancho fijo y la proporción elegida.
  expectedHeight = cint((scaledImageWidth * aspectHeight) / aspectWidth)
  ' Garantiza que la imágen quede más alta que ancha.
  if expectedHeight <= m.emissionImage.width then expectedHeight = m.emissionImage.width + 1
  ' Aplica el alto final manteniendo la proporción seleccionada.
  m.emissionImage.height = expectedHeight

  ' Aplica traslación final para que playImage quede justo en el centro de la imagen.
  centeredPlayX = cint((m.emissionImage.width - m.playImage.width) / 2)
  centeredPlayY = cint((m.emissionImage.height - m.playImage.height) / 2)
  m.playImage.translation = [centeredPlayX, centeredPlayY]

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
  infoWidth = m.top.widthContainer - m.emissionImage.width - cint(scaleValue(450, m.scaleInfo))
  ' Evita valores negativos en resoluciones pequeñas.
  if infoWidth < cint(scaleValue(100, m.scaleInfo)) then infoWidth = cint(scaleValue(100, m.scaleInfo))
  ' Aplica ancho del texto al título.
  m.episodeTitle.width = infoWidth
  ' Aplica ancho del texto a la sinopsis.
  m.episodeSynopsis.width = infoWidth
end sub