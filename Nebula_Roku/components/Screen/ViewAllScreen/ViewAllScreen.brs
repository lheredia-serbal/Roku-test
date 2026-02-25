' Inicializa referencias internas del componente ViewAllScreen.
sub init()
  ' Guardamos información de escala para posicionamiento responsive.
  m.scaleInfo = m.global.scaleInfo
  ' Referencia al timer que difiere el summary al mover foco.
  m.programTimer = m.top.findNode("programTimer")
  ' Referencia al componente visual de Program Summary. 
  m.programInfo = m.top.findNode("programInfo") 
  ' Referencia al gradiente superior como en MainScreen.
  m.infoGradient = m.top.findNode("infoGradient") 
  ' Referencia al poster de fondo dinámico.
  m.programImageBackground = m.top.findNode("programImageBackground") 
  ' Referencia al contenedor donde vive el carrusel de ViewAll.
  m.carouselContainer = m.top.findNode("carouselContainer")
  ' Referencia al indicador de selección del carrusel.
  m.selectedIndicator = m.top.findNode("selectedIndicator")
end sub

' Procesa el payload enviado desde MainScreen para cargar el carrusel completo.
sub onDataChange()
  __configMain()
  if m.top.data = invalid or m.top.data = "" then return
  payload = ParseJson(m.top.data)
  if payload = invalid then return
  m.viewAllPayload = payload
   ' Aplicamos layout visual
  __applyLayout()
  ' Disparamos el consumo del servicio de ViewAll.
  __getViewAllCarousel() 
end sub

' Maneja la lógica de foco para la pantalla.
sub initFocus()
  ' Delegamos foco al contenedor del carrusel inferior.
  if m.top.onFocus and m.carouselContainer <> invalid then m.carouselContainer.setFocus(true) 
end sub

' Carga la configuracion inicial de la ViewAll.
sub __configMain()
  m.programInfo.width = (m.scaleInfo.width - scaleValue(300, m.scaleInfo))
  m.programInfo.initConfig = true
end sub

' Configura posiciones y tamaños principales igual que MainScreen.
sub __applyLayout()
  if m.scaleInfo = invalid then return
  safeX = m.scaleInfo.safeZone.x 
  safeY = m.scaleInfo.safeZone.y 
  width = m.scaleInfo.width
  height = m.scaleInfo.height
  m.infoGradient.width = width
  m.infoGradient.height = height
  m.programImageBackground.width = width
  m.programImageBackground.height = height
  m.programInfo.translation = [safeX + scaleValue(0, m.scaleInfo), safeY + scaleValue(20, m.scaleInfo)]
  m.carouselContainer.translation = [safeX + scaleValue(0, m.scaleInfo), safeY + scaleValue(20, m.scaleInfo)]
  m.selectedIndicator.translation = [scaleValue(124, m.scaleInfo), safeY + scaleValue(148, m.scaleInfo)]
end sub

' Solicita el detalle del carrusel seleccionado en la vista "Ver todos".
sub __getViewAllCarousel()
  if m.viewAllPayload = invalid then return
  if m.viewAllPayload.menuSelectedItemId = invalid or m.viewAllPayload.carouselId = invalid then return
  ' Obtenemos API base si aún no está cacheada.
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL) 
  ' Abortamos si no hay URL de API disponible.
  if m.apiUrl = invalid then return 
  ' Mostramos loading durante la llamada.
  if m.top.loading <> invalid and not m.top.loading.visible then m.top.loading.visible = true 
  ' Creamos id único para registrar acción pendiente.
  requestId = createRequestId() 
  action = {
    apiRequestManager: m.apiRequestManager
    url: urlViewAllCarousels(m.apiUrl, m.viewAllPayload.menuSelectedItemId, m.viewAllPayload.carouselId)
    method: "GET"
    responseMethod: "onViewAllCarouselResponse"
    body: invalid
    token: invalid
    publicApi: false
    requestId: requestId
    dataAux: FormatJson(m.viewAllPayload)
    run: function() as Object
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
      return { success: true, error: invalid }
    end function
  }
  ' Registramos y ejecutamos acción con mecanismo de retry.
  runAction(requestId, action, ApiType().CLIENTS_API_URL) 
  m.apiRequestManager = action.apiRequestManager
end sub

' Procesa la respuesta del servicio de ViewAll.
sub onViewAllCarouselResponse()
  if m.apiRequestManager = invalid then
    ' Re-disparamos la obtención del carrusel.
    __getViewAllCarousel() 
    return
  end if
  ' Evaluamos si la respuesta HTTP es correcta.
  if validateStatusCode(m.apiRequestManager.statusCode) then 
    ' Quitamos la acción del pool pendiente.
    removePendingAction(m.apiRequestManager.requestId) 
    resp = ParseJson(m.apiRequestManager.response)
    ' Validamos que existan items para pintar.
    if resp <> invalid and resp.data <> invalid and resp.data.items <> invalid and resp.data.items.count() > 0 then 
      m.carousel = resp.data
      ' Renderizamos carrusel con datos de ViewAll.
      __populateViewAllCarousel(resp.data) 
    else
      ' Limpiamos UI cuando la API no trae items.
      __clearViewAllCarousel() 
    end if
  else
    error = m.apiRequestManager.errorResponse
    statusCode = m.apiRequestManager.statusCode
    if m.apiRequestManager.serverError then
      changeStatusAction(m.apiRequestManager.requestId, "error")
      retryAll()
    else
      ' Limpiamos acción pendiente no reintentable.
      removePendingAction(m.apiRequestManager.requestId) 
      printError("ViewAllCarousel:", error)
      ' Validamos si el error requiere forzar logout.
      if validateLogout(statusCode, m.top) then 
        m.apiRequestManager = clearApiRequest(m.apiRequestManager)
        if m.top.loading <> invalid then m.top.loading.visible = false
        return
      end if
    end if
  end if
  m.apiRequestManager = clearApiRequest(m.apiRequestManager)
  if m.top.loading <> invalid then m.top.loading.visible = false
end sub

' Crea y configura el listado de carruseles inferior usando un flujo equivalente a populateCarousels de MainScreen.
sub __populateViewAllCarousel(data as Object)
  if m.carouselContainer = invalid then return
  yPosition = 0
  previousCarousel = invalid
  ' Limpiamos carruseles previos antes de repintar contenido.
  __clearViewAllCarousel() 
  sourceItems = []
  ' Usamos directamente data.items cuando ya es una lista de carruseles.
  if data <> invalid and data.items <> invalid and data.items.count() > 0 and data.items[0].style <> invalid then sourceItems = data.items 
  if sourceItems.count() = 0 and data <> invalid and data.items <> invalid and data.items.count() > 0 then sourceItems = [data]
  ' Recorremos cada carrusel para crearlo igual que MainScreen.
  for each carouselData in sourceItems 
    ' Calculamos cuántos ítems entran en pantalla sin scroll horizontal.
    itemsPerRow = __getMaxItemsPerRow(carouselData.style) 
    rowIndex = 0 ' Inicializamos índice de fila para distribuir items de izquierda a derecha y luego hacia abajo.
    startIndex = 0 ' Inicializamos cursor para particionar items del carrusel en filas.
    while carouselData.items <> invalid and startIndex < carouselData.items.count() ' Particionamos items del carrusel para evitar scroll lateral.
      rowItems = [] ' Armamos subconjunto de items para la fila actual.
      endExclusive = startIndex + itemsPerRow ' Definimos límite superior de la fila actual.
      if endExclusive > carouselData.items.count() then endExclusive = carouselData.items.count() ' Ajustamos límite al total disponible.
      for i = startIndex to endExclusive - 1 ' Copiamos items de esta fila.
        rowItems.push(carouselData.items[i])
      end for

      newCarousel = m.carouselContainer.createChild("Carousel") ' Creamos una instancia del componente Carousel.
      carouselRowId = 0 ' Inicializamos id base para evitar colisiones entre filas generadas.
      if carouselData.id <> invalid then carouselRowId = carouselData.id * 1000 ' Reservamos bloque de ids por carrusel para cada fila.
      newCarousel.id = carouselRowId + rowIndex ' Asignamos id único por fila derivado del carrusel original.
      newCarousel.contentType = carouselData.contentType ' Asignamos tipo de contenido del carrusel.
      newCarousel.style = carouselData.style ' Asignamos estilo visual del carrusel.
      if rowIndex = 0 then newCarousel.title = carouselData.title else newCarousel.title = "" ' Mostramos título sólo en la primera fila.
      newCarousel.code = carouselData.code ' Asignamos código de negocio del carrusel.
      newCarousel.imageType = carouselData.imageType ' Asignamos tipo de imagen para summary.
      newCarousel.redirectType = carouselData.redirectType ' Asignamos redirectType del carrusel.
      newCarousel.items = rowItems ' Cargamos sólo items que caben en esta fila.
      newCarousel.translation = [0, yPosition] ' Posicionamos carrusel en eje Y acumulado.
      newCarousel.ObserveField("focused", "onFocusItem") ' Observamos foco para disparar Program Summary.
      if previousCarousel <> invalid then previousCarousel.focusDown = newCarousel ' Enlazamos foco hacia abajo desde carrusel anterior.
      if previousCarousel <> invalid then newCarousel.focusUp = previousCarousel ' Enlazamos foco hacia arriba hacia carrusel anterior.
      previousCarousel = newCarousel ' Actualizamos referencia para la próxima iteración.
      yPosition = yPosition + newCarousel.height + scaleValue(20, m.scaleInfo) ' Avanzamos separación vertical como en MainScreen.

      rowIndex = rowIndex + 1 ' Avanzamos a la siguiente fila visual.
      startIndex = endExclusive ' Continuamos con los siguientes items del carrusel.
    end while
  end for
  if m.carouselContainer.getChildCount() > 0 then ' Validamos que exista al menos un carrusel renderizado.
    firstCarousel = m.carouselContainer.getChild(0) ' Obtenemos primer carrusel para asignar foco inicial.
    firstList = firstCarousel.findNode("carouselList") ' Obtenemos lista interna del primer carrusel.
    m.selectedIndicator.size = firstCarousel.size ' Ajustamos indicador al tamaño del carrusel enfocado.
    m.selectedIndicator.visible = true ' Mostramos indicador porque hay contenido enfocable.
    if firstList <> invalid and m.top.onFocus then firstList.setFocus(true) ' Aplicamos foco inicial cuando pantalla está activa.
  else
    m.selectedIndicator.visible = false ' Ocultamos indicador cuando no hay carruseles válidos.
  end if
end sub

' Devuelve la cantidad máxima de ítems por fila según el estilo del carrusel.
function __getMaxItemsPerRow(style as integer) as integer
  if style = getCarouselStyles().PORTRAIT_FEATURED then return 6
  if style = getCarouselStyles().LANDSCAPE_STANDARD then return 5
  if style = getCarouselStyles().LANDSCAPE_FEATURED then return 4
  if style = getCarouselStyles().SQUARE_STANDARD then return 10
  if style = getCarouselStyles().SQUARE_FEATURED then return 3
  if style = -1 then return 12 
  return 8
end function

' Limpia el carrusel actual de ViewAll y resetea estado visual asociado.
sub __clearViewAllCarousel()
  if m.carouselContainer = invalid then return
  while m.carouselContainer.getChildCount() > 0 
    child = m.carouselContainer.getChild(0)
    child.unobserveField("focused")
    m.carouselContainer.removeChild(child)
  end while
  ' Ocultamos indicador al no existir carrusel renderizado.
  m.selectedIndicator.visible = false 
   ' Ocultamos summary al limpiar contenido.
  m.programInfo.visible = false
  ' Limpiamos imagen de fondo del programa previo.
  m.programImageBackground.uri = "" 
end sub

' Reacciona al foco de un item del carrusel y prepara solicitud de Program Summary.
sub onFocusItem()
  ' Validamos que el foco pertenezca al carrusel activo.
  if m.carouselContainer = invalid or not m.carouselContainer.isInFocusChain() then return 
  ' Validamos que exista carrusel enfocado.
  if m.carouselContainer.focusedChild = invalid then return 
  newFocus = ParseJson(m.carouselContainer.focusedChild.focused)
  if newFocus = invalid then return
  ' Evitamos llamadas duplicadas para el mismo item.
  if m.itemfocused = invalid or (newFocus.key <> m.itemfocused.key or newFocus.id <> m.itemfocused.id or newFocus.redirectKey <> m.itemfocused.redirectKey or newFocus.redirectId <> m.itemfocused.redirectId) then 
    ' Ocultamos summary mientras se carga el nuevo programa.
    m.programInfo.visible = false 
    ' Limpiamos fondo para evitar mostrar data vieja.
    m.programImageBackground.uri = "" 
    ' Guardamos item enfocado que se usará en la consulta.
    m.itemfocused = newFocus 
    m.carouselContainer.focusedChild.focused = invalid
    clearTimer(m.programTimer)
    m.programTimer.ObserveField("fire", "getProgramInfo")
    m.programTimer.control = "start"
  end if
end sub

' Solicita Program Summary del item enfocado, emulando el flujo de MainScreen.
sub getProgramInfo()
  clearTimer(m.programTimer) ' Frenamos el timer actual al entrar al handler.
  if m.itemfocused = invalid then return ' Salimos si no hay item válido para consultar.
  if m.program <> invalid and m.program.infoKey = m.itemfocused.redirectKey and m.program.infoId = m.itemfocused.redirectId then ' Reutilizamos cache si ya tenemos ese summary.
    m.programInfo.visible = true ' Mostramos summary sin golpear API nuevamente.
    return ' Cortamos porque no hace falta nueva consulta.
  end if
  if m.apiSummaryRequestManager <> invalid then ' Si hay request en curso, reprogramamos para evitar solapamiento.
    m.programTimer.ObserveField("fire", "getProgramInfo") ' Reasignamos callback para nuevo intento.
    m.programTimer.control = "start" ' Reintentamos al finalizar ventana corta.
    return ' Salimos esperando que termine request vigente.
  end if
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL) ' Recuperamos API URL si aún no existe en memoria.
  if m.apiUrl = invalid then return ' Cortamos si la app no tiene URL de API disponible.
  mainImageTypeId = getCarouselImagesTypes().NONE.toStr() ' Inicializamos tipo de imagen principal por defecto.
  if m.carouselContainer.focusedChild <> invalid and m.carouselContainer.focusedChild.imageType <> invalid and m.carouselContainer.focusedChild.imageType <> 0 then mainImageTypeId = m.carouselContainer.focusedChild.imageType.ToStr() ' Usamos imageType del carrusel cuando está presente.
  requestId = createRequestId() ' Generamos identificador de acción para retry tracking.
  action = { ' Armamos acción para solicitar Program Summary.
    apiSummaryRequestManager: m.apiSummaryRequestManager ' Referencia al manager de summary independiente.
    url: urlProgramSummary(m.apiUrl, m.itemfocused.redirectKey, m.itemfocused.redirectId, mainImageTypeId, getCarouselImagesTypes().SCENIC_LANDSCAPE) ' URL de summary con tipos de imagen requeridos.
    method: "GET" ' Método HTTP de la solicitud.
    responseMethod: "onProgramSummaryResponse" ' Callback de respuesta para update UI.
    body: invalid ' Sin body al ser GET.
    token: invalid ' Token gestionado por sesión activa.
    publicApi: false ' Endpoint autenticado de cliente.
    dataAux: invalid ' Sin data auxiliar en este request.
    requestId: requestId ' Adjuntamos id del request.
    run: function() as Object ' Ejecutamos request mediante helper común.
      m.apiSummaryRequestManager = sendApiRequest(m.apiSummaryRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux) ' Disparamos petición de summary.
      return { success: true, error: invalid } ' Confirmamos ejecución local.
    end function ' Cerramos función run.
  } ' Cerramos objeto action.
  runAction(requestId, action, ApiType().CLIENTS_API_URL) ' Ejecutamos acción con soporte de reintentos.
  m.apiSummaryRequestManager = action.apiSummaryRequestManager ' Guardamos manager actualizado.
end sub

' Procesa la respuesta de Program Summary para actualizar la franja superior.
sub onProgramSummaryResponse()
  if m.apiSummaryRequestManager = invalid then ' Si el manager se limpió, volvemos a intentar desde el foco actual.
    getProgramInfo() ' Reintentamos solicitar summary del item vigente.
    return ' Salimos tras programar el reintento.
  end if
  if validateStatusCode(m.apiSummaryRequestManager.statusCode) then ' Procesamos sólo respuestas HTTP exitosas.
    m.itemfocused = invalid ' Limpiamos cache de foco pendiente tras responder.
    resp = ParseJson(m.apiSummaryRequestManager.response) ' Parseamos respuesta JSON de summary.
    if resp <> invalid and resp.data <> invalid then ' Validamos disponibilidad de data útil.
      removePendingAction(m.apiSummaryRequestManager.requestId) ' Quitamos request exitoso del retry pool.
      m.apiSummaryRequestManager = clearApiRequest(m.apiSummaryRequestManager) ' Limpiamos manager de summary.
      m.program = resp.data ' Guardamos programa actual para reutilización.
      if m.program.backgroundImage <> invalid then ' Validamos si el programa trae imagen de fondo.
        m.programImageBackground.uri = getImageUrl(m.program.backgroundImage) ' Pintamos imagen de fondo superior.
      else
        m.programImageBackground.uri = "" ' Limpiamos fondo cuando no llega imagen.
      end if
      m.programInfo.program = FormatJson(m.program) ' Enviamos summary al componente ProgramSummary.
      if m.carouselContainer <> invalid and m.carouselContainer.focusedChild <> invalid then m.carouselContainer.focusedChild.updateNode = FormatJson(m.program) ' Actualizamos nodo enfocado con info enriquecida.
      m.programInfo.visible = true ' Mostramos bloque superior con la información del programa.
    else
      m.programInfo.visible = false ' Ocultamos summary si respuesta llega sin data.
      m.programImageBackground.uri = "" ' Limpiamos fondo para mantener consistencia visual.
      m.apiSummaryRequestManager = clearApiRequest(m.apiSummaryRequestManager) ' Limpiamos manager tras respuesta vacía.
    end if
  else
    statusCode = m.apiSummaryRequestManager.statusCode ' Capturamos código de error del summary.
    errorResponse = m.apiSummaryRequestManager.errorResponse ' Capturamos payload de error del summary.
    if m.apiSummaryRequestManager.serverError then ' Si es error de backend, activamos retry.
      changeStatusAction(m.apiSummaryRequestManager.requestId, "error") ' Marcamos acción para reintento.
      retryAll() ' Ejecutamos reintentos pendientes.
    else
      removePendingAction(m.apiSummaryRequestManager.requestId) ' Limpiamos pending action no reintentable.
      printError("ProgramSummary ViewAll:", errorResponse) ' Log de error funcional en summary.
      if validateLogout(statusCode, m.top) then return ' Delegamos si error obliga logout.
      m.programInfo.visible = false ' Ocultamos summary en error funcional.
      m.programImageBackground.uri = "" ' Limpiamos fondo en error funcional.
    end if
    m.apiSummaryRequestManager = clearApiRequest(m.apiSummaryRequestManager) ' Cerramos ciclo limpiando manager.
  end if
end sub