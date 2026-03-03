' Inicialización del componente Emissions.
sub init()
  ' Guarda última key recibida para reintento de request.
  m.lastKey = invalid
  ' Guarda último id recibido para reintento de request.
  m.lastId = invalid
    ' Inicializa manager de requests para evitar referencias inválidas.
  m.apiRequestManager = invalid
  ' Referencia al título principal de la pantalla.
  m.emissionsTitle = m.top.findNode("emissionsTitle")
  ' Guarda referencia de la lista visual de episodios.
  m.episodesList = m.top.findNode("episodesList")
  ' Guarda referencia del indicador de selección fijo.
  m.selectedIndicator = m.top.findNode("selectedIndicator")
  ' Índice lógico del episodio actualmente enfocado por la selección.
  m.selectedEpisodeIndex = 0
  ' Cantidad de episodios renderizados para navegación vertical.
  m.episodesCount = 0
  ' Obtiene scaleInfo global para escalar medidas y posiciones del layout.
  m.scaleInfo = m.global.scaleInfo
  ' Intenta resolver loading desde la escena cuando no viene inyectado.
  if m.top <> invalid and m.top.loading = invalid then
    scene = m.top.getScene()
    if scene <> invalid then m.top.loading = scene.findNode("Loading")
  end if

    ' Inicializa ancho de pantalla con fallback a resolución base.
  m.screenWidth = 1280
  ' Marca si scaleInfo global pudo proveer un ancho válido.
  hasScaleWidth = false
  ' Prioriza ancho calculado por scaleInfo global cuando está disponible.
  if m.global <> invalid and m.global.scaleInfo <> invalid and m.global.scaleInfo.width <> invalid then
    ' Guarda ancho de pantalla reportado por scaleInfo global.
    m.screenWidth = m.global.scaleInfo.width
    ' Indica que ya existe ancho válido proveniente de scaleInfo.
    hasScaleWidth = true
  end if
  ' Usa ancho real de display cuando no existe scaleInfo global.
  if not hasScaleWidth then m.screenWidth = CreateObject("roDeviceInfo").GetDisplaySize().w
  ' Crea scaleInfo de fallback cuando aún no está disponible en globals.
  if m.scaleInfo = invalid then m.scaleInfo = getScaleInfo(CreateObject("roDeviceInfo"))
  ' Aplica tamaños y posiciones escaladas para todos los nodos de emisiones.
  __applyScaledLayout()
end sub

' Aplica medidas escaladas a width y height de los nodos visuales.
sub __applyScaledLayout()
  ' Evita aplicar layout cuando no existe información de escala.
  if m.scaleInfo = invalid then return
  ' Escala ancho del título para respetar resolución del dispositivo.
  ' Escala posición y tamaño de la lista de episodios.

  if m.emissionsTitle <> invalid then
    m.emissionsTitle.translation = scaleSize([80, 40], m.scaleInfo)
  end if

  if m.episodesList <> invalid then
    m.episodesList.translation = scaleSize([80, 100], m.scaleInfo)
    m.episodesList.width = scaleValue(1600, m.scaleInfo)
    m.episodesList.height = scaleValue(860, m.scaleInfo)
  end if

  if m.selectedIndicator <> invalid then
    m.selectedIndicator.translation = scaleSize([80, 100], m.scaleInfo)
    m.selectedIndicator.size = [scaleValue(1100, m.scaleInfo), scaleValue(237, m.scaleInfo)]
  end if
end sub


' Maneja foco de pantalla al mostrarse.
sub initFocus()
  ' No requiere comportamiento adicional al tomar foco.
end sub

' Procesa payload de entrada y dispara servicio de episodios.
sub initData()
  ' Evita ejecución cuando no hay payload.
  if m.top.data = invalid or m.top.data = "" then return
  ' Resuelve apiUrl reutilizando la misma lógica del resto de pantallas.
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL)
  ' Limpia episodios anteriores antes de una nueva carga.
  __clearEpisodes()
  ' Parsea payload enviado desde ProgramDetail.
  payload = ParseJson(m.top.data)
  ' Evita request si payload es inválido.
  if payload = invalid then return
  ' Valida key requerida para endpoint de episodios.
  if payload.key = invalid then return
  ' Valida id requerido para endpoint de episodios.
  if payload.id = invalid then return
  ' Ejecuta request de episodios con key e id recibidos.
  __getEpisodes(payload.key, payload.id)
end sub

' Captura eventos de teclado para volver a la pantalla anterior.
function onKeyEvent(key as string, press as boolean) as boolean
  ' Ignora eventos de liberación de tecla.
  if not press then return false

  ' Intercepta BACK para retornar a ProgramDetail.
  if key = KeyButtons().BACK then
    ' Notifica salida hacia MainScene.
    m.top.onBack = true
    ' Marca evento como manejado.
    return true
  end if

  ' Navega episodio anterior manteniendo fijo el SelectionBox.
  if key = KeyButtons().UP then
    return __moveSelection(-1)
  end if

  ' Navega episodio siguiente manteniendo fijo el SelectionBox.
  if key = KeyButtons().DOWN then
    return __moveSelection(1)
  end if

  ' Deja pasar otros eventos al padre.
  return false
end function

' Ejecuta request al servicio urlEpisodes reutilizando runAction.
sub __getEpisodes(key, id)
  ' Guarda parámetros para posibles reintentos.
  m.lastKey = key
  ' Guarda id para posibles reintentos.
  m.lastId = id
  ' Activa loading compartido mientras se consulta API.
  if m.top.loading <> invalid then m.top.loading.visible = true
  ' Crea identificador de acción para retry manager.
  requestId = createRequestId()

  ' Define request siguiendo el patrón existente del proyecto.
  action = {
    apiRequestManager: m.apiRequestManager
    url: urlEpisodes(m.apiUrl, m.lastKey, m.lastId)
    method: "GET"
    responseMethod: "onEpisodesResponse"
    body: invalid
    token: invalid
    publicApi: false
    requestId: requestId
    dataAux: invalid
    run: function() as Object
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
      return { success: true, error: invalid }
    end function
  }

  ' Ejecuta request con soporte de retry global.
  runAction(requestId, action, ApiType().CLIENTS_API_URL)
  ' Actualiza referencia local del request manager.
  m.apiRequestManager = action.apiRequestManager
end sub

' Procesa respuesta del servicio de episodios.
sub onEpisodesResponse()
  ' Reintenta automáticamente si el manager quedó inválido.
  if m.apiRequestManager = invalid then
    ' Reintenta usando últimos parámetros válidos.
    __getEpisodes(m.lastKey, m.lastId)
    ' Corta ejecución actual.
    return
  end if

  ' Flujo exitoso HTTP.
  if validateStatusCode(m.apiRequestManager.statusCode) then
    ' Convierte respuesta a objeto para renderizar episodios.
    response = ParseJson(m.apiRequestManager.response)
    ' Obtiene arreglo de episodios desde el nodo data.
    episodes = invalid
    ' Prioriza lista dentro de data cuando exista.
    if response <> invalid and response.data <> invalid then episodes = response.data
    ' Soporta respuesta como arreglo directo si aplica.
    if episodes = invalid and type(response) = "roArray" then episodes = response
    ' Renderiza N EpisodeItem según cantidad recibida por servicio.
    __renderEpisodes(episodes.episodes)
    ' Remueve acción pendiente al completar correctamente.
    removePendingAction(m.apiRequestManager.requestId)
    ' Parsea respuesta para mostrar título en pantalla.
    response = ParseJson(m.apiRequestManager.response)
    if m.emissionsTitle <> invalid then
      if response <> invalid and response.data <> invalid and response.data.title <> invalid then
        m.emissionsTitle.text = response.data.title
      else
        m.emissionsTitle.text = ""
      end if
    end if
    ' Limpia request manager al finalizar.
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
  else
    ' Obtiene status para decisiones de error.
    statusCode = m.apiRequestManager.statusCode
    ' Obtiene payload de error para logging.
    errorResponse = m.apiRequestManager.errorResponse
    ' Maneja errores de servidor con estrategia global.
    if m.apiRequestManager.serverError then
      setCdnErrorCodeFromStatus(statusCode, ApiType().CLIENTS_API_URL)
      changeStatusAction(m.apiRequestManager.requestId, "error")
      retryAll()
    else
      ' Remueve acción pendiente no reintentable.
      removePendingAction(m.apiRequestManager.requestId)
      ' Loguea error para soporte.
      printError("Episodes:", errorResponse)
      ' Valida si corresponde logout por sesión expirada.
      if validateLogout(statusCode, m.top) then return
    end if
    ' Limpia request manager luego de manejar error.
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
  end if

  ' Oculta loading al finalizar cualquier resultado.
  if m.top.loading <> invalid then m.top.loading.visible = false
end sub


' Crea visualmente los EpisodeItem según la respuesta del servicio.
sub __renderEpisodes(episodes)
  ' Evita render si el contenedor aún no existe.
  if m.episodesList = invalid then return
  ' Limpia elementos previos antes de pintar nuevos episodios.
  __clearEpisodes()
  ' Corta render cuando la respuesta no contiene lista.
  if episodes = invalid then return
  ' Recorre episodios para crear un EpisodeItem por cada uno.
  for each item in episodes
    ' Crea un nuevo componente reusable EpisodeItem.
    newEpisodeItem = m.episodesList.createChild("EpisodeItem")
    ' Asigna ancho al 100% de la pantalla.
    newEpisodeItem.widthContainer = scaleValue(m.screenWidth - 400, m.scaleInfo)
    ' Pasa el objeto image para que EpisodeItem use getImageUrl internamente.
    if item <> invalid and item.image <> invalid then newEpisodeItem.image = item.image
    ' Pasa synopsis para setearla en episodeSynopsis dentro de EpisodeItem.
    if item <> invalid and item.synopsis <> invalid then newEpisodeItem.synopsis = item.synopsis
    ' Pasa formattedDuration para setearla en episodeTime dentro de EpisodeItem.
    if item <> invalid and item.formattedDuration <> invalid then newEpisodeItem.formattedDuration = item.formattedDuration
    ' Pasa play normalizado para mostrar u ocultar playImage según reglas de negocio.
    newEpisodeItem.play = __resolveEpisodePlay(item)
    ' Pasa título compuesto con fecha, hora y nombre de canal.
    newEpisodeItem.title = __buildEpisodeTitle(item)
  end for

  ' Reinicia índice al primer elemento y ajusta la lista al SelectionBox fijo.
  __updateSelection(0)
end sub

' Construye datos de EpisodeItem con fallback temporal.
function __buildEpisodeItemData(item as dynamic) as object
  ' Inicia estructura con textos de ejemplo requeridos.
  data = {
    episodeTitle: ""
    episodeSynopsis: ""
    episodeTime: ""
    emissionImage: ""
  }
  ' Evita leer campos cuando el item del servicio es inválido.
  if item = invalid then return data
  ' Sobrescribe título cuando el servicio lo envía.
  if item.title <> invalid and item.title <> "" then data.episodeTitle = item.title
  ' Sobrescribe sinopsis cuando el servicio la envía.
  if item.synopsis <> invalid and item.synopsis <> "" then data.episodeSynopsis = item.synopsis
  ' Sobrescribe duración cuando el servicio la envía.
  if item.duration <> invalid and item.duration <> "" then data.episodeTime = item.duration
  ' Sobrescribe imagen principal cuando el servicio la envía.
  if item.image <> invalid and item.image <> "" then data.emissionImage = item.image
  ' Retorna payload final para EpisodeItem.
  return data
end function

' Normaliza el flag play tomando en cuenta actions inválido y casos faltantes.
function __resolveEpisodePlay(item as dynamic) as boolean
  ' Devuelve false por defecto en cualquier caso no válido.
  result = false
  ' Corta cuando el episodio es inválido.
  if item = invalid then return result
  ' Corta cuando actions no existe en el episodio.
  if item.actions = invalid then return result
  ' Corta cuando play no existe en actions.
  if item.actions.play = invalid then return result
  ' Activa play solo cuando el valor sea boolean true.
  if type(item.actions.play) = "roBoolean" and item.actions.play then result = true
  ' Devuelve flag final para EpisodeItem.
  return result
end function

' Construye título con formato "longDate shortTime (channelName)".
function __buildEpisodeTitle(item as dynamic) as string
  ' Devuelve string vacío cuando no hay episodio válido.
  if item = invalid then return ""

  startTime = CreateObject("roDateTime")

  startTime.FromISO8601String(item.startTime)
  startTime.ToLocalTime()
  ' Devuelve string vacío cuando no se pudo convertir startTime.
  if startTime = invalid then return ""
  ' Obtiene meses traducidos desde i18n para componer longDate.
  months = i18n_months(m.global.i18n)
  ' Formatea fecha larga equivalente al pipe pqvLocalDate: 'longDate'.
  longDate = dateConverter(startTime, "dd to MMMM yyyy hh:mm", months)
  ' Formatea hora corta equivalente al pipe pqvLocalDate: 'shortTime'.
  channelName = ""
  ' Lee channel.name cuando el nodo channel existe.
  if item.channel <> invalid and item.channel.name <> invalid then channelName = item.channel.name
  ' Compone título final con el formato solicitado por negocio.
  return longDate + " (" + channelName + ")"
end function

' Limpia todos los EpisodeItem creados dinámicamente.
sub __clearEpisodes()
  ' Evita operar si la lista no está inicializada.
  if m.episodesList = invalid then return
  ' Elimina cada hijo existente del contenedor.
  m.episodesCount = 0
  ' Reinicia el contador total para evitar navegación con datos obsoletos.
  m.selectedEpisodeIndex = 0
  ' Reinicia la selección al primer elemento para la próxima carga.
  m.episodesList.translation = scaleSize([80, 100], m.scaleInfo)
  ' Devuelve la lista a su posición base cuando se limpia la pantalla.

  while m.episodesList.getChildCount() > 0
    ' Remueve el primer hijo hasta vaciar la lista.
    m.episodesList.removeChild(m.episodesList.getChild(0))
  end while

  ' Oculta el SelectionBox cuando no quedan episodios visibles.
  if m.selectedIndicator <> invalid then m.selectedIndicator.visible = false
end sub

' Mueve la selección vertical y desplaza los EpisodeItem para mantener fijo el indicador.
function __moveSelection(direction as integer) as boolean
  ' Evita navegación cuando no existen episodios en pantalla.
  if m.episodesList = invalid or m.episodesCount <= 0 then return false

  ' Calcula el nuevo índice a partir de la dirección recibida por teclado.
  newIndex = m.selectedEpisodeIndex + direction
  ' Consume la tecla aunque el índice quede fuera de rango para frenar bubbling.
  if newIndex < 0 or newIndex > m.episodesCount - 1 then return true

  ' Aplica la selección válida y desplaza visualmente los ítems.
  __updateSelection(newIndex)
  ' Informa que UP/DOWN fue gestionado por EmissionsScreen.
  return true
end function

' Aplica índice seleccionado y reposiciona la lista para dejar fijo el SelectionBox.
sub __updateSelection(newIndex as integer)
  ' Corta actualización cuando no existe la lista visual.
  if m.episodesList = invalid then return

  ' Refresca la cantidad de episodios a partir del árbol renderizado actual.
  m.episodesCount = m.episodesList.getChildCount()
  ' Si no hay episodios, oculta indicador y termina sin mover lista.
  if m.episodesCount <= 0 then
    ' Garantiza que el marco no quede visible cuando la lista está vacía.
    if m.selectedIndicator <> invalid then m.selectedIndicator.visible = false
    ' Sale temprano para evitar cálculos de desplazamiento sin contenido.
    return
  end if

  ' Clampa el índice inferior para impedir valores negativos.
  if newIndex < 0 then newIndex = 0
  ' Clampa el índice superior para no sobrepasar el último elemento.
  if newIndex > m.episodesCount - 1 then newIndex = m.episodesCount - 1

  ' Persiste el índice seleccionado que usará la navegación posterior.
  m.selectedEpisodeIndex = newIndex

  ' Calcula la posición base (reposo) de la lista en la pantalla.
  baseTranslation = scaleSize([80, 100], m.scaleInfo)
  ' Obtiene el paso vertical real para desplazar exactamente un item.
  stepY = __getEpisodeStepY()

  ' Mueve la lista verticalmente mientras el SelectionBox permanece fijo.
  m.episodesList.translation = [baseTranslation[0], baseTranslation[1] - (m.selectedEpisodeIndex * stepY)]

  ' Muestra el marco de selección al existir un episodio activo.
  if m.selectedIndicator <> invalid then m.selectedIndicator.visible = true
end sub



' Calcula el desplazamiento vertical por item (alto del episodio + spacing del LayoutGroup).
function __getEpisodeStepY() as integer
  ' Define fallback con valores de diseño base escalados.
  ' Usa un fallback escalado para no depender de medidas aún no calculadas.
  stepY = scaleValue(324, m.scaleInfo)
  ' Retorna fallback cuando no hay lista o no existen hijos renderizados.
  if m.episodesList = invalid or m.episodesList.getChildCount() <= 0 then return stepY

  ' Toma el primer EpisodeItem como referencia de alto de fila.
  firstEpisode = m.episodesList.getChild(0)
  ' Solo calcula bounds si el primer item existe físicamente.
  if firstEpisode <> invalid then
    ' Lee boundingRect para usar altura real ya layout-eada por SceneGraph.
    bounds = firstEpisode.boundingRect()
    ' Usa altura real cuando viene informada y es mayor que cero.
    if bounds <> invalid and bounds.height <> invalid and cint(bounds.height) > 0 then
      ' Inicializa paso con la altura visual del EpisodeItem.
      stepY = cint(bounds.height)
      ' Suma spacing vertical configurado en el LayoutGroup de episodios.
      if m.episodesList.itemSpacings <> invalid and m.episodesList.itemSpacings.count() > 0 then
        ' Agrega separación entre filas para alinear salto con navegación real.
        stepY = stepY + cint(m.episodesList.itemSpacings[0])
      end if
    end if
  end if

  ' Entrega el desplazamiento final que usará __updateSelection.
  return stepY
end function

' Limpia estado cuando ocurre logout.
sub onLogoutChange()
  ' Resetea payload y flags básicos del componente.
  if m.top.logout then
    ' Limpia episodios renderizados durante logout.
    __clearEpisodes()
    ' Limpia payload de entrada.
    m.top.data = invalid
    ' Limpia bandera de salida por back.
    m.top.onBack = false
    ' Limpia última key cacheada.
    m.lastKey = invalid
    ' Limpia último id cacheado.
    m.lastId = invalid
    if m.emissionsTitle <> invalid then m.emissionsTitle.text = ""

    ' Limpia el título cuando se resetea la pantalla por logout.
    if m.emissionsTitle <> invalid then m.emissionsTitle.text = ""
    ' Oculta el marco para evitar residuos visuales al salir de sesión.
    if m.selectedIndicator <> invalid then m.selectedIndicator.visible = false
  end if
end sub
