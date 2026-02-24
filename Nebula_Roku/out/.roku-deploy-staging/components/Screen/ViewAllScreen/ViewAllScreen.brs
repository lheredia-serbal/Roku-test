' Inicializa referencias internas del componente ViewAllScreen.
sub init()
  m.scaleInfo = m.global.scaleInfo ' Guardamos información de escala para posicionamiento responsive.
  m.programTimer = m.top.findNode("programTimer") ' Referencia al timer que difiere el summary al mover foco.
  m.programInfo = m.top.findNode("programInfo") ' Referencia al componente visual de Program Summary.
  m.infoGradient = m.top.findNode("infoGradient") ' Referencia al gradiente superior como en MainScreen.
  m.programImageBackground = m.top.findNode("programImageBackground") ' Referencia al poster de fondo dinámico.
  m.carouselContainer = m.top.findNode("carouselContainer") ' Referencia al contenedor donde vive el carrusel de ViewAll.
  m.selectedIndicator = m.top.findNode("selectedIndicator") ' Referencia al indicador de selección del carrusel.
  onTitleChange() ' Aplicamos el valor inicial del field title.
end sub

' Actualiza el label lógico cuando cambia el field title.
sub onTitleChange()
  if m.top.title = invalid or m.top.title = "" then m.top.title = "Ver todo" ' Garantizamos un fallback para el título de pantalla.
end sub

' Procesa el payload enviado desde MainScreen para cargar el carrusel completo.
sub onDataChange()
  if m.top.data = invalid or m.top.data = "" then return ' Evitamos procesar payload vacío.
  payload = ParseJson(m.top.data) ' Parseamos el contexto serializado enviado por MainScreen.
  if payload = invalid then return ' Cortamos si el payload no es JSON válido.
  m.viewAllPayload = payload ' Persistimos el payload para reintentos y consumo del servicio.
  if payload.title <> invalid and payload.title <> "" then m.top.title = payload.title ' Usamos el título del carrusel de origen.
  __applyLayout() ' Aplicamos layout visual estilo MainScreen en esta pantalla.
  __getViewAllCarousel() ' Disparamos el consumo del servicio de ViewAll.
end sub

' Maneja la lógica de foco para la pantalla.
sub initFocus()
  if m.top.onFocus and m.carouselContainer <> invalid then m.carouselContainer.setFocus(true) ' Delegamos foco al contenedor del carrusel inferior.
end sub

' Configura posiciones y tamaños principales igual que MainScreen.
sub __applyLayout()
  if m.scaleInfo = invalid then return ' Evitamos operar sin datos de resolución.
  safeX = m.scaleInfo.safeZone.x ' Capturamos safe zone horizontal.
  safeY = m.scaleInfo.safeZone.y ' Capturamos safe zone vertical.
  width = m.scaleInfo.width ' Capturamos ancho de pantalla.
  height = m.scaleInfo.height ' Capturamos alto de pantalla.
  m.infoGradient.width = width ' Ajustamos gradiente al ancho total.
  m.infoGradient.height = height ' Ajustamos gradiente al alto total.
  m.programImageBackground.width = width ' Ajustamos fondo al ancho total.
  m.programImageBackground.height = height ' Ajustamos fondo al alto total.
  m.programInfo.translation = [safeX + scaleValue(60, m.scaleInfo), safeY + scaleValue(20, m.scaleInfo)] ' Posicionamos summary superior como en Home.
  m.carouselContainer.translation = [scaleValue(55, m.scaleInfo), safeY + scaleValue(20, m.scaleInfo)] ' Posicionamos carrusel debajo del summary.
  m.selectedIndicator.translation = [scaleValue(124, m.scaleInfo), safeY + scaleValue(148, m.scaleInfo)] ' Ajustamos indicador de foco para items del carrusel.
end sub

' Solicita el detalle del carrusel seleccionado en la vista "Ver todos".
sub __getViewAllCarousel()
  if m.viewAllPayload = invalid then return ' Validamos que exista contexto para solicitar datos.
  if m.viewAllPayload.menuSelectedItemId = invalid or m.viewAllPayload.carouselId = invalid then return ' Validamos ids requeridos por endpoint.
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL) ' Obtenemos API base si aún no está cacheada.
  if m.apiUrl = invalid then return ' Abortamos si no hay URL de API disponible.
  if m.top.loading <> invalid and not m.top.loading.visible then m.top.loading.visible = true ' Mostramos loading durante la llamada.
  requestId = createRequestId() ' Creamos id único para registrar acción pendiente.
  action = { ' Construimos objeto de acción estándar usado por runAction.
    apiRequestManager: m.apiRequestManager ' Pasamos referencia del request manager principal.
    url: urlViewAllCarousels(m.apiUrl, m.viewAllPayload.menuSelectedItemId, m.viewAllPayload.carouselId) ' Armamos URL de carrusel ViewAll.
    method: "GET" ' Definimos método HTTP de consulta.
    responseMethod: "onViewAllCarouselResponse" ' Definimos callback de respuesta.
    body: invalid ' Sin body para GET.
    token: invalid ' Token no explícito porque usa sesión actual.
    publicApi: false ' Consumimos API privada autenticada.
    requestId: requestId ' Adjuntamos id de request para retry tracking.
    dataAux: FormatJson(m.viewAllPayload) ' Guardamos contexto para posible reintento.
    run: function() as Object ' Ejecutamos la petición mediante helper común.
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux) ' Disparamos request en manager.
      return { success: true, error: invalid } ' Reportamos estado de ejecución local.
    end function ' Cerramos función de ejecución de acción.
  } ' Cerramos objeto action.
  runAction(requestId, action, ApiType().CLIENTS_API_URL) ' Registramos y ejecutamos acción con mecanismo de retry.
  m.apiRequestManager = action.apiRequestManager ' Persistimos manager actualizado.
end sub

' Procesa la respuesta del servicio de ViewAll.
sub onViewAllCarouselResponse()
  if m.apiRequestManager = invalid then ' Reintenta si el manager fue limpiado por flujo externo.
    __getViewAllCarousel() ' Re-disparamos la obtención del carrusel.
    return ' Cortamos ejecución actual tras solicitar reintento.
  end if
  if validateStatusCode(m.apiRequestManager.statusCode) then ' Evaluamos si la respuesta HTTP es correcta.
    removePendingAction(m.apiRequestManager.requestId) ' Quitamos la acción del pool pendiente.
    resp = ParseJson(m.apiRequestManager.response) ' Parseamos payload de respuesta.
    if resp <> invalid then m.viewAllResponse = resp ' Persistimos respuesta cruda para depuración/uso futuro.
    if resp <> invalid and resp.data <> invalid and resp.data.items <> invalid and resp.data.items.count() > 0 then ' Validamos que existan items para pintar.
      m.carousel = resp.data
      __populateViewAllCarousel(resp.data) ' Renderizamos carrusel con datos de ViewAll.
    else
      __clearViewAllCarousel() ' Limpiamos UI cuando la API no trae items.
    end if
  else
    error = m.apiRequestManager.errorResponse ' Tomamos payload de error del manager.
    statusCode = m.apiRequestManager.statusCode ' Tomamos código HTTP para validaciones.
    if m.apiRequestManager.serverError then ' Si es error de servidor, aplicamos retry automático.
      changeStatusAction(m.apiRequestManager.requestId, "error") ' Marcamos acción en error para retryAll.
      retryAll() ' Reintentamos según política global.
    else
      removePendingAction(m.apiRequestManager.requestId) ' Limpiamos acción pendiente no reintentable.
      printError("ViewAllCarousel:", error) ' Logueamos error funcional de ViewAll.
      if validateLogout(statusCode, m.top) then ' Validamos si el error requiere forzar logout.
        m.apiRequestManager = clearApiRequest(m.apiRequestManager) ' Limpiamos estado de request manager.
        if m.top.loading <> invalid then m.top.loading.visible = false ' Ocultamos loading antes de salir.
        return ' Cortamos ejecución al delegar en flujo logout.
      end if
    end if
  end if
  m.apiRequestManager = clearApiRequest(m.apiRequestManager) ' Limpiamos manager principal al finalizar ciclo.
  if m.top.loading <> invalid then m.top.loading.visible = false ' Ocultamos loading al cerrar procesamiento.
end sub

' Crea y configura el listado de carruseles inferior usando un flujo equivalente a populateCarousels de MainScreen.
sub __populateViewAllCarousel(data as Object)
  yPosition = 0 ' Inicializamos posición vertical acumulada de cada carrusel.
  previousCarousel = invalid ' Inicializamos referencia del carrusel anterior para enlazar foco vertical.
  __clearViewAllCarousel() ' Limpiamos carruseles previos antes de repintar contenido.
  if m.carouselContainer = invalid then return ' Protegemos ejecución si no existe contenedor de carruseles.
  sourceItems = [] ' Preparamos colección normalizada de carruseles para iteración.
  if data <> invalid and data.items <> invalid and data.items.count() > 0 and data.items[0].style <> invalid then sourceItems = data.items[0].items ' Usamos directamente data.items cuando ya es una lista de carruseles.
  if sourceItems.count() = 0 and data <> invalid and data.items <> invalid and data.items.count() > 0 then sourceItems = [data] ' Envolvemos data como único carrusel cuando items representa programas.
  for each carouselData in sourceItems ' Recorremos cada carrusel para crearlo igual que MainScreen.
    if carouselData.style <> getCarouselStyles().NEWS then ' Omitimos carruseles de noticias para mantener comportamiento de Home.
      newCarousel = m.carouselContainer.createChild("Carousel") ' Creamos una instancia del componente Carousel.
      newCarousel.id = carouselData.id ' Asignamos id del carrusel recibido por API.
      newCarousel.contentType = carouselData.contentType ' Asignamos tipo de contenido del carrusel.
      newCarousel.style = carouselData.style ' Asignamos estilo visual del carrusel.
      newCarousel.title = carouselData.title ' Asignamos título visible del carrusel.
      newCarousel.code = carouselData.code ' Asignamos código de negocio del carrusel.
      newCarousel.imageType = carouselData.imageType ' Asignamos tipo de imagen para summary.
      newCarousel.redirectType = carouselData.redirectType ' Asignamos redirectType del carrusel.
      newCarousel.items = carouselData.items ' Cargamos programas asociados al carrusel.
      newCarousel.translation = [0, yPosition] ' Posicionamos carrusel en eje Y acumulado.
      newCarousel.ObserveField("focused", "onFocusItem") ' Observamos foco para disparar Program Summary.
      if previousCarousel <> invalid then previousCarousel.focusDown = newCarousel ' Enlazamos foco hacia abajo desde carrusel anterior.
      if previousCarousel <> invalid then newCarousel.focusUp = previousCarousel ' Enlazamos foco hacia arriba hacia carrusel anterior.
      previousCarousel = newCarousel ' Actualizamos referencia para la próxima iteración.
      yPosition = yPosition + newCarousel.height + scaleValue(20, m.scaleInfo) ' Avanzamos separación vertical como en MainScreen.
    end if
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

' Limpia el carrusel actual de ViewAll y resetea estado visual asociado.
sub __clearViewAllCarousel()
  if m.carouselContainer = invalid then return ' Evitamos errores si el contenedor aún no fue inicializado.
  while m.carouselContainer.getChildCount() > 0 ' Removemos todos los carouseles existentes.
    child = m.carouselContainer.getChild(0) ' Tomamos el primer hijo para borrado iterativo.
    child.unobserveField("focused") ' Quitamos observer de foco para evitar fugas.
    m.carouselContainer.removeChild(child) ' Eliminamos nodo del árbol de SceneGraph.
  end while
  m.selectedIndicator.visible = false ' Ocultamos indicador al no existir carrusel renderizado.
  m.programInfo.visible = false ' Ocultamos summary al limpiar contenido.
  m.programImageBackground.uri = "" ' Limpiamos imagen de fondo del programa previo.
end sub

' Reacciona al foco de un item del carrusel y prepara solicitud de Program Summary.
sub onFocusItem()
  if m.carouselContainer = invalid or not m.carouselContainer.isInFocusChain() then return ' Validamos que el foco pertenezca al carrusel activo.
  if m.carouselContainer.focusedChild = invalid then return ' Validamos que exista carrusel enfocado.
  newFocus = m.carousel.items[0].items[0] ' Parseamos item actualmente enfocado.
  if newFocus = invalid then return ' Ignoramos eventos de foco inválidos.
  if m.itemfocused = invalid or (newFocus.key <> m.itemfocused.key or newFocus.id <> m.itemfocused.id or newFocus.redirectKey <> m.itemfocused.redirectKey or newFocus.redirectId <> m.itemfocused.redirectId) then ' Evitamos llamadas duplicadas para el mismo item.
    m.programInfo.visible = false ' Ocultamos summary mientras se carga el nuevo programa.
    m.programImageBackground.uri = "" ' Limpiamos fondo para evitar mostrar data vieja.
    m.itemfocused = newFocus ' Guardamos item enfocado que se usará en la consulta.
    m.carouselContainer.focusedChild.focused = invalid ' Limpiamos field focused para próximos cambios.
    clearTimer(m.programTimer) ' Reiniciamos debounce del timer.
    m.programTimer.ObserveField("fire", "getProgramInfo") ' Asociamos callback del timer con request summary.
    m.programTimer.control = "start" ' Iniciamos timer para pedir summary tras breve pausa.
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