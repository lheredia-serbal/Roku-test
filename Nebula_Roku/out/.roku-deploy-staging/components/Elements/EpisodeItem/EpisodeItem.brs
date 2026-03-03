' Inicializa referencias del componente visual EpisodeItem.
sub init()
  ' Guarda contenedor horizontal principal.
  m.episodeContainer = m.top.findNode("episodeContainer")
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
  ' Fuerza ancho fijo solicitado para emissionImage.
  m.emissionImage.width = 300
  ' Usa relación de aspecto 16:9 como valor base si no hay tamaño real.
  expectedHeight = cint((300 * 9) / 16)
  ' Conserva alto existente si ya fue calculado por el Poster.
  if m.emissionImage.height > 0 then expectedHeight = m.emissionImage.height
  ' Aplica alto calculado manteniendo relación de aspecto.
  m.emissionImage.height = 800
  ' Centra playImage dentro de emissionImage.
  m.playImage.translation = [cint((m.emissionImage.width - m.playImage.width) / 2), cint((m.emissionImage.height - m.playImage.height) / 2)]
  ' Ubica bloque de tiempo en esquina inferior derecha de emissionImage.
  m.episodeTimeGroup.translation = [m.emissionImage.width - m.episodeTimeGroup.width, m.emissionImage.height - m.episodeTimeGroup.height]
  ' Ajusta ancho disponible para columna de texto.
  infoWidth = m.top.widthContainer - m.emissionImage.width - 24
  ' Evita valores negativos en resoluciones pequeñas.
  if infoWidth < 100 then infoWidth = 100
  ' Aplica ancho calculado a episodeInfo.
  m.episodeInfo.width = infoWidth
  ' Aplica ancho del texto al título.
  m.episodeTitle.width = infoWidth
  ' Aplica ancho del texto a la sinopsis.
  m.episodeSynopsis.width = infoWidth
end sub