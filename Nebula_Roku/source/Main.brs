' Inicio de la app
sub Main(_input)
    'Indicate this is a Roku SceneGraph application'
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)

    'Create a scene and load /components/MainScene.xml'
    scene = screen.CreateScene("MainScene")
    screen.show()

    'observe the appExit event to know when to kill the channel
    scene.observeField("appExit", m.port)
    'focus the scene so it can respond to key events
    scene.setFocus(true)

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        'respond to the appExit field on MainScene
        else if msgType = "roSGNodeEvent" then
            field = msg.getField()
            'if the scene's appExit field was changed in any way, exit the channel
            if field = "appExit" then return
        end if
    end while
end sub