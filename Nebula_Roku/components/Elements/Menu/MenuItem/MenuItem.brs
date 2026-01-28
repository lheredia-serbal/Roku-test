' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.scaleInfo = m.global.scaleInfo
    
    m.menuItemContent = m.top.findNode("menuItemContent")
    m.menuItemLayout = m.top.findNode("menuItemLayout")
    m.itemImage = m.top.findNode("itemImage")
    m.itemText = m.top.findNode("itemText")
    m.itemIndicatorSelected = m.top.findNode("itemIndicatorSelected")

    m.top.observeField("focusedChild", "onFocusChange")

    m.colorFosused = m.global.colors.WHITE
    m.colorDefault = m.global.colors.MENU_ITEM_DEFAULT
    
    m.itemText.color = m.colorDefault
    m.itemImage.blendColor = m.colorDefault
    m.itemIndicatorSelected.color = m.global.colors.PRIMARY
    __applyLayout()
end sub

sub __applyLayout()
    if m.menuItemLayout <> invalid then
        m.menuItemLayout.itemSpacings = [scaleValue(20, m.scaleInfo)]
    end if

    m.itemImage.width = scaleValue(20, m.scaleInfo)
    m.itemImage.height = scaleValue(20, m.scaleInfo)

    m.itemIndicatorSelected.width = scaleValue(20, m.scaleInfo)
    m.itemIndicatorSelected.height = scaleValue(5, m.scaleInfo)
    m.itemIndicatorSelected.translation = [0, scaleValue(25, m.scaleInfo)]

    m.itemText.height = scaleValue(25, m.scaleInfo)
end sub

sub updateImage()
    m.itemImage.uri = m.top.imageURL
end sub

sub updateText()
    m.itemText.text = m.top.text
end sub

sub onOpacityChange()
    m.itemText.opacity = m.top.opacityText
end sub

' Marca al item selecionado
sub onSelectedItem()
    if m.top.selected then 
        m.itemIndicatorSelected.visible = true
    else
        m.itemIndicatorSelected.visible = false
    end if
end sub

' Dispara la validacion si el componente tiene o no el foco sobre él
sub onFocusChange()
    if m.top.focusedChild <> invalid and m.top.focusedChild.focusable then 
        ' Tiene foco 
        m.itemImage.blendColor = m.colorFosused
        m.itemText.color = m.colorFosused
    else 
        ' No tiene foco 
        m.itemImage.blendColor = m.colorDefault
        m.itemText.color = m.colorDefault
      end if
end sub