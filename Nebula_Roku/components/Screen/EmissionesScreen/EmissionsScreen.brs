' Inicialización del componente Emissions.
sub init()
  ' Guarda última key recibida para reintento de request.
  m.lastKey = invalid
  ' Guarda último id recibido para reintento de request.
  m.lastId = invalid
  ' Guarda referencia de la lista visual de episodios.
  m.episodesList = m.top.findNode("episodesList")
  ' Guarda ancho de pantalla para items al 100%.
  m.screenWidth = 1280
  ' Intenta usar ancho real de escena cuando esté disponible.
  scene = m.top.getScene()
  ' Actualiza ancho si la escena ya tiene medida válida.
  if scene <> invalid and scene.width > 0 then m.screenWidth = scene.width
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
  ' Intercepta BACK para retornar a ProgramDetail.
  if press and key = KeyButtons().BACK then
    ' Notifica salida hacia MainScene.
    m.top.onBack = true
    ' Marca evento como manejado.
    return true
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
    __renderEpisodes(episodes)
    ' Remueve acción pendiente al completar correctamente.
    removePendingAction(m.apiRequestManager.requestId)
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
    newEpisodeItem.widthContainer = m.screenWidth
    ' Arma payload básico con fallback de textos de ejemplo.
    newEpisodeItem.itemData = __buildEpisodeItemData(item)
  end for
end sub

' Construye datos de EpisodeItem con fallback temporal.
function __buildEpisodeItemData(item as dynamic) as object
  ' Inicia estructura con textos de ejemplo requeridos.
  data = {
    episodeTitle: "3 de marzo de 2026 7:44 (HBO)"
    episodeSynopsis: "T13 E2 - El espacio de humor de John Oliver, durante treinta minutos, le da una satírica mirada a los informes, política y diferentes acontecimientos de la actualidad. Contiene varios segmentos cortos y un ciclo principal, y los sketches breves casi siempre tienen relación con sucesos recientes. El bloque principal se centra en los detalles de una información de política, aún cuando no es de la semana. Éste periodista inyecta una dosis de gracia constante a su presentación, utilizando analogías sarcásticas y alusiones a la cultura popular y a las celebridades."
    episodeTime: "40m"
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

' Limpia todos los EpisodeItem creados dinámicamente.
sub __clearEpisodes()
  ' Evita operar si la lista no está inicializada.
  if m.episodesList = invalid then return
  ' Elimina cada hijo existente del contenedor.
  while m.episodesList.getChildCount() > 0
    ' Remueve el primer hijo hasta vaciar la lista.
    m.episodesList.removeChild(m.episodesList.getChild(0))
  end while
end sub

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
  end if
end sub
