function  getVideoAction() As object
    return {
        PLAY: "play",
        PAUSE: "pause",
        STOP: "stop"
    }
End function 


function getVideoState() As Object
    return {
        PLAYING: "playing",
        PAUSED: "paused",
        BUFFERING: "buffering",
        STOPPED: "stopped",
        ERROR: "error"
    }
end function
