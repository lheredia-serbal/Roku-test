' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.channelList = m.top.findNode("channelList")
    
    m.scaleInfo = m.global.scaleInfo

    m.targetItems = 8
    m.top.refreshLoadChannelList = 0
    m.separator = scaleValue(18, m.scaleInfo)
    m.size = scaleSize([283, 110], m.scaleInfo)

    m.targetRects = createTargetRects(m.targetItems, -(m.size[1] + m.separator), (m.size[1] + m.separator), m.size[0], m.size[1], "InY")
end sub

' Carga los datos de componente, si no recibe datos o los recibe vacios entonces dispara la limpieza del componete
sub initData()
    if m.top.items <> invalid and m.top.items.count() > 0 then 
        m.top.refreshProgressBars = false
        __populateList()
    else 
        __clearList()
    end if
end sub

' Posiciona el el foco sobre el canal que concuerda con el Id pasado
sub onShowPositioninChannelId()
    if m.top.positioninChannelId  then
        __searchChannelPosition()
        m.channelList.jumpToItem = m.top.channelIdIndexOf
        m.channelList.setFocus(true)
        m.top.positioninChannelId = false
    end if
end sub

' Dispara la busqueda de la posicion del canal.  
sub onSearchChannelPosition()
    if m.top.searchChannelPosition then
        m.top.searchChannelPosition = false 
        __searchChannelPosition()
    end if
end sub

' Dispara la actualizacion de la barra de progreso de todos los nodos de la lista
sub onUpdateProgressBars()
    if  m.top.refreshProgressBars then
        if m.channelList.content <> invalid then
            now = CreateObject("roDateTime")
            now.ToLocalTime()
            nowTime = now.AsSeconds()

            for i = 0 to m.channelList.content.getChildCount() - 1
                itemNode = m.channelList.content.getChild(i)
                if itemNode.percentageElapsed <> invalid and itemNode.startTime <> invalid and itemNode.endTime <> invalid and itemNode.percentageElapsed <> 0 and itemNode.startTime <> 0 and itemNode.endTime <> 0 then
                    itemNode.percentageElapsed = __calculatePercentageElapsed(itemNode.startTime,  itemNode.endTime,  nowTime)
                end if
            end for

        end if
        m.top.refreshProgressBars = false
    end if
end sub

' Devuelve el nodo que se a seleccionado
sub itemSelectedChanged()
    m.top.channelIdIndexOf = m.channelList.itemSelected
    m.top.selected = FormatJson(m.top.items[m.channelList.itemSelected])
end sub

' Limpia todas las propiedades internas o observables necesarios en su uso interno
sub __clearList()
    m.channelList.unobserveField("itemSelected")
    m.channelList.targetSet = invalid
    m.channelList.content = invalid
    m.top.refreshLoadChannelList = 0
    m.top.refreshProgressBars = false
    m.top.channelIdIndexOf = -1
end sub

' Genera el carousel de canales y procesa para cargar cada uno de los nodos en el componente
sub __populateList()
    contentRoot = createObject("roSGNode", "ChannelListItemContentNode")
    startTime = CreateObject("roDateTime")
    endTime = CreateObject("roDateTime")
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    nextLoadList = now.AsSeconds() + 120 
    nextUpdate = 0

    i = 0
    for each item in m.top.items
        if m.top.channelIdIndexOf = -1 and m.top.channelId <> invalid and m.top.channelId <> 0 and m.top.channelId = item.id then m.top.channelIdIndexOf = i

        child = contentRoot.createChild("ChannelListItemContentNode")
        
        if item.number <> invalid then 
            child.channelTitle = item.number.ToStr() + " - " + item.name
        else
            child.channelTitle = item.name
        end if 

        child.key = "ChannelId"
        child.id = item.id

        if item.program <> invalid  then 
            if item.program.title <> invalid then child.programTitle = item.program.title 
            
            if item.program.percentageElapsed <> invalid then 
                child.percentageElapsed = item.program.percentageElapsed
            else 
                child.percentageElapsed = 0 
            end if
            
            if item.program.endTime <> invalid then
                endTime.FromISO8601String(item.program.endTime)
                endTime.ToLocalTime()
                endTimeEpoch = endTime.AsSeconds() 

                if nextUpdate <> 0 then
                    if nextUpdate > endTimeEpoch and endTimeEpoch > nextLoadList then 
                        if endTimeEpoch < nextLoadList then
                            nextUpdate = nextLoadList    
                        else 
                            nextUpdate = endTimeEpoch
                        end if
                    end if
                else 
                    if endTimeEpoch < nextLoadList then 
                        nextUpdate = endTimeEpoch
                    else 
                        nextUpdate = nextLoadList
                    end if
                end if 

                if item.program.startTime <> invalid  then 
                    startTime.FromISO8601String(item.program.startTime)
                    startTime.ToLocalTime()
                    child.startTime = startTime.AsSeconds()
                    child.endTime = endTime.AsSeconds()
        
                    child.date = dateConverter(startTime, i18n_t(m.global.i18n, "time.formatHours")) + " - " + dateConverter(endTime, i18n_t(m.global.i18n, "time.formatHours"))
                end if
            end if
        end if

        child.imageURL = getImageUrl(item.image)
        i++
    end for

    if (m.top.channelIdIndexOf = -1) then m.top.channelIdIndexOf = 0 
  
    m.top.refreshLoadChannelList = nextUpdate
    ' Configura channelList utilizando la función de setup (ajusta los valores según diseño)
    focusedTargetSet = createObject("roSGNode", "TargetSet")
    
    __setupTargetList(focusedTargetSet, contentRoot)
end sub
  
' Función para configurar un TargetList con su TargetSet y contenido
sub __setupTargetList(targetSet as Object, content as Object)
    ' Genera las posiciones de los targets dinámicamente según la cantidad de items
    targetSet.targetRects = m.targetRects
    targetSet.focusIndex = 2
    
    m.channelList.targetSet = targetSet
    m.channelList.content = content
    m.channelList.itemComponentName = "ChannelListItem"
    m.channelList.showTargetRects = false
    m.channelList.observeField("itemSelected", "itemSelectedChanged")
end sub

' Busca la posicion de un canal en la lista de canales y hace foco en él
sub __searchChannelPosition()
    if m.top.channelIdIndexOf = -1 then 
        items = m.top.items
        for i = 0 to items.count() - 1
            if m.top.channelIdIndexOf = -1 and m.top.channelId <> invalid and m.top.channelId <> 0 and m.top.channelId = items[i].id then 
                m.top.channelIdIndexOf = i
                i = items.count() - 1
            end if 
        end for

        if m.top.channelIdIndexOf = -1 then m.top.channelIdIndexOf = 0 
    end if
end sub

' Actualiza las barras de progreso de cada programa
function __calculatePercentageElapsed(startEpoch as integer, endEpoch as integer, nowEpoch as integer) as Integer
    if nowEpoch <= startEpoch then return 0
    if nowEpoch >= endEpoch then return 100

    percent = Int(((nowEpoch - startEpoch) / (endEpoch - startEpoch)) * 100)
    return percent
end function