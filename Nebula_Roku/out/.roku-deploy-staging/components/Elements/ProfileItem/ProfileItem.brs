' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.profileName = m.top.findNode("profileName")
    m.opacityLayout = m.top.findNode("opacityLayout")

    m.itemImage = m.top.findNode("itemImage")
    m.opacityByEdit = m.top.findNode("opacityByEdit")
    m.profileByEdit = m.top.findNode("profileByEdit")
    m.selectedIndicator = m.top.findNode("selectedIndicator")
    
    m.scaleInfo = m.global.scaleInfo
    
    m.top.observeField("focusedChild", "onFocusChange")
    m.top.observeField("showManageProfile", "onShowManageProfile")
end sub

' Detecta y actualiza el cambio de nombre
sub nameChanged()
    if m.top.name <> invalid and m.top.name <> "" then 
        m.profileName.text = m.top.name
    else 
        m.profileName.text = ""
        m.profileName.visible = false
        m.profileName.width = 1
        m.profileName.height = 1
        m.profileName.translation = [0, 0]
    end if
end sub

' Detecta y actualiza el cambio de imagen del avatar
sub imageChanged()
    if m.top.uriImage <> invalid and m.top.uriImage <> "" then 
        m.itemImage.uri = m.top.uriImage
    else 
        m.itemImage.uri = ""
    end if
end sub

' Dispara la validacion si el componente tiene o no el foco sobre él
sub onFocusChange()
    if m.top.focusedChild <> invalid and m.top.focusedChild.focusable then 
        ' Tiene foco 
        m.opacityLayout.opacity = 0.3
        m.selectedIndicator.visible = true
        m.profileName.color = m.global.colors.WHITE
        m.opacityByEdit.visible = m.top.showManageProfile
    else 
        ' No tiene foco 
        m.opacityLayout.opacity = 0.0
        m.selectedIndicator.visible = false
        m.profileName.color = m.global.colors.LIGHT_GRAY
        m.opacityByEdit.visible = false
    end if

    m.profileByEdit.visible = m.top.showManageProfile
end sub

sub onShowManageProfile() 
    m.profileByEdit.visible = m.top.showManageProfile
    m.opacityByEdit.visible = m.top.showManageProfile
end sub

' Setea el tamaño del componente
sub setSize()
    scaledSize = m.top.size
    m.itemImage.width = scaledSize[0]
    m.itemImage.height = scaledSize[1]
    
    m.opacityLayout.width = scaledSize[0]
    m.opacityLayout.height = scaledSize[1]
    
    m.opacityByEdit.width = scaledSize[0]
    m.opacityByEdit.height = scaledSize[1]

    m.profileByEdit.width = scaledSize[0]
    m.profileByEdit.height = scaledSize[1]

    m.selectedIndicator.size = [scaledSize[0] - 1 ,  scaledSize[1] - 1]
    
    m.profileName.width = scaledSize[0]
    m.profileName.translation = [0, scaledSize[1] + 10]

    m.opacityLayout.opacity = 0.0
    m.selectedIndicator.visible = false
    m.profileName.color = m.global.colors.LIGHT_GRAY
end sub