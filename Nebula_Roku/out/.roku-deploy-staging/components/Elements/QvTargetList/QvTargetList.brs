' Funcion que interpreta los eventos de teclado y retorna true si fue porcesada por este componente. Sino es porcesado por el
' entonces sigue con el siguente metodo onKeyEvent del compoente superior
function onKeyEvent(key as String, press as Boolean) as Boolean

  if key = KeyButtons().LEFT then 
    m.top.leftEvent = press
    m.top.leftEvent = not press
    if press then
      m.top.happenedLeft = false
    else 
      m.top.happenedLeft = true
      m.top.happenedLeft = false
    end if
    
  else if key = KeyButtons().RIGHT then
    m.top.rightEvent = press
    m.top.rightEvent = not press
    
    if press then
      m.top.happenedRight = false
    else 
      m.top.happenedRight = true
      m.top.happenedRight = false
    end if
  end if

  return false
end function