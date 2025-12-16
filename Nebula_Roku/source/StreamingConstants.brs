function getStreamingAction() as Object
    return {
        PLAY: "Play",
        CONTINUE: "Continue",
        RESTART: "Restart"
    }
end function

function getStreamingFormat() as Object
    return {
        HLS: 1,
        DASH: 2,
    }
end function

function getVideoType() as Object
    return {
        LIVE: "live",
        DVR: "dvr",
        VOD: "vod",
        LIVE_REWIND: "liverewind"
    }
end function

function getDRMTechnology() as Object
    return {
        FAIR_PLAY: "FairPlay",
        PLAY_READY: "PlayReady",
        WIDEVINE: "Widevine"
    }
end function

function getPlayerAction() as Object
    return {
        FORWARD: "forward",
        BACKWARD: "backward",
        PLAY: "play",
        PAUSE: "pause",
        RESTART: "restart",
    }
end function

function getStreamingType() as Object
    return {
        DEFAULT: "d",
        LIVE_REWIND: "lr",
    }
end function

function getResizeModeVideoStretching() as Object
    return {
        NONE: 1,
        FIT: 2,
        FILL: 3,
        ZOOM: 4,
    }
end function