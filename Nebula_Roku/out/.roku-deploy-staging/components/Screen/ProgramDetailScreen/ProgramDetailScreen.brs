' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
  m.programDetailContent = m.top.findNode("programDetailContent")
  
  m.notFoundLayoutGroup = m.top.findNode("notFoundLayoutGroup")
  m.notFoundTitle = m.top.findNode("notFoundTitle")
  m.programImageGroup = m.top.findNode("programImageGroup")

  m.programInfo = m.top.findNode("programInfo")
  m.programImage = m.top.findNode("programImage")

  m.programTitleContainerByError = m.top.findNode("programTitleContainerByError")
  m.programTitleError = m.top.findNode("programTitleError")

  m.actionsBtn = m.top.findNode("actionsBtn")
  m.creditsContainer = m.top.findNode("creditsContainer")
  
  m.relatedContainer = m.top.findNode("relatedContainer")
  m.selectedIndicator = m.top.findNode("selectedIndicator")
  m.related = m.top.findNode("related")
  m.isOpenEmissions = false

  m.infoGradient = m.top.findNode("infoGradient")
  m.programImageBackground = m.top.findNode("programImageBackground")

  m.scaleInfo = m.global.scaleInfo

  m.programImage.ObserveField("loadStatus", "onStatusChange")
  
  m.lastKey = invalid
  m.lastId = invalid

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

  if m.actionsBtn.isInFocusChain() then 
    if key = KeyButtons().OK then
      if press then 
        if m.actionsBtn.focusedChild <> invalid and m.actionsBtn.focusedChild.id = "btnPlay" then 
          m.lastButtonSelect = m.actionsBtn.focusedChild
          __openPlayer(getStreamingAction().PLAY)
        else if m.actionsBtn.focusedChild <> invalid and m.actionsBtn.focusedChild.id = "btnRestart" then 
          m.lastButtonSelect = m.actionsBtn.focusedChild
          __openPlayer(getStreamingAction().RESTART)
        else if m.actionsBtn.focusedChild <> invalid and m.actionsBtn.focusedChild.id = "btnContinue" then 
          m.lastButtonSelect = m.actionsBtn.focusedChild
          __openPlayer(getStreamingAction().CONTINUE)
        else if m.actionsBtn.focusedChild <> invalid and m.actionsBtn.focusedChild.id = "btnEmissions" then 
          m.lastButtonSelect = m.actionsBtn.focusedChild
          __openEmissions()
        else if m.actionsBtn.focusedChild <> invalid and m.actionsBtn.focusedChild.id = "btnBack" then 
          __goToBack()
        end if
      end if
      handled = true

    else if key = KeyButtons().RIGHT then
      if press then
        if m.actionsBtn.focusedChild <> invalid and m.actionsBtn.focusedChild.focusRight <> invalid then
          m.actionsBtn.focusedChild.focusRight.setFocus(true)
        end if
      end if
      handled = true
  
    else if key = KeyButtons().LEFT then
      if press then
        if m.actionsBtn.focusedChild <> invalid and m.actionsBtn.focusedChild.focusLeft <> invalid then
          m.actionsBtn.focusedChild.focusLeft.setFocus(true)
        end if
      end if
      handled = true
    
    else if key = KeyButtons().DOWN 
      if press and m.relatedContainer.visible then       
        if m.actionsBtn.focusedChild <> invalid then m.lastButtonSelect = m.actionsBtn.focusedChild
 
        m.related.findNode("carouselList").setFocus(true)
        m.selectedIndicator.size = m.related.size
        m.selectedIndicator.visible = true
      end if

      handled = true
    else if key = KeyButtons().UP then
      handled = true
    end if

  else if key = KeyButtons().UP then
    if press and m.related.isInFocusChain() and m.lastButtonSelect <> invalid then 
      m.lastButtonSelect.setFocus(true)
      m.selectedIndicator.visible = false
    end if

    handled = true
  else if m.related.isInFocusChain() and key = KeyButtons().DOWN then 
    handled = true
  end if

  return handled
end function 

' Carga los datos de componente, si no recibe datos o los recibe vacios entonces dispara la limpieza del componete
sub initData()
  if m.top.data <> invalid and m.top.data <> "" then 
    __configProgramDetail()

    if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL) 
    if m.beaconUrl = invalid then m.beaconUrl = getConfigVariable(m.global.configVariablesKeys.BEACON_URL) 

    data = ParseJson(m.top.data)
    __getProgramDetail(data.redirectKey, data.redirectId)
  else
    _clearScreen()
  end if
end sub

' Inicializa el foco del componente seteando los valores necesarios
sub initFocus()
  if m.top.onFocus then
    __applyTranslations()
    if m.program <> invalid then 
      if not m.isOpenEmissions then 
        requestId = createRequestId()

        action = {
          apiRequestManager: m.apiRequestManager
          url: urlProgramAction(m.apiUrl, m.program.key, m.program.id)
          method: "GET"
          responseMethod: "onActionsResponse"
          body: invalid
          token: invalid
          publicApi: false
          requestId: requestId
          dataAux: invalid
          run: function() as Object
            m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
            return { success: true, error: invalid }
          end function
        }
        
        runAction(requestId, action, ApiType().CLIENTS_API_URL)
        m.apiRequestManager = action.apiRequestManager
      else
        m.isOpenEmissions = false
        if m.lastButtonSelect <> invalid then m.lastButtonSelect.setFocus(true)
      end if 
    end if
  end if 
end sub

' Procesa la respuesta al obtener la informacion completa del programa
sub onGetByIdResponse() 
  if m.apiRequestManager then
    __getProgramDetail(m.lastKey, m.lastId)
    return
  else
    if validateStatusCode(m.apiRequestManager.statusCode) then
      removePendingAction(m.apiRequestManager.requestId)
      resp = ParseJson(m.apiRequestManager.response)
      m.apiRequestManager = clearApiRequest(m.apiRequestManager) 

      if resp.data <> invalid then
        m.top.loading.visible = false
        __loadProgramInfo(resp.data)
      else
        __showNotFound()
        m.top.loading.visible = false
      end if 
    else
      m.top.loading.visible = false

      error = m.apiRequestManager.errorResponse
      statusCode = m.apiRequestManager.statusCode

      if m.apiRequestManager.serverError then
        changeStatusAction(m.apiRequestManager.requestId, "error")
        retryAll()
      else
        removePendingAction(m.apiRequestManager.requestId)
        
        printError("ProgramSumary:", error)
      
        if validateLogout(statusCode, m.top) then return 

        if (statusCode = 408) or (statusCode = 500) then 
          m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogReloadDetailClosed", [i18n_t(m.global.i18n, "button.retry"), i18n_t(m.global.i18n, "button.back")])
        else if (statusCode = 404) then
          __showNotFound()
        else
          __validateError(statusCode, 0, error, __showNotFound())
        end if
      
        actionLog = createLogError(generateErrorDescription(error), generateErrorPageUrl("getDetail", "ProgramComponent"), getServerErrorStack(error), m.lastKey, m.lastId)
        __saveActionLog(actionLog)
      end if
      m.apiRequestManager = clearApiRequest(m.apiRequestManager) 
    end if
  end if
end sub

' Procesa la respuesta al obtener la acciones disposnibles para el programa actual
sub onActionsResponse()
  if m.apiRequestManager = invalid then
    initFocus()
    return
  else 
    if validateStatusCode(m.apiRequestManager.statusCode) then
      removePendingAction(m.apiRequestManager.requestId)
      m.lastButtonSelect = invalid
      resp = ParseJson(m.apiRequestManager.response)
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)

      __clearButtons()
      if resp.data <> invalid then
        m.program.actions = resp.data 
        __processActions()
        m.top.loading.visible = false
      end if 
    else
      m.top.loading.visible = false
      statusCode = m.apiRequestManager.statusCode
      errorResponse = m.apiRequestManager.errorResponse

      if m.apiRequestManager.serverError then
        changeStatusAction(m.apiRequestManager.requestId, "error")
        retryAll()
      else
        removePendingAction(m.apiRequestManager.requestId)
        
        if m.lastButtonSelect <> invalid then
          m.lastButtonSelect.setFocus(true)
          m.lastButtonSelect = invalid
        end if 
        
        printError("Actions:", errorResponse)

        if validateLogout(statusCode, m.top) then return 
      end if
      m.apiRequestManager = clearApiRequest(m.apiRequestManager) 
    end if
  end if
end sub

' Procesa la respuesta de si el ususario puede ver
sub onWatchValidateResponse()
  if m.apiRequestManager = invalid then
    onParentalControlResponse()
    return
  else
    if validateStatusCode(m.apiRequestManager.statusCode) then
      removePendingAction(m.apiRequestManager.requestId)
      resp = ParseJson(m.apiRequestManager.response).data
      m.apiRequestManager = clearApiRequest(m.apiRequestManager) 

      if resp.resultCode = 200 then
        setWatchSessionId(resp.watchSessionId)
        setWatchToken(resp.watchToken)
        if m.program <> invalid then
          if m.streamingAction = invalid then m.streamingAction = getStreamingAction().PLAY
          requestId = createRequestId()

          action = {
            apiRequestManager: m.apiRequestManager
            url: urlStreaming(m.apiUrl, m.program.key, m.program.id, m.streamingAction)
            method: "GET"
            responseMethod: "onStreamingsResponse"
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
          
          runAction(requestId, action, ApiType().CLIENTS_API_URL)
          m.apiRequestManager = action.apiRequestManager
        end if
      else
        m.top.loading.visible = false

        if m.apiRequestManager.serverError then
          changeStatusAction(m.apiRequestManager.requestId, "error")
          retryAll()
        else
          removePendingAction(m.apiRequestManager.requestId)        
          
          __validateError(0, resp.resultCode, invalid)
          printError("WatchValidate ResultCode:", resp.resultCode)
        end if
        m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      end if
    else 
      if m.apiRequestManager.serverError then
        changeStatusAction(m.apiRequestManager.requestId, "error")
        retryAll()
      else
        m.top.loading.visible = false
        statusCode = m.apiRequestManager.statusCode
        errorResponse = m.apiRequestManager.errorResponse
        
        if (statusCode = 408) then
          m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
        else 
          __validateError(statusCode, 0, errorResponse)
        end if

        printError("WatchValidate Stastus:", statusCode.toStr() + " " +  errorResponse)
      end if

      m.apiRequestManager = clearApiRequest(m.apiRequestManager) 
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
        streaming = resp.data
        streaming.key = m.program.key 
        streaming.id = m.program.id
        streaming.streamingType = getStreamingType().DEFAULT
        m.top.streaming = FormatJson(streaming)
      else
        m.top.loading.visible = false
        printError("Streamings Emty:", m.apiRequestManager.response)
        m.apiRequestManager = clearApiRequest(m.apiRequestManager) 
        m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
      end if
    else 
      m.top.loading.visible = false
      statusCode = m.apiRequestManager.statusCode
      errorResponse = m.apiRequestManager.errorResponse

      if m.apiRequestManager.serverError then
        changeStatusAction(m.apiRequestManager.requestId, "error")
        retryAll()
      else
        removePendingAction(m.apiRequestManager.requestId)      

        if (statusCode = 408) then
          m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
        else 
          __validateError(statusCode, 0, errorResponse)
        end if

        printError("Streamings:",errorResponse)
      end if
      m.apiRequestManager = clearApiRequest(m.apiRequestManager) 
    end if
  end if
end sub

' Dispara la seleccion del item del carousel de relacioandos 
sub onSelectItem()
  if m.related <> invalid and m.related.isInFocusChain() then
    itemSelected = ParseJson(m.related.selected)
    m.related.selected = invalid
    _clearScreen()
    m.top.loading.visible = true
    __getProgramDetail(itemSelected.redirectKey, itemSelected.redirectId)
  end if
end sub

' Se dispara cuando ocurre un cambio de evento al cargar una imagen y define que hacer.
sub onStatusChange()
  if m.programImage.visible = true and ((m.programImage.loadStatus = "failed") or (m.programImage.loadStatus = "none")) then 
    m.programTitleContainerByError.visible = true
    m.programImage.uri = getImageError()
  end if 
end sub

' Procesa la respuesta de programas relacionados al programa actual
sub onGetRelatedResponse()
  if m.apiRequestManager = invalid then
    return
  else
    if validateStatusCode(m.apiRequestManager.statusCode) then
      removePendingAction(m.apiRequestManager.requestId)
      resp = ParseJson(m.apiRequestManager.response)
      m.apiRequestManager = clearApiRequest(m.apiRequestManager) 
      
      if resp.data <> invalid then
        m.top.loading.visible = false
        __loadRelatedCarousel(resp.data)
      end if 
    else
      statusCode = m.apiRequestManager.statusCode
      errorResponse = m.apiRequestManager.errorResponse

      if m.apiRequestManager.serverError then
        changeStatusAction(m.apiRequestManager.requestId, "error")
        retryAll()
      else
        removePendingAction(m.apiRequestManager.requestId)
        
        if validateLogout(statusCode, m.top) then return 

        printError("Related:",errorResponse)
      end if
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    end if
  end if
end sub

' Hace foco en objeto que lo tenia antes de que se abriera el modal
sub onDialogClosedLastFocus()
  option = clearDialogAndGetOption(m.top, m.dialog)
  m.dialog = invalid
  
  if option = 0 then
    if m.lastButtonSelect <> invalid then m.lastButtonSelect.setFocus(true)
  end if
end sub

' Procesa el cierre del modal al fallar la peticion
sub onDialogReloadDetailClosed()
  option = clearDialogAndGetOption(m.top, m.dialog)
  m.dialog = invalid
  
  if option = 0 then
    __getProgramDetail(m.lastKey, m.lastId)
  else
    __goToBack()
  end if
end sub

' Dispara el evento de deslogueo
sub onLogoutChange()
  if m.top.logout then _clearScreen()
end sub

' Se dispara la validacion del PIN cargado en el modal
sub onPinDialogLoad()
  resp = clearPINDialogAndGetOption(m.top, m.pinDialog)
  m.pinDialog = invalid
  
  if (resp.option = 0 and resp.pin <> invalid and Len(resp.pin) = 4) then 
    m.top.loading.visible = true
    requestId = createRequestId()

     action = {
      apiRequestManager: m.apiRequestManager
      url: urlParentalControlPin(m.apiUrl, resp.pin)
      method: "GET"
      responseMethod: "onParentalControlResponse"
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
    
    runAction(requestId, action, ApiType().CLIENTS_API_URL)
    m.apiRequestManager = action.apiRequestManager
  else 
    if m.lastButtonSelect <> invalid then m.lastButtonSelect.setFocus(true)
  end if 
end sub

' Procesa la respuesta de la validacion del PIN
sub onParentalControlResponse()
  if m.apiRequestManager = invalid then
    onPinDialogLoad()
    return
  else 
    if validateStatusCode(m.apiRequestManager.statusCode) then
      removePendingAction(m.apiRequestManager.requestId)
      resp = ParseJson(m.apiRequestManager.response)

      if resp <> invalid and resp.data <> invalid and resp.data then
        if m.top.isOpenByPlayer then
          m.top.loading.visible = false
          streamingAction = getStreamingAction().PLAY
          
          if m.streamingAction <> invalid then streamingAction = m.streamingAction
          
          m.program.streamingAction = streamingAction
          m.top.programOpenInPlayer = FormatJson(m.program)
        else
          m.top.loading.visible = true
          watchSessionId = getWatchSessionId()
          requestId = createRequestId()

          action = {
            apiRequestManager: m.apiRequestManager
            url: urlWatchValidate(m.apiUrl, watchSessionId, m.program.key, m.program.id)
            method: "GET"
            responseMethod: "onWatchValidateResponse"
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
          
          runAction(requestId, action, ApiType().CLIENTS_API_URL)
          m.apiRequestManager = action.apiRequestManager
        end if
      else
        m.top.loading.visible = false
        m.dialog = createAndShowDialog(m.top, "", i18n_t(m.global.i18n, "shared.parentalControlModal.error.invalid"), "onDialogClosedLastFocus")
      end if
    else     
      m.top.loading.visible = false
      statusCode = m.apiRequestManager.statusCode
      errorResponse = m.apiRequestManager.errorResponse

      if m.apiRequestManager.serverError then
        changeStatusAction(m.apiRequestManager.requestId, "error")
        retryAll()
      else
        removePendingAction(m.apiRequestManager.requestId)
        
        if (statusCode = 408) then
          m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
        else 
          __validateError(statusCode, 0, errorResponse)
        end if

        printError("ParentalControl:", statusCode.toStr() + " " +  errorResponse)
      end if
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    end if
  end if
end sub

' Dispara el retroceso del componente
sub __goToBack()
  m.top.onBack = true
end sub

' Limpia el contenedor de los botones
sub __clearButtons()
  while m.actionsBtn.getChildCount() > 0
    child = m.actionsBtn.getChild(0)
    child.focusLeft = invalid
    child.focusRight = invalid
    m.actionsBtn.removeChild(child)
  end while
end sub

' Dispara la busqueda de la infromacion de un programa 
sub __getProgramDetail(key, id)
  m.lastKey = key
  m.lastId = id
  requestId = createRequestId()

  action = {
    apiRequestManager: m.apiRequestManager
    url: urlProgramById(m.apiUrl, m.lastKey, m.lastId, getCarouselImagesTypes().POSTER_PORTRAIT, getCarouselImagesTypes().SCENIC_LANDSCAPE)
    method: "GET"
    responseMethod: "onGetByIdResponse"
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
  
  runAction(requestId,action, ApiType().CLIENTS_API_URL)
  m.apiRequestManager = action.apiRequestManager
end sub

' Crea y define cada uno de los botones en base a las acciones disponibles para el programa
sub __processActions()
  focusElement = invalid
  lastBtnCreate = invalid
  buttonSize = [ scaleValue(150, m.scaleInfo),  scaleValue(40, m.scaleInfo)]

  if m.program.actions <> invalid then
    if  m.program.actions.play <> invalid and m.program.actions.play then 
      btnPlay = m.actionsBtn.createChild("QvButton")
      btnPlay.id = "btnPlay"
      btnPlay.text =  i18n_t(m.global.i18n, "programDetail.button.watch")
      btnPlay.focusable = true
      btnPlay.size = buttonSize
      lastBtnCreate = btnPlay 
      if focusElement = invalid then focusElement = btnPlay
    end if

    if  m.program.actions.continue <> invalid and m.program.actions.continue then 
      btnContinue = m.actionsBtn.createChild("QvButton")
      btnContinue.id = "btnContinue"
      btnContinue.text = i18n_t(m.global.i18n, "programDetail.button.continue")
      btnContinue.focusable = true
      btnContinue.size = buttonSize
      if lastBtnCreate <> invalid then 
        lastBtnCreate.focusRight = btnContinue
        btnContinue.focusLeft = lastBtnCreate
      end if
      lastBtnCreate = btnContinue 
      if focusElement = invalid then focusElement = btnContinue
    end if

    if  m.program.actions.restart <> invalid and m.program.actions.restart then 
      btnRestart = m.actionsBtn.createChild("QvButton")
      btnRestart.id = "btnRestart"
      btnRestart.text = i18n_t(m.global.i18n, "programDetail.button.restart")
      btnRestart.focusable = true
      btnRestart.size = buttonSize
      if lastBtnCreate <> invalid then 
        lastBtnCreate.focusRight = btnRestart
        btnRestart.focusLeft = lastBtnCreate
      end if
      lastBtnCreate = btnRestart 

      if focusElement = invalid then focusElement = btnRestart
    end if

    ' if  m.program.actions.emissions <> invalid and m.program.actions.emissions then 
    '   btnEmissions = m.actionsBtn.createChild("QvButton")
    '   btnEmissions.id = "btnEmissions"
    '   btnEmissions.text = "Emissions"
    '   btnEmissions.focusable = true
    '   btnEmissions.size = buttonSize

    '   if lastBtnCreate <> invalid then 
    '     lastBtnCreate.focusRight = btnEmissions
    '     btnEmissions.focusLeft = lastBtnCreate
    '   end if
    '   lastBtnCreate = btnEmissions

    '   if focusElement = invalid then focusElement = btnEmissions
    ' end if

    btnBack = m.actionsBtn.createChild("QvButton")
    btnBack.id = "btnBack"
    btnBack.size = buttonSize
    btnBack.text = i18n_t(m.global.i18n, "button.back")
    btnBack.focusable = true

    if lastBtnCreate <> invalid then 
      lastBtnCreate.focusRight = btnBack
      btnBack.focusLeft = lastBtnCreate
    end if
    lastBtnCreate = btnBack

    if focusElement = invalid then focusElement = btnBack
  end if

  if focusElement <> invalid then focusElement.setFocus(true)
end sub

' Aplicar las traducciones en el componente
sub __applyTranslations()
  if m.global.i18n = invalid then return

  m.notFoundTitle.text = i18n_t(m.global.i18n, "shared.errorComponent.notFound")
end sub


' Carga la informacion del programa actual en pantalla
sub __loadProgramInfo(program)
  actionLog = getActionLog({ actionCode: ActionLogCode().PROGRAM_DETAIL, program: program })
  __saveActionLog(actionLog)

  m.program = program

  if program.backgroundImage <> invalid then
    m.programImageBackground.uri = getImageUrl(program.backgroundImage)
  else 
    m.programImageBackground.uri = ""
  end if

  if m.program.image <> invalid then
    m.programImage.uri = getImageUrl(m.program.image)
    m.programImage.visible = true
  else
    m.programImage.visible = false
  end if

  m.programInfo.program = FormatJson(m.program)

  m.programInfo.visible = true
  
  __processActions()

  __renderCreditGroups()
  requestId = createRequestId()
  
  action = {
    apiRequestManager: m.apiRequestManager
    url: urlProgramRelated(m.apiUrl, m.program.key, m.program.id)
    method: "GET"
    responseMethod: "onGetRelatedResponse"
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

' Carga el carousel de programas relacionados.
sub __loadRelatedCarousel(carouselData)
  if carouselData.items <> invalid and carouselData.items.count() > 0 then 
    m.related.id = carouselData.id
    m.related.style = carouselData.style
    m.related.title = carouselData.title
    m.related.code = carouselData.code
    m.related.contentType = carouselData.contentType
    m.related.imageType = carouselData.imageType
    m.related.redirectType = carouselData.redirectType
    m.related.items = carouselData.items
  
    m.related.ObserveField("selected", "onSelectItem")
    m.relatedContainer.visible = true
  else 
    m.relatedContainer.visible = false
    m.related.items = invalid
    m.related.unobserveField("selected")
  end if 
end sub

' Dispara la obtencion de la URL para abrir el player o la validacion de control parental en caso de ser necesario.
sub __openPlayer(streamingAction)
  if m.program <> invalid then 
    m.streamingAction = streamingAction
    if m.program.parentalControl <> invalid and m.program.parentalControl then
      m.pinDialog = createAndShowPINDialog(m.top, i18n_t(m.global.i18n, "shared.parentalControlModal.title"), "onPinDialogLoad", [i18n_t(m.global.i18n, "button.ok"), i18n_t(m.global.i18n, "button.cancel")])
    else  
      if m.top.isOpenByPlayer then
        if streamingAction = invalid then streamingAction = getStreamingAction().PLAY
        
        m.program.streamingAction = streamingAction
        m.top.programOpenInPlayer = FormatJson(m.program)
      else
        m.top.loading.visible = true
        watchSessionId = getWatchSessionId()
        requestId = createRequestId()

        action = {
          apiRequestManager: m.apiRequestManager
          url: urlWatchValidate(m.apiUrl, watchSessionId, m.program.key, m.program.id)
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
    end if 
  end if 
end sub

' Dispara la navegacion a emisiones
sub __openEmissions()
  m.isOpenEmissions = true
  printLog("openEmissions")
end sub

' Carga la configuracion inicial de la pantalla de detalle de programas.
sub __configProgramDetail()
  width = m.scaleInfo.width
  height = m.scaleInfo.height

  m.programInfo.width = (m.scaleInfo.width - scaleValue(400, m.scaleInfo))
  m.programInfo.translation = [300, 0]
  m.programInfo.initConfig = true

  m.infoGradient.width = width
  m.infoGradient.height = height
 
  m.programImageBackground.width = width
  m.programImageBackground.height = height

  m.programImage.width = scaleValue(216, m.scaleInfo) 
  m.programImage.height = scaleValue(324, m.scaleInfo)

  if m.programImageGroup <> invalid then
    m.programImageGroup.translation = [-scaleValue(70, m.scaleInfo), -scaleValue(50, m.scaleInfo)]
  end if

  m.programDetailContent.translation = scaleSize([70, 50], m.scaleInfo)
  m.programTitleContainerByError.translation = scaleSize([160, 162], m.scaleInfo)

  m.programTitleError.width = scaleValue(200, m.scaleInfo) 
  m.programTitleError.height = scaleValue(300, m.scaleInfo)
  
  m.notFoundLayoutGroup.translation = [(width / 2), (height / 2)]
  m.notFoundTitle.width = width - scaleValue(230, m.scaleInfo)

  m.relatedContainer.translation = scaleSize([-70, 0], m.scaleInfo)
  m.related.translation = scaleSize([0, -100], m.scaleInfo)

  if m.top.isOpenByPlayer then 
    m.programImageBackground.visible = false
  else 
    m.programImageBackground.visible = true
  end if

  m.selectedIndicator.translation = scaleSize([68, 30], m.scaleInfo)
end sub

' Metodo encargado de limpiar todas las dependecias, cancelar las peticiones y quitar los escuchadores de la pantalla
sub _clearScreen()
  m.programInfo.program = invalid
  m.programInfo.visible = false
  m.programDetailContent.visible = true
  m.notFoundLayoutGroup.visible = false
  m.apiRequestManager = clearApiRequest(m.apiRequestManager) 
  m.program = invalid
  m.streamingAction = invalid
  m.programImage.uri = ""
  m.programImageBackground.uri = ""
  __clearButtons()
  if m.creditsContainer <> invalid then
    while m.creditsContainer.getChildCount() > 0
      m.creditsContainer.removeChild(m.creditsContainer.getChild(0))
    end while
  end if
  m.lastButtonSelect = invalid
  m.selectedIndicator.visible = false
  m.relatedContainer.visible = false
  m.programTitleContainerByError.visible = false
  m.programTitleError.text = ""
  m.related.items = invalid
  m.isOpenEmissions = false
  m.lastKey = invalid
  m.lastId = invalid
  m.related.unobserveField("selected")
end sub

' Dispara la redireccion a la pantalla de sesiones activas porque se alcanzo el limite de perfiles viendo
sub __redirectToManySessionsScreeen()
  if not m.top.loading.visible then m.top.loading.visible = true
  m.top.pendingStreamingSession = FormatJson({ redirectKey: m.program.key, redirectId: m.program.id })
end sub

' Muestra el mensaje de programa no encontrado.
sub __showNotFound()
  m.programDetailContent.visible = false
  m.notFoundLayoutGroup.visible = true
end sub

' Valdia el error obtenido desde la API
sub __validateError(statusCode, resultCode, errorResponse, callback = invalid)
  error = invalid

  if validateLogout(statusCode, m.top) then return 
  
  if errorResponse <> invalid and errorResponse <> "" then 
    error = ParseJson(errorResponse) 
  else 
    error = { code: resultCode }
  end if

  if (error <> invalid and error.code <> invalid) then 
    if (error.code = 5931) then
      m.dialog = createAndShowDialog(m.top,i18n_t(m.global.i18n, "shared.errorComponent.weAreSorry"), (i18n_t(m.global.i18n, "shared.errorComponent.youCurrentlyDoNotHavePlan")).Replace("[ProductName]", m.productName), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    
    else if (error.code = 5932) then
      m.dialog = createAndShowDialog(m.top,i18n_t(m.global.i18n, "shared.errorComponent.weAreSorry"), (i18n_t(m.global.i18n, "shared.errorComponent.youCurrentlyDoNotHaveAnyActiveSubscriptions")).Replace("[ProductName]", m.productName), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    
    else if (error.code = 5939) then
      m.dialog = createAndShowDialog(m.top,i18n_t(m.global.i18n, "shared.errorComponent.weAreSorry"), i18n_t(m.global.i18n, "shared.errorComponent.youCurrentlyDoNotHaveSufficientBalance"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    
    else if (error.code = 5930) then
      __redirectToManySessionsScreeen()
    end if
  else 
    if (statusCode = 400) or (statusCode = 404) or (statusCode = 500) then 
      m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.unhandled"), i18n_t(m.global.i18n, "shared.errorComponent.extendedMessage"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    else 
      if (callback <> invalid) then callback()
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
    requestId = createRequestId()
    action = {
      apiRequestManager: m.apiLogRequestManager
      url: urlActionLogs(m.beaconUrl)
      method: "POST"
      responseMethod: "onActionLogResponse"
      body: FormatJson(actionLog)
      token: beaconToken
      publicApi: false
      requestId: requestId
      dataAux: invalid
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


sub __renderCreditGroups()
    if m.creditsContainer = invalid then return

    ' limpiar anteriores
    while m.creditsContainer.getChildCount() > 0
        m.creditsContainer.removeChild(m.creditsContainer.getChild(0))
    end while

    if m.program.creditGroups = invalid then return
    if Type(m.program.creditGroups) <> "roArray" then return

    for each grp in m.program.creditGroups
      if grp = invalid then return

      creditType = ""
      if grp.creditType <> invalid then creditType = grp.creditType

      names = GetCreditsNames(grp.credits) ' devuelve array de strings
      namesText = JoinStrings(names, ", ")

      ' fila horizontal
      row = CreateObject("roSGNode", "LayoutGroup")
      row.layoutDirection = "horiz"
      row.horizAlignment = KeyButtons().LEFT
      row.vertAlignment = "top"
      row.itemSpacings = [scaleValue(12, m.scaleInfo)]

      lType = CreateObject("roSGNode", "Label")
      lType.text = creditType + ":"
      lType.wrap = false
      lType.font = "font:SmallerSystemFont"
      lType.maxLines = 1
      lType.width = scaleValue(100, m.scaleInfo)

      lNames = CreateObject("roSGNode", "Label")
      lNames.text = namesText
      lNames.wrap = true
      lNames.font = "font:SmallerSystemFont"
      lNames.maxLines = 2
      lNames.color = m.global.colors.LIGHT_GRAY
      ' opcional: para que no se te vaya infinito, poné un ancho razonable
      lNames.width = scaleValue(760, m.scaleInfo)

      row.appendChild(lType)
      row.appendChild(lNames)

      m.creditsContainer.appendChild(row)
    end for
end sub

function GetCreditsNames(credits as object) as object
    result = []

    if credits = invalid then return result

    t = Type(credits)

    ' si viene como 1 solo objeto {id,name}
    if t = "roAssociativeArray"
        if credits.name <> invalid and credits.name <> "" then result.push(credits.name)
        return result
    end if

    ' si viene como array [{...},{...}]
    if t = "roArray"
        for each c in credits
            if c <> invalid and Type(c) = "roAssociativeArray"
                if c.name <> invalid and c.name <> "" then result.push(c.name)
            end if
        end for
    end if

    return result
end function

function JoinStrings(arr as object, sep as string) as string
    if arr = invalid or Type(arr) <> "roArray" or arr.count() = 0 then return ""

    out = ""
    for i = 0 to arr.count() - 1
        if i > 0 then out = out + sep
        out = out + arr[i]
    end for
    return out
end function