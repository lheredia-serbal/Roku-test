' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
  m.opacityForMenu = m.top.findNode("opacityForMenu")
  m.groupOpacityForMenu = m.top.findNode("groupOpacityForMenu")
  m.myMenu = m.top.findNode("myMenu")

  'carousel
  m.carouselContainer = m.top.findNode("carouselContainer")
  m.selectedIndicator = m.top.findNode("selectedIndicator")

  'Program summary
  m.programTimer = m.top.findNode("programTimer")
  m.programInfo = m.top.findNode("programInfo")
  m.infoGradient = m.top.findNode("infoGradient")
  m.programImageBackground = m.top.findNode("programImageBackground")

  ' Without content
  m.withoutContentLayoutGroup = m.top.findNode("withoutContentLayoutGroup")
  m.withoutContentTitle = m.top.findNode("withoutContentTitle")
  m.withoutContentMessage = m.top.findNode("withoutContentMessage")
  
  m.logo = m.top.findNode("mainLogo")
  m.nameOrganization = m.top.findNode("nameOrganization")

  m.scaleInfo = m.global.scaleInfo

  if m.global <> invalid then
    m.global.observeField("activeApiUrl", "onActiveApiUrlChanged")
  end if
end sub

' Funcion que interpreta los eventos de teclado y retorna true si fue porcesada por este componente. Sino es porcesado por el
' entonces sigue con el siguente metodo onKeyEvent del compoente superior
function onKeyEvent(key as string, press as boolean) as boolean
  if m.top.loading.visible <> false and key <> KeyButtons().BACK then 
    return true
  end if

  handled = false
  if key = KeyButtons().UP
    if press and m.carouselContainer <> invalid and m.carouselContainer.isInFocusChain() and m.carouselContainer.focusedChild <> invalid and m.carouselContainer.focusedChild.focusUp <> invalid then
      focusItem = m.carouselContainer.focusedChild.focusUp.findNode("carouselList")
      if focusItem <> invalid then 
        m.carouselContainer.focusedChild.focusUp.opacity = "1.0"
        focusItem.setFocus(true)
        m.carouselContainer.translation = [m.xPosition, -(m.carouselContainer.focusedChild.translation[1] - m.yPosition)] ' Mover hacia arriba
        m.selectedIndicator.size = m.carouselContainer.focusedChild.size
      end if
    end if
    handled = true

  else if key = KeyButtons().DOWN
    if press and m.carouselContainer <> invalid and m.carouselContainer.isInFocusChain() and m.carouselContainer.focusedChild <> invalid and m.carouselContainer.focusedChild.focusDown <> invalid  then
      focusItem = m.carouselContainer.focusedChild.focusDown.findNode("carouselList")
      if focusItem <> invalid then 
        m.carouselContainer.focusedChild.opacity = "0.0"
        focusItem.setFocus(true)
        m.carouselContainer.translation = [m.xPosition, -(m.carouselContainer.focusedChild.translation[1] - m.yPosition)]
        m.selectedIndicator.size = m.carouselContainer.focusedChild.size ' Mover hacia arriba
      end if
    end if
    handled = true

  else if (key = KeyButtons().RIGHT or key = KeyButtons().BACK) and m.myMenu.isInFocusChain()
    if press then
      m.myMenu.action = "collapse"
      __focusCarousels()
    end if

    handled = true
  
  else if (key = KeyButtons().LEFT and m.carouselContainer.hasFocus()) then
    m.myMenu.action = "expand"
    handled = true

  else if (key = KeyButtons().BACK and m.carouselContainer <> invalid and m.carouselContainer.isInFocusChain() and m.carouselContainer.focusedChild <> invalid and  m.menuSelectedItem <> invalid and not m.isHomeSelected) then
    if press and m.myMenu.loadHome = false then 
      if m.myMenu <> invalid then m.myMenu.loadHome = true
    end if
    handled = true
  end if
  
  return handled
end function 

' Carga los datos de componente, si no recibe datos o los recibe vacios entonces dispara la limpieza del componete
sub initData()
  __configMain()
  if m.top.onFocus and m.top.loadData then
    if m.top.loading.visible = false then m.top.loading.visible = true
    
    safeX = m.scaleInfo.safeZone.x
    safeY = m.scaleInfo.safeZone.y
    width = m.scaleInfo.width
    height = m.scaleInfo.height

    m.opacityForMenu.width = width
    m.opacityForMenu.height = height
   
    m.infoGradient.width = width
    m.infoGradient.height = height
   
    m.programImageBackground.width = width
    m.programImageBackground.height = height
    
    m.groupOpacityForMenu.clippingRect = [0, 0, safeX + scaleValue(60, m.scaleInfo), height]

    logoWidth = scaleValue(200, m.scaleInfo)
    logoHeight = scaleValue(100, m.scaleInfo)
    m.logo.width = logoWidth
    m.logo.height = logoHeight
    m.logo.loadWidth = logoWidth
    m.logo.loadHeight = logoHeight
    m.logo.translation = [(width - scaleValue(250, m.scaleInfo)), scaleValue(30, m.scaleInfo)]
    m.nameOrganization.translation = [(width - safeX - scaleValue(200, m.scaleInfo)), scaleValue(130, m.scaleInfo)]
    m.withoutContentLayoutGroup.translation = [(width / 2), (height / 2)]
    
    errorSafeZone = width - (safeX * 2) - scaleValue(230, m.scaleInfo)
    m.withoutContentTitle.width = errorSafeZone
    m.withoutContentMessage.width = errorSafeZone

    m.programInfo.translation = [safeX + scaleValue(60, m.scaleInfo), safeY + scaleValue(20, m.scaleInfo)]

    if m.productCode = invalid then m.productCode = getConfigVariable(m.global.configVariablesKeys.PRODUCT_CODE)
    if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL) 
    if m.beaconUrl = invalid then m.beaconUrl = getConfigVariable(m.global.configVariablesKeys.BEACON_URL) 
    if m.productName = invalid then m.productName = getConfigVariable(m.global.configVariablesKeys.PRODUCT_NAME) 
    if m.logoDisplayType = invalid then m.logoDisplayType = getConfigVariable(m.global.configVariablesKeys.LOGO_DISPLAY_TYPE) 

    m.myMenu.ObserveField("selectedItem", "onSelectMenuItem")
    __getMenu()

    __loadOrganizationLogo()
  end if
end sub

' Inicializa el foco del componente seteando los valores necesarios
sub initFocus()
  if m.top.onFocus then 
    __applyTranslations()
    __validateAutoUpgradeTime()
  end if 
  if m.dialog <> invalid and m.dialog.visible then return
  if m.top.onFocus and m.lastFocus <> invalid then
    __validateVariables()
    if m.lastRefreshDate <> invalid then
      nowDate = CreateObject("roDateTime")
      nowDate.ToLocalTime()

      ' Paso mas de 5 minutos que se cargo la vista?
      if (m.lastRefreshDate.asSeconds() + 300) <= nowDate.asSeconds() then
        ' Valido que la vista seleccionada no sea la de la Guia
        if m.menuSelectedItem <> invalid and m.menuSelectedItem.code <> "epg" then
          ' Volver a cargar la vista 
          __selectMenuItem(m.menuSelectedItem)
          return
        end if
      end if
    end if

    m.lastFocus.setFocus(true)
    m.top.loading.visible = false
  end if
end sub

' Toma la seleccion del item del menu
sub onSelectMenuItem()
  if m.myMenu <> invalid and m.myMenu.selectedItem <> invalid then
    m.menuSelectedItem = ParseJson(m.myMenu.selectedItem)
    m.myMenu.selectedItem = invalid
    __selectMenuItem(m.menuSelectedItem)
  end if
end sub

' Función que crea dinámicamente los carouseles en el contenedor
sub populateCarousels(data as Object)
  yPosition = 0
  previousCarousel = invalid

  __clearContentView()
  __clearProgramInfo()

  m.carouselContainer.translation = [scaleValue(55, m.scaleInfo), m.scaleInfo.safeZone.y + scaleValue(20, m.scaleInfo)]
  m.xPosition = m.carouselContainer.translation[0]
  m.yPosition = m.carouselContainer.translation[1]

  m.selectedIndicator.translation = [scaleValue(124, m.scaleInfo), m.scaleInfo.safeZone.y + scaleValue(148, m.scaleInfo)]

  for each carouselData in data.items
    if carouselData.style <> getCarouselStyles().NEWS then 
      ' Crea una instancia del componente Carousel
      newCarousel = m.carouselContainer.createChild("Carousel")
      
      ' Asigna los datos e items recibidos del servidor
      newCarousel.id = carouselData.id
      newCarousel.contentType = carouselData.contentType
      newCarousel.style = carouselData.style
      newCarousel.title = carouselData.title
      newCarousel.code = carouselData.code
      newCarousel.imageType = carouselData.imageType
      newCarousel.redirectType = carouselData.redirectType
      newCarousel.items = carouselData.items
      
      ' Posiciona el carousel verticalmente
      newCarousel.translation = [0, yPosition]
      
      ' Se agrega el evento click
      newCarousel.ObserveField("selected", "onSelectItem")
      newCarousel.ObserveField("focused", "onFocusItem")
      newCarousel.ObserveField("openMenu", "onOpenMenuCarousel")
  
      ' Configura la navegación vertical entre carouseles
      if previousCarousel <> invalid then
          previousCarousel.focusDown = newCarousel
          newCarousel.focusUp = previousCarousel
      end if
      previousCarousel = newCarousel
  
      ' Usa la propiedad height definida en el componente para calcular la posición
      yPosition = yPosition + newCarousel.height + scaleValue(20, m.scaleInfo)
    end if
  end for

  ' Una vez creados todos los carouseles, establece el foco en el primer item del primer carousel:
  if m.carouselContainer.getChildCount() > 0 then
    firstCarousel = m.carouselContainer.getChild(0)
    firstList = firstCarousel.findNode("carouselList")
    if firstList <> invalid and m.autoUpgradeDialogOpen <> true then
      firstList.setFocus(true)
      m.selectedIndicator.size = firstCarousel.size
      m.selectedIndicator.visible = true
    end if
  end if

  nowDate = CreateObject("roDateTime")
  nowDate.ToLocalTime()

  m.lastRefreshDate = nowDate
end sub

' Toma la seleccion del item del carousel y dispara la validacion de si puede ver. 
sub onSelectItem()
  if m.carouselContainer <> invalid and m.carouselContainer.isInFocusChain() and m.carouselContainer.focusedChild <> invalid then
    m.itemSelected = ParseJson(m.carouselContainer.focusedChild.selected)
    
    m.carouselContainer.focusedChild.selected = invalid
    if m.itemSelected.redirectKey = "ChannelId" then

      if m.itemSelected.parentalControl <> invalid and m.itemSelected.parentalControl then
        __markLastFocus()
        m.pinDialog = createAndShowPINDialog(m.top, i18n_t(m.global.i18n, "shared.parentalControlModal.title"), "onPinDialogLoad", [i18n_t(m.global.i18n, "button.ok"), i18n_t(m.global.i18n, "button.cancel")])
      else 
        m.top.loading.visible = true
        watchSessionId = getWatchSessionId()
        action = {
          apiRequestManager: m.apiRequestManager
          url: urlWatchValidate(m.apiUrl, watchSessionId, m.itemSelected.redirectKey, m.itemSelected.redirectId)
          method: "GET"
          responseMethod: "onWatchValidateResponse"
          body: invalid
          token: invalid
          publicApi: false
          dataAux: invalid
          run: function() as Object
            m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
            return { success: true, error: invalid }
          end function
        }
        __setRequestId(action)
        executeWithRetry(action, ApiType().CLIENTS_API_URL)
        m.apiRequestManager = action.apiRequestManager
      end if 
      
    else
      m.apiRequestManager = clearApiRequest(m.apiRequestManager) 
      __markLastFocus()
      m.top.loading.visible = true
      m.top.detail = FormatJson(m.itemSelected) 
    end if
  end if
end sub

' Dispara la apertura del menu al llegar al limite izquierdo del carousel
sub onOpenMenuCarousel() 
  __markLastFocus()
  m.myMenu.action = "expand"
  m.selectedIndicator.visible = false
end sub

' Dispara la busqueda del summary del item que esta teniendo foco en el carousel actual
sub onFocusItem()
  if m.carouselContainer <> invalid and m.carouselContainer.isInFocusChain() and m.carouselContainer.focusedChild <> invalid then
    newFocus = ParseJson(m.carouselContainer.focusedChild.focused)
    if (m.itemfocused = invalid) or (m.itemfocused <> invalid and (newFocus.key <> m.itemfocused.key or newFocus.id <> m.itemfocused.id or newFocus.redirectKey <> m.itemfocused.redirectKey or newFocus.redirectId <> m.itemfocused.redirectId)) then
      
      m.programInfo.visible = false
      m.programImageBackground.uri = ""
      m.itemfocused = newFocus
      m.carouselContainer.focusedChild.focused = invalid
      clearTimer(m.programTimer)
      m.programTimer.ObserveField("fire","getProgramInfo")
      m.programTimer.control = "start"
    end if
  end if
end sub

' Procesa la respuesta al pedir el ultimo canal visto disparando la validacion si puede ver y navegando al player con la guia abierta.
sub onLastWatchedResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response).data
    if (resp <> invalid) then 
      resp.key = "ChannelId"
      resp.redirectKey = "ChannelId"
      resp.redirectId = resp.id

      m.itemSelected = resp
      watchSessionId = getWatchSessionId()
      action = {
        apiRequestManager: m.apiRequestManager
        url: urlWatchValidate(m.apiUrl, watchSessionId.toStr(), resp.key, resp.id)
        method: "GET"
        responseMethod: "onWatchValidateResponse"
        body: invalid
        token: invalid
        publicApi: false
        dataAux: invalid
        run: function() as Object
          m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
          return { success: true, error: invalid }
        end function
      }
      __setRequestId(action)
      executeWithRetry(action, ApiType().CLIENTS_API_URL)
      m.apiRequestManager = action.apiRequestManager
    else
      m.top.loading.visible = false
      statusCode = m.apiRequestManager.statusCode
      m.apiRequestManager = clearApiRequest(m.apiRequestManager) 
      m.top.openGuide = false
      
      if (statusCode = 408) then
        __markLastFocus() 
        m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
      else 
        __validateError(statusCode, 0, invalid)
      end if
  
      printError("LastWatched (Emty):")
    end if 
  else
    retryManager = RetryOn9000(m, "onLastWatchedResponse", m.apiRequestManager, ApiType().CLIENTS_API_URL)
    if retryManager <> invalid then
      m.apiRequestManager = retryManager
      return
    end if
    m.top.loading.visible = false
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    m.top.openGuide = false
    
    if (statusCode = 408) then
      __markLastFocus() 
      m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    else 
      __validateError(statusCode, 0, errorResponse)
    end if

    printError("LastWatched:", errorResponse)
  end if
end sub

' Procesa la respuesta de si el ususario puede ver
sub onWatchValidateResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response).data
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    if resp.resultCode = 200 then
      setWatchSessionId(resp.watchSessionId)
      setWatchToken(resp.watchToken)
      if m.itemSelected <> invalid then
        action = {
          apiRequestManager: m.apiRequestManager
          url: urlStreaming(m.apiUrl, m.itemSelected.redirectKey, m.itemSelected.redirectId)
          method: "GET"
          responseMethod: "onStreamingsResponse"
          body: invalid
          token: invalid
          publicApi: false
          dataAux: invalid
          run: function() as Object
            m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
            return { success: true, error: invalid }
          end function
        }
        __setRequestId(action)
        executeWithRetry(action, ApiType().CLIENTS_API_URL)
        m.apiRequestManager = action.apiRequestManager
      end if
    else 
      m.top.loading.visible = false
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      
      __validateError(0, resp.resultCode, invalid)
      printError("WatchValidate ResultCode:", resp.resultCode)
    end if
  else 
    retryManager = RetryOn9000(m, "onWatchValidateResponse", m.apiRequestManager, ApiType().CLIENTS_API_URL)
    if retryManager <> invalid then
      m.apiRequestManager = retryManager
      return
    end if
    m.top.loading.visible = false
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    
    if (statusCode = 408) then
      __markLastFocus() 
      m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    else 
      __validateError(statusCode, 0, errorResponse)
    end if

    printError("WatchValidate Stastus:", statusCode.toStr() + " " +  errorResponse)
  end if
end sub

' Procesa la respuesta al obtener la url de lo que se quiere ver
sub onStreamingsResponse() 
  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)
    if resp.data <> invalid then
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      __markLastFocus()
      streaming = resp.data
      streaming.key = m.itemSelected.redirectKey 
      streaming.id = m.itemSelected.redirectId
      streaming.streamingType = getStreamingType().DEFAULT
      m.top.streaming = FormatJson(streaming)
    else 
      m.top.loading.visible = false
      __markLastFocus()
      printError("Streamings Emty:", m.apiRequestManager.response)
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    end if
  else 
    retryManager = RetryOn9000(m, "onStreamingsResponse", m.apiRequestManager, ApiType().CLIENTS_API_URL)
    if retryManager <> invalid then
      m.apiRequestManager = retryManager
      return
    end if
    m.top.loading.visible = false
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    __markLastFocus()
    if (statusCode = 408) then 
      m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    else 
      __validateError(statusCode, 0, errorResponse)
    end if
    printError("Streamings:",errorResponse)
  end if
end sub

' Procesa el cierre del modal al fallar la peticion de carga del menú
sub onDialogReloadMenuClosed()
  option = clearDialogAndGetOption(m.top, m.dialog)
  m.dialog = invalid
  
  if option = 0 then
    ' Disparar Reintentar
    __getMenu()
  else
    ' Disparar Salir
    m.top.forceExit = true
  end if 
end sub

' Procesa el cierre del modal al fallar la peticion de carga de la vista
sub onDialogReloadContentViewClosed()
  option = clearDialogAndGetOption(m.top, m.dialog)
  m.dialog = invalid
  
  if option = 0 then
    ' Disparar Reintentar
    __selectMenuItem(m.menuSelectedItem)
  else
    ' Disparar Salir
    m.top.forceExit = true
  end if 
end sub

' Procesa el cierre del modal tras que el usuario selecione el cierre de sesion.
sub onDialogLogoutContainer()
  option = clearDialogAndGetOption(m.top, m.dialog)
  m.dialog = invalid
  
  if option = 0 then
    ' Disparar logout
    m.top.logout = true
  else 
    ' Disparar el volver a enfocar cuando la opcion "No"    
    if m.lastFocus <> invalid then m.lastFocus.setFocus(true)
  end if 
end sub

' Procesa el cierre de los modales de error para volver a dar foco sobre el elemento que lo 
' tenia antes del error
sub onDialogClosedFocusContainer()
  option = clearDialogAndGetOption(m.top, m.dialog)
  m.dialog = invalid
  
  if option = 0 then __focusCarousels()
end sub

' Hace foco en objeto que lo tenia antes de que se abriera el modal
sub onDialogClosedLastFocus()
  onDialogClosedFocusContainer()
  if m.lastFocus <> invalid then m.lastFocus = invalid 
end sub

' Dispara el evento de deslogueo
sub onLogoutChange()
  if m.top.logout then __clearScreen()
end sub

' Dispara la busqueda del programa que esta teniendo el foco. Usa un timer para buscarlo una vez que el 
' usuario se detuvo en la navegacion
sub getProgramInfo()
  try 
  clearTimer(m.programTimer)
  if m.itemfocused <> invalid then
    if m.program <> invalid and m.program.infoKey = m.itemfocused.redirectKey and m.program.infoId = m.itemfocused.redirectId then 
      endTime = CreateObject("roDateTime")
      nowDate = CreateObject("roDateTime")
      
      endTime.FromISO8601String(m.program.endTime)
      endTime.ToLocalTime()

      nowDate.ToLocalTime()

      if (m.program.infoKey <> "ChannelId") or (m.program.infoKey = "ChannelId" and endTime.AsSeconds() > nowDate.AsSeconds()) then 
        m.programInfo.visible = true      
        return
      end if
    end if

    if m.apiSummaryRequestManager <> invalid then
      m.programTimer.ObserveField("fire","getProgramInfo")
      m.programTimer.control = "start"
      return 
    end if
    mainImageTypeId = getCarouselImagesTypes().NONE.toStr()

    if m.carouselContainer.focusedChild <> invalid and m.carouselContainer.focusedChild.imageType <> invalid and m.carouselContainer.focusedChild.imageType <> 0 then
      mainImageTypeId = m.carouselContainer.focusedChild.imageType.ToStr()
    end if

    action = {
      apiRequestManager: m.apiSummaryRequestManager
      url: urlProgramSummary(m.apiUrl, m.itemfocused.redirectKey, m.itemfocused.redirectId, mainImageTypeId, getCarouselImagesTypes().SCENIC_LANDSCAPE)
      method: "GET"
      responseMethod: "onProgramSummaryResponse"
      body: invalid
      token: invalid
      publicApi: false
      dataAux: invalid
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    __setRequestId(action)
    executeWithRetry(action, ApiType().CLIENTS_API_URL)
    m.apiSummaryRequestManager = action.apiRequestManager
   end if 
  catch error
    printError("Error al cargar la programa summary", error)
  end try
end sub

' Procesa la respuesta de la peticion del Summay del programa
sub onProgramSummaryResponse()
  if validateStatusCode(m.apiSummaryRequestManager.statusCode) then
    m.itemfocused = invalid
    resp = ParseJson(m.apiSummaryRequestManager.response)
    if resp.data <> invalid then
      m.apiSummaryRequestManager = clearApiRequest(m.apiSummaryRequestManager)
      m.program = resp.data

      if  m.program.backgroundImage <> invalid then
        m.programImageBackground.uri = getImageUrl(m.program.backgroundImage)
      else 
        m.programImageBackground.uri = ""
      end if

      m.programInfo.program = FormatJson(m.program)
      if m.carouselContainer.focusedChild <> invalid then m.carouselContainer.focusedChild.updateNode = FormatJson(m.program)

      m.programInfo.visible = true
    else
      __clearProgramInfo()
      printError("ProgramSumary Emty:", m.apiSummaryRequestManager.response)
      m.apiSummaryRequestManager = clearApiRequest(m.apiSummaryRequestManager)
    end if 
  else
    retryManager = RetryOn9000(m, "onProgramSummaryResponse", m.apiSummaryRequestManager, ApiType().CLIENTS_API_URL)
    if retryManager <> invalid then
      m.apiSummaryRequestManager = retryManager
      return
    end if
    statusCode = m.apiSummaryRequestManager.statusCode
    errorResponse = m.apiSummaryRequestManager.errorResponse
    m.apiSummaryRequestManager = clearApiRequest(m.apiSummaryRequestManager)
    
    printError("ProgramSumary:", errorResponse)
    if validateLogout(statusCode, m.top) then return 
  
    __clearProgramInfo()
  end if
end sub

' Procesa la respuesta de la peticion del menú
sub onMenuResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    if resp.data <> invalid then
      m.myMenu.items = resp.data
    else 
      m.top.loading.visible = false
      m.myMenu.items = [] 
      m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.unhandled"), i18n_t(m.global.i18n, "shared.errorComponent.extendedMessage"), "onDialogClosedFocusContainer", [i18n_t(m.global.i18n, "button.cancel")])
    end if 
  else 
    retryManager = RetryOn9000(m, "onMenuResponse", m.apiRequestManager, ApiType().CLIENTS_API_URL)
    if retryManager <> invalid then
      m.apiRequestManager = retryManager
      return
    end if
    m.top.loading.visible = false
    error =  m.apiRequestManager.errorResponse
    statusCode =  m.apiRequestManager.statusCode
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    
    printError("Menu:", error)
    
    if validateLogout(statusCode, m.top) then return 

    if (statusCode = 408 or statusCode = 400) then  
      m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogReloadMenuClosed", [i18n_t(m.global.i18n, "button.retry"), i18n_t(m.global.i18n, "button.exit")])
    else 
      __validateError(statusCode, 0, error)
    end if

    actionLog = createLogError(generateErrorDescription(error), generateErrorPageUrl("getAllMenu", "AppComponent"), getServerErrorStack(error))
    __saveActionLog(actionLog)
  end if  
end sub

' Procesa la respuesta de la peticion de la vista de contenido
sub onContentViewResponse()

  menuSelected = ParseJson(m.apiRequestManager.dataAux) 

  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)  
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    if resp.metadata.resultCode = 200 then

      actionLog = getActionLog({
        actionCode: ActionLogCode().OPEN_PAGE,
        objectKey: "ContentViewId",
        objectId: menuSelected.id,
        objectDescription: menuSelected.text,
        pageUrl: menuSelected.code
      })

      __saveActionLog(actionLog)

      if resp.data <> invalid and resp.data.items <> invalid and resp.data.items.count() > 0 and not (resp.data.items.count() = 1 and resp.data.items[0].code = "news") then
        
        populateCarousels(resp.data)
        m.top.loading.visible = false
      else 
        __showWithoutContent()
        m.top.loading.visible = false
      end if
    else
      __showWithoutContent()
      m.top.loading.visible = false
    end if
  else 
    m.top.loading.visible = false
    error = m.apiRequestManager.errorResponse
    statusCode = m.apiRequestManager.statusCode

    if statusCode = 9000 then
      retryManager = RetryOn9000Action(m, m.lastContentViewAction, m.apiRequestManager, ApiType().CLIENTS_API_URL)
      if retryManager <> invalid then
        m.apiRequestManager = retryManager
        return
      end if
    else
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      
      printError("ContentView:", error)
      
      if validateLogout(statusCode, m.top) then return 
      
      if (statusCode = 408) or (statusCode = 500) then 
        m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogReloadContentViewClosed", [i18n_t(m.global.i18n, "button.retry"), i18n_t(m.global.i18n, "button.exit")])
      else 
        __validateError(statusCode, 0, error, __showWithoutContent())
      end if

      actionLog = createLogError(generateErrorDescription(error), generateErrorPageUrl("getCarouselsById", "HomeComponent"), getServerErrorStack(error), menuSelected.key, menuSelected.id)
      __saveActionLog(actionLog)
    end if
  end if
end sub

' Se dispara la validacion del PIN cargado en el modal
sub onPinDialogLoad()
  resp = clearPINDialogAndGetOption(m.top, m.pinDialog)
  m.pinDialog = invalid
  
  if (resp.option = 0 and resp.pin <> invalid and Len(resp.pin) = 4) then 
    m.top.loading.visible = true
    action = {
      apiRequestManager: m.apiRequestManager
      url: urlParentalControlPin(m.apiUrl, resp.pin)
      method: "GET"
      responseMethod: "onParentalControlResponse"
      body: invalid
      token: invalid
      publicApi: false
      dataAux: invalid
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    __setRequestId(action)
    executeWithRetry(action, ApiType().CLIENTS_API_URL)
    m.apiRequestManager = action.apiRequestManager
  else 
    __focusCarousels()
  end if 
end sub

' Procesa la respuesta de la validacion del PIN
sub onParentalControlResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)

    if resp <> invalid and resp.data <> invalid and resp.data then 
      watchSessionId = getWatchSessionId()
      action = {
        apiRequestManager: m.apiRequestManager
        url: urlWatchValidate(m.apiUrl, watchSessionId, m.itemSelected.redirectKey, m.itemSelected.redirectId)
        method: "GET"
        responseMethod: "onWatchValidateResponse"
        body: invalid
        token: invalid
        publicApi: false
        dataAux: invalid
        run: function() as Object
            m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
            return { success: true, error: invalid }
          end function
        }
        __setRequestId(action)
        executeWithRetry(action, ApiType().CLIENTS_API_URL)
        m.apiRequestManager = action.apiRequestManager
      else
        m.top.loading.visible = false
        __markLastFocus() 
        m.dialog = createAndShowDialog(m.top, "", i18n_t(m.global.i18n, "shared.parentalControlModal.error.invalid"), "onDialogClosedFocusContainer")
    end if
  else     
    retryManager = RetryOn9000(m, "onParentalControlResponse", m.apiRequestManager, ApiType().CLIENTS_API_URL)
    if retryManager <> invalid then
      m.apiRequestManager = retryManager
      return
    end if
    m.top.loading.visible = false
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    printError("ParentalControl:", statusCode.toStr() + " " +  errorResponse)
    
    if validateLogout(statusCode, m.top) then return 
  
    if (statusCode = 408) then
      __markLastFocus() 
      m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    else 
      __validateError(statusCode, 0, errorResponse)
    end if
 
    actionLog = createLogError(generateErrorDescription(errorResponse), generateErrorPageUrl("valdiatePin", "ParentalControlModalComponent"), getServerErrorStack(errorResponse))
    __saveActionLog(actionLog)
  end if
end sub

' Procesa la respuesta de la actualizacion las variables de plataforma 
sub onPlatformResponse()
  if validateStatusCode(m.apiVariableRequest.statusCode) then
    addAndSetFields(m.global, {variables: ParseJson(m.apiVariableRequest.response).data} )
    m.apiVariableRequest = clearApiRequest(m.apiVariableRequest)
    saveNextUpdateVariables()
  else
    retryManager = RetryOn9000(m, "onPlatformResponse", m.apiVariableRequest, ApiType().CLIENTS_API_URL)
    if retryManager <> invalid then
      m.apiVariableRequest = retryManager
      return
    end if
    m.apiVariableRequest = clearApiRequest(m.apiVariableRequest)
  end if
end sub

' Dispara la peticion del pedido de los items del munú
sub __getMenu()
  action = {
    apiRequestManager: m.apiRequestManager
    url: urlMenu(m.apiUrl, m.productCode)
    method: "GET"
    responseMethod: "onMenuResponse"
    body: invalid
    token: invalid
    publicApi: false
    dataAux: invalid
    run: function() as Object
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
      return { success: true, error: invalid }
    end function
  }
  __setRequestId(action)
  executeWithRetry(action, ApiType().CLIENTS_API_URL)
  m.apiRequestManager = action.apiRequestManager
end sub

' Procesa el item seleccionado en el menú cerrandolo y disparando la accion pertinente (Redirigir a otra pantalla, recargar una vista, etc)
sub __selectMenuItem(menuSelectedItem)

  if menuSelectedItem.key = "MenuId" and menuSelectedItem.id = -1 and menuSelectedItem.code <> invalid and menuSelectedItem.code = "setting" then
    m.myMenu.action = "collapse"
    m.selectedIndicator.visible = true

    actionLog =  getActionLog({
      actionCode: ActionLogCode().OPEN_PAGE,
      objectKey: "ContentViewId",
      objectId: menuSelectedItem.id,
      objectDescription: menuSelectedItem.text,
      pageUrl: menuSelectedItem.code
    })

    __saveActionLog(actionLog)

    m.top.setting = true
  
  else if menuSelectedItem.key = "MenuId" and menuSelectedItem.id = -1 and menuSelectedItem.code <> invalid and menuSelectedItem.code = "exit" then
    m.myMenu.action = "collapse"
    m.selectedIndicator.visible = true
    if m.lastFocus <> invalid then m.lastFocus.setFocus(true)

    actionLog =  getActionLog({ actionCode: ActionLogCode().LOGOUT })

    __saveActionLog(actionLog)
    
    m.top.onExit = true

  else if menuSelectedItem.key = "MenuId" and menuSelectedItem.id = -1 and menuSelectedItem.code <> invalid and menuSelectedItem.code = "logout" then
    m.myMenu.action = "collapse"
    m.selectedIndicator.visible = true 
    m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.exitModal.title"), i18n_t(m.global.i18n, "shared.exitModal.askLogout"), "onDialogLogoutContainer", [ i18n_t(m.global.i18n, "button.yes"), i18n_t(m.global.i18n, "button.no")])

  else if menuSelectedItem.key = "MenuId" and menuSelectedItem.id = -1 and menuSelectedItem.code <> invalid and menuSelectedItem.code = "profiles" then
    __redirectToProfilesScreen()

  else if menuSelectedItem.key = "ContentViewId" then
    if m.myMenu.action <> invalid and m.myMenu.action <> "" and m.myMenu.action <> "collapse" then m.myMenu.action = "collapse"
    if not m.top.loading.visible then m.top.loading.visible = true

    m.isHomeSelected = (menuSelectedItem.behavior <> invalid and menuSelectedItem.behavior = "home")

    ' Limpio el pedido de la Summary por si cambio la vista
    m.apiSummaryRequestManager = clearApiRequest(m.apiSummaryRequestManager)

    action = {
      apiRequestManager: m.apiRequestManager
      url: urlContentViewsCrousels(m.apiUrl, menuSelectedItem.id)
      method: "GET"
      responseMethod: "onContentViewResponse"
      body: invalid
      token: invalid
      publicApi: false
      dataAux: FormatJson(menuSelectedItem)
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    m.lastContentViewAction = action
    __setRequestId(action)
    executeWithRetry(action, ApiType().CLIENTS_API_URL)
    m.apiRequestManager = action.apiRequestManager

  else if menuSelectedItem.key = "MenuId" and menuSelectedItem.code <> invalid and menuSelectedItem.code = "epg" then
    m.top.openGuide = true
    
    m.myMenu.action = "collapse"
    __focusCarousels()

    m.top.loading.visible = true
    action = {
      apiRequestManager: m.apiRequestManager
      url: urlChannelsLastWatched(m.apiUrl)
      method: "GET"
      responseMethod: "onLastWatchedResponse"
      body: invalid
      token: invalid
      publicApi: false
      dataAux: invalid
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    __setRequestId(action)
    executeWithRetry(action, ApiType().CLIENTS_API_URL)
    m.apiRequestManager = action.apiRequestManager
  else 
    __showWithoutContent()
    m.top.loading.visible = false
    m.myMenu.action = "collapse"
    m.lastFocus = invalid
    printError("Menu Selected:", menuSelectedItem.key + " " + menuSelectedItem.id.toStr())
  end if 
end sub

sub onSuccessLogsTokenResponse() 
  if validateStatusCode(m.apiRequestLogsManager.statusCode) then
    ' resp = ParseJson(m.apiRequestLogsManager.response)
    m.apiRequestLogsManager = clearApiRequest(m.apiRequestLogsManager)
  else 
    ' statusCode = m.apiRequestLogsManager.statusCode
    errorResponse = m.apiRequestLogsManager.errorResponse
    
    m.apiRequestLogsManager = clearApiRequest(m.apiRequestLogsManager)
    printError("error:", errorResponse)
    end if
end sub

' Dispara la redireccion a la pantalla de perfiles.
sub __redirectToProfilesScreen()
  __clearScreen()
  m.top.onChangeProfile = true
end sub

' Dispara la redireccion a la pantalla de sesiones activas porque se alcanzo el limite de perfiles viendo
sub __redirectToManySessionsScreeen()
  __markLastFocus()
  if not m.top.loading.visible then m.top.loading.visible = true
  m.top.pendingStreamingSession = FormatJson({ redirectKey: m.itemSelected.redirectKey, redirectId: m.itemSelected.redirectId })
end sub

' Carga la configuracion inicial de la Main.
sub __configMain()
  m.programInfo.width = (m.scaleInfo.width - scaleValue(400, m.scaleInfo))
  m.programInfo.initConfig = true

  m.myMenu.initConfig = true
end sub

' Limpia el componente con la infromacion del programa y cancela el timer de busqueda
sub __clearProgramInfo()
  m.programInfo.program = invalid
  m.programInfo.visible = false
  m.programImageBackground.uri = ""
  m.itemfocused = invalid
  clearTimer(m.programTimer)
end sub

' Limpia el componente que tiene los carouseles y cancela los escuchadores
sub __clearContentView()
  m.program = invalid
  m.withoutContentLayoutGroup.visible = false

  while m.carouselContainer.getChildCount() > 0
    child = m.carouselContainer.getChild(0)
    child.items = invalid
    child.focusDown = invalid
    child.focusUp = invalid
    
    child.unobserveField("selected")
    child.unobserveField("focused")
    child.unobserveField("openMenu")
    
    m.carouselContainer.removeChild(child)
  end while
end sub

' Metodo encargado de limpiar todas las dependecias, cancelar las peticiones y quitar los escuchadores de la pantalla
sub __clearScreen()
  m.top.loading.visible = true

  m.myMenu.unobserveField("selectedItem")
  m.myMenu.items = invalid
  m.myMenu.action = "collapse"
  m.selectedIndicator.visible = false
  m.isHomeSelected = false
  m.lastFocus = invalid
  m.lastRefreshDate = invalid

  m.apiVariableRequest = clearApiRequest(m.apiVariableRequest)
  m.apiRequestManager = clearApiRequest(m.apiRequestManager) 
  m.apiSummaryRequestManager = clearApiRequest(m.apiSummaryRequestManager)

  __clearContentView()
  __clearProgramInfo()
end sub

' Aplicar las traducciones en el componente
sub __applyTranslations()
  if m.global.i18n = invalid then return

  m.withoutContentTitle.text = i18n_t(m.global.i18n, "content.contentPage.notDisplayTitle")
  m.withoutContentMessage.text = i18n_t(m.global.i18n, "content.contentPage.notDisplayContect")
end sub

' Hace foco en los carruseles ya sea en el ultimo item de lso carouseles que tuvo foco o en el contenedor en si si no hay carouseles 
sub __focusCarousels()
  if m.autoUpgradeDialogOpen = true then return
  if m.carouselContainer.getChildCount() > 0 then 
    m.selectedIndicator.visible = true
    if m.lastFocus <> invalid then m.lastFocus.setFocus(true)
  else
    m.carouselContainer.setFocus(true)
  end if
end sub

' Actualiza el indicador de seleccion segun el carrusel enfocado
sub __updateSelectedIndicator()
  if m.carouselContainer <> invalid and m.carouselContainer.focusedChild <> invalid then
    m.selectedIndicator.size = m.carouselContainer.focusedChild.size
    m.selectedIndicator.visible = true
  end if
end sub

' Muestra el mensaje de error que no hay planes o contenido disposnible
sub __showWithoutContent()
  __clearContentView()
  __clearProgramInfo()
  __focusCarousels()
  m.withoutContentLayoutGroup.visible = true
end sub

' Valida si ya paso el tiempo para volver a consultar AutoUpgrade
sub __validateAutoUpgradeTime()
  nextCheck = getNextAutoUpgradeCheck()
  if nextCheck = invalid or nextCheck = "" then return

  nowDate = CreateObject("roDateTime")
  nowDate.ToLocalTime()

  if Val(nextCheck) <= nowDate.AsSeconds() then
    __validateAutoUpgrade()
  end if
end sub

' Dispara la validacion de AutoUpgrade con token
sub __validateAutoUpgrade()
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL)
  body = {
    appCode: m.global.appCode,
    versionCode: getVersionCode(),
    signedByGooglePlay: true,
    startUp: false
  }
  action = {
    apiRequestManager: m.autoUpgradeRequestManager
    url: urlAutoUpgradeValidate(m.apiUrl)
    method: "POST"
    responseMethod: "onAutoUpgradeResponse"
    body: FormatJson(body)
    token: invalid
    publicApi: false
    dataAux: invalid
    run: function() as Object
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
      return { success: true, error: invalid }
    end function
  }
  __setRequestId(action)
  executeWithRetry(action, ApiType().CLIENTS_API_URL)
  m.autoUpgradeRequestManager = action.apiRequestManager
end sub

' Procesa la respuesta del AutoUpgrade
sub onAutoUpgradeResponse()
  if validateStatusCode(m.autoUpgradeRequestManager.statusCode) then
    resp = ParseJson(m.autoUpgradeRequestManager.response)
    data = resp
    if resp <> invalid and resp.data <> invalid then data = resp.data

    if data <> invalid and data.checkTime <> invalid and data.checkTime > 0 then
      nowDate = CreateObject("roDateTime")
      nowDate.ToLocalTime()
      setNextAutoUpgradeCheck((nowDate.asSeconds() + data.checkTime).ToStr())
    end if

    upgrade = false
    if data <> invalid and data.upgrade <> invalid then
      upgrade = data.upgrade
    end if

    mandatory = false
    if data <> invalid and data.mandatory <> invalid then
      mandatory = data.mandatory
    end if

    if upgrade then
      m.autoUpgradeMandatory = mandatory
      m.autoUpgradeDialogOpen = true
      m.selectedIndicator.visible = false
      __markLastFocus()
      messageKey = "autoUpgrade.message"
      buttons = [i18n_t(m.global.i18n, "autoUpgrade.remindLater"), i18n_t(m.global.i18n, "button.exit")]
      if mandatory then
        messageKey = "autoUpgrade.mandatoryMessage"
        buttons = [i18n_t(m.global.i18n, "button.exit")]
      end if
      m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "autoUpgrade.title"), i18n_t(m.global.i18n, messageKey), "onAutoUpgradeAvailableDialogClosed", buttons)
      m.dialog.setFocus(true)
    else
      m.autoUpgradeMandatory = false
    end if
    m.autoUpgradeRequestManager = clearApiRequest(m.autoUpgradeRequestManager)
  else 
    retryManager = RetryOn9000(m, "onAutoUpgradeResponse", m.autoUpgradeRequestManager, ApiType().CLIENTS_API_URL)
    if retryManager <> invalid then
      m.autoUpgradeRequestManager = retryManager
      return
    end if
    printError("AutoUpgrade: ", m.autoUpgradeRequestManager.errorResponse)
    m.autoUpgradeRequestManager = clearApiRequest(m.autoUpgradeRequestManager)
    m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onAutoUpgradeDialogClosed", [i18n_t(m.global.i18n, "button.retry"), "Exit"])
  end if
end sub

' Procesa el evento de cierre del dialogo de AutoUpgrade
sub onAutoUpgradeDialogClosed(_event)
  option = m.dialog.buttonSelected

  m.dialog.visible = false
  m.dialog.unobserveField("buttonSelected")
  m.top.removeChild(m.dialog)
  m.dialog = invalid

  if option = 0 then
    __validateAutoUpgrade()
  else
    m.top.forceExit = true
  end if
end sub

' Procesa el evento de cierre del modal de upgrade disponible
sub onAutoUpgradeAvailableDialogClosed(_event)
  option = m.dialog.buttonSelected

  m.dialog.visible = false
  m.dialog.unobserveField("buttonSelected")
  m.top.removeChild(m.dialog)
  m.dialog = invalid
  m.autoUpgradeDialogOpen = false

  if m.autoUpgradeMandatory = true then
    m.top.forceExit = true
    return
  end if

  if option = 1 then
    m.top.forceExit = true
  else
    if m.lastFocus <> invalid then
      m.lastFocus.setFocus(true)
    else
      __focusCarousels()
    end if
    __updateSelectedIndicator()
  end if
end sub

' Valida si debe perdir nuevamente las variables y si es asi dispara la peticion parapedir la nueva variable
sub __validateVariables()
  nowDate = CreateObject("roDateTime")
  nowDate.ToLocalTime()

  expired = getNextUpdateVariables()
  
  if expired <> invalid and Val(expired) <= nowDate.AsSeconds() then
    m.apiVariableRequest = clearApiRequest(m.apiVariableRequest)
    action = {
      apiRequestManager: m.apiVariableRequest
      url: urlPlatformsVariables(m.apiUrl, m.global.appCode, getVersionCode())
      method: "GET"
      responseMethod: "onPlatformResponse"
      body: invalid
      token: invalid
      publicApi: false
      dataAux: invalid
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    __setRequestId(action)
    executeWithRetry(action, ApiType().CLIENTS_API_URL)
    m.apiVariableRequest = action.apiRequestManager
  end if
end sub

' Valdia el error obtenido desde la API
sub __validateError(statusCode, resultCode, errorResponse, callback = invalid)
  ' Centraliza la validación de errores HTTP/resultCode para la MainScreen.
  ' Decide cuándo redirigir, mostrar diálogos y setear códigos específicos en el CDN dialog.
  error = invalid
  
  if validateLogout(statusCode, m.top) then return 

  if errorResponse <> invalid and errorResponse <> "" then 
    ' Si llega un body de error, intenta parsearlo para obtener el code interno.
  else 
    ' Si no hay body de error, usa el resultCode recibido.
    error = { code: resultCode }
  end if

  if (error <> invalid and error.code <> invalid) then 
    if (error.code = 5014) then 
      ' El usuario debe regresar al selector de perfiles.
      m.top.loading.visible = true
      __redirectToProfilesScreen()
    else if (error.code = 5931) then
      ' No tiene plan: mostrar diálogo con mensaje específico.
      __markLastFocus() 
      m.dialog = createAndShowDialog(m.top,i18n_t(m.global.i18n, "shared.errorComponent.weAreSorry"), (i18n_t(m.global.i18n, "shared.errorComponent.youCurrentlyDoNotHavePlan")).Replace("[ProductName]", m.productName), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    
    else if (error.code = 5932) then
      ' No tiene suscripciones activas: mostrar diálogo con mensaje específico.
      __markLastFocus() 
      m.dialog = createAndShowDialog(m.top,i18n_t(m.global.i18n, "shared.errorComponent.weAreSorry"), (i18n_t(m.global.i18n, "shared.errorComponent.youCurrentlyDoNotHaveAnyActiveSubscriptions")).Replace("[ProductName]", m.productName), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    
    else if (error.code = 5939) then
      ' Saldo insuficiente: mostrar diálogo con mensaje específico.
      __markLastFocus() 
      m.dialog = createAndShowDialog(m.top,i18n_t(m.global.i18n, "shared.errorComponent.weAreSorry"), i18n_t(m.global.i18n, "shared.errorComponent.youCurrentlyDoNotHaveSufficientBalance"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    
    else if (error.code = 5930) then
      ' Demasiadas sesiones activas: redirigir a la pantalla correspondiente.
      __redirectToManySessionsScreeen()
    else if (error.code = 9000) then
      ' Error de configuración inicial: mapear a código CDN usando statusCode.
      setCdnErrorCodeFromStatus(statusCode, ApiType().CLIENTS_API_URL)
    else if (error.code = 100) or (error.code = 101) then
      ' Errores de parseo/estructura JSON de CDN: mapear a códigos PR.
      setCdnErrorCodeFromStatus(error.code, ApiType().CLIENTS_API_URL)
    else if (error.code = 404) or (error.code = 521) or (error.code = 523) then
      ' Errores al cargar módulos cliente: mapear a códigos CL.
      setClientModuleErrorCodeFromStatus(error.code, ApiType().CLIENTS_API_URL)
    end if
  end if 
end sub

' Setear un id unico para cada action
sub __setRequestId(action as Object)
  if action = invalid then return
  if action.requestId = invalid or action.requestId = "" then
    now = CreateObject("roDateTime")
    action.requestId = now.AsSeconds().toStr() + "-" + now.GetMilliseconds().toStr()
  end if
  TrackAction(m, action)
end sub

' Guarda el ultimo utem que a tenido foco en los carouseles en la variable lastFocus
sub __markLastFocus()
  if m.carouselContainer.focusedChild <> invalid and  m.carouselContainer.focusedChild.findNode("carouselList") <> invalid then 
    m.lastFocus = m.carouselContainer.focusedChild.findNode("carouselList")
  end if
end sub

' Guardar el log cuandos se cambia una opción del menú 
sub __saveActionLog(actionLog as object)

  if beaconTokenExpired() and m.apiUrl <> invalid then
    action = {
      apiRequestManager: m.apiLogRequestManager
      url: urlActionLogsToken(m.apiUrl)
      method: "GET"
      responseMethod: "onActionLogTokenResponse"
      body: invalid
      token: invalid
      publicApi: false
      dataAux: FormatJson(actionLog)
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    __setRequestId(action)
    executeWithRetry(action, ApiType().LOGS_API_URL)
    m.apiLogRequestManager = action.apiRequestManager
  else
      __sendActionLog(actionLog)
  end if
end sub

' Obtener el beacon token
sub onActionLogTokenResponse() 

  retryManager = RetryOn9000(m, "onActionLogTokenResponse", m.apiLogRequestManager, ApiType().LOGS_API_URL)
  if retryManager <> invalid then
    m.apiLogRequestManager = retryManager
    return
  end if
  resp = ParseJson(m.apiLogRequestManager.response)
  actionLog = ParseJson(m.apiLogRequestManager.dataAux)

  setBeaconToken(resp.actionsLogToken)

  now = CreateObject("roDateTime")
  now.ToLocalTime()
  m.global.beaconTokenExpiresIn = now.asSeconds() + ((resp.expiresIn - 60) * 1000)

  m.apiLogRequestManager = clearApiRequest(m.apiLogRequestManager) 
  __sendActionLog(actionLog)
end sub

' Llamar al servicio para guardar el log
sub __sendActionLog(actionLog as object)
  beaconToken = getBeaconToken()

  if (beaconToken <> invalid and m.beaconUrl <> invalid)
    action = {
      apiRequestManager: m.apiLogRequestManager
      url: urlActionLogs(m.beaconUrl)
      method: "POST"
      responseMethod: "onActionLogResponse"
      body: FormatJson(actionLog)
      token: beaconToken
      publicApi: false
      dataAux: invalid
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    __setRequestId(action)
    executeWithRetry(action, ApiType().LOGS_API_URL)
    m.apiLogRequestManager = action.apiRequestManager
  end if
end sub

' Limpiar la llamada del log
sub onActionLogResponse() 
  retryManager = RetryOn9000(m, "onActionLogResponse", m.apiLogRequestManager, ApiType().LOGS_API_URL)
  if retryManager <> invalid then
    m.apiLogRequestManager = retryManager
    return
  end if
  m.apiLogRequestManager = clearApiRequest(m.apiLogRequestManager)
end sub

sub __loadOrganizationLogo()

  organization = m.global.organization

  ' Validar el tipo de logo a mostrar
  if m.logoDisplayType <> invalid then

    ' El logo viene en la organización
    if m.logoDisplayType = LogoDisplayType().ORGANIZATION then
      m.nameOrganization.visible = false
      if organization <> invalid and organization.image <> invalid then
        m.logo.uri = getImageUrl(organization.image)
      else
        m.logo.visible = false
      end if

    ' El logo viene de la organización padre
    else if m.logoDisplayType = LogoDisplayType().PARENT_ORGANIZATION then
      m.nameOrganization.visible = false
      if organization <> invalid and organization.parent <> invalid and organization.parent.image <> invalid then
        m.logo.uri = getImageUrl(organization.parent.image)
      else
        m.logo.visible = false
      end if

    ' El logo lo obtiene de la carpeta local
    else if m.logoDisplayType = LogoDisplayType().RESOURCE then
      m.nameOrganization.visible = false
      m.logo.uri = "pkg:/images/client/header_icon.png"

    ' El logo lo obtiene desde la carpeta local y mostrar el nombre de la organización
    else if m.logoDisplayType = LogoDisplayType().RESOURCE_AND_ORGANIZATION_NAME then
  
      if organization <> invalid and organization.name <> invalid then
        m.nameOrganization.text = organization.name
        m.nameOrganization.visible = true
      end if

      m.logo.uri = "pkg:/images/client/header_icon.png"

    ' No mostrar nada
    else if m.logoDisplayType = LogoDisplayType().NONE then
      m.nameOrganization.visible = false
      m.logo.visible = false
    else 

      ' Por defecto mostrar la imágen de la organización o local
      'm.nameOrganization.visible = false

      if organization.image <> invalid then
        m.logo.uri = getImageUrl(organization.image)
      else
        m.logo.uri = "pkg:/images/client/header_icon.png"
      end if
    end if
      
  else
    ' Por defecto mostrar la imágen de la organización o local
    if organization <> invalid and organization.image <> invalid then
      m.logo.uri = getImageUrl(organization.image)
    else 
      m.logo.uri = "pkg:/images/client/header_icon.png"
    end if
  end if
end sub

sub onActiveApiUrlChanged()
  __syncApiUrlFromGlobal()
end sub

sub __syncApiUrlFromGlobal()
  if m.global.activeApiUrl <> invalid and m.global.activeApiUrl <> "" then
    m.apiUrl = m.global.activeApiUrl
  end if
end sub