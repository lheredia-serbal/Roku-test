' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.scaleInfo = m.global.scaleInfo
    if m.scaleInfo = invalid then
        m.scaleInfo = getScaleInfo()
    end if

    m.profileName = m.top.findNode("profileName")
    m.opacityLayout = m.top.findNode("opacityLayout")

    m.itemImage = m.top.findNode("itemImage")
    m.opacityByEdit = m.top.findNode("opacityByEdit")
    m.selectedIndicator = m.top.findNode("selectedIndicator")
    
    m.top.observeField("focusedChild", "onFocusChange")
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
        if m.top.showManageProfile then m.opacityByEdit.visible = true
    else 
        ' No tiene foco 
        m.opacityLayout.opacity = 0.0
        m.selectedIndicator.visible = false
        m.opacityByEdit.visible = false
        m.profileName.color = m.global.colors.LIGHT_GRAY
    end if
end sub

' Setea el tamaño del componente
sub setSize()
    scaledSize = getScaledSize()
    m.itemImage.width = scaledSize[0]
    m.itemImage.height = scaledSize[1]
    
    m.opacityLayout.width = scaledSize[0]
    m.opacityLayout.height = scaledSize[1]
    
    m.opacityByEdit.width = scaledSize[0]
    m.opacityByEdit.height = scaledSize[1]

    m.selectedIndicator.size = [scaledSize[0] - 1 ,  scaledSize[1] - 1]
end sub

function getScaledSize() as object
    if m.top.size <> invalid and m.top.size.count() = 2 then
        return scaleSize(m.top.size, m.scaleInfo)
    end if

    return [0, 0]
end function