function GetLastAction(context as Object, responseMethod as String) as Object
  if context <> invalid and context.lastActions <> invalid and context.lastActions[responseMethod] <> invalid then
    return context.lastActions[responseMethod]
  end if
  return invalid
end function

function RetryOn9000(context as Object, responseMethod as String, requestManager as Object, apiTypeParam as Dynamic) as Object
  if requestManager <> invalid and requestManager.serverError = true then
    action = GetLastAction(context, responseMethod)
    if action <> invalid and tryRetryFromResponse("", action, requestManager, apiTypeParam) then
      return action.apiRequestManager
    end if
  end if
  return invalid
end function

' Setear un id unico para cada action
function createRequestId() as String
  now = CreateObject("roDateTime")
   return now.AsSeconds().toStr() + "-" + now.GetMilliseconds().toStr()
end function