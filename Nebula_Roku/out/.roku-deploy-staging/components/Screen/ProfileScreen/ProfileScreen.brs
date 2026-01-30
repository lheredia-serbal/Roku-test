' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
  m.top.finished = false 
  m.allowAddingProfiles = false

  'Elegir perfil
  m.screenProfileSelected = m.top.findNode("screenProfileSelected")
  m.titleSelected = m.top.findNode("titleSelected")
  m.buttonRectangleEdit = m.top.findNode("buttonRectangleEdit")
  m.buttonRectangle = m.top.findNode("buttonRectangle")
  m.manageProfile = m.top.findNode("manageProfile")
  m.profilesElements = m.top.findNode("profilesElements")
  
  'Editar perfil
  m.screenProfileEdit = m.top.findNode("screenProfileEdit")
  m.titleEdit = m.top.findNode("titleEdit")
  m.profileImageEdit = m.top.findNode("profileImageEdit")
  m.profileName = m.top.findNode("profileName")
  m.buttonEditContainer = m.top.findNode("buttonEditContainer")
  m.keyboard = m.top.findNode("keyboard")
  
  'Editar avatar
  m.avatar = m.top.findNode("avatar")
  m.screenAvatarEdit = m.top.findNode("screenAvatarEdit")
  m.carousels = m.top.findNode("carousels")
  m.carouselContainer = m.top.findNode("carouselContainer")
  m.selectedIndicator = m.top.findNode("selectedIndicator")
  m.profileNameInAvatars = m.top.findNode("profileNameInAvatars")
  m.profileImageInAvatars = m.top.findNode("profileImageInAvatars")
  m.profileImageAndNameContainer = m.top.findNode("profileImageAndNameContainer")

  m.scaleInfo = m.global.scaleInfo
  
  m.profiles = []
  m.lastProfileFocus = invalid

  m.profileByEdit = invalid
  m.blockLoading = false
end sub

' Funcion que interpreta los eventos de teclado y retorna true si fue porcesada por este componente. Sino es porcesado por el
' entonces sigue con el siguente metodo onKeyEvent del compoente superior
function onKeyEvent(key as string, press as boolean) as boolean
  if m.top.loading.visible <> false and key <> KeyButtons().BACK then 
    return true
  end if

  if m.blockLoading and m.top.loading.visible  and key = KeyButtons().BACK then
    return false
  end if

  handled = false

  ' Eventos dentro del la pantalla de seleccion
  if m.screenProfileSelected.visible then
    if key = KeyButtons().UP then
      if press and m.manageProfile.isInFocusChain() and m.profiles.count() > 0 then
        'Se coloca en el 2° elemento porque el primero es el Rectanble para evitar desplazamiento en pantalla 
        m.profilesElements.getChild(1).showManageProfile = m.showManageProfile 
        m.profilesElements.getChild(1).setFocus(true)
      end if
      handled = true
    else if key = KeyButtons().DOWN then
      if press and m.profilesElements.isInFocusChain() then 
        m.manageProfile.setFocus(true)
      end if
      handled = true
    else if key = KeyButtons().LEFT then
      if press and m.profilesElements.isInFocusChain() and m.profilesElements.focusedChild <> invalid and m.profilesElements.focusedChild.focusLeft <> invalid then 
        m.profilesElements.focusedChild.focusLeft.showManageProfile = m.showManageProfile
        m.profilesElements.focusedChild.focusLeft.setFocus(true)
      end if
      handled = true
    else if key = KeyButtons().RIGHT then
      if press and m.profilesElements.isInFocusChain() and m.profilesElements.focusedChild <> invalid and m.profilesElements.focusedChild.focusRight <> invalid then 
        if m.profilesElements.focusedChild.focusRight.profileId <> -1 then
          m.profilesElements.focusedChild.focusRight.showManageProfile = m.showManageProfile
        end if
        m.profilesElements.focusedChild.focusRight.setFocus(true)
      end if
      handled = true
    else if key = KeyButtons().OK then
      if press and m.profilesElements.isInFocusChain() and m.profilesElements.focusedChild <> invalid then 
        if m.profilesElements.focusedChild.profileId <> -1 then
          if m.showManageProfile then
            __editProfile(m.profilesElements.focusedChild.profileId)
          else
            __selectProfile(m.profilesElements.focusedChild.profileId, m.profilesElements.focusedChild.auxInfo)
          end if
        else 
          __addProfile()
        end if
      end if

      if press and m.manageProfile.isInFocusChain() then 
        if m.showManageProfile then 
          m.manageProfile.text = i18n_t(m.global.i18n, "profiles.profilePage.titleButton")
          m.showManageProfile = false
  
        else 
          m.manageProfile.text = i18n_t(m.global.i18n, "button.ready")
          m.showManageProfile = true
        end if 
      end if
      handled = true
    end if

  ' Eventos dentro del la pantalla edicion del perfil 
  else if m.screenProfileEdit.visible then
    if m.top.loading.visible <> false and key = KeyButtons().BACK then 
      __backToSelectProfile(false)
      return true
    end if

    if key = KeyButtons().DOWN and (m.buttonEditContainer.isInFocusChain() or m.profileImageEdit.isInFocusChain()) then
      if press then 
        m.keyboard.setFocus(true)
      end if
      handled = true

    else if key = KeyButtons().RIGHT and m.profileImageEdit.isInFocusChain() then
      if press then m.btnSave.setFocus(true)
      handled = true
    
    else if key = KeyButtons().UP and m.keyboard.isInFocusChain() then
      if press then m.btnSave.setFocus(true)
      handled = true
    
    else if key = KeyButtons().UP and m.buttonEditContainer.isInFocusChain() then
      handled = true

    else if (key = KeyButtons().LEFT or key = KeyButtons().UP) and m.profileImageEdit.isInFocusChain() then
      handled = true

    else if (key = KeyButtons().RIGHT or key = KeyButtons().LEFT) and m.buttonEditContainer.isInFocusChain() then
      if press then
        if key = KeyButtons().RIGHT then
          if m.btnSave.isInFocusChain() then
            m.btnCancel.setFocus(true)
          else if m.btnCancel.isInFocusChain() and m.btnDeleteProfile <> invalid then
            m.btnDeleteProfile.setFocus(true)
          end if
        end if
  
        if key = KeyButtons().LEFT then
          if m.btnDeleteProfile <> invalid and m.btnDeleteProfile.isInFocusChain() then
            m.btnCancel.setFocus(true)
          else if m.btnCancel.isInFocusChain() then
            m.btnSave.setFocus(true)
          else if m.btnSave.isInFocusChain() then
            m.profileImageEdit.setFocus(true)
          end if
        end if
      end if 
      
      handled = true

    else if key = KeyButtons().OK and m.btnCancel.isInFocusChain() then
      if press then __backToSelectProfile(false)
      handled = true

    else if key = KeyButtons().OK and m.btnDeleteProfile <> invalid and m.btnDeleteProfile.isInFocusChain() then
      if press then m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "profiles.confirmDeleteModal.title"), i18n_t(m.global.i18n, "profiles.confirmDeleteModal.askDelete"), "onDialogDeleteClosed", ["Delete", i18n_t(m.global.i18n, "button.cancel")])
      handled = true

    else if key = KeyButtons().OK and m.profileImageEdit.isInFocusChain() then
      if press then __editAvatar()
      handled = true

      
    else if key = KeyButtons().OK and m.btnSave.isInFocusChain() then
      if press then __saveProfile()
      handled = true

    else if key = KeyButtons().BACK then
      if press then __backToSelectProfile(false)
      handled = true

    end if

  ' Eventos dentro del la pantalla edicion del avatar
  else if m.screenAvatarEdit.visible then

    if key = KeyButtons().UP
      if press and m.carouselContainer <> invalid and m.carouselContainer.isInFocusChain() and m.carouselContainer.focusedChild <> invalid and m.carouselContainer.focusedChild.focusUp <> invalid then
        focusItem = m.carouselContainer.focusedChild.focusUp.findNode("carouselList")
        if focusItem <> invalid then 
          m.carouselContainer.focusedChild.focusUp.opacity = "1.0"
          focusItem.setFocus(true)
          m.carouselContainer.translation = [m.xPosition, -(m.carouselContainer.focusedChild.translation[1] - m.yPosition)] ' Mover hacia arriba
          m.selectedIndicator.size = m.carouselContainer.focusedChild.size
        end if
      end if
      handled = true

    else if key = KeyButtons().DOWN
      if press and m.carouselContainer <> invalid and m.carouselContainer.isInFocusChain() and m.carouselContainer.focusedChild <> invalid and m.carouselContainer.focusedChild.focusDown <> invalid  then
        focusItem = m.carouselContainer.focusedChild.focusDown.findNode("carouselList")
        if focusItem <> invalid then 
          m.carouselContainer.focusedChild.opacity = "0.0"
          focusItem.setFocus(true)
          m.carouselContainer.translation = [m.xPosition, -(m.carouselContainer.focusedChild.translation[1] - m.yPosition)]
          m.selectedIndicator.size = m.carouselContainer.focusedChild.size
        end if
      end if
      handled = true
      
    else if key = KeyButtons().BACK
        if press then __backToEditProfile(true)
        handled = true
    end if
  end if
  
  return handled
end function 

' Inicializa el foco del componente seteando los valores necesarios
sub initFocus()
  if m.top.onFocus then
    __applyTranslations()
    __initConfig()
    __getAllProfile()
  end if
end sub 

' Procesa la respuesta de la lista de perfiles del usuario
sub onGetAllProfileResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)
    m.allowAddingProfiles = (resp.metadata <> invalid and resp.metadata.actions <> invalid and resp.metadata.actions.add <> invalid and resp.metadata.actions.add)
    if resp.data <> invalid and resp.data.count() > 0 then 
      profiles = resp.data
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      __loadProfiles(profiles)
    end if
  else 
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    printError("GetAll Profile:", errorResponse)
    
    if validateLogout(statusCode, m.top) then return 
    
    m.top.loading.visible = false

    m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogReloadProfilesClosed", [i18n_t(m.global.i18n, "button.retry")])

    actionLog = createLogError(generateErrorDescription(errorResponse), generateErrorPageUrl("getAllProfile", "SelectProfileComponent"), getServerErrorStack(errorResponse))
    __saveActionLog(actionLog)
  end if 
end sub 

' Procesa la respuesta de eleccion de nuevo perfil del usuario.
sub onSussessSelectResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)

    actionLog =  getActionLog({ actionCode: ActionLogCode().SELECT_PROFILE })
    __saveActionLog(actionLog)
    
    contact = m.global.contact
    contact.profile = ParseJson(m.auxInfo)

    addAndSetFields(m.global, {contact: contact} )

    saveTokens(resp)
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    m.blockLoading = false
    m.top.finished = true
  else
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse

    profileId = m.apiRequestManager.dataAux
    
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    printError("Select Profile:", errorResponse)

    if validateLogout(statusCode, m.top) then return 

    m.auxInfo = invalid
    m.top.loading.visible = false
    m.blockLoading = false

    m.lastItemFocus = m.focusedChild

    m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogFocusToLastElementClosed", [i18n_t(m.global.i18n, "button.cancel")])

    actionLog = createLogError(generateErrorDescription(errorResponse), generateErrorPageUrl("updateSessionProfile", "ProfileComponent"), getServerErrorStack(errorResponse), "ProfileId", profileId)
    __saveActionLog(actionLog)
  end if 
end sub

' Procesa la respuesta que obtiene todos los de avatars disposnibles
sub onGetAllAvatarsResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    avatars = ParseJson(m.apiRequestManager.response).data
    
    if avatars.count() > 0 then 
      yPosition = 0
      previousCarousel = invalid
      
      __clearAvatarsCarousel()

      m.carouselContainer.translation = scaleSize([50, 20], m.scaleInfo)
      m.xPosition = m.carouselContainer.translation[0]
      m.yPosition = m.carouselContainer.translation[1]

      id = 0
      for each carouselData in avatars
        ' Crea una instancia del componente Carousel
        newCarousel = m.carouselContainer.createChild("Carousel")
        
        ' Asigna los datos e items recibidos del servidor
        newCarousel.id = id
        newCarousel.style = -1 'Estilo definido para el Avatar
        newCarousel.title = carouselData.name
        newCarousel.items = carouselData.avatars
        
        ' Posiciona el carousel verticalmente
        newCarousel.translation = [0, yPosition]
        
        ' Se agrega el evento click
        newCarousel.ObserveField("selected", "onSelectItem")
    
        ' Configura la navegación vertical entre carouseles
        if previousCarousel <> invalid then
            previousCarousel.focusDown = newCarousel
            newCarousel.focusUp = previousCarousel
        end if
        previousCarousel = newCarousel
    
        ' Usa la propiedad height definida en el componente para calcular la posición
        yPosition = yPosition + newCarousel.height + scaleValue(20, m.scaleInfo)
        
        id++
      end for

      ' Una vez creados todos los carouseles, establece el foco en el primer item del primer carousel:
      if m.carouselContainer.getChildCount() > 0 then
        firstCarousel = m.carouselContainer.getChild(0)
        firstList = firstCarousel.findNode("carouselList")
        if firstList <> invalid then
          firstList.setFocus(true)
          m.selectedIndicator.size = firstCarousel.size
          m.selectedIndicator.visible = true
        end if
      end if
    end if
    m.top.loading.visible = false
  else
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse

    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    printError("AllAvatar Profile:", errorResponse)

    if validateLogout(statusCode, m.top) then return 
    
    m.top.loading.visible = false
    m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogReturnProfileEditClosed", [i18n_t(m.global.i18n, "button.cancel")])
  end if 
end sub

' Procesa el cierre del modal al querer eliminar un perfil
sub onDialogDeleteClosed(_event)
  option = clearDialogAndGetOption(m.top, m.dialog)
  m.dialog = invalid
  
  if option = 0 then
    'Disparar el delete
    m.top.loading.visible = true
    m.blockLoading = true
    action = {
    apiRequestManager: m.apiRequestManager
    url: urlProfilesbyId(m.apiUrl, m.profileByEdit.id)
    method: "DELETE"
    responseMethod: "onSussessDeleteResponse"
    body: invalid
    token: invalid
    publicApi: false
    dataAux: invalid
    run: function() as Object
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
      return { success: true, error: invalid }
    end function
  }
  executeWithRetry(action, __getApiUrlRefreshAction(), ApiType().CLIENTS_API_URL)
  m.apiRequestManager = action.apiRequestManager
  else
    ' Se cancela el modal
    m.btnDeleteProfile.setFocus(true)
  end if 
end sub

' Procesa el cierre del modal al fallar la carga de la lista de perfiles
sub onDialogReloadProfilesClosed(_event)
  option = clearDialogAndGetOption(m.top, m.dialog)
  m.dialog = invalid
  
  if option = 0 then
    m.top.loading.visible = true
    __getAllProfile()
  end if 
end sub

' Procesa el cierre del modal al ocurrir un error y se quiere volver a dar foco al ultimo item que lo tenia
' antes del errror 
sub onDialogFocusToLastElementClosed(_event)
  option = clearDialogAndGetOption(m.top, m.dialog)
  m.dialog = invalid
  
  if option = 0 then
    m.lastItemFocus.setFocus(true)
    m.lastItemFocus = invalid
  end if 
end sub

' Procesa el cierre del modal al ocurrir un error al querer guardar un perfil, se le hace foco al ultimo 
' item que lo tenia antes del errror 
sub onDialogReturnProfileEditClosed(_event)
  option = clearDialogAndGetOption(m.top, m.dialog)
  m.dialog = invalid
  
  if option = 0 then __backToEditProfile(false)
end sub

' Procesa el cierre del modal al ocurrir un error al querer editar un perfil, se le hace foco al ultimo 
' item que lo tenia antes del errror 
sub onDialogReturnProfileListClosed(_event)
  option = clearDialogAndGetOption(m.top, m.dialog)
  m.dialog = invalid
  
  if option = 0 then __backToSelectProfile(false)
end sub

' Procesa la respuesta de que se confirmo eliminar el perfil selecioando
sub onSussessDeleteResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    m.blockLoading = false
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    __backToSelectProfile(true)
  else 
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    printError("Delete Profile:", errorResponse)

    if validateLogout(statusCode, m.top) then return 

    m.top.loading.visible = false
    m.blockLoading = false
    m.lastItemFocus = m.btnDeleteProfile

    m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogFocusToLastElementClosed", [i18n_t(m.global.i18n, "button.cancel")])
  end if 
end sub

' Procesa la respuesta de que se confirmo el guardado del perfil selecioando
sub onSussessSaveResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    m.blockLoading = false
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    __backToSelectProfile(true)
  else 
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    printError("Save Profile:", errorResponse)
    
    if validateLogout(statusCode, m.top) then return 

    m.blockLoading = false
    m.lastItemFocus = m.btnSave
    m.top.loading.visible = false
    
    m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogFocusToLastElementClosed", [i18n_t(m.global.i18n, "button.cancel")])
  end if 
end sub

' Procesa la respuesta del avatar por defecto para el nuevo perfil.
sub onGetDefaultAvatarResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    defaultAvatar = ParseJson(m.apiRequestManager.response).data
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    __loadEditProfile({id: 0, avatar: defaultAvatar, kids: false, name: ""})
  else 
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    printError("DefaultAvatar Profile:", errorResponse)
    
    if validateLogout(statusCode, m.top) then return 

    m.top.loading.visible = false
    
    m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogReturnProfileListClosed", [i18n_t(m.global.i18n, "button.cancel")])
  end if
end sub

' Procesa la respuesta al obtener la informacion completa del perfil
sub onGetByIdResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    __loadEditProfile(ParseJson(m.apiRequestManager.response).data)
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
  else 
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    printError("GetById Profile:", errorResponse)

    if validateLogout(statusCode, m.top) then return 

    m.top.loading.visible = false

    m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogReturnProfileListClosed", [i18n_t(m.global.i18n, "button.cancel")])
  end if
end sub

' Administrar el uso de los Inputs anidando el input posicionado en pantalla con el que usa internamente el teclado.
sub onTextBoxManagment()
  m.profileName.cursorPosition = m.keyboard.textEditBox.cursorPosition
  m.profileName.text = m.keyboard.textEditBox.text
  m.profileName.active = m.keyboard.textEditBox.active
end sub

' Toma la seleccion del avatar del carousel de avatars
sub onSelectItem()
  if m.carouselContainer <> invalid and m.carouselContainer.isInFocusChain() and m.carouselContainer.focusedChild <> invalid then
    avatarSelected = ParseJson(m.carouselContainer.focusedChild.selected)
    m.carouselContainer.focusedChild.selected = invalid
    m.profileByEdit.avatar = avatarSelected 
    m.profileImageInAvatars.uri = getImageUrl(m.profileByEdit.avatar.image) 
  end if
end sub

' Dispara el evento de deslogueo
sub onLogoutChange()
  if m.top.logout then __clearScreen()
end sub

' Carga la configuracion inicial del componente, escuchando los observable y obteniendo las 
' referencias de compenentes necesarios para su uso
sub __initConfig()
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL) 
  if m.beaconUrl = invalid then m.beaconUrl = getConfigVariable(m.global.configVariablesKeys.BEACON_URL) 

  width = m.scaleInfo.width
  height = m.scaleInfo.height
  
  m.manageProfile.text = i18n_t(m.global.i18n, "profiles.profilePage.titleButton")
  m.manageProfile.size = [scaleValue(260, m.scaleInfo)]
  m.showManageProfile = false
  
  m.screenProfileSelected.translation = [(width / 2), (height / 2)]
  m.titleSelected.width = width
  
  m.screenProfileEdit.translation = [(width / 2), scaleValue(80, m.scaleInfo)]
  m.buttonRectangleEdit.height = scaleValue(224, m.scaleInfo)
  m.buttonRectangle.height = scaleValue(216, m.scaleInfo)
  m.titleEdit.width = width
  m.keyboard.showTextEditBox = false
  m.keyboard.text = ""
  m.keyboard.textEditBox.maxTextLength = 255
  m.profileName.maxTextLength = 255
  m.profileName.hintTextColor = m.global.colors.LIGHT_GRAY

  m.profileImageEdit.size = scaleSize([200, 200], m.scaleInfo)
  m.profileName.width = scaleValue(600, m.scaleInfo)
  m.avatar.translation = scaleSize([77, 50], m.scaleInfo)

  m.profileImageInAvatars.width = scaleValue(90, m.scaleInfo)
  m.profileImageInAvatars.height = scaleValue(90, m.scaleInfo)

  m.carousels.translation = scaleSize([0, 20], m.scaleInfo)
  m.carouselContainer.translation = scaleSize([50, 20], m.scaleInfo)
  m.selectedIndicator.translation = scaleSize([78, 148], m.scaleInfo)

  m.profileImageAndNameContainer.translation = [width - scaleValue(150, m.scaleInfo), scaleValue(20, m.scaleInfo)]

  'clear variables
  m.lastProfileFocus = invalid
  m.profileByEdit = invalid
  m.blockLoading = false
  m.top.finished = false
end sub

' Limpia la lista de los perfiles del usuario
sub __clearArrayProfile()
  m.lastProfileFocus = invalid

  for each item in m.profiles
    m.profilesElements.removeChild(item)
  end for

  m.profiles = []
end sub

' Dispara la peticion para obtener la lista de perfiles del usuario.
sub __getAllProfile()
  m.apiRequestManager = clearApiRequest(m.apiRequestManager)
  __clearArrayProfile()

  action = {
    apiRequestManager: m.apiRequestManager
    url: urlProfiles(m.apiUrl)
    method: "GET"
    responseMethod: "onGetAllProfileResponse"
    body: invalid
    token: invalid
    publicApi: false
    dataAux: invalid
    run: function() as Object
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
      return { success: true, error: invalid }
    end function
  }
  executeWithRetry(action, __getApiUrlRefreshAction(), ApiType().CLIENTS_API_URL)
  m.apiRequestManager = action.apiRequestManager
end sub

' carga en pantalla cada uno de los perfiles de la lista de perfiles obtenido.
sub __loadProfiles(profilesResp)
  fistElement = invalid
  lastProfile = invalid

  for each profile in profilesResp
    newProfile = m.profilesElements.createChild("ProfileItem")
    newProfile.size = scaleSize([150, 150], m.scaleInfo)
    newProfile.uriImage = getImageUrl(profile.avatar.image)
    newProfile.id ="profile" + profile.id.ToStr() 
    newProfile.profileId = profile.id
    newProfile.name = profile.name
    newProfile.focusable = true
    newProfile.auxInfo = FormatJson(profile)

    m.profiles.push(newProfile)

    if (fistElement = invalid) then fistElement = newProfile

    ' Configura la navegación vertical entre carouseles
    if lastProfile <> invalid then
      lastProfile.focusRight = newProfile
      newProfile.focusLeft = lastProfile
    end if
    lastProfile = newProfile
  end for

  if m.allowAddingProfiles then 
    addProfileButton = m.profilesElements.createChild("ProfileItem")
    addProfileButton.size = scaleSize([150, 150], m.scaleInfo)
    addProfileButton.uriImage = "pkg:/images/shared/add_profile.png"
    addProfileButton.id ="profileSelected" 
    addProfileButton.profileId = -1
    addProfileButton.focusable = true
    addProfileButton.name = i18n_t(m.global.i18n, "profiles.profilePage.addProfile")

    addProfileButton.focusLeft = m.profiles.[m.profiles.count() - 1]
    m.profiles.[m.profiles.count() - 1].focusRight = addProfileButton

    m.profiles.push(addProfileButton)
  end if

  if (fistElement <> invalid) then 
    fistElement.showManageProfile = m.showManageProfile
    fistElement.setFocus(true)
  end if
  
  m.top.loading.visible = false
end sub

' Dispara la peticion para editar el perfil selecionado y carga la pantalla de edicion de perfiles
sub __editProfile(profileId)
  m.apiRequestManager = clearApiRequest(m.apiRequestManager)
  m.lastProfileFocus = m.profilesElements.focusedChild
  m.top.loading.visible = true
  m.screenProfileSelected.visible = false
  m.screenProfileEdit.visible = true
  
  action = {
    apiRequestManager: m.apiRequestManager
    url: urlProfilesbyId(m.apiUrl, profileId)
    method: "GET"
    responseMethod: "onGetByIdResponse"
    body: invalid
    token: invalid
    publicApi: false
    dataAux: invalid
    run: function() as Object
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
      return { success: true, error: invalid }
    end function
  }
  executeWithRetry(action, __getApiUrlRefreshAction(), ApiType().CLIENTS_API_URL)
  m.apiRequestManager = action.apiRequestManager
end sub

' Dispara la peticion para selecionar un el perfil para usar
sub __selectProfile(profileId, auxInfo)
  m.top.loading.visible = true
  m.blockLoading = true
  m.auxInfo = auxInfo
  
  action = {
    apiRequestManager: m.apiRequestManager
    url: urlAuthProfile(m.apiUrl, profileId)
    method: "PUT"
    responseMethod: "onSussessSelectResponse"
    body: invalid
    token: invalid
    publicApi: false
    dataAux: StrI(profileId)
    run: function() as Object
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
      return { success: true, error: invalid }
    end function
  }
  executeWithRetry(action, __getApiUrlRefreshAction(), ApiType().CLIENTS_API_URL)
  m.apiRequestManager = action.apiRequestManager
end sub

' Dispara la peticion para editar el avatar del perfil selecionado y carga la pantalla de avatars
sub __editAvatar()
  m.top.loading.visible = true
  m.screenProfileEdit.visible = false
  
  m.screenAvatarEdit.visible = true

  m.profileNameInAvatars.text = m.profileByEdit.name
  m.profileImageInAvatars.uri = getImageUrl(m.profileByEdit.avatar.image)

  action = {
    apiRequestManager: m.apiRequestManager
    url: urlAvatarsAll(m.apiUrl)
    method: "GET"
    responseMethod: "onGetAllAvatarsResponse"
    body: invalid
    token: invalid
    publicApi: false
    dataAux: invalid
    run: function() as Object
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
      return { success: true, error: invalid }
    end function
  }
  executeWithRetry(action, __getApiUrlRefreshAction(), ApiType().CLIENTS_API_URL)
  m.apiRequestManager = action.apiRequestManager
end sub

' Dispara la peticion para obtener un avatar por defecto y carga la pantalla de edicion de perfiles
sub __addProfile()
  m.apiRequestManager = clearApiRequest(m.apiRequestManager)
  m.lastProfileFocus = m.profilesElements.focusedChild
  m.top.loading.visible = true
  m.screenProfileSelected.visible = false
  m.screenProfileEdit.visible = true
  
    action = {
    apiRequestManager: m.apiRequestManager
    url: urlAvatarsDefault(m.apiUrl)
    method: "GET"
    responseMethod: "onGetDefaultAvatarResponse"
    body: invalid
    token: invalid
    publicApi: false
    dataAux: invalid
    run: function() as Object
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
      return { success: true, error: invalid }
    end function
  }
  executeWithRetry(action, __getApiUrlRefreshAction(), ApiType().CLIENTS_API_URL)
  m.apiRequestManager = action.apiRequestManager
end sub

' Dispara la peticion para guardar/crear el perfil en la pantalla de perfiles, validando que tenga avatar y nombre 
sub __saveProfile()
  if (m.profileName.text = invalid) or (m.profileName.text = "") then 
    m.lastItemFocus = m.btnSave
    m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.unhandled"), i18n_t(m.global.i18n, "profiles.profilePage.error.nameRequired"), "onDialogFocusToLastElementClosed")
    printError("required field Profile")
    return
  end if 

  if (m.profileByEdit.avatar = invalid) then 
    m.lastItemFocus = m.btnSave
    m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.unhandled"), i18n_t(m.global.i18n, "profiles.profilePage.error.avatarRequired"), "onDialogFocusToLastElementClosed")
    printError("required field Profile")
    return
  end if 

  m.top.loading.visible = true

  m.profileByEdit.name = m.profileName.text 
  m.blockLoading = true

  if m.profileByEdit.id <> 0 then
    'update
    action = {
      apiRequestManager: m.apiRequestManager
      url: urlProfilesbyId(m.apiUrl, m.profileByEdit.id)
      method: "PUT"
      responseMethod: "onSussessSaveResponse"
      body: FormatJson(m.profileByEdit)
      token: invalid
      publicApi: false
      dataAux: invalid
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    executeWithRetry(action, __getApiUrlRefreshAction(), ApiType().CLIENTS_API_URL)
    m.apiRequestManager = action.apiRequestManager
  else
    'insert
    action = {
      apiRequestManager: m.apiRequestManager
      url: urlProfiles(m.apiUrl)
      method: "POST"
      responseMethod: "onSussessSaveResponse"
      body: FormatJson(m.profileByEdit)
      token: invalid
      publicApi: false
      dataAux: invalid
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    executeWithRetry(action, __getApiUrlRefreshAction(), ApiType().CLIENTS_API_URL)
    m.apiRequestManager = action.apiRequestManager
  end if
end sub

' Carga el perfil a editar y define la pantalla de edicion de perfiles 
sub __loadEditProfile(profileByEdit)
  m.profileByEdit = profileByEdit
  m.profileImageEdit.uriImage = getImageUrl(m.profileByEdit.avatar.image) 
  m.keyboard.setFocus(true) 

  m.keyboard.textEditBox.text = m.profileByEdit.name
  m.keyboard.textEditBox.cursorPosition = m.keyboard.text.len()
  m.keyboard.ObserveField("textEditBox", "onTextBoxManagment")

  m.btnSave = m.buttonEditContainer.createChild("QvButton")
  m.btnSave.id = "btnSave"
  m.btnSave.text = i18n_t(m.global.i18n, "button.save")
  m.btnSave.focusable = true
  m.btnSave.size = [scaleValue(220, m.scaleInfo)]

  m.btnCancel = m.buttonEditContainer.createChild("QvButton")
  m.btnCancel.id = "btnCancel"
  m.btnCancel.text = i18n_t(m.global.i18n, "button.cancel")
  m.btnCancel.focusable = true
  m.btnCancel.size = [scaleValue(220, m.scaleInfo)]

  if m.profileByEdit.id <> invalid and m.profileByEdit.id <> 0 and not m.profileByEdit.default then 
    m.btnDeleteProfile = m.buttonEditContainer.createChild("QvButton")
    m.btnDeleteProfile.id = "btnDeleteProfile"
    m.btnDeleteProfile.text = i18n_t(m.global.i18n, "profiles.profilePage.DeleteProfile")
    m.btnDeleteProfile.size = [scaleValue(220, m.scaleInfo)]
    m.btnDeleteProfile.focusable = true
  end if 
  m.top.loading.visible = false
end sub  

' Limpia los carouseles de avatars, las referencias y elimina los escuchadores 
sub __clearAvatarsCarousel()
  while m.carouselContainer.getChildCount() > 0
    child = m.carouselContainer.getChild(0)
    child.items = invalid
    m.carouselContainer.removeChild(child)
    child.unobserveField("selected")
  end while
  m.selectedIndicator.visible = false
end sub

' Aplicar las traducciones en el componente
sub __applyTranslations()
  if m.global.i18n = invalid then return

  m.titleSelected.text = i18n_t(m.global.i18n, "profiles.profilePage.askTitle")
  m.titleEdit.text = i18n_t(m.global.i18n, "profiles.profilePage.EditProfile")
  m.profileName.hintText = i18n_t(m.global.i18n, "profiles.profilePage.name")
  m.avatar.text = i18n_t(m.global.i18n, "profiles.profilePage.chooseAvatar")
end sub

' Procesa el back de la pantalla de editar perfiles.
sub __backToEditProfile(editImage)
  if editImage then m.top.loading.visible = true
  m.screenAvatarEdit.visible = false
  m.screenProfileEdit.visible = true
  
  __clearAvatarsCarousel()

  m.profileImageInAvatars.uri = ""
  m.profileNameInAvatars.text = ""

  if editImage then m.profileImageEdit.uriImage = getImageUrl(m.profileByEdit.avatar.image) 

  m.profileImageEdit.setFocus(true)
  if editImage then m.top.loading.visible = false
end sub

' Procesa el back de la pantalla de eleccion de perfiles.
sub __backToSelectProfile(reloadProfile)
  m.keyboard.unobserveField("textEditBox")
  if not m.top.loading.visible then m.top.loading.visible = true
  m.screenProfileEdit.visible = false
  m.profileByEdit = invalid
  
  m.profileImageEdit.uriImage = invalid 
  m.keyboard.text = ""
  m.profileName.text = ""

  m.buttonEditContainer.removeChild(m.btnSave)
  m.btnSave = invalid
  m.buttonEditContainer.removeChild(m.btnCancel)
  m.btnCancel = invalid

  if m.btnDeleteProfile <> invalid then 
    m.buttonEditContainer.removeChild(m.btnDeleteProfile)
    m.btnDeleteProfile = invalid
  end if
  
  m.screenProfileSelected.visible = true
  
  if reloadProfile then
    __getAllProfile()
  else 
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    m.top.loading.visible = false

    if m.lastProfileFocus  <> invalid then 
      m.lastProfileFocus.setFocus(true)
      m.lastProfileFocus = invalid 
    else 
      m.profilesElements.getChild(1).setFocus(true)
    end if 
  end if
end sub

' Metodo encargado de limpiar todas las dependecias, cancelar las peticiones y quitar los escuchadores de la pantalla
sub __clearScreen()
  m.lastProfileFocus = invalid
  m.blockLoading = false
  m.profileByEdit = invalid
  m.top.finished = false
  m.auxInfo = invalid
  m.lastItemFocus = invalid 
  
  m.apiRequestManager = clearApiRequest(m.apiRequestManager)
  __clearArrayProfile()
  __clearAvatarsCarousel()

  m.profileImageInAvatars.uri = ""
  m.profileNameInAvatars.text = ""

  m.profileImageEdit.uriImage = invalid 
  m.keyboard.text = ""
  m.profileName.text = ""

  if m.btnSave <> invalid then
    m.buttonEditContainer.removeChild(m.btnSave)
    m.btnSave = invalid
  end if

  if m.btnCancel <> invalid then
    m.buttonEditContainer.removeChild(m.btnCancel)
    m.btnCancel = invalid
  end if

  if m.btnDeleteProfile <> invalid then 
    m.buttonEditContainer.removeChild(m.btnDeleteProfile)
    m.btnDeleteProfile = invalid
  end if
  
  m.screenProfileSelected.visible = true
  m.screenProfileEdit.visible = false
  m.screenAvatarEdit.visible = false
end sub

' Actualiza la URL de API antes de ejecutar el retry.
function __getApiUrlRefreshAction() as Object
  return {
    run: __refreshApiUrl
  }
end function

sub __refreshApiUrl()
  m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL)
end sub

' Guardar el log cuandos se cambia una opción del menú 
sub __saveActionLog(actionLog as object)

  if beaconTokenExpired() and m.apiUrl <> invalid then
    action = {
      apiRequestManager: m.apiLogRequestManager
      url: urlActionLogsToken(m.apiUrl)
      method: "GET"
      responseMethod: "onActionLogTokenResponse"
      body: invalid
      token: invalid
      publicApi: false
      dataAux: FormatJson(actionLog)
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    executeWithRetry(action, __getApiUrlRefreshAction(), ApiType().LOGS_API_URL)
    m.apiLogRequestManager = action.apiRequestManager
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
    action = {
      apiRequestManager: m.apiLogRequestManager
      url: urlActionLogs(m.beaconUrl)
      method: "POST"
      responseMethod: "onActionLogResponse"
      body: FormatJson(actionLog)
      token: beaconToken
      publicApi: false
      dataAux: invalid
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    executeWithRetry(action, __getApiUrlRefreshAction(), ApiType().LOGS_API_URL)
    m.apiLogRequestManager = action.apiRequestManager
  end if
end sub

' Limpiar la llamada del log
sub onActionLogResponse() 
  m.apiLogRequestManager = clearApiRequest(m.apiLogRequestManager)
end sub