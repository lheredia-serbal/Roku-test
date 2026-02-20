' Inicio de la app
sub Main(args as Object)
    'Indicate this is a Roku SceneGraph application'
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    ' Inicializa el monitoreo de memoria recomendado por Roku
    InitMemoryMonitoring(m.port)

    if args <> invalid
        if args.reason <> invalid then
        end if
        
        if args.contentID <> invalid then
            m.contentID = args.contentID
        end if
    end if

    'Create a scene and load /components/MainScene.xml'
    scene = screen.CreateScene("MainScene")
    screen.show()

    'observe the appExit event to know when to kill the channel
    scene.observeField("appExit", m.port)
    'focus the scene so it can respond to key events
    scene.setFocus(true)

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        'respond to the appExit field on MainScene
        else if HandleSystemEvents(msg)
            ' Evento de sistema/memoria ya gestionado
       
        else if msgType = "roInputEvent"
            info = msg.GetInfo()

        else if msgType = "roSGNodeEvent" then
            field = msg.getField()
            'if the scene's appExit field was changed in any way, exit the channel
            if field = "appExit" then return
        end if
    end while
end sub

sub InitMemoryMonitoring(port as Object)
    ' Monitor específico de memoria de la app/canal
    m.memMon = CreateObject("roAppMemoryMonitor")
    memMonIf = invalid
    if m.memMon <> invalid then
        ' Verifica que la interfaz exista para compatibilidad con distintas versiones de OS
        memMonIf = GetInterface(m.memMon, "ifAppMemoryMonitor")
        if memMonIf <> invalid then
            ' Enlaza el monitor al mismo puerto del loop principal
            m.memMon.SetMessagePort(port)
            ' Habilita warnings cuando el canal entra en presión de memoria
            m.memMon.EnableMemoryWarningEvent(true)

            ' Snapshot inicial de memoria para diagnóstico en logs
            channelAvailableMemory = m.memMon.GetChannelAvailableMemory()
            channelMemoryLimit = m.memMon.GetChannelMemoryLimit()
            memoryLimitPercent = m.memMon.GetMemoryLimitPercent()
        end if
    end if

    ' Eventos de memoria general del dispositivo (no solo del canal)
    m.devInfo = CreateObject("roDeviceInfo")
    if m.devInfo <> invalid then
        m.devInfo.SetMessagePort(port)
        ' Habilita notificación cuando el sistema reporta memoria general baja
        m.devInfo.EnableLowGeneralMemoryEvent(true)
    end if
end sub

function HandleSystemEvents(msg as Object) as Boolean
    msgType = type(msg)
    if msgType = "roAppMemoryMonitorEvent" then
        ' Punto ideal para degradación controlada: limpiar cachés, liberar imágenes pesadas, etc.

        if m.memMon <> invalid then
            ' Snapshot al momento del warning para entender severidad
            channelAvailableMemory = m.memMon.GetChannelAvailableMemory()
            channelMemoryLimit = m.memMon.GetChannelMemoryLimit()
            memoryLimitPercent = m.memMon.GetMemoryLimitPercent()
        end if
        return true
    else if msgType = "roDeviceInfoEvent" then
        ' Evento de memoria general del sistema
        info = msg.GetInfo()
        if info <> invalid and info.generalMemoryLevel <> invalid then
        end if
        return true
    end if

    return false
end function