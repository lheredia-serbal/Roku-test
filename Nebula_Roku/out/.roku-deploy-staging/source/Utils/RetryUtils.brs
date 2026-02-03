' Registra la accion para poder reintentarla ante error 9000.
sub TrackAction(context as Object, action as Object)
  if action = invalid then return
  if action.requestId = invalid or action.requestId = "" then
    now = CreateObject("roDateTime")
    action.requestId = now.AsSeconds().toStr() + "-" + now.GetMilliseconds().toStr()
  end if
  if context <> invalid then
    if context.lastActions = invalid then context.lastActions = {}
    if action.responseMethod <> invalid then
      context.lastActions[action.responseMethod] = action
    end if
  end if
end sub

function GetLastAction(context as Object, responseMethod as String) as Object
  if context <> invalid and context.lastActions <> invalid and context.lastActions[responseMethod] <> invalid then
    return context.lastActions[responseMethod]
  end if
  return invalid
end function

function RetryOn9000(context as Object, responseMethod as String, requestManager as Object, apiTypeParam as Dynamic) as Object
  if requestManager <> invalid and requestManager.statusCode = 9000 then
    action = GetLastAction(context, responseMethod)
    if action <> invalid and tryRetryFromResponse(action, requestManager, apiTypeParam) then
      return action.apiRequestManager
    end if
  end if
  return invalid
end function

function RetryOn9000Action(context as Object, action as Object, requestManager as Object, apiTypeParam as Dynamic) as Object
  if requestManager <> invalid and requestManager.statusCode = 9000 then
    if action <> invalid and tryRetryFromResponse(action, requestManager, apiTypeParam) then
      return action.apiRequestManager
    end if
  end if
  return invalid
end function
