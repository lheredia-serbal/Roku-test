' Inicialización del componente SearchScreen.
sub init()
  ' Referencio el contenedor principal para mantener una estructura consistente.
  m.searchLayoutGroup = m.top.findNode("searchLayoutGroup")
end sub

' Inicializa foco cuando la pantalla se vuelve activa.
sub initFocus()
  ' Si SearchScreen tiene foco activo, fuerzo foco en el propio componente.
  if m.top.onFocus then m.top.setFocus(true)
end sub