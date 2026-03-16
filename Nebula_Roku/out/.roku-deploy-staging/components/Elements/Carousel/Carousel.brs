' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
  m.carouselList = m.top.findNode("carouselList")
  m.carouselTitle = m.top.findNode("carouselTitle")
  
  ' Referencio el label secundario donde se dibujarán los tags de título.
  m.carouselTitleTags = m.top.findNode("carouselTitleTags")
  
  m.scaleInfo = m.global.scaleInfo
  
  m.carouselTitle.translation = scalePoint([70, 75], m.scaleInfo)

  ' Alineo verticalmente los tags con el título principal del carrusel.
  m.carouselList.translation = scalePoint([-80, 130], m.scaleInfo)

  m.labelSpace = scaleValue(40, m.scaleInfo)
  m.separator = scaleValue(30, m.scaleInfo)
  m.xInitial = 0
  m.clearItems = createObject("roSGNode", "CarouselItemContentNode")
  m.targetRects = invalid
end sub

' Carga los datos de componente, si no recibe datos o los recibe vacios entonces dispara la limpieza del componete
sub initData()
  if m.top.items <> invalid and m.top.items.count() > 0 then
    ' Seteo el título principal del carrusel con el valor recibido.
    m.carouselTitle.text = m.top.title

    ' Ajusto el ancho del título según su texto renderizado para que el row horizontal calcule bien.
    titleWidth = __syncCarouselTitleWidth()
    m.carouselTitle.height = scaleValue(48, m.scaleInfo)
    ' Seteo por defecto el texto de tags (puede ser vacío si no aplica).

    if m.carouselTitleTags <> invalid then m.carouselTitleTags.text = m.top.titleTagsText
    m.items = m.top.items
    __populateList()
  else 
    __clearList()
  end if
end sub

' Calcula y aplica el ancho del título con base en su texto renderizado.
sub __syncCarouselTitleWidth()
  ' Obtengo el ancho real del texto ya renderizado en el label.
  titleBounds = m.carouselTitle.boundingRect()
  ' Inicializo el ancho con cero para decidir si uso valor real o fallback por caracteres.
  titleWidth = 0
  ' Si todavía no hay ancho renderizado (primer frame), calculo fallback por cantidad de caracteres.
  if titleWidth = 0 then titleWidth = (len(m.top.title) * scaleValue(12, m.scaleInfo))
  ' Aplico un mínimo para que el label no colapse visualmente.
  if titleWidth < scaleValue(20, m.scaleInfo) then titleWidth = scaleValue(20, m.scaleInfo)
  ' Seteo el ancho final para que el layout horizontal ubique tags pegados al título.
  m.carouselTitle.width = titleWidth
  ' Solo cuando titleWidth tiene valor, posiciono los tags en X según ancho del título y Y fija solicitada.
  if titleWidth > 0 and m.carouselTitleTags <> invalid then 
    m.carouselTitleTags.translation = scaleSize([titleWidth - 140, 103], m.scaleInfo)
  end if
end sub

' Define la configuracion necesaria del estilo del carousel
sub initSyle()
  if m.top.style = -1 then ' AvatarsItem
    m.top.size = scaleSize([120, 120], m.scaleInfo)
    m.labelSpace = scaleValue(60, m.scaleInfo)
    m.separator = scaleValue(20, m.scaleInfo)
    m.top.height = (m.top.size[1] + m.labelSpace)
    m.targetItems = 12
    m.styleItem = "AvatarItem"
    m.xInitial = scaleValue(-171, m.scaleInfo)
    m.carouselTitle.translation = scalePoint([29, 110], m.scaleInfo)
    m.targetRects = createTargetRects(m.targetItems, m.xInitial, (m.top.size[0] + m.separator), m.top.size[0], m.top.size[1])

  else if m.top.style = getCarouselStyles().PORTRAIT_FEATURED then ' carouselPortraitFeatured
    m.top.size = scaleSize([270, 405], m.scaleInfo)
    __defaultConfig()
    m.top.height = (m.top.size[1] + m.labelSpace)
    m.targetItems = 6
    m.styleItem = "BasicItem"
    m.xInitial = scaleValue(-449, m.scaleInfo)
    m.targetRects = createTargetRects(m.targetItems, m.xInitial, (m.top.size[0] + m.separator), m.top.size[0], m.top.size[1])

  else if m.top.style = getCarouselStyles().LANDSCAPE_STANDARD then ' carouselLandscapeStandard
    m.top.size = scaleSize([450, 253], m.scaleInfo)
    __defaultConfig()
    m.top.height = (m.top.size[1] + m.labelSpace)
    m.targetItems = 5
    m.styleItem = "BasicItem"
    m.xInitial = scaleValue(-808, m.scaleInfo)
    m.targetRects = createTargetRects(m.targetItems, m.xInitial, (m.top.size[0] + m.separator), m.top.size[0], m.top.size[1])

  else if m.top.style = getCarouselStyles().LANDSCAPE_FEATURED then ' carouselLandscapeFeatured
    m.top.size = scaleSize([450, 253], m.scaleInfo)
    __defaultConfig()
    m.top.height = (m.top.size[1] + m.labelSpace)
    m.targetItems = 4
    m.styleItem = "BasicItem"
    m.xInitial = scaleValue(-808, m.scaleInfo)
    m.targetRects = createTargetRects(m.targetItems, m.xInitial, (m.top.size[0] + m.separator), m.top.size[0], m.top.size[1])

  else if m.top.style = getCarouselStyles().SQUARE_STANDARD then ' carouselSquareStandard
    m.top.size = scaleSize([120, 120], m.scaleInfo)
    __defaultConfig()
    m.top.height = (m.top.size[1] + m.labelSpace)
    m.targetItems = 10
    m.styleItem = "SquareItem"
    m.xInitial = scaleValue(-150, m.scaleInfo)
    m.targetRects = createTargetRects(m.targetItems, m.xInitial, (m.top.size[0] + m.separator), m.top.size[0], m.top.size[1])

  else if m.top.style = getCarouselStyles().SQUARE_FEATURED then ' carouselSquareFeatured
    m.top.size = scaleSize([310, 110], m.scaleInfo)
    __defaultConfig()
    m.top.height = (m.top.size[1] + m.labelSpace)
    m.targetItems = 6
    if (m.top.contentType = getCarouselContentType().PROGRAMS) then
      m.styleItem = "SquareFeaturedProgramItem"
    else
      m.styleItem = "SquareFeaturedItem"
    end if
    m.xInitial = scaleValue(-530, m.scaleInfo)
    m.targetRects = createTargetRects(m.targetItems, m.xInitial, (m.top.size[0] + m.separator), m.top.size[0], m.top.size[1])

  else ' Style = getCarouselStyles().PORTRAIT_STANDARD and default carouselPortraitStandard
    m.top.size = scaleSize([180, 270], m.scaleInfo)
    __defaultConfig()
    m.top.height = (m.top.size[1] + m.labelSpace)
    m.targetItems = 8
    m.styleItem = "BasicItem"
    m.xInitial = scaleValue(-269, m.scaleInfo)
    m.targetRects = createTargetRects(m.targetItems, m.xInitial, (m.top.size[0] + m.separator), m.top.size[0], m.top.size[1])

  end if 
end sub

' Devuelve el nodo que se a seleccionado
sub onItemSelectedChanged()
  m.top.selected = FormatJson(m.items[m.carouselList.itemSelected])
end sub

' devuelve el nodo que esta teniendo el foco.
sub onItemFocusedChanged()
  focusTo = m.items[m.carouselList.itemFocused]
  if focusTo <> invalid then
    focusTo.itempPosition = m.carouselList.itemFocused
    focusTo.imageType = m.top.imageType
    focusTo.carouselCode = m.top.code
    m.top.focused = FormatJson(focusTo)
  end if
end sub

' Procesa el evento flecha izquierda al llegar al final del carousel.
sub onProcessLeftEvent()
  newItem = m.carouselList.itemFocused - 1
  if m.carouselList.leftEvent and newItem = -1 then 
    m.top.openMenu = not m.top.openMenu
  end if
end sub

' actualiza la informacion del nodo que actualmente tiene foco
sub onUpdateNode()
  if m.top.updateNode <> invalid and m.top.updateNode <> "" and m.items <> invalid and m.items.count() > 0 then 
    indexFocused = m.carouselList.itemFocused

    newInfo = ParseJson(m.top.updateNode)
    m.top.updateNode = invalid

    oldInfo = m.items[indexFocused]

    if oldInfo = invalid then return
    child = m.carouselList.content.getChild(indexFocused)

    if oldInfo.redirectKey = newInfo.infoKey and oldInfo.redirectId = newInfo.infoId then
      if newInfo.percentageElapsed <> invalid and m.top.style <> getCarouselStyles().SQUARE_STANDARD then 
        oldInfo.percentageElapsed = newInfo.percentageElapsed
      else if oldInfo.percentageElapsed <> invalid then
         oldInfo.percentageElapsed = invalid
      end if
  
      if newInfo.startTime <> invalid then oldInfo.startTime = newInfo.startTime
      if newInfo.endTime <> invalid then oldInfo.endTime = newInfo.endTime
  
      if oldInfo.key = "ChannelId" and m.top.style = getCarouselStyles().SQUARE_STANDARD then 
        oldInfo.title = newInfo.channel.name
        oldInfo.image = newInfo.channel.image
        
      else if oldInfo.key = "ChannelId" and m.top.style = getCarouselStyles().SQUARE_FEATURED and m.top.contentType = getCarouselContentType().CHANNELS then
        oldInfo.title = newInfo.title
        oldInfo.image = newInfo.channel.image

      else 
        oldInfo.title = newInfo.title
        if getImageUrl(newInfo.image) <> getImageUrl (newInfo.channel.iamge) then 
          oldInfo.image = newInfo.image
        end if
      end if
      
      m.items[indexFocused] = oldInfo
  
      startTime = CreateObject("roDateTime")
      endTime = CreateObject("roDateTime")
      
      if child <> invalid then 
        child.title = oldInfo.title
        child.percentageElapsed = oldInfo.percentageElapsed
        child.category = oldInfo.category
    
        if oldInfo.endTime <> invalid then
          endTime.FromISO8601String(oldInfo.endTime)
          endTime.ToLocalTime()
    
          if oldInfo.startTime <> invalid  then 
            startTime.FromISO8601String(oldInfo.startTime)
            startTime.ToLocalTime()
    
            child.date = dateConverter(startTime, i18n_t(m.global.i18n, "time.formatHours")) + " - " + dateConverter(endTime, i18n_t(m.global.i18n, "time.formatHours"))
          end if
        end if
        
        child.imageURL = getImageUrl(oldInfo.image)
      end if
    end if
  end if 
end sub

' Define la configuracion inicial
sub __defaultConfig()
  m.separator = scaleValue(30, m.scaleInfo)
end sub

' Limpia todas las propiedades internas o observables necesarios en su uso interno
sub __clearList()
  m.carouselList.unobserveField("itemSelected")
  m.carouselList.unobserveField("itemFocused")
  m.carouselList.unobserveField("leftEvent")
  m.items = m.clearItems
  m.carouselTitle.text = ""
  ' Limpio el texto de tags cuando se vacía el carrusel.
  if m.carouselTitleTags <> invalid then m.carouselTitleTags.text = ""
  m.carouselList.jumpToItem = 0 
  m.carouselList.targetSet = invalid
  m.carouselList.content = m.items
  m.carouselList.itemComponentName = invalid
  m.top.id = 0
  m.top.style = 0
  m.top.title = ""
  m.top.code = invalid
  m.top.contentType = 0
  m.top.imageType = 0
  m.top.redirectType = 0
  m.top.focusDown = invalid
  m.top.focusUp = invalid
  m.targetRects = invalid
end sub

' Ejemplo de función populateList que usa el API para obtener items y configurar el carousel
sub __populateList()
  ' Supongamos que m.items contiene la lista de items recibidos del servidor
  contentRoot = createObject("roSGNode", "CarouselItemContentNode")
  startTime = CreateObject("roDateTime")
  endTime = CreateObject("roDateTime")
  
  for each item in m.items
    child = contentRoot.createChild("CarouselItemContentNode")
    child.title = item.title
    child.key = item.key
    child.id = item.id
    child.redirectKey = item.redirectKey
    child.redirectId = item.redirectId
    child.percentageElapsed = item.percentageElapsed
    child.category = item.category
    child.contentType = m.top.contentType
    child.size = m.top.size
    child.style = m.top.style

    if item.endTime <> invalid then
      endTime.FromISO8601String(item.endTime)
      endTime.ToLocalTime()

      if item.startTime <> invalid  then 
        startTime.FromISO8601String(item.startTime)
        startTime.ToLocalTime()

        child.date = dateConverter(startTime, i18n_t(m.global.i18n, "time.formatHours")) + " - " + dateConverter(endTime, i18n_t(m.global.i18n, "time.formatHours"))
      end if
    end if
    
    child.imageURL = getImageUrl(item.image)
  end for

  ' Mostrar una tarjeta adicional que pueder ser "Ver todos" o "Ir a la guía"
  if (m.top.redirectType = 4 or m.top.redirectType = 2 or m.top.redirectType = 3) then
    child = contentRoot.createChild("CarouselItemContentNode")
    child.key = 0
    child.id = 0
    child.redirectKey = 0
    child.redirectId = 0
    child.percentageElapsed = 0
    child.category = 0
    child.contentType = 0
    child.size = m.top.size
    child.style = m.top.style
    child.imageURL = ""

    ' La tarjeta es de "Ver todos"
    if m.top.redirectType = 4 then
      child.title = i18n_t(m.global.i18n, "content.contentPage.seeMore")
      child.showSeeMore = true
    end if

    ' La tarjeta es "Ir a la guía"
    if (m.top.redirectType = 2 or m.top.redirectType = 3) then
      child.title = i18n_t(m.global.i18n, "content.contentPage.goToGuide")
      child.goToGuide = true
    end if

    ' Guardamos un nodo lógico equivalente en m.items para poder detectar la selección de "Ver todos".
    m.items.push({
      title: child.title
      key: child.key
      id: child.id
      redirectKey: child.redirectKey
      redirectId: child.redirectId
      showSeeMore: child.showSeeMore
      goToGuide: child.goToGuide
      carouselId: m.top.id
      carouselCode: m.top.code
      carouselTitle: m.top.title
    })
  end if

  ' Configura carouselList  utilizando la función de setup (ajusta los valores según diseño)
  focusedTargetSet = createObject("roSGNode", "TargetSet")
  
  __setupTargetList(focusedTargetSet, contentRoot)
end sub

function __getCarouselTitleRenderedWidth() as float
  if m.carouselTitle = invalid then return 0

  mainTitleNode = m.carouselTitle.findNode("mainText")
  if mainTitleNode <> invalid then
    return mainTitleNode.localBoundingRect().width
  end if

  return m.carouselTitle.localBoundingRect().width
end function

' Función para configurar un TargetList con su TargetSet y contenido
sub __setupTargetList(targetSet as Object, content as Object)
  ' Genera las posiciones de los targets dinámicamente según la cantidad de items
  targetSet.targetRects = m.targetRects
  targetSet.focusIndex = 2
  
  m.carouselList.targetSet = targetSet
  m.carouselList.content = content
  m.carouselList.itemComponentName = m.styleItem
  m.carouselList.showTargetRects = false
  m.carouselList.observeField("itemSelected", "onItemSelectedChanged")
  m.carouselList.observeField("itemFocused", "onItemFocusedChanged")
  m.carouselList.ObserveField("leftEvent", "onProcessLeftEvent")
end sub

