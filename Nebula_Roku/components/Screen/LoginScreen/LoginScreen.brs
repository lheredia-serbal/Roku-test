' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
  m.top.finished = false 
  m.userField = m.top.findNode("userField")
  m.passwordField = m.top.findNode("passwordField")
  m.passwordLabel = m.top.findNode("passwordLabel")
  m.nextButton = m.top.findNode("nextButton")
  m.prevButton = m.top.findNode("prevButton")
  m.buttonContainer = m.top.findNode("buttonContainer")
  m.keyboard = m.top.findNode("keyboard")
  m.logo = m.top.findNode("logo")
  m.email = m.top.findNode("email")

  m.keyboard.showTextEditBox = false
  m.keyboard.textEditBox.maxTextLength = 255
  
  m.passwordLabel.opacity = 0.0
  m.passwordField.opacity = 0.0

  m.userField.maxTextLength = 255
  m.passwordField.maxTextLength = 255

  m.userField.hintTextColor = m.global.colors.LIGHT_GRAY
  m.passwordField.hintTextColor = m.global.colors.LIGHT_GRAY

  m.i18n = invalid
  scene = m.top.getScene()
  if scene <> invalid then
      m.i18n = scene.findNode("i18n")
  end if
  applyTranslations()
end sub

sub applyTranslations()
    if m.i18n = invalid then
        return
    end if

    m.email.text = i18n_t(m.i18n, "config.configPage.titleEmail")
    m.passwordLabel.text = i18n_t(m.i18n, "login.loginPage.password")
    m.prevButton.text = i18n_t(m.i18n, "button.previous")
    m.nextButton.text = i18n_t(m.i18n, "button.next")
    m.userField.hintText = i18n_t(m.i18n, "login.loginPage.enterYourEmail")
    m.passwordField.hintText = i18n_t(m.i18n, "login.loginPage.passwordInput")
end sub

' Funcion que interpreta los eventos de teclado y retorna true si fue porcesada por este componente. Sino es porcesado por el
' entonces sigue con el siguente metodo onKeyEvent del compoente superior
function onKeyEvent(key as String, press as Boolean) as Boolean
  if m.top.loading.visible <> false and key <> KeyButtons().BACK then 
    return true
  end if

  handled = false

  if m.keyboard.isInFocusChain() and key = KeyButtons().UP then
    if not press then 
      m.nextButton.setFocus(true)
    end if
    handled = true
  else if m.prevButton.isInFocusChain() and key = KeyButtons().RIGHT then
    if not press then 
      m.nextButton.setFocus(true)
    end if
    handled = true
  else if m.prevButton.isInFocusChain() and key = KeyButtons().DOWN then
    if not press then 
      __focusKeyboard()
    end if 
    handled = true
  else if m.prevButton.isInFocusChain() and key = KeyButtons().OK then
    if not press then __prevButtonPressed()
    handled = true
  else if m.nextButton.isInFocusChain() and key = KeyButtons().LEFT then
    if not press and m.inputFocus = "password" then  
      m.prevButton.setFocus(true)
    end if
    handled = true
  else if m.nextButton.isInFocusChain() and key = KeyButtons().DOWN then
    __focusKeyboard()
    handled = true
  else if m.nextButton.isInFocusChain() and key = KeyButtons().OK then
    if not press then __nextButtonPressed()
    handled = true
  end if

  return handled
end function

' Inicializa el foco del componente seteando los valores necesarios
sub initFocus()
  if m.top.onFocus then
    m.sendLoginPost = false
    m.inputFocus = "user"
    m.prevButton.disable = true

    m.keyboard.unobserveField("textEditBox")

    width = m.global.width

    m.buttonContainer.translation = [((width - 380) / 2), 0]
    m.logo.translation = [(width - 280), 30]
    
    m.keyboard.ObserveField("textEditBox", "onTextBoxManagment")
    __focusKeyboard()
  end if
end sub 

' Procesa la respuesta al tratar de loguear al usuario a traves de credenciales
sub onLoginResponse()
  if valdiateStatusCode(m.apiRequestManager.statusCode) then

    actionLog = getActionLog({ actionCode: ActionLogCode().LOGIN_BY_CREDENTIALS })
    __saveActionLog(actionLog)

    resp = ParseJson(m.apiRequestManager.response)
    
    addAndSetFields(m.global, {device: resp.device, organization: resp.organization, contact: resp.contact, variables: resp.variables} )
    
    saveNextUpdateVariables()

    SetDevice(resp.device)
    saveTokens(resp)
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    m.keyboard.unobserveField("textEditBox")
    m.sendLoginPost = false
    m.top.finished = true
  else 
    if m.resultCodes = invalid then m.resultCodes = getResultCodes()
    m.top.loading.visible = false

    error = ParseJson(m.apiRequestManager.errorResponse)

    errorAPI = ""

    if error.code = m.resultCodes.UNAUTHORIZED then
      errorAPI = "Incorrect email or password"
    else if error.code = m.resultCodes.NOT_CONFIRMED then
      errorAPI = "unconfirmed account"
    else if error.code = m.resultCodes.NOT_ACTIVATED then
      errorAPI = "Account not activated by administrator"
    else if error.code = m.resultCodes.REQUESTTIMEOUT then
      errorAPI = "Server connection error"
    else 
      errorAPI = "Error processing the request"
    end if
      
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    __showDialog(errorAPI)
  end if 
end sub

' Notifica que finalizo las tareas de la pantalla
sub onFinished()
  if m.top.finished then 
    m.sendLoginPost = false
    m.inputFocus = "user"
    m.prevButton.disable = true

    m.keyboard.text = ""
    m.inputFocus = "user"
    m.userField.text = invalid
    m.passwordField.text = invalid
    m.passwordLabel.opacity = 0.0
    m.passwordField.opacity = 0.0
    m.prevButton.disable = true
  end if 
end sub 

' Procesa el evento de cierre del dialogo y realiza la accion pertinente
sub onDialogClosed(_event)
  ' Eliminar el diálogo cuando el usuario cierra la ventana
  m.dialog.visible = false
  m.dialog.unobserveField("buttonSelected")
  m.top.removeChild(m.dialog)
  m.dialog = invalid
  m.sendLoginPost = false
  __focusKeyboard()
end sub

' Administrar el uso de los Inputs anidando el input posicionado en pantalla con el que usa internamente el teclado.
sub onTextBoxManagment()
  if m.inputFocus = "user" then 
    m.userField.cursorPosition = m.keyboard.textEditBox.cursorPosition
    m.userField.text = m.keyboard.textEditBox.text
    m.userField.active = m.keyboard.textEditBox.active
  else
    m.passwordField.cursorPosition = m.keyboard.textEditBox.cursorPosition
    m.passwordField.text = m.keyboard.textEditBox.text
    m.passwordField.active = m.keyboard.textEditBox.active
  end if
end sub

' Valdia y realiza las acciones pertinentes al precionar el boton Previus de la pantalla 
sub __prevButtonPressed()
  if m.inputFocus = "password" then
    m.keyboard.text = m.userField.text
    m.inputFocus = "user"
    m.passwordField.text = invalid
    m.nextButton.setFocus(true)
    m.passwordLabel.opacity = 0.0
    m.passwordField.opacity = 0.0
    m.prevButton.disable = true
  end if  
end sub

' Valdia y realiza las acciones pertinentes al precionar el boton Next de la pantalla 
sub __nextButtonPressed()
  if m.inputFocus = "user" then
    if m.userField.text <> invalid and m.userField.text <> "" then 
      m.passwordLabel.opacity = 1.0
      m.passwordField.opacity = 1.0
      m.prevButton.disable = false
      m.inputFocus = "password"
      m.keyboard.text = invalid
    else
      __showDialog("User is required!")
    end if
  else if m.inputFocus = "password" then
    if m.passwordField.text <> invalid and m.passwordField.text <> "" then 
      if m.sendLoginPost = false then
        m.sendLoginPost = true
        user = m.userField.text
        password = m.passwordField.text
        __initData()
        
        if user = "" or password = "" then      
          m.sendLoginPost = false
          __showDialog("Invalid email or password")
          return
        end if
        __login(user, password)
      end if
    else
      __showDialog("Password is required!")
    end if 
  end if
end sub

' Carga los datos de componente
sub __initData()
  if m.productCode = invalid then m.productCode = getConfigVariable(m.global.configVariablesKeys.PRODUCT_CODE)
  if m.platformCode = invalid then m.platformCode = getConfigVariable(m.global.configVariablesKeys.PLATFORM_CODE)
  if m.enviroment = invalid then m.enviroment = getConfigVariable(m.global.configVariablesKeys.ENVIRONMENT) 
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL) 
  if m.beaconUrl = invalid then m.beaconUrl = getConfigVariable(m.global.configVariablesKeys.BEACON_URL) 
end sub

' Realiza la peticion de logueo del usuario con las credenciales cargadas y los datos propios de la aplicaicon, 
' como la infromacion del dispositivo.
sub __login(user as String, password as String)
  if m.top.loading.visible = false then 
    credentials = {
      user: user,
      password: password,
      productCode: m.productCode,
      platformCode: m.platformCode,
      environment: m.enviroment,
      keepLoggedIn: true,
      device: m.global.device
    }
    
    m.top.loading.visible = true  
    m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlAuthCredentialsLogin(m.apiUrl), "POST", "onLoginResponse", FormatJson(credentials), invalid, true)
  end if 
end sub

' Muestra el modal con el mensaje de error pasado por parametro.
sub __showDialog(errorAPI as String)
  m.dialog = createAndShowDialog(m.top, i18n_t(m.i18n, "shared.errorComponent.unhandled"), errorAPI, "onDialogClosed")
end sub

' Entrega el foco al Teclado y actualiza la posicion del cursor.
sub __focusKeyboard()
  if m.inputFocus = "user" then 
    m.keyboard.textEditBox.cursorPosition = m.userField.text.Len()
  else
    m.keyboard.textEditBox.cursorPosition = m.passwordField.text.Len()
  end if
  m.keyboard.setFocus(true)
end sub

' Guardar el log cuandos se cambia una opción del menú 
sub __saveActionLog(actionLog as object)

  if beaconTokenExpired() and m.apiUrl <> invalid then
    m.apiLogRequestManager = sendApiRequest(m.apiLogRequestManager, urlActionLogsToken(m.apiUrl), "GET", "onActionLogTokenResponse", invalid, invalid, false, FormatJson(actionLog))
  else
      __sendActionLog(actionLog)
  end if
end sub

' Obtener el beacon token
sub onActionLogTokenResponse() 

  resp = ParseJson(m.apiLogRequestManager.response)
  actionLog = ParseJson(m.apiLogRequestManager.dataAux)

  setBeaconToken(resp.actionsLogToken)

  now = CreateObject("roDateTime")
  now.ToLocalTime()
  m.global.beaconTokenExpiresIn = now.asSeconds() + ((resp.expiresIn - 60) * 1000)

  m.apiLogRequestManager = clearApiRequest(m.apiLogRequestManager) 
  __sendActionLog(actionLog)
end sub

' Llamar al servicio para guardar el log
sub __sendActionLog(actionLog as object)
  beaconToken = getBeaconToken()

  if (beaconToken <> invalid and m.beaconUrl <> invalid)
    m.apiLogRequestManager = sendApiRequest(m.apiLogRequestManager, urlActionLogs(m.beaconUrl), "POST", "onActionLogResponse", FormatJson(actionLog), beaconToken, false)
  end if
end sub

' Limpiar la llamada del log
sub onActionLogResponse() 
  m.apiLogRequestManager = clearApiRequest(m.apiLogRequestManager)
end sub