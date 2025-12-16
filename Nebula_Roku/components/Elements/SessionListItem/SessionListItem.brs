' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.theRect = m.top.findNode("theRect")
    m.theRectangle = m.top.findNode("theRectangle")
    m.theRectLeft = m.top.findNode("theRectLeft")
    m.theRectRight = m.top.findNode("theRectRight")
    m.theRectangleLeft = m.top.findNode("theRectangleLeft")
    m.theRectangleRight = m.top.findNode("theRectangleRight")
end sub

' Carga los datos de Node en el compoente
sub itemContentChanged()
    if m.top.itemContent <> invalid then

        m.theRectangle.width = m.top.widthContainer

        m.theRect.translation = [(m.top.widthContainer / 2), 0]

        m.theRectangleLeft.width = (m.top.widthContainer / 2)
        m.theRectangleRight.width = (m.top.widthContainer / 2)

        if m.top.itemContent.deviceDescription <> invalid and m.top.itemContent.deviceDescription <> "" then
            labelDevice = m.theRectLeft.createChild("Label")
            labelDevice.text = m.top.itemContent.deviceDescription
            labelDevice.maxLines = 1
            labelDevice.wrap = false
            labelDevice.font= "font:SmallestBoldSystemFont"
        else 
            if m.top.itemContent.deviceTypeDescription <> invalid and m.top.itemContent.deviceTypeDescription <> "" then
                labelDevice = m.theRectLeft.createChild("Label")
                labelDevice.text = m.top.itemContent.deviceTypeDescription
                labelDevice.maxLines = 1
                labelDevice.wrap = false
                labelDevice.font= "font:SmallestBoldSystemFont"
            end if
        end if
        
        if m.top.itemContent.programDescription <> invalid and m.top.itemContent.programDescription <> "" then
            m.labelExtraInfo = m.theRectLeft.createChild("Label")
            m.labelExtraInfo.text = " - " +  m.top.itemContent.programDescription
            m.labelExtraInfo.maxLines = 1
            m.labelExtraInfo.wrap = false
            m.labelExtraInfo.font= "font:SmallestSystemFont"
        end if
        
        if m.top.itemContent.profileName <> invalid and m.top.itemContent.profileName <> "" then
            if (m.labelExtraInfo = invalid) then
                m.labelExtraInfo = m.theRectLeft.createChild("Label")
                m.labelExtraInfo.text = " -"
                m.labelExtraInfo.maxLines = 1
                m.labelExtraInfo.wrap = false
                m.labelExtraInfo.font= "font:SmallestSystemFont"
            end if 

            m.labelExtraInfo.text += " (" + m.top.itemContent.profileName + ")"
        end if
        
        btnClose = m.theRectRight.createChild("QvButton")
        btnClose.id = "CloseSession" 
        btnClose.text = "Close"
        btnClose.focusable = true
    else
        m.top.unobserveField("focusedChild")
        while m.theRect.getChildCount() > 0
            m.theRect.removeChild(m.theRect.getChild(0))
        end while
    end if
end sub
