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
  ' Ajusta layout inicial del item.
  __updateLayout()
end sub

' Recalcula layout cuando cambia el ancho disponible.
sub onLayoutChanged()
  ' Reaplica tamaños y posiciones dependientes del ancho.
  __updateLayout()
end sub

' Actualiza contenido visible cuando llega itemData.
sub onItemDataChanged()
  ' Evita actualizar si no hay datos válidos.
  if m.top.itemData = invalid then return
  ' Setea título desde el payload o mantiene fallback.
  if m.top.itemData.episodeTitle <> invalid then m.episodeTitle.text = m.top.itemData.episodeTitle
  ' Setea sinopsis desde el payload o mantiene fallback.
  if m.top.itemData.episodeSynopsis <> invalid then m.episodeSynopsis.text = m.top.itemData.episodeSynopsis
  ' Setea duración desde el payload o mantiene fallback.
  if m.top.itemData.episodeTime <> invalid then m.episodeTime.text = m.top.itemData.episodeTime
  ' Setea imagen principal desde el payload cuando exista URL.
  if m.top.itemData.emissionImage <> invalid and m.top.itemData.emissionImage <> "" then m.emissionImage.uri = m.top.itemData.emissionImage
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
  m.emissionImage.height = expectedHeight
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