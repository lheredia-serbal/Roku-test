' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
  m.opacityForMenu = m.top.findNode("opacityForMenu")
  m.groupOpacityForMenu = m.top.findNode("groupOpacityForMenu")
  m.myMenu = m.top.findNode("myMenu")

  ' Referencia al overlay independiente donde vive el título de News.
  m.newsTitle = m.top.findNode("newsTitle")
  ' Referencia al contenedor de dots independiente del componente NewsItem.
  m.dotsContainer = m.top.findNode("dotsContainer")

  ' Referencia al contenedor absoluto para el carrusel de noticias.
  m.newsContainer = m.top.findNode("newsContainer")

  ' Referencia al sombreado difuminado izquierdo que se dibuja detrás del menú.
  m.leftBlurShade = m.top.findNode("leftBlurShade")

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
  ' Indica si el foco debe volver al NewsItem tras cerrar menú.
  m.returnFocusToNewsAfterMenu = false

  ' Define cuánto se eleva el primer carrusel para que se vea detrás/arriba del bloque News cuando News tiene foco.
  m.newsPeekOffset = scaleValue(200, m.scaleInfo)

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
    ' Si el foco está en NewsItem, permite bajar al primer carrusel navegable.
  if key = KeyButtons().DOWN and press and __isNewsFocused() then
    __focusFirstCarouselFromNews()
    handled = true
  else if key = KeyButtons().UP and press and __isFocusedCarouselAboveNews() then
    ' Si el carrusel actual tiene como foco superior a NewsItem, vuelve al hero de noticias.
    __focusNewsFromFirstCarousel()
    handled = true
  end if

  if handled then return true

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

  else if key = KeyButtons().LEFT and press and ( __isNewsFocused() or (m.carouselContainer <> invalid and m.carouselContainer.isInFocusChain()) ) then
    m.returnFocusToNewsAfterMenu = __isNewsFocused()
    m.myMenu.action = "expand"
    m.selectedIndicator.visible = false
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

    ' Define un ancho fijo de 450 escalado para el sombreado lateral izquierdo.
    leftShadeWidth = scaleValue(450, m.scaleInfo)
    ' Aplica el ancho calculado al sombreado difuminado.
    m.leftBlurShade.width = leftShadeWidth
    ' Extiende el sombreado al 100% de alto de pantalla.
    m.leftBlurShade.height = height
    ' Posiciona el sombreado en el borde izquierdo de la pantalla.
    m.leftBlurShade.translation = [0, 0]

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
    ' Ajusta tamaño y posición del overlay de News para mantenerlo arriba del carrusel de noticias.
    __layoutNewsOverlay()

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
     ' Prioriza foco inicial en NewsItem cuando existe; si no, mantiene foco en carouseles.
    if m.newsCarouselItem <> invalid then
      m.newsCarouselItem.setFocus(true)
    else
      m.carouselContainer.setFocus(true)
    end if
    __updateOverlayVisibilityByFocus()
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
  ' Referencia temporal al carrusel visual de noticias para ubicarlo siempre primero.
  newsCarouselItem = invalid

  ' Cache local de carouseles visibles para mapear carouselIndex -> carouselData.id al abrir ViewAll.
  m.carouselData = []

  __clearContentView()
  __clearProgramInfo()

  m.carouselContainer.translation = [scaleValue(55, m.scaleInfo), m.scaleInfo.safeZone.y + scaleValue(20, m.scaleInfo)]
  m.xPosition = m.carouselContainer.translation[0]
  m.yPosition = m.carouselContainer.translation[1]

  m.selectedIndicator.translation = [scaleValue(124, m.scaleInfo), m.scaleInfo.safeZone.y + scaleValue(148, m.scaleInfo)]

  ' Asegura que el contenedor de noticias quede anclado al origen absoluto de MainScreen.
  m.newsContainer.translation = [0, 0]

  for each carouselData in data.items
    if carouselData.style = getCarouselStyles().NEWS and newsCarouselItem = invalid then
      ' Crea una instancia del componente NewsItem para representar el carrusel tipo noticias.
      ' Crea el NewsItem dentro de un contenedor independiente para mantenerlo en (0,0).
      newsCarouselItem = m.newsContainer.createChild("NewsItem")
      ' Guarda referencia persistente al NewsItem para orquestar foco y visibilidad de overlays.
      m.newsCarouselItem = newsCarouselItem
      ' Asigna el conjunto de items de noticias recibido del servidor.
      newsCarouselItem.items = carouselData.items
      ' Setea un título fallback por si los items no traen title.
      newsCarouselItem.title = carouselData.title
      ' Fuerza que el bloque de noticias comience arriba de todo dentro del contenedor.
      newsCarouselItem.translation = [0, 0]
      ' Escucha cambios del índice de News para refrescar título y dots externos en MainScreen.
      newsCarouselItem.observeField("currentIndex", "onNewsStateChanged")
      ' Escucha cambios de items para reconstruir dots externos al recargar el carrusel de News.
      newsCarouselItem.observeField("items", "onNewsStateChanged")
      ' Escucha cambios del título fallback de News para reflejarlo en el overlay externo.
      newsCarouselItem.observeField("title", "onNewsStateChanged")
      ' Sincroniza inmediatamente el overlay externo con el estado inicial del News recién creado.
      __syncNewsOverlay()
      ' Reserva el primer bloque vertical para que los demás carruseles comiencen debajo de NewsItem.
      yPosition = int(m.scaleInfo.height * 0.7) + scaleValue(20, m.scaleInfo)
    end if
  end for


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

      ' Guardamos la referencia lógica para luego resolver carouselData[carouselIndex].id.
      m.carouselData.push(carouselData)
      
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

  ' Una vez creados todos los carouseles, establece el foco en el primer item del primer carousel.
  if m.carouselContainer.getChildCount() > 0 then
    ' Recorre hijos para encontrar el primer nodo Carousel con lista navegable.
    for i = 0 to m.carouselContainer.getChildCount() - 1
      ' Obtiene el hijo actual del contenedor para validar si tiene carouselList.
      firstCarousel = m.carouselContainer.getChild(i)
      ' Busca la lista interna del carrusel para darle foco inicial.
      firstList = firstCarousel.findNode("carouselList")
      ' Si encontró una lista válida y no hay diálogo de auto-upgrade, fija foco e indicador.
      if firstList <> invalid and m.autoUpgradeDialogOpen <> true then
        
        ' Conecta navegación: desde NewsItem se baja al primer carrusel y viceversa.
        if m.newsCarouselItem <> invalid then
          ' Permite subir desde el primer carrusel al NewsItem.
          firstCarousel.focusUp = m.newsCarouselItem
        end if

        ' Si existe NewsItem, prioriza su foco inicial al entrar en MainScreen.
        if m.newsCarouselItem <> invalid then
          m.newsCarouselItem.setFocus(true)
          __updateOverlayVisibilityByFocus()
        else
          ' Aplica el foco al primer carrusel navegable cuando no hay NewsItem.
          firstList.setFocus(true)
          ' Ajusta el tamaño del indicador según el carrusel enfocado.
          m.selectedIndicator.size = firstCarousel.size
          ' Muestra el indicador visual de selección.
          m.selectedIndicator.visible = true
          __updateOverlayVisibilityByFocus()
        end if

        ' Corta la búsqueda al encontrar el primer carrusel navegable.
        exit for
      end if
    end for
  end if

  nowDate = CreateObject("roDateTime")
  nowDate.ToLocalTime()

  m.lastRefreshDate = nowDate
end sub

' Toma la seleccion del item del carousel y dispara la validacion de si puede ver. 
sub onSelectItem()
  if m.carouselContainer <> invalid and m.carouselContainer.isInFocusChain() and m.carouselContainer.focusedChild <> invalid then
    m.itemSelected = ParseJson(m.carouselContainer.focusedChild.selected)
    m.top.openGuide = (m.itemSelected <> invalid and m.itemSelected.goToGuide = true)
    
    m.carouselContainer.focusedChild.selected = invalid

    if m.itemSelected <> invalid and m.itemSelected.goToGuide = true then
      __markLastFocus()
      m.top.loading.visible = true
      requestId = createRequestId()

      action = {
        apiRequestManager: m.apiRequestManager
        url: urlChannelsLastWatched(m.apiUrl)
        method: "GET"
        responseMethod: "onLastWatchedResponse"
        body: invalid
        token: invalid
        publicApi: false
        dataAux: invalid
        requestId: requestId
        run: function() as Object
          m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
          return { success: true, error: invalid }
        end function
      }

      runAction(requestId, action, ApiType().CLIENTS_API_URL)
      m.apiRequestManager = action.apiRequestManager
      return
    end if

    ' Si se selecciona la tarjeta "Ver todos", notificamos a MainScene para abrir ViewAllScreen.
    if m.itemSelected <> invalid and m.itemSelected.showSeeMore = true then
      __markLastFocus()
      m.top.loading.visible = true

      ' Obtenemos carouselId desde carouselData[carouselIndex].id como pide el flujo de Home -> ViewAll.
      carouselIndex = __getFocusedCarouselIndex()
      carouselId = invalid
      if carouselIndex <> invalid and m.carouselData <> invalid and carouselIndex >= 0 and carouselIndex < m.carouselData.count() and m.carouselData[carouselIndex] <> invalid then
        carouselId = m.carouselData[carouselIndex].id
      else if m.itemSelected.carouselId <> invalid then
        ' Fallback defensivo por si cambia la estructura del contenedor.
        carouselId = m.itemSelected.carouselId
      end if

      menuSelectedItemId = invalid
      if m.menuSelectedItem <> invalid and m.menuSelectedItem.id <> invalid then
        menuSelectedItemId = m.menuSelectedItem.id
      end if

      m.top.viewAll = FormatJson({
        menuSelectedItemId: menuSelectedItemId
        carouselId: carouselId
        carouselCode: m.itemSelected.carouselCode
        title: m.itemSelected.carouselTitle
      })
      return
    end if

    if m.itemSelected.redirectKey = "ChannelId" then

      if m.itemSelected.parentalControl <> invalid and m.itemSelected.parentalControl then
        __markLastFocus()
        m.pinDialog = createAndShowPINDialog(m.top, i18n_t(m.global.i18n, "shared.parentalControlModal.title"), "onPinDialogLoad", [i18n_t(m.global.i18n, "button.ok"), i18n_t(m.global.i18n, "button.cancel")])
      else 
        m.top.loading.visible = true
        watchSessionId = getWatchSessionId()

        requestId = createRequestId()

        action = {
          apiRequestManager: m.apiRequestManager
          url: urlWatchValidate(m.apiUrl, watchSessionId, m.itemSelected.redirectKey, m.itemSelected.redirectId)
          method: "GET"
          responseMethod: "onWatchValidateResponse"
          body: invalid
          token: invalid
          publicApi: false
          dataAux: invalid
          requestId: requestId
          run: function() as Object
            m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
            return { success: true, error: invalid }
          end function
        }
        
        runAction(requestId, action, ApiType().CLIENTS_API_URL)
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

' Busca el índice del carrusel que actualmente tiene foco para alinear con carouselData[carouselIndex].
function __getFocusedCarouselIndex() as dynamic
  if m.carouselContainer = invalid or m.carouselContainer.focusedChild = invalid then return invalid

  for index = 0 to m.carouselContainer.getChildCount() - 1
    if m.carouselContainer.getChild(index).id = m.carouselContainer.focusedChild.id then
      return index
    end if
  end for

  return invalid
end function

' Dispara la apertura del menu al llegar al limite izquierdo del carousel
sub onOpenMenuCarousel() 
  __markLastFocus()
  m.returnFocusToNewsAfterMenu = false
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
    __updateOverlayVisibilityByFocus()
  end if
end sub

' Procesa la respuesta al pedir el ultimo canal visto disparando la validacion si puede ver y navegando al player con la guia abierta.
sub onLastWatchedResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    removePendingAction(m.apiRequestManager.requestId)
    resp = ParseJson(m.apiRequestManager.response).data
    if (resp <> invalid) then 
      resp.key = "ChannelId"
      resp.redirectKey = "ChannelId"
      resp.redirectId = resp.id

      m.itemSelected = resp
      watchSessionId = getWatchSessionId()
      requestId = createRequestId()

      action = {
        apiRequestManager: m.apiRequestManager
        url: urlWatchValidate(m.apiUrl, watchSessionId.toStr(), resp.key, resp.id)
        method: "GET"
        responseMethod: "onWatchValidateResponse"
        body: invalid
        token: invalid
        publicApi: false
        dataAux: invalid
        requestId: requestId
        run: function() as Object
          m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
          return { success: true, error: invalid }
        end function
      }
      
      runAction(requestId, action, ApiType().CLIENTS_API_URL)
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
    m.top.loading.visible = false
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse    

    if m.apiRequestManager.serverError then
      __validateError(statusCode, 9000, errorResponse)
      changeStatusAction(m.apiRequestManager.requestId, "error")
      retryAll()
    else
      removePendingAction(m.apiRequestManager.requestId)
      m.top.openGuide = false
      
      if (statusCode = 408) then
        __markLastFocus() 
        m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
      else 
        __validateError(statusCode, 0, errorResponse)
      end if

      printError("LastWatched:", errorResponse)
    end if

    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
  end if
end sub

' Procesa la respuesta de si el ususario puede ver
sub onWatchValidateResponse()
  if m.apiRequestManager = invalid then
    onSelectItem()
    return
  else
    if validateStatusCode(m.apiRequestManager.statusCode) then
      resp = ParseJson(m.apiRequestManager.response).data

      if resp.resultCode = 200 then
        setWatchSessionId(resp.watchSessionId)
        setWatchToken(resp.watchToken)
        if m.itemSelected <> invalid then
          m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlStreaming(m.apiUrl, m.itemSelected.redirectKey, m.itemSelected.redirectId), "GET", "onStreamingsResponse")
        end if
      else 
        m.top.loading.visible = false
        m.apiRequestManager = clearApiRequest(m.apiRequestManager)
        
        __validateError(0, resp.resultCode, invalid)
        printError("WatchValidate ResultCode:", resp.resultCode)
      end if
    else 
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
  end if
end sub

' Procesa la respuesta al obtener la url de lo que se quiere ver
sub onStreamingsResponse() 
  if m.apiRequestManager = invalid then
    onWatchValidateResponse()
    return
  else
    if validateStatusCode(m.apiRequestManager.statusCode) then
      removePendingAction(m.apiRequestManager.requestId)
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
      m.top.loading.visible = false
      statusCode = m.apiRequestManager.statusCode
      errorResponse = m.apiRequestManager.errorResponse
      removePendingAction(m.apiRequestManager.requestId)
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)

      if m.apiRequestManager.serverError then
        __validateError(statusCode, 9000, errorResponse)
        changeStatusAction(m.apiRequestManager.requestId, "error")
        retryAll()
      else
        __markLastFocus()
        if (statusCode = 408) then 
          m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
        else 
          __validateError(statusCode, 0, errorResponse)
        end if
        printError("Streamings:",errorResponse)
      end if
    end if
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
  if m.itemfocused <> invalid and (m.itemfocused.showSeeMore = invalid or not m.itemfocused.showSeeMore) then
    if m.program <> invalid and m.program.infoKey = m.itemfocused.redirectKey and m.program.infoId = m.itemfocused.redirectId then 
      endTime = CreateObject("roDateTime")
      nowDate = CreateObject("roDateTime")
      
      endTime.FromISO8601String(m.program.endTime)
      endTime.ToLocalTime()

      nowDate.ToLocalTime()

      if not __isNewsFocused() and (m.program.infoKey <> "ChannelId") or (m.program.infoKey = "ChannelId" and endTime.AsSeconds() > nowDate.AsSeconds()) then 
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

    requestId = createRequestId()

    action = {
      apiSummaryRequestManager: m.apiSummaryRequestManager
      url: urlProgramSummary(m.apiUrl, m.itemfocused.redirectKey, m.itemfocused.redirectId, mainImageTypeId, getCarouselImagesTypes().SCENIC_LANDSCAPE)
      method: "GET"
      responseMethod: "onProgramSummaryResponse"
      body: invalid
      token: invalid
      publicApi: false
      dataAux: invalid
      requestId: requestId
      run: function() as Object
        m.apiSummaryRequestManager = sendApiRequest(m.apiSummaryRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    
    runAction(requestId, action, ApiType().CLIENTS_API_URL)
    m.apiSummaryRequestManager = action.apiSummaryRequestManager
   end if 
  catch error
    printError("Error al cargar la programa summary", error)
  end try
end sub

' Procesa la respuesta de la peticion del Summay del programa
sub onProgramSummaryResponse()
  if (m.apiSummaryRequestManager = invalid) then 
    getProgramInfo() 
  else
    if validateStatusCode(m.apiSummaryRequestManager.statusCode) and not __isNewsFocused() then
      m.itemfocused = invalid
      resp = ParseJson(m.apiSummaryRequestManager.response)
      if resp.data <> invalid then
        removePendingAction(m.apiSummaryRequestManager.requestId)
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
      statusCode = m.apiSummaryRequestManager.statusCode
      errorResponse = m.apiSummaryRequestManager.errorResponse    

      if m.apiSummaryRequestManager.serverError then
        __validateError(statusCode, 9000, errorResponse)
        changeStatusAction(m.apiSummaryRequestManager.requestId, "error")
        retryAll()
      else
        removePendingAction(m.apiSummaryRequestManager.requestId)
      
        printError("ProgramSumary:", errorResponse)
        if validateLogout(statusCode, m.top) then return 
          __clearProgramInfo()
          end if
      end if

      m.apiSummaryRequestManager = clearApiRequest(m.apiSummaryRequestManager)
    end if
end sub

' Procesa la respuesta de la peticion del menú
sub onMenuResponse()
  if m.apiRequestManager = invalid then
    __getMenu()
    return
  else  
    if validateStatusCode(m.apiRequestManager.statusCode) then
      removePendingAction(m.apiRequestManager.requestId)
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
      m.top.loading.visible = false
      error =  m.apiRequestManager.errorResponse
      statusCode =  m.apiRequestManager.statusCode

      if m.apiRequestManager.serverError then
        __validateError(statusCode, 9000, error)
        changeStatusAction(m.apiRequestManager.requestId, "error")
        retryAll()
      else
        removePendingAction(m.apiRequestManager.requestId)
      
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

      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    end if  
  end if
end sub

' Procesa la respuesta de la peticion de la vista de contenido
sub onContentViewResponse()

  if m.apiRequestManager = invalid then
    __selectMenuItem(m.menuSelectedItem)
    return
  else
    menuSelected = ParseJson(m.apiRequestManager.dataAux) 

    if validateStatusCode(m.apiRequestManager.statusCode) then
      resp = ParseJson(m.apiRequestManager.response)
      removePendingAction(m.apiRequestManager.requestId)
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

      if m.apiRequestManager.serverError then
        __validateError(statusCode, 9000, error)
        changeStatusAction(m.apiRequestManager.requestId, "error")
        retryAll()
      else
        removePendingAction(m.apiRequestManager.requestId)
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
  end if
end sub

' Se dispara la validacion del PIN cargado en el modal
sub onPinDialogLoad()
  resp = clearPINDialogAndGetOption(m.top, m.pinDialog)
  m.pinDialog = invalid

  requestId = createRequestId()
  
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
      requestId: requestId
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    
    runAction(requestId, action, ApiType().CLIENTS_API_URL)
    m.apiRequestManager = action.apiRequestManager
  else 
    __focusCarousels()
  end if 
end sub

' Procesa la respuesta de la validacion del PIN
sub onParentalControlResponse()
  if m.apiRequestManager = invalid then
    onPinDialogLoad()
    return
  else
    if validateStatusCode(m.apiRequestManager.statusCode) then
      resp = ParseJson(m.apiRequestManager.response)

      if resp <> invalid and resp.data <> invalid and resp.data then 
        removePendingAction(m.apiRequestManager.requestId)
        watchSessionId = getWatchSessionId()
        requestId = createRequestId()
        action = {
          apiRequestManager: m.apiRequestManager
          url: urlWatchValidate(m.apiUrl, watchSessionId, m.itemSelected.redirectKey, m.itemSelected.redirectId)
          method: "GET"
          responseMethod: "onWatchValidateResponse"
          body: invalid
          token: invalid
          publicApi: false
          dataAux: invalid
          requestId: requestId
          run: function() as Object
              m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
              return { success: true, error: invalid }
            end function
          }
          
          runAction(requestId, action, ApiType().CLIENTS_API_URL)
          m.apiRequestManager = action.apiRequestManager
        else
          m.top.loading.visible = false
          __markLastFocus() 
          m.dialog = createAndShowDialog(m.top, "", i18n_t(m.global.i18n, "shared.parentalControlModal.error.invalid"), "onDialogClosedFocusContainer")
      end if
    else     
      m.top.loading.visible = false
      statusCode = m.apiRequestManager.statusCode
      errorResponse = m.apiRequestManager.errorResponse
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)

      if m.apiRequestManager.serverError then
        __validateError(statusCode, 9000, errorResponse)
        changeStatusAction(m.apiRequestManager.requestId, "error")
        retryAll()
      else
        removePendingAction(m.apiRequestManager.requestId)

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
    end if
  end if
end sub

' Procesa la respuesta de la actualizacion las variables de plataforma 
sub onPlatformResponse()
  if m.apiVariableRequest = invalid then
    __validateVariables()
    return
  else
    if validateStatusCode(m.apiVariableRequest.statusCode) then
      removePendingAction(m.apiRequestManager.requestId)
      addAndSetFields(m.global, {variables: ParseJson(m.apiVariableRequest.response).data} )
      m.apiVariableRequest = clearApiRequest(m.apiVariableRequest)
      saveNextUpdateVariables()
    else
      if m.apiRequestManager.serverError then
        changeStatusAction(m.apiRequestManager.requestId, "error")
        retryAll()
      end if
      m.apiVariableRequest = clearApiRequest(m.apiVariableRequest)
    end if
  end if
end sub

' Dispara la peticion del pedido de los items del munú
sub __getMenu()
  requestId = createRequestId()

  action = {
    apiRequestManager: m.apiRequestManager
    url: urlMenu(m.apiUrl, m.productCode)
    method: "GET"
    responseMethod: "onMenuResponse"
    body: invalid
    token: invalid
    publicApi: false
    dataAux: invalid
    requestId: requestId
    run: function() as Object
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
      return { success: true, error: invalid }
    end function
  }
  
  runAction(requestId, action, ApiType().CLIENTS_API_URL)
  m.apiRequestManager = action.apiRequestManager
end sub

' Procesa el item seleccionado en el menú cerrandolo y disparando la accion pertinente (Redirigir a otra pantalla, recargar una vista, etc)
sub __selectMenuItem(menuSelectedItem)

  getNeedRefresh()
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

    else if menuSelectedItem.key = "MenuId" and menuSelectedItem.id = -1 and menuSelectedItem.code <> invalid and menuSelectedItem.code = "search" then
    ' Colapso el menu antes de navegar a la pantalla de búsqueda.
    m.myMenu.action = "collapse"
    ' Mantengo el indicador de selección visible para consistencia visual.
    m.selectedIndicator.visible = true
    ' Disparo la navegación a SearchScreen en MainScene.
    m.top.search = true

  else if menuSelectedItem.key = "ContentViewId" then
    if m.myMenu.action <> invalid and m.myMenu.action <> "" and m.myMenu.action <> "collapse" then m.myMenu.action = "collapse"
    if not m.top.loading.visible then m.top.loading.visible = true

    m.isHomeSelected = (menuSelectedItem.behavior <> invalid and menuSelectedItem.behavior = "home")

    ' Limpio el pedido de la Summary por si cambio la vista
    m.apiSummaryRequestManager = clearApiRequest(m.apiSummaryRequestManager)

    requestId = createRequestId()

    action = {
      apiRequestManager: m.apiRequestManager
      url: urlContentViewsCarousels(m.apiUrl, menuSelectedItem.id)
      method: "GET"
      responseMethod: "onContentViewResponse"
      body: invalid
      token: invalid
      publicApi: false
      requestId: requestId
      dataAux: FormatJson(menuSelectedItem)
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    
    runAction(requestId, action, ApiType().CLIENTS_API_URL)
    m.apiRequestManager = action.apiRequestManager

  else if menuSelectedItem.key = "MenuId" and menuSelectedItem.code <> invalid and menuSelectedItem.code = "epg" then
    m.top.openGuide = true
    
    m.myMenu.action = "collapse"
    __focusCarousels()

    m.top.loading.visible = true
    requestId = createRequestId()

    action = {
      apiRequestManager: m.apiRequestManager
      url: urlChannelsLastWatched(m.apiUrl)
      method: "GET"
      responseMethod: "onLastWatchedResponse"
      body: invalid
      token: invalid
      publicApi: false
      dataAux: invalid
      requestId: requestId
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    
    runAction(requestId, action, ApiType().CLIENTS_API_URL)
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
  ' Reinicia referencia al NewsItem para evitar foco a nodos eliminados.
  m.newsCarouselItem = invalid

  ' Limpia el contenedor dedicado de noticias para recrearlo desde cero.
  while m.newsContainer <> invalid and m.newsContainer.getChildCount() > 0
    ' Toma el NewsItem actual para desvincular su contenido.
    newsChild = m.newsContainer.getChild(0)
    ' Desuscribe observadores del índice para evitar callbacks colgantes tras remover NewsItem.
    newsChild.unobserveField("currentIndex")
    ' Desuscribe observadores de items para evitar callbacks colgantes tras remover NewsItem.
    newsChild.unobserveField("items")
    ' Desuscribe observadores del título para evitar callbacks colgantes tras remover NewsItem.
    newsChild.unobserveField("title")
    ' Resetea los items del NewsItem antes de removerlo.
    newsChild.items = invalid
    ' Remueve el NewsItem del contenedor de noticias.
    m.newsContainer.removeChild(newsChild)
  end while

  ' Limpia el título externo de News cuando se regenera la vista principal.
  if m.newsTitle <> invalid then m.newsTitle.text = ""
  ' Limpia dots externos de News para reconstruirlos con la siguiente carga.
  if m.dotsContainer <> invalid then m.dotsContainer.removeChildrenIndex(m.dotsContainer.getChildCount(), 0)

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

  if m.returnFocusToNewsAfterMenu and m.newsCarouselItem <> invalid then
    m.newsCarouselItem.setFocus(true)
    m.returnFocusToNewsAfterMenu = false
    __updateOverlayVisibilityByFocus()
    return
  end if

  if m.carouselContainer.getChildCount() > 0 then 
    m.selectedIndicator.visible = true
    if m.lastFocus <> invalid then m.lastFocus.setFocus(true)
  else
    m.carouselContainer.setFocus(true)
  end if
  __updateOverlayVisibilityByFocus()
end sub

' Indica si el foco actual está en el carrusel hero de noticias.
function __isNewsFocused() as boolean
  ' Valida que exista referencia al NewsItem.
  if m.newsCarouselItem = invalid then return false
  ' Retorna true cuando NewsItem participa en la cadena de foco activa.
  return m.newsCarouselItem.isInFocusChain()
end function

' Valida de forma segura si el foco actual está en el primer carrusel y su navegación UP apunta a News.
function __isFocusedCarouselAboveNews() as boolean
  if m.carouselContainer = invalid then return false ' Corta cuando el contenedor principal de carruseles no existe.
  if m.carouselContainer.isInFocusChain() <> true then return false ' Corta cuando la cadena de foco no está dentro de carruseles.
  focusedCarousel = m.carouselContainer.focusedChild ' Toma el carrusel enfocado para evaluar su destino en UP.
  if focusedCarousel = invalid then return false ' Corta cuando no hay hijo enfocado.
  focusUpNode = focusedCarousel.focusUp ' Lee el nodo destino de navegación hacia arriba.
  if focusUpNode = invalid then return false ' Corta cuando no existe destino superior.
  if m.newsCarouselItem = invalid then return false ' Corta cuando no existe referencia al NewsItem.
  if type(focusUpNode) <> "roSGNode" then return false ' Evita excepción por comparar tipos incompatibles o valores no nodo.
  return focusUpNode.subtype() = m.newsCarouselItem.subtype() ' Compara por subtipo para detectar NewsItem sin comparar referencias de distinto tipo.
end function

' Mueve el foco desde NewsItem al primer carrusel navegable cuando el usuario presiona DOWN.
sub __focusFirstCarouselFromNews()
  ' Recorre carruseles para ubicar el primer carouselList habilitado.
  if m.carouselContainer = invalid then return
  for i = 0 to m.carouselContainer.getChildCount() - 1
    carouselNode = m.carouselContainer.getChild(i)
    carouselList = carouselNode.findNode("carouselList")
    if carouselList <> invalid then
      m.newsContainer.translation = [0, -(carouselNode.translation[1] - m.yPosition)] ' Aplica desplazamiento vertical del hero de noticias para mantener la misma animación que el resto.
      m.newsCarouselItem.opacity = "0.0" ' Replica la lógica de opacidad usada al navegar entre carruseles estándar con DOWN ocultando el carrusel actual (News).
      carouselList.setFocus(true) ' Posiciona el foco en el primer carrusel navegable debajo de News.
      m.carouselContainer.translation = [m.xPosition, -(carouselNode.translation[1] - m.yPosition)] ' Sincroniza la traslación del contenedor de carruseles con el mismo patrón de animación.
      m.selectedIndicator.size = carouselNode.size ' Ajusta el tamaño del indicador al carrusel que tomó foco.
      m.programInfo.visible = true ' Fuerza la visibilidad del resumen cuando se sale del carrusel de News.
      m.selectedIndicator.visible = true ' Fuerza la visibilidad del indicador cuando el foco entra a carruseles estándar.
      __updateOverlayVisibilityByFocus() ' Revalida el estado final de overlays según la cadena de foco actual.
      return
    end if
  end for
end sub

' Mueve el foco desde el primer carrusel no-News hacia NewsItem conservando animación y overlays esperados.
sub __focusNewsFromFirstCarousel()
  if m.newsCarouselItem = invalid then return ' Evita procesar si el NewsItem no existe.
  if m.carouselContainer = invalid then return ' Evita procesar si el contenedor de carruseles no está disponible.
  focusedCarousel = m.carouselContainer.focusedChild ' Toma referencia al carrusel actualmente enfocado para calcular desplazamientos.
  if focusedCarousel = invalid then return ' Evita errores si no existe un hijo enfocado.
  if focusedCarousel.focusUp <> invalid then focusedCarousel.focusUp.opacity = "1.0" ' Restaura opacidad del nodo superior replicando la navegación vertical estándar.
  m.newsContainer.translation = [0, 0] ' Devuelve el bloque de noticias a su posición base con la misma transición visual.
  m.carouselContainer.translation = [m.xPosition, m.yPosition] ' Reestablece el contenedor de carruseles a su origen como al inicio de Home.
  m.newsCarouselItem.setFocus(true) ' Posiciona foco en el carrusel de News al presionar UP en el primer carrusel no-News.
  m.programInfo.visible = false ' Oculta programInfo cuando el foco vuelve al hero de noticias.
  m.selectedIndicator.visible = false ' Oculta selectedIndicator cuando el foco vuelve al hero de noticias.
  __updateOverlayVisibilityByFocus() ' Mantiene centralizada la regla final de visibilidad según foco.
end sub

' Alterna visibilidad de ProgramInfo y SelectedIndicator según foco en NewsItem.
sub __updateOverlayVisibilityByFocus()
  ' Si el foco está en NewsItem, se ocultan overlays superiores del listado.
  if __isNewsFocused() then
    ' Busca el primer carrusel no-News para calcular el desplazamiento visual mientras News mantiene el foco.
    firstCarousel = __getFirstNonNewsCarousel()
    ' Aplica elevación solo si existe al menos un carrusel no-News para mostrarlo parcialmente sobre News.
    if firstCarousel <> invalid then m.carouselContainer.translation = [m.xPosition, m.yPosition - m.newsPeekOffset]
    m.programInfo.visible = false
    m.selectedIndicator.visible = false
  else
    ' Si el foco salió de NewsItem, vuelve a mostrar overlays contextuales.
    m.programInfo.visible = true
    if m.carouselContainer <> invalid and m.carouselContainer.focusedChild <> invalid then
      m.selectedIndicator.visible = true
    end if
  end if
end sub

' Devuelve la primera instancia de Carousel (no-News) para usarla como referencia visual del peek sobre News.
function __getFirstNonNewsCarousel() as dynamic
  ' Corta si el contenedor no está listo para evitar excepciones.
  if m.carouselContainer = invalid then return invalid
  ' Corta si no hay hijos porque no existe ningún carrusel disponible.
  if m.carouselContainer.getChildCount() = 0 then return invalid
  ' Retorna el primer hijo porque populateCarousels agrega únicamente carruseles no-News en este contenedor.
  return m.carouselContainer.getChild(0)
end function

' Reacciona a cambios de estado del carrusel News para actualizar overlay externo en MainScreen.
sub onNewsStateChanged()
  ' Sincroniza título y dots externos cada vez que cambia índice o dataset de News.
  __syncNewsOverlay()
end sub

' Calcula layout responsivo del título y dots de News en el overlay externo.
sub __layoutNewsOverlay()
  ' Sale temprano si el título externo todavía no fue creado en el XML.
  if m.newsTitle = invalid then return
  ' Sale temprano si el contenedor de dots externo todavía no fue creado en el XML.
  if m.dotsContainer = invalid then return
  ' Toma ancho de pantalla escalado para usarlo como base de layout.
  screenWidth = m.scaleInfo.width
  ' Toma alto de pantalla escalado para usarlo como base de layout.
  screenHeight = m.scaleInfo.height
  ' Configura ancho máximo del título para conservar la misma jerarquía visual del hero.
  m.newsTitle.width = scaleValue(int(screenWidth * 0.72), m.scaleInfo)
  ' Configura alto máximo del título para permitir hasta tres líneas sin recorte.
  m.newsTitle.height = scaleValue(int(screenHeight * 0.30), m.scaleInfo)
  ' Posiciona el título un poco más arriba de los carruseles y encima del hero de News.
  m.newsTitle.translation = scaleSize([150, 0], m.scaleInfo)
  ' Escala el título para mantener la presencia visual previa del NewsItem original.
  m.newsTitle.scale = [1.7, 1.7]
  ' Ajusta ancho del contenedor de dots al 100% del ancho de la pantalla.
  m.dotsContainer.width = screenWidth
  ' Posiciona los dots por encima del inicio de carruseles, siempre encima del hero de News.
  m.dotsContainer.translation = scaleSize([600, 550], m.scaleInfo)
end sub

' Sincroniza título y dots del overlay externo usando el estado actual del NewsItem.
sub __syncNewsOverlay()
  ' Sale si el título externo no existe para evitar errores cuando el árbol aún no está montado.
  if m.newsTitle = invalid then return
  ' Sale si el contenedor de dots externo no existe para evitar errores cuando el árbol aún no está montado.
  if m.dotsContainer = invalid then return
  ' Limpia dots previos para reconstruir el estado actual del carrusel News.
  m.dotsContainer.removeChildrenIndex(m.dotsContainer.getChildCount(), 0)
  ' Si no hay NewsItem activo, limpia título y termina.
  if m.newsCarouselItem = invalid then
    ' Borra el título externo cuando no existe carrusel de News activo.
    m.newsTitle.text = ""
    ' Termina porque no hay datos para renderizar.
    return
  end if
  ' Obtiene el arreglo de noticias actual desde el NewsItem activo.
  newsItems = m.newsCarouselItem.items
  ' Toma el índice activo del NewsItem para activar el dot correcto.
  currentIndex = m.newsCarouselItem.currentIndex
  ' Inicializa fallback con el título general del carrusel para cuando la noticia no tenga título.
  currentTitle = m.newsCarouselItem.title
  ' Valida que exista dataset antes de leer noticia activa.
  if newsItems <> invalid and newsItems.count() > 0 and currentIndex >= 0 and currentIndex < newsItems.count() then
    ' Lee la noticia activa en base al índice actual del carrusel.
    currentNewsItem = newsItems[currentIndex]
    ' Prioriza título de la noticia activa cuando existe y no está vacío.
    if currentNewsItem <> invalid and currentNewsItem.title <> invalid and currentNewsItem.title <> "" then currentTitle = currentNewsItem.title
    ' Recorre noticias para dibujar dots externos y resaltar el índice activo.
    for i = 0 to newsItems.count() - 1
      ' Crea un dot circular reutilizando el asset compartido del proyecto.
      dot = createObject("roSGNode", "Poster")
      ' Define ancho del dot externo para mantener consistencia con el diseño original.
      dot.width = 12
      ' Define alto del dot externo para mantener consistencia con el diseño original.
      dot.height = 12
      ' Asigna el recurso circular usado como indicador de paginación.
      dot.uri = "pkg:/images/shared/ball.png"
      ' Marca dot activo con opacidad plena para indicar la noticia seleccionada.
      if i = currentIndex then
        ' Opacidad máxima para el dot activo.
        dot.opacity = 1.0
      else
        ' Opacidad reducida para dots inactivos.
        dot.opacity = 0.45
      end if
      ' Inserta el dot en el contenedor externo de indicadores.
      m.dotsContainer.appendChild(dot)
    end for
  end if
  ' Actualiza el título externo con la noticia activa o fallback del carrusel.
  m.newsTitle.text = currentTitle
end sub


' Actualiza el indicador de seleccion segun el carrusel enfocado
sub __updateSelectedIndicator()
  if m.carouselContainer <> invalid and m.carouselContainer.focusedChild <> invalid and not __isNewsFocused() then
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
  requestId = createRequestId()

  action = {
    apiRequestManager: m.autoUpgradeRequestManager
    url: urlAutoUpgradeValidate(m.apiUrl)
    method: "POST"
    responseMethod: "onAutoUpgradeResponse"
    body: FormatJson(body)
    token: invalid
    publicApi: false
    dataAux: invalid
    requestId: requestId
    run: function() as Object
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
      return { success: true, error: invalid }
    end function
  }
  
  runAction(requestId, action, ApiType().CLIENTS_API_URL)
  m.autoUpgradeRequestManager = action.apiRequestManager
end sub

' Procesa la respuesta del AutoUpgrade
sub onAutoUpgradeResponse()
  if validateStatusCode(m.autoUpgradeRequestManager.statusCode) then
    if m.apiRequestManager <> invalid then removePendingAction(m.apiRequestManager.requestId)
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
    removePendingAction(m.apiRequestManager.requestId)
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
    requestId = createRequestId()

    action = {
      apiRequestManager: m.apiVariableRequest
      url: urlPlatformsVariables(m.apiUrl, m.global.appCode, getVersionCode())
      method: "GET"
      responseMethod: "onPlatformResponse"
      body: invalid
      token: invalid
      publicApi: false
      dataAux: invalid
      requestId: requestId
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    
    runAction(requestId, action, ApiType().CLIENTS_API_URL)
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

' Guarda el ultimo utem que a tenido foco en los carouseles en la variable lastFocus
sub __markLastFocus()
  if m.carouselContainer.focusedChild <> invalid and  m.carouselContainer.focusedChild.findNode("carouselList") <> invalid then 
    m.lastFocus = m.carouselContainer.focusedChild.findNode("carouselList")
  end if
end sub

' Guardar el log cuandos se cambia una opción del menú 
sub __saveActionLog(actionLog as object)

  if beaconTokenExpired() and m.apiUrl <> invalid then
    requestId = createRequestId()

    action = {
      apiRequestManager: m.apiLogRequestManager
      url: urlActionLogsToken(m.apiUrl)
      method: "GET"
      responseMethod: "onActionLogTokenResponse"
      body: invalid
      token: invalid
      publicApi: false
      requestId: requestId
      dataAux: FormatJson(actionLog)
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    
    runAction(requestId, action, ApiType().LOGS_API_URL)
    m.apiLogRequestManager = action.apiRequestManager
  else
      __sendActionLog(actionLog)
  end if
end sub

' Obtener el beacon token
sub onActionLogTokenResponse() 

  if not m.apiLogRequestManager.serverError then
    resp = ParseJson(m.apiLogRequestManager.response)
    actionLog = ParseJson(m.apiLogRequestManager.dataAux)

    setBeaconToken(resp.actionsLogToken)

    now = CreateObject("roDateTime")
    now.ToLocalTime()
    m.global.beaconTokenExpiresIn = now.asSeconds() + ((resp.expiresIn - 60) * 1000)

    m.apiLogRequestManager = clearApiRequest(m.apiLogRequestManager) 
    __sendActionLog(actionLog)
  end if
end sub

' Llamar al servicio para guardar el log
sub __sendActionLog(actionLog as object)
  beaconToken = getBeaconToken()

  requestId = createRequestId()

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
      requestId: requestId
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    
    runAction(requestId, action, ApiType().LOGS_API_URL)
    m.apiLogRequestManager = action.apiRequestManager
  end if
end sub

' Limpiar la llamada del log
sub onActionLogResponse() 
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