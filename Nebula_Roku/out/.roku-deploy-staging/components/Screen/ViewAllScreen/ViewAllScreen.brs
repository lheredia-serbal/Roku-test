' Inicializa referencias internas del componente ViewAllScreen.
sub init()
  ' Guardamos referencia al título para actualizarlo fácilmente.
  m.titleLabel = m.top.findNode("titleLabel")
  ' Guardamos referencia al subtítulo para mostrar el contexto de la navegación.
  m.descriptionLabel = m.top.findNode("descriptionLabel")

  ' Aplicamos el valor inicial del field title.
  onTitleChange()
end sub

' Actualiza el label cuando cambia el field title.
sub onTitleChange()
  if m.titleLabel <> invalid then
    ' Si title llega vacío, se usa un fallback legible.
    m.titleLabel.text = m.top.title
    if m.titleLabel.text = "" then
      m.titleLabel.text = "Ver todo"
    end if
  end if
end sub

' Procesa el payload enviado desde MainScreen para mostrar contexto en la vista.
sub onDataChange()
  if m.top.data = invalid or m.top.data = "" then return

  payload = ParseJson(m.top.data)
  if payload = invalid then return

  m.viewAllPayload = payload

  ' Usamos el título del carrusel como título principal de la pantalla de "Ver todos".
  if payload.title <> invalid and payload.title <> "" then
    m.top.title = payload.title
  end if

  if m.descriptionLabel <> invalid then
    ' Mostramos ids de contexto (menuSelectedItem.id y carouselId) más el código del carrusel de origen.
    m.descriptionLabel.text = "Listado completo de: " + m.top.title

    if payload.menuSelectedItemId <> invalid then
      m.descriptionLabel.text = m.descriptionLabel.text + " | MenuId: " + payload.menuSelectedItemId.toStr()
    end if

    if payload.carouselId <> invalid then
      m.descriptionLabel.text = m.descriptionLabel.text + " | CarouselId: " + payload.carouselId.toStr()
    end if

    if payload.carouselCode <> invalid and payload.carouselCode <> "" then
      m.descriptionLabel.text = m.descriptionLabel.text + " (" + payload.carouselCode + ")"
    end if
  end if

  ' Disparamos el consumo del servicio igual que en MainScreen, usando sendApiRequest + runAction.
  __getViewAllCarousel()
end sub

' Maneja la lógica de foco para la pantalla.
sub initFocus()
  if m.top.onFocus then
    ' Al recibir foco, transferimos foco visual al propio contenedor.
    m.top.setFocus(true)
  end if
end sub

' Solicita el detalle del carrusel seleccionado en la vista "Ver todos".
sub __getViewAllCarousel()
  if m.viewAllPayload = invalid then return
  if m.viewAllPayload.menuSelectedItemId = invalid or m.viewAllPayload.carouselId = invalid then return

  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL)
  if m.apiUrl = invalid then return

  if m.top.loading <> invalid and not m.top.loading.visible then m.top.loading.visible = true

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

  runAction(requestId, action, ApiType().CLIENTS_API_URL)
  m.apiRequestManager = action.apiRequestManager
end sub

' Procesa la respuesta del servicio de ViewAll de forma equivalente a MainScreen.
sub onViewAllCarouselResponse()
  if m.apiRequestManager = invalid then
    __getViewAllCarousel()
    return
  end if

  if validateStatusCode(m.apiRequestManager.statusCode) then
    removePendingAction(m.apiRequestManager.requestId)
    resp = ParseJson(m.apiRequestManager.response)

    ' Dejamos disponible la respuesta para futuras iteraciones de UI de ViewAll.
    if resp <> invalid then m.viewAllResponse = resp
  else
    error = m.apiRequestManager.errorResponse
    statusCode = m.apiRequestManager.statusCode

    if m.apiRequestManager.serverError then
      changeStatusAction(m.apiRequestManager.requestId, "error")
      retryAll()
    else
      removePendingAction(m.apiRequestManager.requestId)
      printError("ViewAllCarousel:", error)

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
