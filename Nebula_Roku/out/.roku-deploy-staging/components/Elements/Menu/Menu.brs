' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()

  m.opacityForMenu = m.top.findNode("opacityForMenu")
  m.groupOpacityForMenu = m.top.findNode("groupOpacityForMenu")
  m.backgroundMenu = m.top.findNode("backgroundMenu")
  m.menuContainer = m.top.findNode("menuContainer")
  
  m.principalMenuLayoutGroup = m.top.findNode("principalMenuLayoutGroup")
  m.secondaryMenuLayoutGroup = m.top.findNode("secondaryMenuLayoutGroup")
  m.exitLabel = m.top.findNode("exitLabel")
  m.logoutLabel = m.top.findNode("logoutLabel")
  m.settingLabel = m.top.findNode("settingLabel")
  
  m.menuExpandAnimation = m.top.findNode("MenuExpandAnimation")
  m.menuCollapseAnimation = m.top.findNode("MenuCollapseAnimation")
  m.menuExpandVector2DFAnimation = m.top.findNode("menuExpandVector2DFAnimation")
  m.menuCollapseVector2DFAnimation = m.top.findNode("menuCollapseVector2DFAnimation")
  m.secondaryMenuLayoutGroupAnimation = m.top.findNode("secondaryMenuLayoutGroupAnimation")
  
  m.avatarMenuContainer = m.top.findNode("avatarMenuContainer")
  m.avatarImage = m.top.findNode("avatarImage")
  m.avatarImageOpacity = m.top.findNode("avatarImageOpacity")
  m.selectedProfileChange = m.top.findNode("selectedProfileChange")
  m.avatarName = m.top.findNode("avatarName")
  m.profileChange = m.top.findNode("profileChange")
  m.profileContainer = m.top.findNode("profileContainer")
  
  m.exitItem = {key: "MenuId", Id: -1, code: "exit", behavior: "exit"}
  m.logoutItem = {key: "MenuId", Id: -1, code: "logout", behavior: "logout"}
  m.settingItem = {key: "MenuId", Id: -1, code: "setting", behavior: "setting"}
  m.changeProfilesItem = {key: "MenuId", Id: -1, code: "profiles", behavior: "profiles"}
  m.homeItem = invalid

  m.orderSecondaryMenu = [m.settingLabel, m.exitLabel, m.logoutLabel]
  m.positionSecondaryMenu = 0 

  m.scaleInfo = invalid
end sub

' Funcion que interpreta los eventos de teclado y retorna true si fue porcesada por este componente. Sino es porcesado por el
' entonces sigue con el siguente metodo onKeyEvent del compoente superior
function onKeyEvent(key as string, press as boolean) as boolean
  handled = false

  if m.principalMenuLayoutGroup <> invalid and m.principalMenuLayoutGroup.isInFocusChain() then 
    if key = KeyButtons().UP
      if press then
        if m.principalMenuLayoutGroup.focusedChild.focusUp <> invalid then 
          m.principalMenuLayoutGroup.focusedChild.focusUp.setFocus(true)
        
        else if m.fistPrincipalItem.id = m.principalMenuLayoutGroup.focusedChild.id then
          m.avatarImage.setFocus(true)
          m.selectedProfileChange.visible = true
          m.avatarImageOpacity.opacity = 0.00
          m.profileChange.color = m.colorFosused
        end if
        handled = true
      end if
    else if key = KeyButtons().DOWN
      if press then
        if m.principalMenuLayoutGroup.focusedChild.focusDown <> invalid then 
          m.principalMenuLayoutGroup.focusedChild.focusDown.setFocus(true)
        else if m.lastPrincipalItem.id = m.principalMenuLayoutGroup.focusedChild.id then
          fistElement = m.orderSecondaryMenu[0]
          
          fistElement.setFocus(true)
          fistElement.color = m.colorFosused
          m.positionSecondaryMenu = 0
        end if
      end if
      handled = true
    else if key = KeyButtons().OK
      handled = true
      if press then
        if m.principalMenuLayoutGroup.focusedChild <> invalid then
          __selectItemInPrincipal(m.principalMenuLayoutGroup.focusedChild)
        end if
      end if
    end if

  else if m.avatarMenuContainer <> invalid and m.avatarMenuContainer.isInFocusChain() then 
    if key = KeyButtons().DOWN then
      if press then
        if m.fistPrincipalItem <> invalid then 
          m.fistPrincipalItem.setFocus(true)
          m.selectedProfileChange.visible = false
          m.avatarImageOpacity.opacity = 0.33
          m.profileChange.color = m.colorDefault
        else
          m.selectedProfileChange.visible = false
          m.avatarImageOpacity.opacity = 0.33
          m.profileChange.color = m.colorDefault

          fistElement = m.orderSecondaryMenu[0]
          
          fistElement.setFocus(true)
          fistElement.color = m.colorFosused
          m.positionSecondaryMenu = 0
        end if
        handled = true
      end if 

    else if key = KeyButtons().OK then
        if press then
          m.top.selectedItem = FormatJson(m.changeProfilesItem)
        end if
        handled = true
    end if


  else if m.secondaryMenuLayoutGroup <> invalid and m.secondaryMenuLayoutGroup.isInFocusChain() then 
   if key = KeyButtons().UP
    if press then
      if m.positionSecondaryMenu > 0 and m.positionSecondaryMenu < m.orderSecondaryMenu.count() then 
        newPosition = m.positionSecondaryMenu - 1
        newItemFocus = m.orderSecondaryMenu[newPosition]
        
        if newItemFocus <> invalid then 
          m.orderSecondaryMenu[m.positionSecondaryMenu].color = m.colorDefault
          newItemFocus.setFocus(true)
          newItemFocus.color = m.colorFosused
          m.positionSecondaryMenu = newPosition
        end if 
      else
        m.positionSecondaryMenu = 0
        if m.lastPrincipalItem <> invalid then 
          m.lastPrincipalItem.setFocus(true)
          m.orderSecondaryMenu[0].color = m.colorDefault
        
        else if m.fistPrincipalItem = invalid then
            m.avatarImage.setFocus(true)
            m.selectedProfileChange.visible = true
            m.avatarImageOpacity.opacity = 0.00
            m.profileChange.color = m.colorFosused
            m.orderSecondaryMenu[0].color = m.colorDefault
        end if
      end if 
    end if

    handled = true

    else if key = KeyButtons().DOWN
      if press then
        if m.positionSecondaryMenu >= 0 and m.positionSecondaryMenu < m.orderSecondaryMenu.count() then 
          newPosition = m.positionSecondaryMenu + 1
          newItemFocus = m.orderSecondaryMenu[newPosition]
          
          if newItemFocus <> invalid then 
            m.orderSecondaryMenu[m.positionSecondaryMenu].color = m.colorDefault
            newItemFocus.setFocus(true)
            newItemFocus.color = m.colorFosused
            m.positionSecondaryMenu = newPosition
          end if 
        end if
      end if 

      handled = true
    else if key = KeyButtons().OK
      if press then
        if m.logoutLabel.isInFocusChain() then
          m.top.selectedItem = FormatJson(m.logoutItem)
        else if m.exitLabel.isInFocusChain() then
          m.top.selectedItem = FormatJson(m.exitItem)
        else if m.settingLabel.isInFocusChain() then
          m.top.selectedItem = FormatJson(m.settingItem)
        end if
      end if 
      handled = true
    end if
  end if

  return handled
end function

' carga la configuracion del Menú
sub configureMenu()
  m.scaleInfo = m.global.scaleInfo
  __applyTranslations()

  safeX = m.scaleInfo.safeZone.x
  safeY = m.scaleInfo.safeZone.y
  usableWidth = m.scaleInfo.width
  contentHeight = m.scaleInfo.height - (safeY * 2)

  m.backgroundMenu.translation = [0, 0]
  m.backgroundMenu.width = 1
  m.backgroundMenu.height = m.scaleInfo.height

  m.menuContainer.translation = [0, safeY]
  m.menuContainer.width = scaleValue(118, m.scaleInfo)
  m.menuContainer.height = contentHeight

  m.menuExpandVector2DFAnimation.keyValue = [1, usableWidth]
  m.menuCollapseVector2DFAnimation.keyValue = [usableWidth, 1]

  m.avatarMenuContainer.translation = [safeX + scaleValue(0, m.scaleInfo), safeY + scaleValue(70, m.scaleInfo)]
  m.avatarMenuContainer.itemSpacings = [scaleValue(10, m.scaleInfo)]
  m.avatarImage.width = scaleValue(65, m.scaleInfo)
  m.avatarImage.height = scaleValue(65, m.scaleInfo)
  m.avatarImageOpacity.width = scaleValue(65, m.scaleInfo)
  m.avatarImageOpacity.height = scaleValue(66, m.scaleInfo)
  m.selectedProfileChange.size = scaleSize([62, 62], m.scaleInfo)

  m.principalMenuLayoutGroup.translation = [safeX + scaleValue(0, m.scaleInfo), (safeY + ((contentHeight - scaleValue(160, m.scaleInfo)) / 2))]
  m.principalMenuLayoutGroup.itemSpacings = [scaleValue(20, m.scaleInfo)]

  m.secondaryMenuLayoutGroup.translation = [safeX + scaleValue(0, m.scaleInfo), (safeY + contentHeight - scaleValue(60, m.scaleInfo))]
  m.secondaryMenuLayoutGroup.itemSpacings = [scaleValue(10, m.scaleInfo)]

  m.colorFosused = m.global.colors.WHITE
  m.colorDefault = m.global.colors.MENU_ITEM_DEFAULT
  
  m.avatarName.color =  m.global.colors.SECONDARY
  m.profileChange.color =  m.colorDefault
  m.exitLabel.color = m.colorDefault
  m.logoutLabel.color = m.colorDefault
  m.settingLabel.color = m.colorDefault

  m.animationsMenuItemsExpand = []
  m.animationsMenuItemsCollapse = []
end sub

' Carga los items del menu y el perfil
sub itemData()
  m.fistPrincipalItem = invalid
  m.lastPrincipalItem = invalid

  if m.global.contact <> invalid then 
    contact = m.global.contact
    if contact.profile <> invalid then 
      if contact.profile.name <> invalid and contact.profile.name <> "" then 
        m.avatarName.Text = contact.profile.name
        m.avatarName.visible = true
        m.profileChange.visible = true
      end if
      if contact.profile.avatar <> invalid and  contact.profile.avatar.image <> invalid then 
        m.avatarImage.uri = getImageUrl(contact.profile.avatar.image)
        m.avatarImage.visible = true
      end if
    end if
  end if 

  previousMenuItem = invalid
  
  if m.top.items <> invalid and m.top.items.count() >= 0 then
    selectedItem = invalid

    for each item in m.top.items
      if item.mainMenu then 
        if item.icon <> invalid and item.icon.image <> invalid then
          newMenuItemNode = createObject("roSGNode", "MenuItem")
    
          if item.key <> invalid then newMenuItemNode.menuKey = item.key
          if item.id <> invalid then newMenuItemNode.menuId = item.id
          if item.code <> invalid then newMenuItemNode.code = item.code
          if item.behavior <> invalid then newMenuItemNode.behavior = item.behavior
          if item.key <> invalid and item.id <> invalid then newMenuItemNode.id =  item.key + item.id.ToStr()
          if item.text <> invalid and item.text <> "" then newMenuItemNode.text = item.text
          if item.icon <> invalid and item.icon.image <> invalid then newMenuItemNode.imageURL = getImageUrl(item.icon.image)
          newMenuItemNode.opacityText = 0.0
          newMenuItemNode.focusable = true
  
          if previousMenuItem <> invalid then
            previousMenuItem.focusDown = newMenuItemNode
            newMenuItemNode.focusUp = previousMenuItem
          end if
          previousMenuItem = newMenuItemNode
  
          if m.fistPrincipalItem = invalid then m.fistPrincipalItem = newMenuItemNode          
          m.lastPrincipalItem = newMenuItemNode
        end if
    
        if item.behavior = "home" then 
          selectedItem = item
          m.homeItem = newMenuItemNode
        end if
      
        m.principalMenuLayoutGroup.appendChild(newMenuItemNode)
    
        ' defino las animaciones
        if newMenuItemNode.id <> invalid then 
          newMenuItemNode.id =  item.key + item.id.ToStr()
          
          interpolator = CreateObject("roSGNode", "FloatFieldInterpolator")
          interpolator.id = newMenuItemNode.id + "Animation"
          interpolator.key = [0.0, 1.0]
          interpolator.keyValue = [0.0, 1.0]
          interpolator.fieldToInterp = newMenuItemNode.id + ".opacityText"
    
          m.menuExpandAnimation.appendChild(interpolator)
          m.animationsMenuItemsExpand.push(m.menuExpandAnimation.findNode(interpolator.id))

          interpolator = CreateObject("roSGNode", "FloatFieldInterpolator")
          interpolator.id = newMenuItemNode.id + "Animation"
          interpolator.key = [0.0, 1.0]
          interpolator.keyValue = [1.0, 0.0]
          interpolator.fieldToInterp = newMenuItemNode.id + ".opacityText"
          m.menuCollapseAnimation.appendChild(interpolator)
  
          m.animationsMenuItemsCollapse.push(m.menuCollapseAnimation.findNode(interpolator.id))
        end if
      end if 
    next

    if selectedItem <> invalid then
      m.top.selectedItem = FormatJson(selectedItem)
      m.nodeSelected =  m.homeItem
      if m.nodeSelected.selected <> invalid then m.nodeSelected.selected = true
    end if
  else 
    m.avatarImage.uri = ""
    m.avatarName.Text = ""
    m.avatarImage.visible = false
    m.avatarName.visible = false
    m.profileChange.visible = false

    for i = 0 to m.animationsMenuItemsExpand.count() - 1
      child = m.menuExpandAnimation.findNode(m.animationsMenuItemsExpand[i].id)
      m.menuExpandAnimation.removeChild(child)
    end for
    
    for i = 0 to m.animationsMenuItemsCollapse.count() - 1
      child = m.menuCollapseAnimation.findNode(m.animationsMenuItemsCollapse[i].id)
      m.menuCollapseAnimation.removeChild(child)
    end for
    
    m.animationsMenuItemsExpand = []
    m.animationsMenuItemsCollapse = []
    
    while m.principalMenuLayoutGroup.getChildCount() > 0
      child = m.principalMenuLayoutGroup.getChild(0)

      child.focusDown = invalid
      child.focusUp = invalid

      m.principalMenuLayoutGroup.removeChild(child)
    end while

    m.homeItem = invalid
    m.colorFosused = m.global.colors.WHITE
    m.colorDefault = m.global.colors.MENU_ITEM_DEFAULT
    
    m.avatarName.color =  m.global.colors.SECONDARY
    m.profileChange.color =  m.colorDefault
    m.exitLabel.color = m.colorDefault
    m.logoutLabel.color = m.colorDefault
    m.settingLabel.color = m.colorDefault
  end if 
end sub

' Dispara la seleccion de la Home
sub onShowHome()
  if m.top.loadHome then 
    if m.homeItem <> invalid then __selectItemInPrincipal(m.homeItem)
    m.top.loadHome = false
  end if 
end sub

' actualiza la animacion definida por el action si se expande o contraer
sub changeActionAnimate()
  if m.top.action = "expand" then
    __expandMenu()
  else if m.top.action = "collapse"
    __collapseMenu()
  end if
end sub

' Aplicar las traducciones en el componente
sub __applyTranslations()
  if m.global.i18n = invalid then return
  m.profileChange.text = i18n_t(m.global.i18n, "content.menuComponent.changeProfile")
  m.settingLabel.text = i18n_t(m.global.i18n, "content.menuComponent.Setting")
  m.exitLabel.text    = i18n_t(m.global.i18n, "content.menuComponent.exit")
  m.logoutLabel.text  = i18n_t(m.global.i18n, "content.menuComponent.logout")
end sub

' Realiza la apertura del menú
sub __expandMenu()
  m.menuCollapseAnimation.control = "stop"
  
  if m.nodeSelected <> invalid then 
    m.nodeSelected.setFocus(true)

    for i = 0 to m.orderSecondaryMenu.count() - 1
      element = m.orderSecondaryMenu[i]
      if (m.nodeSelected.id = element.id) then
        element.color = m.colorFosused
        m.positionSecondaryMenu = i
        i = m.orderSecondaryMenu.count() - 1
      end if
    end for
  else 
    m.positionSecondaryMenu = 0
    firstElement = m.orderSecondaryMenu[0]
    m.nodeSelected = firstElement
    m.nodeSelected.setFocus(true)
    firstElement.color = m.colorFosused
  end if
  
  m.menuExpandAnimation.control = "start"
end sub

' Realiza la cierrre del menú
sub __collapseMenu()
  m.menuExpandAnimation.control = "stop"
  m.menuCollapseAnimation.control = "start"
  
  m.selectedProfileChange.visible = false
  m.avatarImageOpacity.opacity = 0.33
  m.profileChange.color = m.colorDefault
  m.exitLabel.color = m.colorDefault
  m.logoutLabel.color = m.colorDefault
  m.settingLabel.color = m.colorDefault
  m.positionSecondaryMenu = 0
end sub

' Dispara la seleccion de alguno de los items del menu.
sub __selectItemInPrincipal(menuItem)
  m.top.selectedItem = FormatJson({key: menuItem.menuKey, id: menuItem.menuId, code: menuItem.code, behavior: menuItem.behavior})
  ' Si es la guia no lo guardo como ultimo nodo selecionado
  if m.nodeSelected.menuKey <> invalid and m.nodeSelected.menuKey <> "MenuId" and menuItem.code <> invalid and menuItem.code <> "epg" then 
    if m.nodeSelected <> invalid and m.nodeSelected.selected <> invalid then m.nodeSelected.selected = false
    m.nodeSelected = menuItem
    if m.nodeSelected.selected <> invalid then m.nodeSelected.selected = true
  end if 
end sub