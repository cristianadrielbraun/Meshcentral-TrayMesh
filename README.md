# TrayMesh
Deserved Tray Icon for MeshCentral Agent

   ------------


## ENGLISH

	THIS IS A PROOF OF CONCEPT VERSION. FULLY FUNCTIONAL, BUT FAR FOR THE FINAL IDEA. 
	FOR NOW, IS JUST A BINARY FILE, AND THAT'S IS (+ 2 DLL ON WINDOWS VERSION).
	HOPEFULLY THIS WILL EVOLVE IN A WELL INTEGRATED PLUGIN FOR MESHCENTRAL, AND INSTALLER, AND A FEW CUSTOMIZABLE OPTIONS.
	
	
This is made on [CodeTyphon](https://www.pilotlogic.com/sitejoom/index.php/wiki/84-wiki/codetyphon-studio/72-codetyphon-about), which is actually a fork of [Lazarus](https://www.lazarus-ide.org/), being both IDEs for Free Pascal (A programming language that I find really great)

**Features:**

   * Shows System name (in an intent to provide some info to the customer on attended remote support. You know, teamviewer style)

   * Shows Public IP (same)

   * Shows connection with server (URL taken from Regedit -on Windows- and .smh file -on Linux-)

   * Shows Agent service status (and you can start/stop/restart it)

   * English and Spanish languages (At least for now. There is just a few strings in the code)
   
   * Windows and Linux versions
   ------------

**Screenshot:**

![Simple and pretty](meshtray.webp)
	
------------

**Future ideas:**

* Full integration via plugin, allowing the server to offer a teamviewer-style ID and password to the clients
* Continuing the previous concept, a full gui window (not just tray icon) showing those ID and password
* Definitely an installer for better integration. This installer should be pushed by the server itself via the mentioned plugin. It could wrap the agent installation, this program, and possibly a -very- slightly modified version of VNC (To be used only for MeshCentral. Better remote performance for long remote sessions)
* Allow costumer to ask for assistance opening a ticket directly from this program. 
* Also, allow them to open the MeshCentral chat
* Add GUI to the temporary mode too (should also wrap the original agent window)
* Suggestions?



   ------------

## SPANISH

	ESTA VERSIÓN ES UNA PRUEBA DE CONCEPTO. ES TOTALMENTE FUNCIONAL, PERO ALEJADA DE LA IDEA FINAL. 
	POR AHORA, ES TAN SOLO UN ARCHIVO BINARIO. SOLO ESO (+ 2 DLL EN LA VERSIÓN DE WINDOWS).
	CON SUERTE, ESTO EVOLUCIONARÁ EN UN PLUGIN PARA MESHCENTRAL MEJOR INTEGRADO, Y PERSONALIZABLE
	
	

Este programa fue hecho en [CodeTyphon](https://www.pilotlogic.com/sitejoom/index.php/wiki/84-wiki/codetyphon-studio/72-codetyphon-about), que es de hecho un fork de [Lazarus](https://www.lazarus-ide.org/), siendo ambos IDEs para Free Pascal (Un lenguaje de programación que realmente me encanta)


**Funciones:**

   * Muestra nombre del sistema(En un intento de proveer información al cliente en sesiones de atención remota. Simulando la idea de Teamviewer o similares

   * Muestra la IP pública (Misma idea que el punto anterior)

   * Muestra la conexión con el servidor (URL obtenida de REGEDIT -En windows- y el archivo .smh -en Linux-)

   * Muestra el estado del servicio del Agente (Y puedes iniciarlo/detenerlo/reiniciarlo)

   * Idiomas español e ingles (Al menos por ahora. El código entero cuenta con muy pocos strings)
   
   * Versiones para Windows y Linux
   ------------

**Captura de pantalla:**

![Simple and pretty](meshtray.webp)
	
------------

**Ideas a futuro:**

* Integración completa vía plugin, permitiendo al servidor ofrecer IDs y passwords a los clientes, simil TeamViewer
* Continuando con el concepto anterior, una GUI completa, con ventana (no solo el icono del tray), mostrando dichos ID y password
* Definitivamente, un instalador para mejorar la integración.Este instalador debería ser enviado por el propio servidor gracias al plugin mencionado. Podría "englobar" el instalador del agente, el presente programa, y quizas una -muy- levemente adaptada versión de VNC (Para ser usado solo por MeshCentral. Mejor rendimiento para sesiones de remoto largas)
* Permitir al cliente abrir un ticket solicitando asistencia directamente desde el programa
* También, permitirles abrir el chat de MeshCentral
* Agregar GUI para el modo temporal también (Que deberia del mismo modo englobar la ventana original del agente)
* ¿Ideas?

