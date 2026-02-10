' Es necesario para evitar lso fallos de los enlaces profundos
Sub Init()
    m.top.functionName = "listenInput"
End Sub

' Describe la operación listen input.
function ListenInput()
    port=createobject("romessageport")
    InputObject=createobject("roInput")
    InputObject.setmessageport(port)

    while true
      msg=port.waitmessage(500)
      if type(msg)="roInputEvent" then
        if msg.isInput()
          inputData = msg.getInfo()

          ' pass the deeplink to UI
          if inputData.DoesExist("mediaType") and inputData.DoesExist("contentID")
            deeplink = {
                id: inputData.contentID
                type: inputData.mediaType
            }
            m.top.inputData = deeplink
          end if
        end if
      end if
    end while
end function
