' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.scaleInfo = m.global.scaleInfo
    if m.scaleInfo = invalid then
        m.scaleInfo = getScaleInfo()
    end if

    m.background = m.top.findNode("background")
    m.guideContainer = m.top.findNode("guideContainer")
    m.carouselGuide = m.top.findNode("carouselGuide")
    m.carouselGuideContainer = m.top.findNode("carouselGuideContainer")

    m.detailGuideContainer = m.top.findNode("detailGuideContainer")

    m.programSummaryPlayer = m.top.findNode("programSummaryPlayer")

    m.prevChannelNumber = m.top.findNode("prevChannelNumber")
    m.prevChannelImage = m.top.findNode("prevChannelImage")
    
    m.currentChannelNumber = m.top.findNode("currentChannelNumber")
    m.currentChannelImage = m.top.findNode("currentChannelImage")

    m.nextChannelNumber = m.top.findNode("nextChannelNumber")
    m.nextChannelImage = m.top.findNode("nextChannelImage")
    
    m.selectedIndicator = m.top.findNode("selectedIndicator")

    m.arrowUp = m.top.findNode("arrowUp")
    m.arrowDown = m.top.findNode("arrowDown")
    
    m.changeUp = m.top.findNode("changeUp")
    m.changeDown = m.top.findNode("changeDown")
    
    m.loadConfig = false
    m.saveDateByEvent = false
    m.channelArray = []

    m.nextCarouselGuide = invalid
    m.currentCarouselGuide = invalid
    m.prevCarouselGuide = invalid

    m.nextChannel = invalid
    m.currentChannel = invalid
    m.prevChannel = invalid
    m.isNowPosition = true
    m.dateTimeByPosition = invalid
    m.lastElementSelect = invalid

    m.indexPosition = 0
    m.currentCatchupHours = 0

    m.separator = scaleValue(15, m.scaleInfo)
    m.size = scaleSize([160, 262], m.scaleInfo)
    m.xInitial = scaleValue(-150, m.scaleInfo)
    m.targetItems = 8

    m.targetRects = createTargetRects(m.targetItems, m.xInitial, (m.size[0] + m.separator), m.size[0], m.size[1])

    m.i18n = invalid
    scene = m.top.getScene()
    if scene <> invalid then
        m.i18n = scene.findNode("i18n")
    end if

    __removeProgramDetailComponent()
end sub

' Funcion que interpreta los eventos de teclado y retorna true si fue porcesada por este componente. Sino es porcesado por el
' entonces sigue con el siguente metodo onKeyEvent del compoente superior
function onKeyEvent(key as string, press as boolean) as boolean
    handled = false

    if key = KeyButtons().UP then 
        if press then 
            m.programBySend = invalid
            
            m.top.channelIdIndexOf = m.top.channelIdIndexOf - 1
    
            if m.top.channelIdIndexOf < 0 then m.top.channelIdIndexOf = m.channelArray.count() - 1 

            prevIndex = m.top.channelIdIndexOf - 1 
            nextIndex = m.top.channelIdIndexOf + 1

            if prevIndex < 0 then prevIndex = m.channelArray.count() - 1
            if nextIndex > m.channelArray.count() - 1 then prevIndex = 0

            m.nextChannel = m.currentChannel
            __updateChannelInfo(m.nextChannel, m.nextChannelNumber, m.nextChannelImage)

            m.currentChannel = m.prevChannel

             m.top.channelId = m.currentChannel.id

            __updateChannelInfo(m.currentChannel, m.currentChannelNumber, m.currentChannelImage)

            if m.channelArray[prevIndex] <> invalid then 
                m.prevChannel = m.channelArray[prevIndex]
                __updateChannelInfo(m.prevChannel, m.prevChannelNumber, m.prevChannelImage)
            end if

            __savePosition()
            
            m.carouselGuide.unobserveField("itemFocused")
            m.carouselGuide.unobserveField("itemSelected")
            m.carouselGuide.unobserveField("happenedLeft")
            m.carouselGuide.unobserveField("happenedRight")

            m.currentChannelNumber.setFocus(true)

            clearTimer(m.changeUp)
            
            m.changeUp.ObserveField("fire","onLoadChangeChannelUp")
            m.changeUp.control = "start"
        end if

        handled = true 

    else if key = KeyButtons().DOWN then
        if press then 
            m.programBySend = invalid

            m.top.channelIdIndexOf = m.top.channelIdIndexOf + 1
    
            if m.top.channelIdIndexOf > m.channelArray.count() - 1 then m.top.channelIdIndexOf = 0 

            prevIndex = m.top.channelIdIndexOf - 1 
            nextIndex = m.top.channelIdIndexOf + 1

            if prevIndex < 0 then prevIndex = m.channelArray.count() - 1
            if nextIndex > m.channelArray.count() - 1 then prevIndex = 0

            m.prevChannel = m.currentChannel
            __updateChannelInfo(m.prevChannel, m.prevChannelNumber, m.prevChannelImage)

            m.currentChannel = m.nextChannel

            m.top.channelId = m.currentChannel.id

            __updateChannelInfo(m.currentChannel, m.currentChannelNumber, m.currentChannelImage)
                
            if m.channelArray[nextIndex] <> invalid then 
                m.nextChannel = m.channelArray[nextIndex]
                __updateChannelInfo(m.nextChannel, m.nextChannelNumber, m.nextChannelImage)
            end if

            __savePosition()
            
            m.carouselGuide.unobserveField("itemFocused")
            m.carouselGuide.unobserveField("itemSelected")
            m.carouselGuide.unobserveField("happenedLeft")
            m.carouselGuide.unobserveField("happenedRight")
            
            m.currentChannelNumber.setFocus(true)
            
            clearTimer(m.changeDown)
            
            m.changeDown.ObserveField("fire","onLoadChangeChannelDown")
            m.changeDown.control = "start"
        end if

        handled = true 
    
    else if key = KeyButtons().OK then
        if press then
            if m.currentChannel <> invalid and m.currentChannelNumber <> invalid and m.currentChannelNumber.isInFocusChain() and m.isNowPosition then 
                __channelSelected()
            end if  
        end if 
        
        handled = true 

    else if key = KeyButtons().LEFT or key = KeyButtons().RIGHT then
        if press then
            if m.currentChannelNumber.isInFocusChain() and m.carouselGuide <> invalid and m.carouselGuide.content <> invalid then 
                m.carouselGuide.setFocus(true)
            end if  
        end if 
        
        handled = true 

    else if key = KeyButtons().BACK then
        if press then
            clearTimer(m.changeUp)
            clearTimer(m.changeDown)

            m.apiRequestCurrentChannel = clearApiRequest(m.apiRequestCurrentChannel)
            m.apiRequestPrevChannel = clearApiRequest(m.apiRequestPrevChannel)
            m.apiRequestNextChannel = clearApiRequest(m.apiRequestNextChannel)
                
            m.carouselGuide.unobserveField("itemFocused")
            m.carouselGuide.unobserveField("itemSelected")
            m.carouselGuide.unobserveField("happenedLeft")
            m.carouselGuide.unobserveField("happenedRight")

            m.currentCatchupHours = 0
            m.programSummaryPlayer.catchupDuration =  m.currentCatchupHours
            m.programSummaryPlayer.program = invalid

            m.carouselGuide.targetSet = invalid
            m.carouselGuide.content = invalid
            m.top.channelIdIndexOf = -1
            m.nextChannel = invalid
            m.currentChannel = invalid
            m.prevChannel = invalid
            m.isNowPosition = true
            m.indexPosition = 0
            m.dateTimeByPosition = invalid
            m.lastElementSelect = invalid
                
            m.selectedIndicator.visible = false

            m.nextCarouselGuide = invalid
            m.currentCarouselGuide = invalid
            m.prevCarouselGuide = invalid

            m.saveDateByEvent = false

            m.prevChannelNumber.text = ""
            m.prevChannelImage.uri = ""
                
            m.currentChannelNumber.text = ""
            m.currentChannelImage.uri = ""
                
            m.nextChannelNumber.text = ""
            m.nextChannelImage.uri = ""
        end if 


        if m.detailGuideContainer.isInFocusChain() then 
            if press then
                __removeProgramDetailComponent()
                m.carouselGuide.setFocus(true)
            end if 
            
            handled = true 
        end if 

    end if 

    return handled
end function

' Carga la lista de canales.
sub loadChannelArray()
    if not m.loadConfig then __initConfig()

    if m.top.items <> invalid and m.top.items.count() > 0 then 
        m.channelArray = m.top.items
        __searchChannel()
    else 
        __clearGuide()
    end if
end sub

' Posiciona el el foco sobre el canal que concuerda con el Id pasado
sub onShowPositioninChannelId()
    if m.top.positioninChannelId then
        m.top.positioninChannelId = false
        if m.currentChannel <> invalid then
            ' En caso de que el id del canal, sea diferente al canals seleccionado, actualizar el canarl
            if m.currentChannel.id <> m.top.channelId and m.channelArray <> invalid then
                for i = 0 to m.channelArray.count() - 1
                    if m.channelArray[i].id = m.top.channelId then
                        m.top.channelIdIndexOf = i
                    end if
                end for

                m.currentChannel = m.channelArray[m.top.channelIdIndexOf]
            end if 
            m.currentChannelNumber.setFocus(true)
            __searchCurrentChannel()
        end if
    end if
end sub

' Dispara la busqueda de la posicion del canal.  
sub onSearchChannelPosition()
    if m.top.searchChannelPosition then
        m.top.searchChannelPosition = false
        __searchChannel()
    end if
end sub

' Se posiciona la guia en el canal recibido por Id.
sub positionChannel()
    if m.top.channelId <> 0 then __searchChannel()
end sub

' Procesa la respuesta de la guia del canal actual
sub onCurrentCarouselResponse()
    if valdiateStatusCode(m.apiRequestCurrentChannel.statusCode) then 
        m.currentCarouselGuide = ParseJson(m.apiRequestCurrentChannel.response)

         if m.apiRequestCurrentChannel.dataAux <> invalid and m.apiRequestCurrentChannel.dataAux <> "" then
            m.currentCarouselGuide.channelId = ParseJson(m.apiRequestCurrentChannel.dataAux).channelId
        end if 

        m.apiRequestCurrentChannel = clearApiRequest(m.apiRequestCurrentChannel)

        if m.currentCarouselGuide <> invalid and m.currentCarouselGuide.data <> invalid then
            if m.currentCarouselGuide.data.catchupDuration <> invalid then 
                m.currentCatchupHours = m.currentCarouselGuide.data.catchupDuration
            else 
                m.currentCatchupHours = 0
            end if

            m.programSummaryPlayer.catchupDuration = m.currentCatchupHours

            if m.currentCarouselGuide.data <> invalid and m.currentCarouselGuide.data.programs.count() > 0 then 
                __processAndLoadCarousel(m.currentCarouselGuide.data.programs)
                __searchPrevChannel()
                __searchNextChannel()
            end if
        end if
    end if
end sub

' Procesa la respuesta de la guia del canal anterior
sub onPrevCarouselResponse()
    if valdiateStatusCode(m.apiRequestPrevChannel.statusCode) then
        m.prevCarouselGuide = ParseJson(m.apiRequestPrevChannel.response)

        if m.apiRequestPrevChannel.dataAux <> invalid and m.apiRequestPrevChannel.dataAux <> "" then
            m.prevCarouselGuide.channelId = ParseJson(m.apiRequestPrevChannel.dataAux).channelId
        end if 

        m.apiRequestPrevChannel = clearApiRequest(m.apiRequestPrevChannel)
    end if
end sub

' Procesa la respuesta de la guia del canal siguiente
sub onNextCarouselResponse()
    if valdiateStatusCode(m.apiRequestNextChannel.statusCode) then 
        m.nextCarouselGuide = ParseJson(m.apiRequestNextChannel.response)

        if m.apiRequestNextChannel.dataAux <> invalid and m.apiRequestNextChannel.dataAux <> "" then
            m.nextCarouselGuide.channelId = ParseJson(m.apiRequestNextChannel.dataAux).channelId
        end if 

        m.apiRequestNextChannel = clearApiRequest(m.apiRequestNextChannel)
    end if
end sub

' Devuelve el nodo que se a seleccionado
sub onItemSelectedChanged()
    indexSelected = m.carouselGuide.itemSelected
    programNode = m.carouselGuide.content.getChild(indexSelected)
    
    loadToPLayer = false

    nowDate = CreateObject("roDateTime")
    nowDate.ToLocalTime()
    nowSeconds = nowDate.AsSeconds()
    
    catchupDate = CreateObject("roDateTime")
    catchupDate.ToLocalTime()
    catchupDateSeconds = catchupDate.AsSeconds()
    catchupDateSeconds = catchupDateSeconds - (m.currentCatchupHours * 60 * 60) ' el catchup llega en horas 
    
    if ((programNode.startSeconds = invalid and programNode.endSeconds = invalid) or (programNode.startSeconds <= nowSeconds and programNode.endSeconds >= nowSeconds)) then 
        ' Programa en vivo
        loadToPLayer = true
    else if m.currentCatchupHours <> 0 and catchupDateSeconds <= programNode.endSeconds and programNode.endSeconds <= nowSeconds then
        ' Programa catchup
        loadToPLayer = true
    end if

    if loadToPLayer then 
        if programNode <> invalid and programNode.parentalControl <> invalid and programNode.parentalControl then 
            if m.carouselGuide.focusedChild <> invalid then m.lastElementSelect = m.carouselGuide.focusedChild
            m.pinDialog = createAndShowPINDialog(m.top, i18n_t(m.i18n, "shared.parentalControlModal.title"), "onPinDialogLoad", [i18n_t(m.i18n, "button.ok"), i18n_t(m.i18n, "button.cancel")])
        else
            m.programBySend = m.currentCarouselGuide.data.programs[indexSelected]
            __loadStreamingForPlayer()
        end if
    else 
        m.programBySend = m.currentCarouselGuide.data.programs[indexSelected]
        __loadDetail()
    end if 
end sub

' devuelve el nodo que esta teniendo el foco.
sub onItemFocusedChanged()
    m.programBySend = invalid
    m.programSummaryPlayer.program = m.carouselGuide.content.getChild(m.carouselGuide.itemFocused)
end sub

' Procesa el evento de flecha izquierda
sub onLeftEvent()
    if m.carouselGuide.happenedLeft then m.saveDateByEvent = true
end sub

' Procesa el evento de flecha derecha
sub onRightEvent()
    if m.carouselGuide.happenedRight then m.saveDateByEvent = true
end sub

' Dispara la carga de la guia del canal superior
sub onLoadChangeChannelUp()
    clearTimer(m.changeUp)

    if m.prevCarouselGuide <> invalid and m.prevCarouselGuide.channelId = m.currentChannel.id then 
        m.nextCarouselGuide = m.currentCarouselGuide
        m.currentCarouselGuide = m.prevCarouselGuide
        m.prevCarouselGuide = invalid

        if m.currentCarouselGuide <> invalid and m.currentCarouselGuide.data <> invalid then
            if m.currentCarouselGuide.data.catchupDuration <> invalid then 
                m.currentCatchupHours = m.currentCarouselGuide.data.catchupDuration
            else 
                m.currentCatchupHours = 0
            end if

            m.programSummaryPlayer.catchupDuration = m.currentCatchupHours

            if m.currentCarouselGuide.data <> invalid and m.currentCarouselGuide.data.programs.count() > 0 then 
                __processAndLoadCarousel(m.currentCarouselGuide.data.programs)
                __searchPrevChannel()
            end if
        end if
    else 
        ' Se fue a mas de un salto 
        __searchCurrentChannel()
    end if
end sub

' Dispara la carga de la guia del canal inferior
sub onLoadChangeChannelDown()
    clearTimer(m.changeDown)

    if m.nextCarouselGuide <> invalid and m.nextCarouselGuide.channelId = m.currentChannel.id then 
        m.prevCarouselGuide = m.currentCarouselGuide
        m.currentCarouselGuide = m.nextCarouselGuide
        m.nextCarouselGuide = invalid

        if m.currentCarouselGuide <> invalid and m.currentCarouselGuide.data <> invalid then
            if m.currentCarouselGuide.data.catchupDuration <> invalid then 
                m.currentCatchupHours = m.currentCarouselGuide.data.catchupDuration
            else 
                m.currentCatchupHours = 0
            end if

            m.programSummaryPlayer.catchupDuration = m.currentCatchupHours

            if m.currentCarouselGuide.data <> invalid and m.currentCarouselGuide.data.programs.count() > 0 then     
                __processAndLoadCarousel(m.currentCarouselGuide.data.programs)
                __searchNextChannel()
            end if
        end if
    else 
        ' Se fue a mas de un salto 
        __searchCurrentChannel()
    end if
end sub

' Se dispara la validacion del PIN cargado en el modal
sub onPinDialogLoad()
  resp = clearPINDialogAndGetOption(m.top, m.pinDialog)
  m.pinDialog = invalid
  
  if (resp.option = 0 and resp.pin <> invalid and Len(resp.pin) = 4) then 
    if m.lastElementSelect <> invalid then m.lastElementSelect.setFocus(true)
    m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlParentalControlPin(m.apiUrl, resp.pin), "GET", "onParentalControlResponse")
  else 
    m.repositionChannnelList = true
    if m.lastElementSelect <> invalid then m.lastElementSelect.setFocus(true)
  end if 
end sub

' Procesa la respuesta de la validacion del PIN
sub onParentalControlResponse()
  if valdiateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)

    if resp <> invalid and resp.data <> invalid and resp.data then
      __loadStreamingForPlayer()
    else
      m.dialog = createAndShowDialog(m.top, "", i18n_t(m.i18n, "shared.parentalControlModal.error.invalid"), "onDialogClosedLastFocus")
    end if
  else     
    m.top.loading.visible = false
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    printError("ParentalControl:", statusCode.toStr() + " " +  errorResponse)
  end if
end sub

' Hace foco en objeto que lo tenia antes de que se abriera el modal
sub onDialogClosedLastFocus()
  option = clearDialogAndGetOption(m.top, m.dialog)
  m.dialog = invalid
  
  if option = 0 then
    if m.lastElementSelect <> invalid then m.lastElementSelect.setFocus(true)
    m.lastElementSelect = invalid
  end if
end sub

' Metodo que dispara el deslogueo del usuario
sub onLogoutEvent()
    printError("FaltaImplementar onLogoutEvent")
    m.carouselGuide.setFocus(true)
    __removeProgramDetailComponent()
end sub

' Metodo que recarga el player con la nueva seleccion del objeto.
sub onStreamingPlayer()
    if m.programDetailComponent.programOpenInPlayer <> invalid and m.programDetailComponent.programOpenInPlayer <> "" then 
        program = ParseJson(m.programDetailComponent.programOpenInPlayer)
        
        m.top.selected = FormatJson({key: program.key, id: program.id, currentChannelId: program.channel.id, streamingAction: program.streamingAction})
    end if 
    __removeProgramDetailComponent()
end sub

' Metodo que dispara la apertura de la pantalla para eliminar sesiones concurrentes
sub onKillSession()
    printError("FaltaImplementar onKillSession")
    m.carouselGuide.setFocus(true)
    __removeProgramDetailComponent()
end sub

' Metodo que levanta la pantalla de detalle sobre el player.
sub onBackDetail()
    m.carouselGuide.setFocus(true)
    __removeProgramDetailComponent()
end sub

' Carga la configuracion inicial del componente, escuchando los observable y obteniendo las 
' referencias de compenentes necesarios para su uso
sub __initConfig()
    width = m.global.width
    height = m.global.height

    m.background.width = width
    m.background.height = height
    m.background.loadWidth = width
    m.background.loadHeight = height
    
    m.carouselGuideContainer.clippingRect = [0, 0, (width - scaleValue(155, m.scaleInfo)), m.size[1] + scaleValue(3, m.scaleInfo)]
    m.programSummaryPlayer.initConfig = true

    grayColor = m.global.colors.LIGHT_GRAY
    
    m.arrowUp.blendColor = grayColor
    m.arrowDown.blendColor = grayColor

    m.guideContainer.translation = [scaleValue(80, m.scaleInfo), (height - scaleValue(50, m.scaleInfo))]
    
    if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL)
    
    if (m.targetSet = invalid) then 
        m.targetSet = createObject("roSGNode", "TargetSet")
        m.targetSet.targetRects = m.targetRects
        m.targetSet.focusIndex = 4
    end if 

    m.selectedIndicator.size = [m.size[0] - scaleValue(2, m.scaleInfo), m.size[1] - scaleValue(24, m.scaleInfo)] 'Ajhuste del label y el espacio de separacion

    m.loadConfig = true
end sub

' Busca el canal pasado definido en el channelId sobre el arreglo de canales
sub __searchChannel()
    if m.channelArray.count() > 0 and m.top.channelId <> 0 then 
        for i = 0 to m.channelArray.count() - 1

            if m.top.channelIdIndexOf = -1 and m.top.channelId <> invalid and m.top.channelId <> 0 and m.top.channelId = m.channelArray[i].id then 
                m.top.channelIdIndexOf = i
    
                prevIndex = i - 1 
                nextIndex = i + 1 
                if prevIndex < 0 then prevIndex = m.channelArray.count() - 1
                if nextIndex > m.channelArray.count() - 1 then prevIndex = 0
    
                if m.channelArray[prevIndex] <> invalid then 
                    m.prevChannel = m.channelArray[prevIndex]
                    __updateChannelInfo(m.prevChannel, m.prevChannelNumber, m.prevChannelImage)
                end if
                 
                if m.channelArray[m.top.channelIdIndexOf] <> invalid then 
                    m.currentChannel = m.channelArray[m.top.channelIdIndexOf]
                    __updateChannelInfo(m.currentChannel, m.currentChannelNumber, m.currentChannelImage)
                end if
                
                if m.channelArray[nextIndex] <> invalid then 
                    m.nextChannel = m.channelArray[nextIndex]
                    __updateChannelInfo(m.nextChannel, m.nextChannelNumber, m.nextChannelImage)
                end if

                i = m.channelArray.count() - 1
            end if
        end for

        if m.top.visible then 
            if m.currentChannel <> invalid then
                m.currentChannelNumber.setFocus(true)
                __searchCurrentChannel()
            end if
        end if 
    end if 
end sub

' Limpia las variables y observables necesarios para el uso interno del componente.
sub __clearGuide()
    clearTimer(m.changeUp)
    clearTimer(m.changeDown)

    m.apiRequestCurrentChannel = clearApiRequest(m.apiRequestCurrentChannel)
    m.apiRequestPrevChannel = clearApiRequest(m.apiRequestPrevChannel)
    m.apiRequestNextChannel = clearApiRequest(m.apiRequestNextChannel)
    
    m.carouselGuide.unobserveField("itemFocused")
    m.carouselGuide.unobserveField("itemSelected")
    m.carouselGuide.unobserveField("happenedLeft")
    m.carouselGuide.unobserveField("happenedRight")

    m.currentCatchupHours = 0
    m.programSummaryPlayer.catchupDuration =  m.currentCatchupHours
    m.programSummaryPlayer.program = invalid

    m.carouselGuide.targetSet = invalid
    m.carouselGuide.content = invalid
    m.top.channelIdIndexOf = -1
    m.nextChannel = invalid
    m.currentChannel = invalid
    m.prevChannel = invalid
    m.isNowPosition = true
    m.indexPosition = 0
    m.dateTimeByPosition = invalid
    m.lastElementSelect = invalid
    
    m.selectedIndicator.visible = false

    m.channelArray = []
    m.nextCarouselGuide = invalid
    m.currentCarouselGuide = invalid
    m.prevCarouselGuide = invalid

    m.loadConfig = false
    m.saveDateByEvent = false

    m.prevChannelNumber.text = ""
    m.prevChannelImage.uri = ""
    
    m.currentChannelNumber.text = ""
    m.currentChannelImage.uri = ""
    
    m.nextChannelNumber.text = ""
    m.nextChannelImage.uri = ""

    __removeProgramDetailComponent()
end sub

' Realiza la busca la guia del canal actual
sub __searchCurrentChannel()
    m.apiRequestCurrentChannel = sendApiRequest(m.apiRequestCurrentChannel, urlEpgCarouselGuide(m.apiUrl, m.currentChannel.id), "GET", "onCurrentCarouselResponse", invalid, invalid, false, FormatJson({channelId: m.currentChannel.id}))
end sub

' Realiza la busca la guia del canal anterior
sub __searchPrevChannel() 
    m.apiRequestPrevChannel = sendApiRequest(m.apiRequestPrevChannel, urlEpgCarouselGuide(m.apiUrl, m.prevChannel.id), "GET", "onPrevCarouselResponse", invalid, invalid, false, FormatJson({channelId: m.prevChannel.id}))
end sub

' Realiza la busca la guia del canal siguiente
sub __searchNextChannel() 
    m.apiRequestNextChannel = sendApiRequest(m.apiRequestNextChannel, urlEpgCarouselGuide(m.apiUrl, m.nextChannel.id), "GET", "onNextCarouselResponse", invalid, invalid, false, FormatJson({channelId: m.nextChannel.id}))
end sub

' Función para configurar un TargetList con su TargetSet y contenido
sub __setupTargetList(content as Object)
    ' Genera las posiciones de los targets dinámicamente según la cantidad de items
    m.carouselGuide.targetSet = m.targetSet
    m.carouselGuide.content = content
    m.carouselGuide.itemComponentName = "GuideSingleItem"
    m.carouselGuide.showTargetRects = false
    m.carouselGuide.observeField("itemSelected", "onItemSelectedChanged")
    m.carouselGuide.observeField("itemFocused", "onItemFocusedChanged")
    m.carouselGuide.observeField("happenedLeft", "onLeftEvent")
    m.carouselGuide.observeField("happenedRight", "onRightEvent")
end sub

' Selecciona un canal enviandolo al player para reproducir o levantando el modal de control 
' parental si el canal lo requiere
sub __channelSelected()
    if m.currentChannel.parentalControl <> invalid and m.currentChannel.parentalControl then
        m.lastElementSelect = m.top.focusedChild
        m.pinDialog = createAndShowPINDialog(m.top, i18n_t(m.i18n, "shared.parentalControlModal.title"), "onPinDialogLoad", [i18n_t(m.i18n, "button.ok"), i18n_t(m.i18n, "button.cancel")])
    else
        __loadStreamingForPlayer()
    end if
end sub

' Procesa y carga la lista de programa del canal que actualmente tiene el foco
sub __processAndLoadCarousel(programs)
    contentRoot = createObject("roSGNode", "ProgramNode")
    startTime = CreateObject("roDateTime")
    endTime = CreateObject("roDateTime")
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    nowSeconds = now.AsSeconds() 
    index = 0
    lastItem = programs.count() - 1

    channelName = ""
    channelCategory = ""
    
    if m.currentChannel <> invalid then
        if m.currentChannel.name <> invalid and  m.currentChannel.name <> "" then
        channelName = m.currentChannel.name
        end if
        
        if m.currentChannel.category <> invalid and m.currentChannel.category <> "" then
        channelCategory = m.currentChannel.category
        end if
    end if

    for each program in programs
        child = contentRoot.createChild("ProgramNode")
        child.size = m.size
        if program.key <> invalid then child.key = program.key
        if program.id <> invalid then child.id = program.id
        if program.title <> invalid and program.title <> "" then child.title = program.title
        if program.subtitle <> invalid and program.subtitle <> "" then child.subtitle = program.subtitle
        if program.synopsis <> invalid and program.synopsis <> "" then child.synopsis = program.synopsis
        if program.category <> invalid and program.category.name <> invalid and program.category.name <> "" then child.categoryName = program.category.name
        if program.formattedDuration <> invalid then child.formattedDuration = program.formattedDuration
        if program.durationInMinutes <> invalid then child.durationInMinutes = program.durationInMinutes
        if program.image <> invalid then child.imageURL = getImageUrl(program.image)

        if program.parentalControl <> invalid then 
            child.parentalControl = program.parentalControl
        else if m.currentChannel.parentalControl <> invalid then 
            child.parentalControl = m.currentChannel.parentalControl
        end if 
        
        program.channelName = channelName
        program.channelCategory = channelCategory

        if program.startTime <> invalid then 
            startTime.FromISO8601String(program.startTime)
            startTime.ToLocalTime()

            child.startTime = program.startTime
            child.startSeconds = startTime.AsSeconds()
            
            child.programTime = dateConverter(startTime, "HH:mm a")
        end if

        if program.endTime <> invalid then 
            endTime.FromISO8601String(program.endTime)
            endTime.ToLocalTime()

            child.endTime = program.endTime 
            child.endSeconds = endTime.AsSeconds()
        end if

        if program.endTime <> invalid and program.startTime <> invalid then
            startSeconds = startTime.AsSeconds()
            endSeconds = endTime.AsSeconds()

            if (startSeconds <= nowSeconds and endSeconds >= nowSeconds) then 
                child.programTime = "NOW"
                child.isNow = true
                if m.isNowPosition then m.indexPosition = index
            end if
            
            if not m.isNowPosition and m.dateTimeByPosition <> invalid then
                if (startSeconds <= m.dateTimeByPosition and endSeconds >= m.dateTimeByPosition) then 
                    m.indexPosition = index
                else if (index = 0) and m.dateTimeByPosition < startSeconds then 
                    m.indexPosition = 0
                else if (index = lastItem) and m.dateTimeByPosition > endSeconds then 
                    m.indexPosition = lastItem
                end if
            end if
        end if

        index++
    end for

    __setupTargetList(contentRoot)

    m.carouselGuide.jumpToItem = m.indexPosition
    
    if m.lastElementSelect <> invalid then 
        m.lastElementSelect = m.carouselGuide
    else 
        m.carouselGuide.setFocus(true)
    end if
    
    m.selectedIndicator.visible = true
end sub

' Actualiza la informacion del canal en pantalla 
sub __updateChannelInfo(channel, roElementNumber, roElementImage)    
    if channel.number <> invalid then 
        roElementNumber.text = channel.number.ToStr()
    else
        roElementNumber.text = ""
    end if 
    
    if channel.image <> invalid then
        roElementImage.uri = getImageUrl(channel.image)
    else
        roElementImage.uri = ""
    end if 
end sub

' Notifica al player que se a selecionado un nuevo programa para reproducir
sub __loadStreamingForPlayer()
    if m.programBySend <> invalid then 
        ' Seleccion por programa
        m.top.selected = FormatJson({key: m.programBySend.key, id: m.programBySend.id, currentChannelId: m.currentChannel.id, streamingAction: invalid})
    else if m.currentChannel <> invalid then 
        ' Seleccion por canal
        m.top.selected = FormatJson({key: "ChannelId", id: m.currentChannel.id, currentChannelId: m.currentChannel.id, streamingAction: invalid})
    end if 
end sub

' Define y muestra el detalle de un programa como modal
sub __loadDetail()
    __removeProgramDetailComponent()
    m.programDetailComponent = m.detailGuideContainer.createChild("ProgramDetailScreen")

    m.programDetailComponent.isOpenByPlayer = true
    m.programDetailComponent.loading = m.top.loading
    
    m.programDetailComponent.observeField("logout", "onLogoutEvent")
    m.programDetailComponent.observeField("programOpenInPlayer", "onStreamingPlayer")
    m.programDetailComponent.observeField("pendingStreamingSession", "onKillSession")
    m.programDetailComponent.observeField("onBack", "onBackDetail")

    ' Se acomoda para que lo interprete la pantalal de detalle
    m.programBySend.redirectKey = m.programBySend.key
    m.programBySend.redirectId = m.programBySend.id
    
    m.programDetailComponent.onFocus = true
    m.programDetailComponent.setFocus(true)
    m.programDetailComponent.data = FormatJson(m.programBySend)
    m.guideContainer.visible = false
end sub

' Guarda la posicion donde se decidio deplazar hacia arriba o abajo para mantener 
' la misma linea temporal al cambiar entre canales de la guia
sub __savePosition()
    if m.saveDateByEvent then
        if m.carouselGuide <> invalid and m.carouselGuide.itemFocused <> invalid and m.carouselGuide.content <> invalid then 
            node = m.carouselGuide.content.getChild(m.carouselGuide.itemFocused)
            if node <> invalid then 
                if node.isNow then
                    m.isNowPosition = true
                    m.dateTimeByPosition = invalid
                else 
                    m.isNowPosition = false
                    m.dateTimeByPosition = node.startSeconds
                end if
            end if 
        end if
    end if
    m.saveDateByEvent = false
end sub

' Limpia el modal del detalle de programa que se abrio sobre el player.
sub __removeProgramDetailComponent()
    if m.programDetailComponent <> invalid then 
        m.detailGuideContainer.removeChild(m.programDetailComponent)
        m.programDetailComponent.unobserveField("logout")
        m.programDetailComponent.unobserveField("programOpenInPlayer")
        m.programDetailComponent.unobserveField("pendingStreamingSession")
        m.programDetailComponent.unobserveField("onBack")
        m.programDetailComponent.onFocus = false
        m.programDetailComponent.data = invalid
        m.programDetailComponent.isOpenByPlayer = false
        m.programDetailComponent.loading = invalid
        m.programDetailComponent.programOpenInPlayer = invalid
    end if
    m.programDetailComponent = invalid
    m.guideContainer.visible = true
end sub