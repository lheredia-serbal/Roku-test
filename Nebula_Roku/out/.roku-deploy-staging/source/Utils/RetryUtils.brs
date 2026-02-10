' Crear un id unico para cada action
function createRequestId() as String
  now = CreateObject("roDateTime")
   return now.AsSeconds().toStr() + "-" + now.GetMilliseconds().toStr()
end function