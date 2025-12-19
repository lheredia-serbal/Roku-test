' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.scaleInfo = m.global.scaleInfo
    if m.scaleInfo = invalid then
        m.scaleInfo = getScaleInfo()
    end if

    m.programContainer = m.top.findNode("programContainer")
    m.programRectangleContainer = m.top.findNode("programRectangleContainer")
    m.programTitle = m.top.findNode("programTitle")
    m.programSubtitle = m.top.findNode("programSubtitle")
    m.programCategory = m.top.findNode("programCategory")
    m.programDate = m.top.findNode("programDate")
    m.programSynopsis = m.top.findNode("programSynopsis")
    m.programAvailableView = m.top.findNode("programAvailableView")

    m.reservedHeight = scaleValue(240, m.scaleInfo)
    m.reservedWidth = scaleValue(1200, m.scaleInfo)
    m.HeightToHide = 1
    m.defaultHeight = 0
    m.spacings = scaleValue(10, m.scaleInfo)
    m.buttonExist = scaleSize([220, 30], m.scaleInfo)
    m.buttonNotExist = [1, 1]

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

    m.programAvailableView.text = i18n_t(m.i18n, "player.guide.availableToView")
end sub


' Carga la configuracion inicial del componente, escuchando los observable y obteniendo las 
' referencias de compenentes necesarios para su uso
sub initConfig()
    if m.top.initConfig then 
        width = m.global.width
        m.reservedWidth = width - scaleValue(140, m.scaleInfo)
    
        m.programRectangleContainer.width = m.reservedWidth
        m.programRectangleContainer.height = m.reservedHeight
        
        m.programContainer.translation = [0, m.reservedHeight]

        m.programTitle.width = m.reservedWidth
        m.programSubtitle.width = m.reservedWidth
        m.programSynopsis.width = m.reservedWidth
        
        m.programCategory.color = m.global.colors.LIGHT_GRAY
        m.programDate.color = m.global.colors.SECONDARY

        AvailableViewColor = m.global.colors.AVAILABLE_VIEW

        m.programAvailableView.textColor = AvailableViewColor
        m.programAvailableView.borderColor = AvailableViewColor

        m.programContainer.itemSpacings = [0, 0, 0, 0, 0]
    end if
end sub

' Detecta y actualiza la informacion del programa a mostrar.
sub changeProgram()
    if m.top.program <> invalid then
        __clearProgramContainer()

        showTitle = false
        showSubtitle = false
        showCategoryOrDate = false
        showSynopsis = false
        showAvailableView = false
        particularItemSpacings = [0, 0, 0, 0, 0]

        
        if (m.top.program.title <> invalid and m.top.program.title <> "") or (m.top.program.channelName <> invalid and m.top.program.channelName <> "") then
            showTitle = true
            particularItemSpacings[0] = m.spacings
        end if
        
        if m.top.program.subtitle <> invalid and m.top.program.subtitle <> "" then
            showSubtitle = true
            particularItemSpacings[1] = m.spacings
        end if 
        
        if (m.top.program.startTime <> invalid and m.top.program.startTime <> "") or (m.top.program.categoryName <> invalid and m.top.program.categoryName <> "") or (m.top.program.channelCategory <> invalid and m.top.program.channelCategory <> "") then
            showCategoryOrDate = true
            particularItemSpacings[2] = m.spacings
        end if
        
        if m.top.program.synopsis <> invalid and m.top.program.synopsis <> "" then
            showSynopsis = true
            particularItemSpacings[3] = m.spacings
        end if

        if m.top.showAvailableView then
            nowDate = CreateObject("roDateTime")
            nowDate.ToLocalTime()
            nowSeconds = nowDate.AsSeconds()
            
            catchupDate = CreateObject("roDateTime")
            catchupDate.ToLocalTime()
            catchupDateSeconds = catchupDate.AsSeconds()
            catchupDateSeconds = catchupDateSeconds - (m.top.catchupDuration * 60 * 60) ' el catchup llega en horas 
          
            if ((m.top.program.startSeconds = invalid and m.top.program.endSeconds = invalid) or (m.top.program.startSeconds <= nowSeconds and m.top.program.endSeconds >= nowSeconds)) then 
                showAvailableView = true
                particularItemSpacings[4] = m.spacings

            else if m.top.catchupDuration <> 0 and catchupDateSeconds <= m.top.program.endSeconds and m.top.program.endSeconds <= nowSeconds then
                showAvailableView = true
                particularItemSpacings[4] = m.spacings
            end if
        end if 

        m.programContainer.itemSpacings = particularItemSpacings


        ' Title
        if showTitle then
            if m.top.program.title <> invalid and m.top.program.title <> "" then    
                m.programTitle.text = m.top.program.title
                m.programTitle.height = m.defaultHeight
                m.programTitle.visible = true
            else if m.top.program.channelName <> invalid and m.top.program.channelName <> "" then
                m.programCategory.text = m.top.program.channelName
                m.programCategory.height = m.defaultHeight
                m.programCategory.visible = true
            end if
        end if


        ' Subtitle
        if showSubtitle then 
            m.programSubtitle.text = m.top.program.subtitle
            m.programSubtitle.height = m.defaultHeight
            m.programSubtitle.visible = true
        end if 
        
        
        ' Category y Date
        if showCategoryOrDate then
            if m.top.program.categoryName <> invalid then 
                m.programCategory.text = m.top.program.categoryName
                m.programCategory.height = m.defaultHeight
                m.programCategory.visible = true
            else if m.top.program.channelCategory <> invalid and m.top.program.channelCategory <> "" then
                 m.programCategory.text = m.top.program.channelCategory
                m.programCategory.height = m.defaultHeight
                m.programCategory.visible = true
            end if 
            
            date = invalid
            if (m.top.program.startTime <> invalid and m.top.program.startTime <> "") then
                startTime = CreateObject("roDateTime")
                startTime.FromISO8601String(m.top.program.startTime)
                startTime.ToLocalTime()
    
                durationStr = ""
                if (m.top.program.durationInMinutes > 0) then durationStr = " - " + m.top.program.durationInMinutes.ToStr() + "min"
    
                if (IsToday(m.top.program.startSeconds)) then
                    date = "Today " + dateConverter(startTime, "HH:mm a") + durationStr
                else if (IsToday(m.top.program.startSeconds + 86400)) then
                    ' Si al sumar un día la fecha es hoy, el inicio fue ayer
                    date = "Yesterday " + dateConverter(startTime, "HH:mm a") + durationStr
                else if (IsToday(m.top.program.startSeconds - 86400)) then
                    ' Si al restar un día la fecha es hoy, el inicio será mañana
                    date = "Tomorrow " + dateConverter(startTime, "HH:mm a") + durationStr
                else
                    date = dateConverter(startTime, "MM/dd/yyyy") + " - " + dateConverter(startTime, "HH:mm a") + durationStr
                end if
                
                if date <> invalid then 
                    m.programDate.text = date
                    m.programDate.height = m.defaultHeight
                    m.programDate.visible = true
                end if
            end if

        end if

        ' Sinopsis
        if showSynopsis then
            m.programSynopsis.text = m.top.program.synopsis
            m.programSynopsis.height = m.defaultHeight
            m.programSynopsis.visible = true
        end if


        ' Disponible para ver 
        if showAvailableView then
            m.programAvailableView.size = m.buttonExist
            m.programAvailableView.visible = true 
        end if 
    else
        __clearProgramContainer()
    end if 
end sub 


' Limpia el contenedor del programa
sub __clearProgramContainer()
    
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

    if m.programCategory.visible then
        m.programCategory.text = ""
        m.programCategory.height = m.HeightToHide
        m.programCategory.visible = false
    end if

    if m.programDate.visible then
        m.programDate.text = ""
        m.programDate.height = m.HeightToHide
        m.programDate.visible = false
    end if

    if m.programSynopsis.visible then
        m.programSynopsis.text = ""
        m.programSynopsis.height = m.HeightToHide
        m.programSynopsis.visible = false
    end if
    
    if m.programAvailableView.visible then
        m.programAvailableView.size = m.buttonNotExist
        m.programAvailableView.visible = false
    end if

    m.programContainer.itemSpacings = [0, 0, 0, 0, 0]
end sub
