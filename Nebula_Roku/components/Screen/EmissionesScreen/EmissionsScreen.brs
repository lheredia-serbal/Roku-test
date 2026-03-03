' Inicialización del componente Emissions.
sub init()
  ' Guarda última key recibida para reintento de request.
  m.lastKey = invalid
  ' Guarda último id recibido para reintento de request.
  m.lastId = invalid
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

' Limpia estado cuando ocurre logout.
sub onLogoutChange()
  ' Resetea payload y flags básicos del componente.
  if m.top.logout then
    m.top.data = invalid
    m.top.onBack = false
    m.lastKey = invalid
    m.lastId = invalid
  end if
end sub
