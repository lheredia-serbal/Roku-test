function urlStreaming(apiUrl, key, id, streamingAction = getStreamingAction().PLAY, streamingType = getStreamingType().DEFAULT, startpid = 0)
    lr = "true"
    if m.global <> invalid and m.global.contact <> invalid and m.global.contact.forTest <> invalid and m.global.contact.forTest then lr = "false" 
    return apiUrl + "/"+ m.global.apiVersions.V2 + "/Streamings/" + key + "/" + id.toStr() + "/" + streamingAction + "?slw=false&lr="+ lr +"&st=" + streamingType + "&startpid=" + startpid.toStr()
end function

