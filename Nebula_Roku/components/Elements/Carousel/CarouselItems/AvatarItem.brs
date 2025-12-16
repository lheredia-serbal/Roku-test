' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.theRect  = m.top.findNode("theRect")
    m.itemImage = m.top.findNode("itemImage")
    m.opacityLayout = m.top.findNode("opacityLayout")
end sub

' Carga los datos de Node en el compoente
sub itemContentChanged()
    if m.top.itemContent.imageURL <> invalid then m.itemImage.uri = m.top.itemContent.imageURL
end sub

' Se dispara al dibujar en pantalla y define oppiedades del xml del componente 
sub currRectChanged()
      m.theRect.width = m.top.currRect.width
      m.theRect.height = m.top.currRect.height
    
      m.itemImage.width = m.top.itemContent.size[0]
      m.itemImage.height = m.top.itemContent.size[1]
      
      m.opacityLayout.width = m.top.itemContent.size[0]
      m.opacityLayout.height = m.top.itemContent.size[1]
end sub

' Define el estilo de foco del componente y como se comporta al tener o no el foco
sub focusPercentChanged()
    if m.opacityLayout <> invalid then
        m.opacityLayout.opacity = 0.3 * (1.0 - m.top.focusPercent) 
    end if
end sub