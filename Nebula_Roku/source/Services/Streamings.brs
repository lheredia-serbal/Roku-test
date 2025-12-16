function urlStreaming(apiUrl, key, id, streamingAction = getStreamingAction().PLAY, treamingType = getStreamingType().DEFAULT, lr = false, startpid = 0, slw = false)
    return apiUrl + "/"+ m.global.apiVersions.V2 + "/Streamings/" + key + "/" + id.toStr() + "/" + streamingAction + "?slw="+ slw.ToStr() +"&lr=" + lr.ToStr() + "&st=" + treamingType + "&startpid=" + startpid.toStr()
end function

