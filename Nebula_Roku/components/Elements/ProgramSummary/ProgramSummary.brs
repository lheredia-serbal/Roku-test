' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.scaleInfo = m.global.scaleInfo
    if m.scaleInfo = invalid then
        m.scaleInfo = getScaleInfo()
    end if

    m.programContainer = m.top.findNode("programContainer")
    m.programTitle = m.top.findNode("programTitle")
    m.programSubtitle = m.top.findNode("programSubtitle")
    m.programDateAndChannel = m.top.findNode("programDateAndChannel")
    m.programLive = m.top.findNode("programLive")
    m.programSynopsis = m.top.findNode("programSynopsis")

    m.animation = m.top.findNode("liveAnimation")

    m.HeightToHide = 1
    m.defaultHeight = 0
    m.spacings = scaleValue(10, m.scaleInfo)

    m.i18n = invalid
    scene = m.top.getScene()
    if scene <> invalid then
        m.i18n = scene.findNode("i18n")
    end if

    applyTranslations()
end sub

sub applyTranslations()
    if m.i18n = invalid then
        return
    end if

    m.programLive.text = i18n_t(m.i18n, "program.programDetail.live")
end sub

' Carga la configuracion inicial del componente, escuchando los observable y obteniendo las 
' referencias de compenentes necesarios para su uso
sub initConfig()
    if m.top.initConfig then 
        m.reservedWidth = (m.global.width - scaleValue(140, m.scaleInfo))
        if m.top.width <> 0 then m.reservedWidth = m.top.width

        m.programTitle.width = m.reservedWidth
        m.programSubtitle.width = m.reservedWidth
        m.programSynopsis.width = m.reservedWidth
        
        m.programDateAndChannel.color = m.global.colors.LIGHT_GRAY
        m.programLive.color = m.global.colors.LIVE_CONTENT

        m.programContainer.itemSpacings = [0, 0, 0, 0]
    end if
end sub

' Detecta y actualiza la informacion del programa a mostrar.
sub changeProgram()
    if m.top.program <> invalid and m.top.program <> "" then
        __clearProgramContainer()

        visibleLive = false
        showTitle = false
        showSubtitle = false
        showChannelAndDateOrLive = false
        showSynopsis = false
        particularItemSpacings = [0, 0, 0, 0]
        program = ParseJson(m.top.program)


        if program.title <> invalid and program.title <> "" then
            showTitle = true
            particularItemSpacings[0] = m.spacings
        else if program.channel <> invalid and program.channel.name <> invalid and program.channel.name <> "" then
            showTitle = true
            particularItemSpacings[0] = m.spacings
        end if
        
        if program.subtitle <> invalid and program.subtitle <> "" then
            showSubtitle = true
            particularItemSpacings[1] = m.spacings
        end if 
        
        if (program.startTime <> invalid and program.startTime <> "" and program.endTime <> invalid and program.endTime <> "") or (program.channel <> invalid and program.channel.name <> invalid and program.channel.name <> "") then
            showChannelAndDateOrLive = true
            particularItemSpacings[2] = m.spacings
        end if
        
        if program.synopsis <> invalid and program.synopsis <> "" then
            showSynopsis = true
            particularItemSpacings[3] = m.spacings
        end if


        m.programContainer.itemSpacings = particularItemSpacings


        ' Title
        if showTitle then
            if program.title <> invalid and program.title <> "" then
                m.programTitle.text = program.title
                m.programTitle.height = m.defaultHeight
                m.programTitle.visible = true
            else if program.channel <> invalid and program.channel.name <> invalid and program.channel.name <> "" 
                m.programTitle.text = program.channel.name
                m.programTitle.height = m.defaultHeight
                m.programTitle.visible = true
            end if
        end if

        ' Subtitle
        if showSubtitle then 
            m.programSubtitle.text = program.subtitle
            m.programSubtitle.height = m.defaultHeight
            m.programSubtitle.visible = true
        end if 

        ' Channel - Date | Live 
        if showChannelAndDateOrLive then
            if (program.startTime <> invalid and program.startTime <> "" and program.endTime <> invalid and program.endTime <> "") then
                startTime = CreateObject("roDateTime")
                endTime = CreateObject("roDateTime")
                nowDate = CreateObject("roDateTime")
                
                startTime.FromISO8601String(program.startTime)
                startTime.ToLocalTime()
    
                endTime.FromISO8601String(program.endTime)
                endTime.ToLocalTime()
    
                nowDate.ToLocalTime()
    
                durationStr = ""
                if (program.durationInMinutes > 0) then durationStr = " - " + program.durationInMinutes.ToStr() + "min"
    
                nowSeconds = nowDate.AsSeconds()
                startSeconds = startTime.AsSeconds()
                endSeconds = endTime.AsSeconds()
    
                if (startSeconds <= nowSeconds and endSeconds >= nowSeconds) then
                    ' El programa está en vivo
                    remaining = program.remaining
        
                    if remaining <> invalid then
                        if (remaining > 60) then
                            modMinutes = remaining mod 60
                            hours = remaining \ 60
                            templateStr = "Ends in [hours]h [minutes]m"
                            m.programDateAndChannel.text = templateStr.Replace("[hours]", hours.ToStr()).Replace("[minutes]", modMinutes.ToStr())
                        else
                            modMinutes = remaining mod 60
                            templateStr = "Ends in [minutes] min"
                            m.programDateAndChannel.text = templateStr.Replace("[minutes]", modMinutes.ToStr())
                        end if
                        visibleLive = true
                    end if
        
                else if (IsToday(startSeconds)) then
                    m.programDateAndChannel.text = "Today " + dateConverter(startTime, "HH:mm a") + durationStr
                    m.programDateAndChannel.height = m.defaultHeight
                    m.programDateAndChannel.visible = true
                else if (IsToday(startSeconds + 86400)) then
                    ' Si al sumar un día la fecha es hoy, el inicio fue ayer
                    m.programDateAndChannel.text = "Yesterday " + dateConverter(startTime, "HH:mm a") + durationStr
                    m.programDateAndChannel.height = m.defaultHeight
                    m.programDateAndChannel.visible = true
                else if (IsToday(startSeconds - 86400)) then
                    ' Si al restar un día la fecha es hoy, el inicio será mañana
                    m.programDateAndChannel.text = "Tomorrow " + dateConverter(startTime, "HH:mm a") + durationStr
                    m.programDateAndChannel.height = m.defaultHeight
                    m.programDateAndChannel.visible = true
                else
                    m.programDateAndChannel.text = dateConverter(startTime, "MM/dd/yyyy") + " - " + dateConverter(startTime, "HH:mm a") + durationStr
                    m.programDateAndChannel.height = m.defaultHeight
                    m.programDateAndChannel.visible = true
                end if
            end if
    
            if program.channel <> invalid and program.channel.name <> invalid and program.channel.name <> ""  then
                if m.programDateAndChannel.text <> "" then m.programDateAndChannel.text = m.programDateAndChannel.text + " | "
    
                m.programDateAndChannel.text = m.programDateAndChannel.text + program.channel.name
                m.programDateAndChannel.height = m.defaultHeight
                m.programDateAndChannel.visible = true
                
                if visibleLive then 
                    m.programLive.height = m.defaultHeight
                    m.programLive.opacity = "1.0"
                    m.animation.control = "start"
                end if
            end if
        end if
        
        ' Sinopsis
        if showSynopsis then
            m.programSynopsis.text = program.synopsis
            m.programSynopsis.height = m.defaultHeight
            m.programSynopsis.visible = true
        end if

    else
        __clearProgramContainer()
    end if 
end sub

' Limpia el contenedor del programa
sub __clearProgramContainer()
    m.animation.control = "stop"
    m.programLive.opacity = "0.0"

    if m.programTitle.visible then 
        m.programTitle.text = ""
        m.programTitle.height = m.HeightToHide
        m.programTitle.visible = false
    end if 

    if m.programSubtitle.visible then
        m.programSubtitle.text = ""
        m.programSubtitle.height = m.HeightToHide
        m.programSubtitle.visible = false
    end if

    if m.programDateAndChannel.visible then
        m.programDateAndChannel.text = ""
        m.programDateAndChannel.height = m.HeightToHide
        m.programDateAndChannel.visible = false
    end if

    if m.programLive.visible then
        m.programLive.height = m.HeightToHide
        m.programLive.opacity = "0.0"
    end if

    if m.programSynopsis.visible then
        m.programSynopsis.text = ""
        m.programSynopsis.height = m.HeightToHide
        m.programSynopsis.visible = false
    end if

    m.programContainer.itemSpacings = [0, 0, 0, 0]
end sub
