
' Inicialización del componente (parte del ciclo de vida de Roku)
' 1st function that runs for the scene on channel startup
sub init()
  ' Imagen de fondo
  m.top.backgroundUri= "pkg:/images/client/bg1.jpg"
  
  'To see print statements/debug info, telnet on port 8089

  m.loading = m.top.FindNode("Loading")
  m.LauncherScreen = m.top.FindNode("LauncherScreen")
  m.SettingScreen = m.top.FindNode("SettingScreen")
  m.LoginScreen = m.top.FindNode("LoginScreen")
  m.ViewAllScreen = m.top.FindNode("ViewAllScreen")
  m.ProfileScreen = m.top.FindNode("ProfileScreen")
  m.MainScreen = m.top.FindNode("MainScreen")
  m.ProgramDetailScreen = m.top.FindNode("ProgramDetailScreen")
  m.KillSessionScreen = m.top.FindNode("KillSessionScreen")
  m.PlayerScreen = m.top.FindNode("PlayerScreen")

  m.cdnErrorDialog = m.top.FindNode("cdnErrorDialog")
  if m.cdnErrorDialog <> invalid then
    m.cdnErrorDialog.observeField("retry", "onCdnErrorRetry")
  end if

  i18n = invalid
  scene = m.top.getScene()
  if scene <> invalid then i18n = scene.findNode("i18n")
  
  addAndSetFields(m.global, {i18n: i18n, cdnErrorDialog: m.cdnErrorDialog})
  __initConfig()
end sub

' Funcion que interpreta los eventos de teclado y retorna true si fue porcesada por este componente. Sino es porcesado por el
' entonces sigue con el siguente metodo onKeyEvent del compoente superior
function onKeyEvent(key as string, press as boolean) as boolean
  if press and key = KeyButtons().BACK then
    if m.StackOfScreens.count() = 0 or (m.StackOfScreens.count() = 1 and m.StackOfScreens.Peek() = "MainScreen") then 
      __showExitAsk()
      return true

    else
      if m.StackOfScreens.Peek() = "PlayerScreen" then   
        m.StackOfScreens.Pop()
        m.PlayerScreen.unobserveField("onBack")
        
        __playerBackProcessing()

      else if m.StackOfScreens.Peek() = "ProgramDetailScreen" then 
        m.StackOfScreens.Pop()

        __hideProgramDetail()
        m.ProgramDetailScreen.data = invalid

        __backManager(m.StackOfScreens.Peek())
        
      else if m.StackOfScreens.Peek() = "SettingScreen" then 
        m.StackOfScreens.Pop()

        __hideSetting()
        __backManager(m.StackOfScreens.Peek())

      else if m.StackOfScreens.Peek() = "ViewAllScreen" then 
        m.StackOfScreens.Pop()

        __hideViewAll()
        __backManager(m.StackOfScreens.Peek())
      
      else if m.StackOfScreens.Peek() = "KillSessionScreen" then 
        m.StackOfScreens.Pop()

        __hideKillSessionScreen()

        __backManager(m.StackOfScreens.Peek())
      end if

      return true
    end if 
  end if
end function

' Metodo que se ejecuta al finalizar la LauncherScreen y valida si redirige al login, pantalla de perfiles o la home.
sub onLauncherFinished()
  if  m.LauncherScreen.finished then 
    ' Esconder Launcher y mostrar MainScreen
    m.LauncherScreen.visible = false
    if isLoginUser() then
      m.LauncherScreen.unobserveField("finished")
      m.LoginScreen.unobserveField("finished")
      m.top.signalBeacon("AppLaunchComplete")
      if m.global.contact <> invalid and m.global.contact.profile <> invalid then
        ' Notifica a Roku que el usuario autenticado abrió la app (Req 4.3).
        NotifyRokuUserIsLoggedIn()
        __initMain()
      else 
        __startAppDialogBeacon()
        __initProfile()
      end if 
    else
      m.top.signalBeacon("AppLaunchComplete")
      m.LauncherScreen.unobserveField("finished")

      __startAppDialogBeacon()
      m.LoginScreen.ObserveField("finished", "onLoginFinished")
      m.LoginScreen.visible = true
      m.LoginScreen.onFocus = true
      m.LoginScreen.setFocus(true)
    end if
  end if
end sub


' Metodo que se ejecuta al desloguear al usuario. Resetea las varibles y configuracion de la app y redirige al login
sub onLogoutEvent()
  if m.MainScreen.logout or m.ProfileScreen.logout or m.ProgramDetailScreen.logout or m.KillSessionScreen.logout or m.PlayerScreen.logout then
    ' Necesito hacer un bloqueo por procesamineto porque sino cuando dispara los logout de cada pantalla al 
    ' cambiar la propeidad logout esta volvera a disaparar el metodo de onLogoutEvent ya que tanto internamente 
    ' como externamente se esta escuchando el cambio de esta propiedad.  
    if not m.blockLogoutProcess then
      m.blockLogoutProcess = true
      m.loading.visible = true
      deleteTokens()
      clear()
      __resetApp()
      
      ' se limpian las variables y se le da el foco al login
      m.LoginScreen.finished = false
      m.LoginScreen.ObserveField("finished", "onLoginFinished")
      m.LoginScreen.visible = true
      m.LoginScreen.onFocus = true
      m.LoginScreen.setFocus(true)
      
      m.loading.visible = false
      m.blockLogoutProcess = false
    end if
  end if
end sub

' Metodo que se ejecuta al finalizar la LoginScreen y valida si redirige al login, pantalla de perfiles o la home.
sub onLoginFinished()
  if m.LoginScreen.finished then 
    m.LoginScreen.unobserveField("finished")
    ' Esconder Launcher y mostrar MainScreen
    m.LoginScreen.visible = false
    m.LoginScreen.onFocus = false
    if m.global.contact <> invalid and m.global.contact.profile <> invalid then
      ' Notifica a Roku que el usuario autenticado inició sesión correctamente (Req 4.3).
      NotifyRokuUserIsLoggedIn()
      __completeAppDialogBeacon()
      __initMain()
    else 
      __initProfile()
    end if 
  end if 
end sub

' Metodo que se ejecuta al finalizar la ProfileScreen y valida si redirige al login, pantalla de perfiles o la home.
sub onProfileFinished()
  if m.ProfileScreen.finished then 
    m.ProfileScreen.unobserveField("finished")
    ' Esconder Launcher y mostrar MainScreen
    m.ProfileScreen.visible = false
    m.ProfileScreen.onFocus = false
    __completeAppDialogBeacon()
    __initMain()
  end if 
end sub

' Cierra la aplicacion.
sub onExitApp()
  m.top.appExit = true
end sub

' Notifica a Roku (RED) que existe un usuario autenticado en la sesión actual.
' Este evento (Roku_Authenticated) ayuda a métricas de autenticación y ranking en Roku Search.
sub NotifyRokuUserIsLoggedIn(rsgScreen = invalid as Object)
  globalNode = invalid

  ' Obtiene el nodo global desde la escena actual (o desde el screen recibido, si aplica).
  if type(m.top) = "roSGNode" then
    globalNode = m.global
  else if rsgScreen <> invalid then
    globalNode = rsgScreen.getGlobalNode()
  end if

  ' Si no hay contexto global válido, no se puede inicializar/usar RED.
  if globalNode = invalid then return

  ' Reutiliza el dispatcher global para no recrear el nodo en cada notificación.
  RAC = globalNode.roku_event_dispatcher
  if RAC = invalid then
    ' Inicializa Roku Analytics Node con RED y lo guarda globalmente.
    RAC = CreateObject("roSGNode", "Roku_Analytics:AnalyticsNode")
    RAC.init = { RED: {} }
    globalNode.addFields({ roku_event_dispatcher: RAC })
  end if

  ' Envía el evento requerido por Roku para aplicaciones con login.
  RAC.trackEvent = { RED: { eventName: "Roku_Authenticated" } }
end sub

sub onCdnErrorRetry()
  enableFetchConfigJson()
  if m.cdnErrorDialog = invalid then return
  if not m.cdnErrorDialog.retry then return
  if m.cdnErrorDialog.buttonDisabled then return
  m.cdnRetryInProgress = true
  m.cdnErrorDialog.retry = false
  m.cdnErrorDialog.showSpinner = true
  m.cdnErrorDialog.buttonDisabled = true
  if m.LauncherScreen <> invalid then
    m.LauncherScreen.callFunc("startCdnInitialization", true)
  end if
end sub

' Metodo que se ejecuta al elegir una opcion del dialogo.
function onDialogButtonClicked(event)
  buttonIndex = event.getData()
  'did the user click "Yes"
  if buttonIndex = 0 then
    'set appExit which will exit main loop in main.brs 
     m.top.appExit = true
  else
      'close the dialog
      m.top.dialog.close = true
      return true
  end if
end function

' Metodo que redirige a la pantalla de detalle
sub onProgramDetail()
  ' Inicializamos payload para resolver si el detalle viene desde MainScreen o ViewAllScreen.
  programDetail = invalid 
  ' Cuando venimos de Home, tomamos detail desde MainScreen.
  if m.StackOfScreens.Peek() = "MainScreen" then 
    programDetail = m.MainScreen.detail
    __hideMain()
    ' Cuando venimos de ViewAll, tomamos detail desde ViewAllScreen.
  else if m.StackOfScreens.Peek() = "ViewAllScreen" then 
    programDetail = m.ViewAllScreen.detail
    ' Ocultamos temporalmente ViewAll sin limpiar data para poder volver desde detalle.
    __hideViewAll(false) 
  end if

  if programDetail = invalid then return
  m.StackOfScreens.Push("ProgramDetailScreen")
  __showProgramDetail()
  m.ProgramDetailScreen.data = programDetail
end sub

' Metodo que redirige a la pantalla de Ver todos.
sub onViewAll()
  if m.MainScreen.viewAll = invalid then return
  viewAllData = m.MainScreen.viewAll
  if viewAllData <> invalid then
    m.MainScreen.viewAll = invalid
    __hideMain()
    m.StackOfScreens.Push("ViewAllScreen")
    __showViewAll(viewAllData)
  end if
end sub

' Metodo que redirige a la pantalla de configuracion
sub onSetting()
  if m.MainScreen.setting then 
    m.MainScreen.setting = false
    __hideMain()
    m.StackOfScreens.Push("SettingScreen")
    __showSetting()
  end if
end sub

' Metodo que redirige a la pantalla del player
sub onStreamingPlayer()
  streaming = invalid
  openGuide = false
  
  if m.StackOfScreens.Peek() = "MainScreen" then
    streaming = m.MainScreen.streaming
    openGuide = m.MainScreen.openGuide
    m.MainScreen.openGuide = false 
    __hideMain()
    ' Si el streaming se originó en ViewAll, lo tomamos desde ese componente.
  else if m.StackOfScreens.Peek() = "ViewAllScreen" then 
    streaming = m.ViewAllScreen.streaming
    ' Ocultamos temporalmente ViewAll sin limpiar data para poder volver desde Player.
    __hideViewAll(false) 
  else if m.StackOfScreens.Peek() = "ProgramDetailScreen" then
    streaming = m.ProgramDetailScreen.streaming
    __hideProgramDetail()
  else if m.StackOfScreens.Peek() = "KillSessionScreen" then
    m.StackOfScreens.Pop()
    streaming = m.KillSessionScreen.streaming
    openGuide = m.KillSessionScreen.openGuide
    __hideKillSessionScreen()
  end if
  
  if streaming <> invalid then __showPlayer(streaming, openGuide)
end sub

' Metodo que retrocede de la pantalla de detalle limpiando las variables de dicha pantalla.
sub onBackDetail()
  if m.ProgramDetailScreen.onBack then 
    m.ProgramDetailScreen.unobserveField("onBack")
    m.ProgramDetailScreen.onBack = false

    if m.StackOfScreens.Peek() = "ProgramDetailScreen" then 
      m.StackOfScreens.Pop()
  
      __hideProgramDetail()
      m.ProgramDetailScreen.data = invalid
  
      __backManager(m.StackOfScreens.Peek())
    end if
  end if
end sub

' Metodo que retrocede de la pantalla del player limpiando las variables de dicha pantalla.
sub onBackPlayer()
  if m.PlayerScreen.onBack then 
    m.PlayerScreen.unobserveField("onBack")
    m.PlayerScreen.onBack = false

    if (m.StackOfScreens.Peek() = "PlayerScreen") then  m.StackOfScreens.Pop()

    __playerBackProcessing()
  end if
end sub

' Metodo que se dispara al querer salir de la app por ociones de menú 
sub onExitEvent()
  if m.MainScreen.onExit then 
    m.MainScreen.onExit = false
    __showExitAsk()
  end if
end sub

' Metodo que se dispara al cambiar el perfil del usuario
sub onChangeProfileEvent()
  if m.MainScreen.onChangeProfile then 
    m.MainScreen.onChangeProfile = false
    m.MainScreen.visible = false
    m.MainScreen.onFocus = false
    m.MainScreen.loadData = false
    m.MainScreen.unobserveField("streaming")
    m.MainScreen.unobserveField("pendingStreamingSession")
    m.MainScreen.unobserveField("detail")
    m.MainScreen.unobserveField("setting")

    __initProfile()
    m.StackOfScreens = []
  end if
end sub

' Metodo que regresa a la home desde la pantalla de sesiones concurrentes
sub goToHomeKillSessionScreen()
  if m.KillSessionScreen.goToHome then
    m.KillSessionScreen.goToHome = false

    if m.StackOfScreens.Peek() = "KillSessionScreen" then m.StackOfScreens.Pop()

    __hideKillSessionScreen()

    if m.StackOfScreens.Peek() = "ProgramDetailScreen" then 
        m.StackOfScreens.Pop()

        __hideProgramDetail()
        m.ProgramDetailScreen.data = invalid
      end if

      __backManager(m.StackOfScreens.Peek())
  end if 
end sub

' Metodo que dispara la apertura de la pantalla para eliminar sesiones concurrentes
sub onKillSession()
  pendingStreamingSession = invalid
  openGuide = false
  
  if m.StackOfScreens.Peek() = "MainScreen" then
    pendingStreamingSession = m.MainScreen.pendingStreamingSession
    openGuide = m.MainScreen.openGuide
    m.MainScreen.openGuide = false
    __hideMain()
  else if m.StackOfScreens.Peek() = "ProgramDetailScreen" then
    pendingStreamingSession = m.ProgramDetailScreen.pendingStreamingSession
    __hideProgramDetail()
  end if
  
  if pendingStreamingSession <> invalid then __showKillSession(pendingStreamingSession, openGuide)
end sub

' Carga la configuracion inicial del componente, escuchando los observable y obteniendo las 
' referencias de compenentes necesarios para su uso
sub __initConfig()
  m.blockLogoutProcess = false

  ' Esperar evento de LauncherScreen
  m.LauncherScreen.ObserveField("finished", "onLauncherFinished")
  m.LauncherScreen.ObserveField("forceExit", "onExitApp")
  
  ' Esperar evento de Salida de la MainScreen
  m.MainScreen.ObserveField("onExit", "onExitEvent")
  m.MainScreen.ObserveField("forceExit", "onExitApp")
  m.MainScreen.ObserveField("onChangeProfile", "onChangeProfileEvent")

  ' Set focus a LauncherScreen primero
  m.LoginScreen.loading = m.loading
  m.ProfileScreen.loading = m.loading
  m.MainScreen.loading = m.loading
  m.PlayerScreen.loading = m.loading
  m.ProgramDetailScreen.loading = m.loading
  m.KillSessionScreen.loading = m.loading

  m.MainScreen.ObserveField("logout", "onLogoutEvent")
  m.ProfileScreen.ObserveField("logout", "onLogoutEvent")
  m.ProgramDetailScreen.ObserveField("logout", "onLogoutEvent")
  m.KillSessionScreen.ObserveField("logout", "onLogoutEvent")
  m.PlayerScreen.ObserveField("logout", "onLogoutEvent")

  m.StackOfScreens = []

  m.LauncherScreen.setFocus(true)
end sub

' Define la configuracion del componente main los observable y si seteando sus variables necesarias
sub __initMain()
  m.StackOfScreens.Push("MainScreen")
  m.MainScreen.visible = true
  m.MainScreen.onFocus = true
  m.MainScreen.loadData = true
  m.MainScreen.setFocus(true)
  m.MainScreen.ObserveField("streaming", "onStreamingPlayer")
  m.MainScreen.ObserveField("pendingStreamingSession", "onKillSession")
  m.MainScreen.ObserveField("detail", "onProgramDetail")
  m.MainScreen.ObserveField("viewAll", "onViewAll")
  m.MainScreen.ObserveField("setting", "onSetting")

  ' Performance Req 3.2: marca que el Home ya quedó visible y navegable.
  if m.launchCompleteSignaled <> true then
    m.launchCompleteSignaled = true
    m.top.signalBeacon("AppLaunchComplete")
  end if
end sub

' Performance Req 3.2: marca el inicio de un diálogo interactivo antes del Home.
sub __startAppDialogBeacon()
  if m.appDialogInitiated <> true then
    m.appDialogInitiated = true
    m.top.signalBeacon("AppDialogInitiate")
  end if
end sub

' Performance Req 3.2: marca el cierre del diálogo cuando termina el flujo hacia Home.
sub __completeAppDialogBeacon()
  if m.appDialogInitiated = true and m.appDialogCompleted <> true then
    m.appDialogCompleted = true
    m.top.signalBeacon("AppDialogComplete")
  end if
end sub

' Define la configuracion del componente Perfil los observable y si seteando sus variables necesarias
sub __initProfile()
  ' Esperar evento de ProfileScreen
  m.ProfileScreen.ObserveField("finished", "onProfileFinished")
  m.ProfileScreen.visible = true
  m.ProfileScreen.onFocus = true
  m.ProfileScreen.setFocus(true)
end sub

' Muestra la pantalla de Detalle de programa y escucha sus observable relacionados
sub __showProgramDetail()
  if m.MainScreen.visible then m.MainScreen.visible = false
  m.ProgramDetailScreen.visible = true
  m.ProgramDetailScreen.onFocus = true
  m.ProgramDetailScreen.setFocus(true)
  m.ProgramDetailScreen.ObserveField("onBack", "onBackDetail")
  m.ProgramDetailScreen.ObserveField("streaming", "onStreamingPlayer")
  m.ProgramDetailScreen.ObserveField("pendingStreamingSession", "onKillSession")
end sub

' Muestra la pantalla de Ver todos
sub __showViewAll(viewAllData as string)
  if m.MainScreen.visible then m.MainScreen.visible = false
  m.ViewAllScreen.visible = true
  m.ViewAllScreen.data = viewAllData
  m.ViewAllScreen.onFocus = true
  m.ViewAllScreen.setFocus(true)
  m.ViewAllScreen.ObserveField("streaming", "onStreamingPlayer")
  m.ViewAllScreen.ObserveField("detail", "onProgramDetail") 
  if m.loading <> invalid then m.loading.visible = false
end sub

' Muestra la pantalla de configuracion
sub __showSetting()
  if m.MainScreen.visible then m.MainScreen.visible = false
  m.SettingScreen.visible = true
  m.SettingScreen.onFocus = true
  m.SettingScreen.setFocus(true)
end sub

' Muestra la pantalla del player y esucha sus observable relacionados
sub __showPlayer(streaming, openGuide = false)
  m.StackOfScreens.Push("PlayerScreen")
  m.PlayerScreen.visible = true
  m.PlayerScreen.onFocus = true
  m.PlayerScreen.ObserveField("onBack", "onBackPlayer")
  m.PlayerScreen.setFocus(true)
  m.PlayerScreen.killedMe = invalid
  m.PlayerScreen.openGuide = openGuide
  m.PlayerScreen.data = streaming
end sub 

' Muestra la pantalla de sesiones concurrentes y esucha sus observable relacionados
sub __showKillSession(pendingStreamingSession, openGuide = false, killedMe = invalid)
  if m.MainScreen.visible then m.MainScreen.visible = false
  if m.ProgramDetailScreen.visible then m.MainScreen.visible = false

  m.StackOfScreens.Push("KillSessionScreen")

  m.KillSessionScreen.visible = true
  m.KillSessionScreen.onFocus = true
  m.KillSessionScreen.goToHome = false
  m.KillSessionScreen.setFocus(true)
  m.KillSessionScreen.ObserveField("streaming", "onStreamingPlayer")
  m.KillSessionScreen.ObserveField("goToHome", "goToHomeKillSessionScreen")

  m.KillSessionScreen.openGuide = openGuide
  m.KillSessionScreen.killedMe = killedMe
  m.KillSessionScreen.data = pendingStreamingSession
end sub 

' Esconde el detalle del programa y no escucha los eventos de esta pantalla ya que ahora abra otra siendo la
' pantalla princripal
sub __hideProgramDetail()
  m.ProgramDetailScreen.visible = false
  m.ProgramDetailScreen.onFocus = false
  m.ProgramDetailScreen.unobserveField("streaming")
  m.ProgramDetailScreen.unobserveField("onBack")
  m.ProgramDetailScreen.unobserveField("pendingStreamingSession")
  m.ProgramDetailScreen.streaming = invalid
  m.ProgramDetailScreen.pendingStreamingSession = invalid
end sub

' Esconde la pantalla Ver todos
sub __hideViewAll(clearData = true)
  m.ViewAllScreen.visible = false
  m.ViewAllScreen.onFocus = false
  m.ViewAllScreen.unobserveField("streaming")
  m.ViewAllScreen.unobserveField("detail")
  m.ViewAllScreen.streaming = invalid
  m.ViewAllScreen.detail = invalid
  if clearData then m.ViewAllScreen.data = invalid
end sub

' Esconde la Configuracion
sub __hideSetting()
  m.SettingScreen.visible = false
  m.SettingScreen.onFocus = false
end sub

' Esconde la eliminar sesiones concurrentes y no escucha los eventos de esta pantalla ya que ahora abra otra 
' siendo la pantalla princripal
sub __hideKillSessionScreen()
  m.KillSessionScreen.visible = false
  m.KillSessionScreen.onFocus = false
  m.KillSessionScreen.unobserveField("streaming")
  m.KillSessionScreen.unobserveField("goToHome")
  m.KillSessionScreen.data = invalid
  m.KillSessionScreen.streaming = invalid
  m.KillSessionScreen.killedMe = invalid
  m.KillSessionScreen.openGuide = false 
  m.KillSessionScreen.goToHome = false
end sub

' Esconde la Main y no escucha los eventos de esta pantalla ya que ahora abra otra siendo la pantalla princripal 
sub __hideMain()
  m.MainScreen.onFocus = false
  m.MainScreen.loadData = false
  m.MainScreen.unobserveField("streaming")
  m.MainScreen.unobserveField("pendingStreamingSession")
  m.MainScreen.unobserveField("detail")
  m.MainScreen.unobserveField("viewAll")
  m.MainScreen.unobserveField("setting")
  m.MainScreen.streaming = invalid
  m.MainScreen.pendingStreamingSession = invalid
  m.MainScreen.detail = invalid
  m.MainScreen.viewAll = invalid
  m.MainScreen.setting = false
end sub

' Procesa el back del player limpiando las variables necesarias
sub __playerBackProcessing()
  if not (m.PlayerScreen.killedMe <> invalid and m.PlayerScreen.killedMe <> "") then 
    ' curso normal
    m.PlayerScreen.visible = false
    m.PlayerScreen.onFocus = false
    
    __backManager(m.StackOfScreens.Peek())
  else
    ' alguien me quito la sesion
    m.PlayerScreen.visible = false
    m.PlayerScreen.onFocus = false
    killedMe = m.PlayerScreen.killedMe
    m.PlayerScreen.killedMe = invalid

    __showKillSession(invalid, false, killedMe)
  end if
end sub

' Limpia tidas las variables internas y configuracion del usuario.
sub __resetApp()
  ' Se usa el cambio para diaparar la limpieza de las pantallas
  if not m.ProfileScreen.logout then m.ProfileScreen.logout = true
  if not m.MainScreen.logout then m.MainScreen.logout = true
  if not m.ProgramDetailScreen.logout then m.ProgramDetailScreen.logout = true
  if not m.KillSessionScreen.logout then m.KillSessionScreen.logout = true
  if not m.PlayerScreen.logout then m.PlayerScreen.logout = true  
  
  m.ProfileScreen.logout = false
  m.MainScreen.logout = false
  m.KillSessionScreen.logout = false
  m.ProgramDetailScreen.logout = false
  m.PlayerScreen.logout = false

  m.StackOfScreens = []

  ' se limpian las variables del player
  m.PlayerScreen.visible = false
  m.PlayerScreen.onFocus = false
  m.PlayerScreen.unobserveField("onBack")
  if m.PlayerScreen.onBack then m.PlayerScreen.onBack = false
  if m.PlayerScreen.killedMe <> invalid then m.PlayerScreen.killedMe = invalid

  __hideMain()
  __hideSetting()
  __hideViewAll()
  __hideProgramDetail()
  __hideKillSessionScreen()
  
  ' se limpia las variables del detalle
  m.ProgramDetailScreen.data = invalid

  ' se limpia las variables del perfil    
  m.ProfileScreen.visible = false
  m.ProfileScreen.onFocus = false
  m.ProfileScreen.finished = false

  ' Se limpia las variables del Main
  m.MainScreen.onChangeProfile = false
  m.MainScreen.visible = false
  m.MainScreen.loadData = false

  deleteSessionData()
  removeFields(m.global, ["contact", "organization", "PrivateVariables"])
end sub

' Dibuja el modal que pregunta si el usuario realmente quiere salir del app.
sub __showExitAsk()
  'create the dialog
  dialog = createObject("roSGNode", "StandardMessageDialog")
  dialog.palette = createPaletteDialog()
  dialog.title = [i18n_t(m.global.i18n, "shared.exitModal.title")]
  dialog.message = [i18n_t(m.global.i18n, "shared.exitModal.askExit")]
  dialog.buttons = [i18n_t(m.global.i18n, "button.yes"), i18n_t(m.global.i18n, "button.no")]
  dialog.observeFieldScoped("buttonSelected", "onDialogButtonClicked")

  'assigning the dialog to m.top.dialog will "show" the dialog
  m.top.dialog = dialog
end sub

' Adminsitrador de eventos back
sub __backManager(ScreenFocus)
  if ScreenFocus = "ProgramDetailScreen" then 
    __showProgramDetail()
  else if ScreenFocus = "ViewAllScreen" then
    ' Restauramos ViewAll al volver desde Player/Detalle cuando quedó en el stack.
    if not m.ViewAllScreen.visible then m.ViewAllScreen.visible = true 
    ' Rehabilitamos foco para retomar navegación en ViewAll.
    m.ViewAllScreen.onFocus = true 
    ' Devolvemos foco al componente para que su lista interna recupere control.
    m.ViewAllScreen.setFocus(true) 
    m.ViewAllScreen.ObserveField("streaming", "onStreamingPlayer")
    m.ViewAllScreen.ObserveField("detail", "onProgramDetail")
    ' Evitamos spinner colgado al volver desde Player.
    if m.loading <> invalid then m.loading.visible = false 
  else if ScreenFocus = "MainScreen" then 
    if not m.MainScreen.visible then m.MainScreen.visible = true
    m.MainScreen.onFocus = true
    m.MainScreen.setFocus(true)
    m.MainScreen.ObserveField("streaming", "onStreamingPlayer")
    m.MainScreen.ObserveField("pendingStreamingSession", "onKillSession")
    m.MainScreen.ObserveField("detail", "onProgramDetail")
    m.MainScreen.ObserveField("viewAll", "onViewAll") 
    m.MainScreen.ObserveField("setting", "onSetting")
  end if
end sub