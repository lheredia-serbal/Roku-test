function GetLastAction(context as Object, responseMethod as String) as Object
  if context <> invalid and context.lastActions <> invalid and context.lastActions[responseMethod] <> invalid then
    return context.lastActions[responseMethod]
  end if
  return invalid
end function

' Setear un id unico para cada action
function createRequestId() as String
  now = CreateObject("roDateTime")
   return now.AsSeconds().toStr() + "-" + now.GetMilliseconds().toStr()
end function