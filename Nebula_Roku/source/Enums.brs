
function getAppConfigVariable() as Object
    return {
        API_URL: "ApiUrl",
        AUTH_API_URL: "AuthApiUrl",
        BEACON_URL: "BeaconsApiUrl",
        LOGS_URL: "LogsApiUrl",
        RESOURCE_CODE: "ResourceCode",
        PRODUCT_CODE: "ProductCode",
        PLATFORM_CODE: "PlatformCode",
        ENVIRONMENT: "Environment",
        ENABLE_SIGN_UP: "EnableSignUp",
        PRODUCT_NAME: "ProductName",
        APP_CODE: "AppCode",
        VARIABLES_UPDATE_TIME: "VariablesUpdateTime",
        LOGO_DISPLAY_TYPE: "LogoDisplayType",
        ENABLE_SEARCH: "EnableSearch",
        ENABLE_LOGIN_BY_CODE: "EnableLoginByCode",
        LOGIN_BY_CODE_URL_QR: "LoginByCodeUrlQr",
        LOGIN_BY_CODE_URL_SHORT: "LoginByCodeUrlShort",
        PLAYER_SEEK_TIME: "PlayerSeekTime",
        PLAYER_INCREASED_SEEK_TIME: "PlayerIncreasedSeekTime",
        MAX_BUFFER_MS: "MaxBufferMs",
        BUFFER_FOR_PLAYBACK_MS: "BufferForPlaybackMs",
        BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS: "BufferForPlaybackAfterRebufferMs",
        MIN_BUFFER_MS: "MinBufferMs",
        SEEK_TO: "SeekTo",
        INACTIVITY_PROMPT_DURATION_IN_SECONDS: "InactivityPromptDurationInSeconds",
        INACTIVITY_PROMPT_TIME_IN_SECONDS: "InactivityPromptTimeInSeconds",
        INACTIVITY_PROMPT_ENABLED: "InactivityPromptEnabled"
    }
end function

function getScopeVariable() as Object
    return {
        PUBLIC: "Public",
        PRIVATE: "Private"
    }
end function

function getApiVersion() as Object
    return {
        V1: "v1",
        V2: "v2",
        V3: "v3"
    }
end function

function ActionLogCode() as Object
    return {
        SIGN_UP:"SignUp"
        LOGIN_BY_CREDENTIALS: "LoginByCredentials"
        LOGIN_BY_REGISTRATION_CODE: "LoginByRegistrationCode"
        LOGOUT: "Logout"
        SELECT_PROFILE: "SelectProfile"
        OPEN_PLAYER:  "OpenPlayer"
        CLOSE_PLAYER: "ClosePlayer"
        WATCH_LIVE: "WatchLive"
        WATCH_LIVE_REWIND:  "WatchLiveRewind"
        WATCH_CARCHUP: "WatchCatchup"
        WATCH_RECORDED: "WatchRecorded"
        WATCH_VOD: "WatchVOD"
        LIVE_REWIND_GO_TO_START: "LiveRewindGoToStart"
        CATCHUP_GO_TO_START: "CatchupGoToStart"
        ADD_RECORDINGS: "AddToRecordings"
        REMOVE_RECORDINGS: "RemoveFromRecordings"
        ADD_FAVORITES: "AddToFavorites"
        REMOVE_FAVORITES: "RemoveFromFavorites"
        PROGRAM_DETAIL: "OpenProgramDetail"
        PLAN_SUBSCRIBE: "PlanSubscribe"
        LOAD_CONSUMPTION: "LoadConsumptionBalance"
        SEND_CONTAC_US: "SendContactUs"
        OPEN_PAGE: "OpenPage"
        CHANGE_PASSWORD: "ChangePassword"
        RECOVERY_PASSWORD:  "RecoveryPassword"
        OPEN_APPLICATION: "OpenApplication"
        START_APP: "StartApp"
        ERROR: "Error"
        DEBUG: "Debug"
    }
end function

function EqvAppConfigVariable() as Object
    return {
        API_URL: "ClientsApiUrl"
        AUTH_API_URL: "AuthApiUrl"
        LOGS_URL: "LogsApiUrl"
        RESOURCE_CODE: "ResourceCode"
        PRODUCT_CODE: "ProductCode"
        PLATFORM_CODE: "PlatformCode"
        ENVIRONMENT: "Environment"
        ENABLE_SIGIN_UP: "EnableSiginUp"
        PRODUCT_NAME: "ProductName"
        APP_CODE: "AppCode"
        VARIABLES_UPDATE_TIME: "VariablesUpdateTime"
        LOGO_DISPLAY_TYPE: "LogoDisplayType"
        ENABLE_SEARCH: "EnableSearch"
        ENABLE_LOGIN_BY_CODE: "EnableLoginByCode"
        LOGIN_BY_CODE_URL_QR: "LoginByCodeUrlQr"
        LOGIN_BY_CODE_URL_SHORT: "LoginByCodeUrlShort"
        PLAYER_SEEK_TIME: "PlayerSeekTime"
        PLAYER_INCREASED_SEEK_TIME: "PlayerIncreasedSeekTime"
        MAX_BUFFER_MS: "MaxBufferMs"
        BUFFER_FOR_PLAYBACK_MS: "BufferForPlaybackMs"
        BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS: "BufferForPlaybackAfterRebufferMs"
        MIN_BUFFER_MS: "MinBufferMs"
        SEEK_TO: "SeekTo"
        INACTIVITY_PROMPT_DURATION_IN_SECONDS: "InactivityPromptDurationInSeconds"
        INACTIVITY_PROMPT_TIME_IN_SECONDS: "InactivityPromptTimeInSeconds"
        INACTIVITY_PROMPT_ENABLED: "InactivityPromptEnabled"
    }
end function

function LogoDisplayType() as Object
    return {
        RESOURCE: "Application",
        ORGANIZATION: "Organization",
        PARENT_ORGANIZATION: "ParentOrganization",
        RESOURCE_AND_ORGANIZATION_NAME: "ApplicationAndOrganizationName",
        NONE: "None"
    }
end function

function KeyButtons() as Object
    return {
        OK: "OK",
        BACK: "back",
        UP: "up",
        DOWN: "down",
        LEFT: "left",
        RIGHT: "right",
        FAST_FORWARD: "fastforward",
        REWIND: "rewind",
        REPLAY: "replay"
    }
end function

