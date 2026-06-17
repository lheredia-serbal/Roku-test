' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.programContainer = m.top.findNode("programContainer")
    m.animation = m.top.findNode("liveAnimation")
    m.liveOpacityInterpolator = invalid

    m.scaleInfo = m.global.scaleInfo
    m.defaultHeight = scaleValue(32, m.scaleInfo)
    m.spacings = scaleValue(0, m.scaleInfo)
    m.reservedWidth = m.scaleInfo.width - scaleValue(140, m.scaleInfo)
end sub

' Carga la configuracion inicial del componente.
sub initConfig()
    if m.top.initConfig then
        m.reservedWidth = m.scaleInfo.width - scaleValue(140, m.scaleInfo)
        if m.top.width <> 0 then m.reservedWidth = m.top.width

        if m.programTitle <> invalid then m.programTitle.width = m.reservedWidth
        if m.programSubtitle <> invalid then m.programSubtitle.width = m.reservedWidth
        if m.programSynopsis <> invalid then m.programSynopsis.width = m.reservedWidth
    end if
end sub

' Detecta y genera solamente la informacion del programa que se debe mostrar.
sub changeProgram()
    __clearProgramContainer()

    if m.top.program = invalid or m.top.program = "" then return

    program = ParseJson(m.top.program)
    if program = invalid then return

    title = ""
    if program.title <> invalid and program.title <> "" then
        title = program.title
    else if program.channel <> invalid and program.channel.name <> invalid and program.channel.name <> "" then
        title = program.channel.name
    end if

    if title <> "" then
        m.programTitle = __createShadowLabel("programTitle", title, "font:MediumBoldSystemFont", m.defaultHeight)
        m.programContainer.appendChild(m.programTitle)
    end if

    if program.subtitle <> invalid and program.subtitle <> "" then
        m.programSubtitle = __createShadowLabel("programSubtitle", program.subtitle, "font:SmallBoldSystemFont", m.defaultHeight)
        m.programContainer.appendChild(m.programSubtitle)
    end if

    infoText = ""
    visibleLive = false

    if program.startTime <> invalid and program.startTime <> "" and program.endTime <> invalid and program.endTime <> "" then
        startTime = CreateObject("roDateTime")
        endTime = CreateObject("roDateTime")
        nowDate = CreateObject("roDateTime")

        startTime.FromISO8601String(program.startTime)
        startTime.ToLocalTime()

        endTime.FromISO8601String(program.endTime)
        endTime.ToLocalTime()

        nowDate.ToLocalTime()

        durationStr = ""
        if program.durationInMinutes <> invalid and program.durationInMinutes > 0 then durationStr = " - " + program.durationInMinutes.ToStr() + "min"

        nowSeconds = nowDate.AsSeconds()
        startSeconds = startTime.AsSeconds()
        endSeconds = endTime.AsSeconds()

        if startSeconds <= nowSeconds and endSeconds >= nowSeconds then
            remaining = program.remaining
            if remaining <> invalid then
                if remaining > 60 then
                    modMinutes = remaining mod 60
                    hours = remaining \ 60
                    templateStr = i18n_t(m.global.i18n, "time.endsInHoursMin")
                    infoText = templateStr.Replace("{{hours}}", hours.ToStr()).Replace("{{minutes}}", modMinutes.ToStr())
                else
                    modMinutes = remaining mod 60
                    templateStr = i18n_t(m.global.i18n, "time.endsInMin")
                    infoText = templateStr.Replace("{{minutes}}", modMinutes.ToStr())
                end if
                visibleLive = true
            end if
        else if IsToday(startSeconds) then
            infoText = i18n_t(m.global.i18n, "time.today") + " " + dateConverter(startTime, i18n_t(m.global.i18n, "time.formatHours")) + durationStr
        else if IsToday(startSeconds + 86400) then
            ' Si al sumar un día la fecha es hoy, el inicio fue ayer
            infoText = i18n_t(m.global.i18n, "time.yesterday") + " " + dateConverter(startTime, i18n_t(m.global.i18n, "time.formatHours")) + durationStr
        else if IsToday(startSeconds - 86400) then
            ' Si al restar un día la fecha es hoy, el inicio será mañana
            infoText = i18n_t(m.global.i18n, "time.tomorrow") + " " + dateConverter(startTime, i18n_t(m.global.i18n, "time.formatHours")) + durationStr
        else
            infoText = dateConverter(startTime, i18n_t(m.global.i18n, "time.formatDate")) + " - " + dateConverter(startTime, i18n_t(m.global.i18n, "time.formatHours")) + durationStr
        end if
    end if

    if program.channel <> invalid and program.channel.name <> invalid and program.channel.name <> "" then
        if infoText <> "" then infoText += " | "
        infoText += program.channel.name
    end if

    if infoText <> "" or visibleLive then
        infoContainer = CreateObject("roSGNode", "LayoutGroup")
        infoContainer.id = "programInfoContainer"
        infoContainer.layoutDirection = "horiz"
        infoContainer.horizAlignment = "left"
        infoContainer.vertAlignment = "top"
        infoContainer.itemSpacings = [scaleValue(10, m.scaleInfo)]

        if infoText <> "" then
            m.programDateAndChannel = CreateObject("roSGNode", "Label")
            m.programDateAndChannel.id = "programDateAndChannel"
            m.programDateAndChannel.text = infoText
            m.programDateAndChannel.height = m.defaultHeight
            m.programDateAndChannel.vertAlign = "top"
            m.programDateAndChannel.font = "font:TinySystemFont"
            m.programDateAndChannel.color = m.global.colors.LIGHT_GRAY
            infoContainer.appendChild(m.programDateAndChannel)
        end if

        if visibleLive then
            m.programLive = CreateObject("roSGNode", "Label")
            m.programLive.id = "programLive"
            m.programLive.text = i18n_t(m.global.i18n, "time.live")
            m.programLive.height = m.defaultHeight
            m.programLive.vertAlign = "top"
            m.programLive.font = "font:TinySystemFont"
            m.programLive.color = m.global.colors.LIVE_CONTENT
            m.programLive.opacity = 1.0
            infoContainer.appendChild(m.programLive)
        end if

        m.programContainer.appendChild(infoContainer)

        if visibleLive then __startLiveAnimation()
    end if

    if program.synopsis <> invalid and program.synopsis <> "" then
        m.programSynopsis = __createShadowLabel("programSynopsis", program.synopsis, "font:SmallerSystemFont", scaleValue(90, m.scaleInfo))
        m.programSynopsis.wrap = true
        m.programSynopsis.maxLines = 3
        m.programContainer.appendChild(m.programSynopsis)
    end if

    __updateItemSpacings()
end sub

' Crea un ShadowLabel con la estética compartida por el resumen.
function __createShadowLabel(id as string, text as string, font as string, height as float) as object
    label = CreateObject("roSGNode", "ShadowLabel")
    label.id = id
    label.text = text
    label.width = m.reservedWidth
    label.height = height
    label.vertAlign = "top"
    label.font = font
    return label
end function

' Inicia la animación solamente cuando programLive ya puede resolverse desde el árbol.
sub __startLiveAnimation()
    liveNode = m.top.findNode("programLive")
    if liveNode = invalid then return

    m.liveOpacityInterpolator = CreateObject("roSGNode", "FloatFieldInterpolator")
    m.liveOpacityInterpolator.id = "liveOpacityInterpolator"
    m.liveOpacityInterpolator.key = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
    m.liveOpacityInterpolator.keyValue = [1.0, 0.8, 0.6, 0.4, 0.2, 0.0, 0.0, 0.2, 0.4, 0.8, 1.0]
    m.animation.appendChild(m.liveOpacityInterpolator)
    m.liveOpacityInterpolator.fieldToInterp = liveNode.id + ".opacity"
    m.animation.control = "start"
end sub

' Mantiene el espaciado vertical únicamente entre los componentes existentes.
sub __updateItemSpacings()
    itemSpacings = []
    for i = 0 to m.programContainer.getChildCount() - 1
        itemSpacings.push(m.spacings)
    end for
    m.programContainer.itemSpacings = itemSpacings
end sub

' Elimina los componentes generados para que los invisibles no ocupen espacio.
sub __clearProgramContainer()
    m.animation.control = "stop"

    if m.liveOpacityInterpolator <> invalid then
        m.animation.removeChild(m.liveOpacityInterpolator)
        m.liveOpacityInterpolator = invalid
    end if

    while m.programContainer.getChildCount() > 0
        m.programContainer.removeChild(m.programContainer.getChild(0))
    end while

    m.programTitle = invalid
    m.programSubtitle = invalid
    m.programDateAndChannel = invalid
    m.programLive = invalid
    m.programSynopsis = invalid
    m.programContainer.itemSpacings = []
end sub