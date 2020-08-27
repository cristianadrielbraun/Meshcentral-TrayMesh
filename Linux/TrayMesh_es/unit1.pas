unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Menus, opensslsockets, Process,
  fphttpclient, StrUtils, registry, LazUTF8;

type

  THAgente = class(Tthread)
  public
    procedure ActualizaEstadoAgente;
  protected
    procedure Execute; override;
  end;

  THServidor = class(Tthread)
  public
    procedure ActualizaServidorOnline;
    procedure ActualizaServidorOffline;
    procedure ActualizaServidorLocal;
  protected
    procedure Execute; override;
  end;




  { TForm1 }

  TForm1 = class(TForm)
    HTTP: TFPHTTPClient;
    ImageList1: TImageList;
    ImageList2: TImageList;
    SystemName: TMenuItem;
    NameTitle: TMenuItem;
    MenuItem4: TMenuItem;
    IpTitle: TMenuItem;
    IpMenu: TMenuItem;
    MenuItem7: TMenuItem;
    ServerUrl: TMenuItem;
    DialogoSalir: TTaskDialog;
    TituloTray: TMenuItem;
    Linea1: TMenuItem;
    StartAgent: TMenuItem;
    StopAgent: TMenuItem;
    RestartAgent: TMenuItem;
    ServerCheckItem: TMenuItem;
    Salir: TMenuItem;
    AgentCheckItem: TMenuItem;
    Line1Item: TMenuItem;
    PopUpTray: TPopupMenu;
    Timer1: TTimer;
    TrayMeshIcon: TTrayIcon;
    procedure FormCreate(Sender: TObject);
    procedure RestartAgentClick(Sender: TObject);
    procedure SalirClick(Sender: TObject);
    procedure StartAgentClick(Sender: TObject);
    procedure StopAgentClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TrayMeshIconClick(Sender: TObject);
    procedure ObtieneServidor(Sender: TObject);
    procedure NombreEquipo;
    procedure GetPublicIp;
    procedure TrayMeshIconMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
  private

  public

  end;

var
  Form1: TForm1;
  RegServer, RegServerStriped, PublicIP: string;
  ThreadAgente: THAgente;
  ThreadServer: THServidor;
  IsRunning, IsOnline: boolean;

implementation

{$R *.frm}

{ TForm1 }


{Hilo para verificación periódica del agente}
procedure THAgente.Execute;
var
  S: ansistring;
begin
  try
    if Runcommand('/bin/sh', ['-c', 'systemctl is-active meshagent.service'], s) then
    begin
      IsRunning := True;
    end
    else
    begin
      IsRunning := False;
    end;
  finally
    Synchronize(@ActualizaEstadoAgente);
  end;

end;

//Sincroniza hilo anterior con este procedimiento
procedure THagente.ActualizaEstadoAgente;
begin
  if IsRunning then
  begin
    Form1.AgentCheckItem.ImageIndex := 1;
    Form1.AgentCheckItem.Caption := 'El agente está iniciado';
    Form1.StartAgent.Enabled := False;
    Form1.StopAgent.Enabled := True;
  end
  else
  begin
    Form1.AgentCheckItem.ImageIndex := 2;
    Form1.AgentCheckItem.Caption := 'El agente está detenido';
    Form1.StartAgent.Enabled := True;
    Form1.StopAgent.Enabled := False;
  end;

end;

{/Hilo para verificación periódica del agente}



{Hilo para verificación periódica del estado del servidor}
procedure THServidor.Execute;
begin
  if RegServerStriped <> 'local' then
  begin
    Form1.HTTP := TFPHttpClient.Create(nil);
    try
      try
        Form1.HTTP.Get('https://' + RegServerStriped);
        if Form1.HTTP.ResponseStatusCode = 200 then
        begin
          Synchronize(@ActualizaServidorOnline);
        end;
      except
        Synchronize(@ActualizaServidorOffline);
      end;
    finally
      Form1.HTTP.Free;
    end;
  end
  else
  begin
    Synchronize(@ActualizaServidorLocal);
  end;
end;

//sincroniza con uno de estos tres
procedure THServidor.ActualizaServidorOnline;
begin
  Form1.ServerCheckItem.ImageIndex := 1;
  Form1.ServerCheckItem.Caption := 'Servidor en línea';
end;

procedure THServidor.ActualizaServidorOffline;
begin
  Form1.ServerCheckItem.ImageIndex := 2;
  Form1.ServerCheckItem.Caption := 'Servidor fuera de línea';
end;

procedure THServidor.ActualizaServidorLocal;
begin
  Form1.ServerCheckItem.ImageIndex := 1;
  Form1.ServerCheckItem.Caption := 'Servidor local';
  Form1.ServerUrl.Free;
end;

{/Hilo para verificación periódica del estado del servidor}



{Inicia servicio de MeshAgent}
function StartService(ServiceName: string): boolean;
var
  S: ansistring;

begin
  try
    Result := Runcommand('/bin/sh', ['-c', 'systemctl start ' + ServiceName], s)
  except
    Result := False;
  end;
end;

{/Inicia servicio de MeshAgent}



{Detiene servicio de MeshAgent}
function StopService(ServiceName: string): boolean;
var
  S: ansistring;
begin
  try
    Result := Runcommand('/bin/sh', ['-c', 'systemctl stop ' + ServiceName], s)
  except
    Result := False;
  end;
end;

{/Detiene servicio de MeshAgent}



{Obtiene nombre del equipo}
procedure tform1.NombreEquipo;
var
  PCNAME: string;
begin
  Runcommand('/bin/bash', ['-c', 'echo $HOSTNAME'], PCNAME);
  Form1.SystemName.Caption := PCNAME;
end;

{/Obtiene nombre del equipo}


{Obtiene IP pública}
procedure TForm1.GetPublicIp;
begin
  try
    try
      HTTP := TFPHttpClient.Create(nil);
      PublicIp := HTTP.Get('http://dynupdate.no-ip.com/ip.php');
      if HTTP.ResponseStatusCode = 200 then
      begin
        IpMenu.Caption := PublicIp;
      end
      else
      begin
        IpMenu.Caption := '-';
      end;
    except
      IpMenu.Caption := '-';
    end;
  finally
    HTTP.Free;
  end;
end;

{/Obtiene IP pública}



{Abre PopUp al hacer click}
//No se usa la propiedad "PopUpMenu" por errores visauales en algunas distros
procedure TForm1.TrayMeshIconMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
begin
  PopUpTray.PopUp;
end;

{/Abre PopUp al hacer click}


{Obtiene nombre del servidor}
procedure TForm1.ObtieneServidor(Sender: TObject);
var
  i, ln: integer;
  sl: TStringList;
  line: string;
begin
  sl := TStringList.Create;
  try
    try
      sl.LoadFromFile('/usr/local/mesh/meshagent.msh');
      for i := 0 to sl.Count - 1 do
      begin
        if Pos('MeshServer', sl[i]) <> 0 then
        begin
          ln := i;
          line := sl[ln];
          regserver := line;
        end;
      end
    finally
      begin
        RegServerStriped := stringreplace(RegServer, 'MeshServer=', '', [rfReplaceAll, rfIgnoreCase]);
        if RegServerStriped <> 'local' then
        begin
          RegServerStriped := stringreplace(RegServerStriped, 'wss://', '', [rfReplaceAll, rfIgnoreCase]);
          RegServerStriped := stringreplace(RegServerStriped, '/agent.ashx', '', [rfReplaceAll, rfIgnoreCase]);
        end;
      end
    end
  except
    ShowMessage('Error al obtener el nombre del servidor. Compruebe su instalación del Mesh Agent');
  end;
end;

{/Obtiene nombre del servidor}



procedure TForm1.RestartAgentClick(Sender: TObject);
begin
  if StopService('meshagent.service') then
  begin
    if StartService('meshagent.service') then
    begin

      Form1.TrayMeshIcon.AnimateInterval := 200;
      Form1.TrayMeshIcon.BalloonTitle := 'Mesh Agent';
      Form1.TrayMeshIcon.BalloonHint := 'Servicio reiniciado correctamente';
      Form1.TrayMeshIcon.BalloonFlags := bfInfo;
      Form1.TrayMeshIcon.ShowBalloonHint;
    end else
     begin
    Form1.ServerCheckItem.ImageIndex := 2;
    Form1.ServerCheckItem.Caption := 'Servidor fuera de linea';
    Form1.TrayMeshIcon.AnimateInterval := 3000;
    Form1.TrayMeshIcon.BalloonTitle := 'Mesh Agent';
    Form1.TrayMeshIcon.BalloonHint := 'Error al reiniciar el servicio';
    Form1.TrayMeshIcon.BalloonFlags := bfInfo;
    Form1.TrayMeshIcon.ShowBalloonHint;
  end;
  end;
end;

procedure TForm1.StartAgentClick(Sender: TObject);
begin
  if StartService('meshagent.service') then
  begin
    Form1.ServerCheckItem.ImageIndex := 1;
    Form1.ServerCheckItem.Caption := 'Servidor en línea';
    Form1.TrayMeshIcon.AnimateInterval := 3000;
    Form1.TrayMeshIcon.BalloonTitle := 'Mesh Agent';
    Form1.TrayMeshIcon.BalloonHint := 'Servicio iniciado correctamente';
    Form1.TrayMeshIcon.BalloonFlags := bfInfo;
    Form1.TrayMeshIcon.ShowBalloonHint;
  end
  else
  begin
    Form1.ServerCheckItem.ImageIndex := 2;
    Form1.ServerCheckItem.Caption := 'Servidor fuera de linea';
    Form1.TrayMeshIcon.AnimateInterval := 3000;
    Form1.TrayMeshIcon.BalloonTitle := 'Mesh Agent';
    Form1.TrayMeshIcon.BalloonHint := 'Error al iniciar el servicio';
    Form1.TrayMeshIcon.BalloonFlags := bfInfo;
    Form1.TrayMeshIcon.ShowBalloonHint;
  end;

end;

procedure TForm1.StopAgentClick(Sender: TObject);
begin
  if StopService('meshagent.service') then
  begin
    Form1.TrayMeshIcon.AnimateInterval := 200;
    Form1.TrayMeshIcon.BalloonTitle := 'Mesh Agent';
    Form1.TrayMeshIcon.BalloonHint := 'Servicio detenido correctamente';
    Form1.TrayMeshIcon.BalloonFlags := bfInfo;
    Form1.TrayMeshIcon.ShowBalloonHint;
  end
  else
  begin
    Form1.TrayMeshIcon.AnimateInterval := 200;
    Form1.TrayMeshIcon.BalloonTitle := 'Mesh Agent';
    Form1.TrayMeshIcon.BalloonHint := 'Error al detener el servicio';
    Form1.TrayMeshIcon.BalloonFlags := bfInfo;
    Form1.TrayMeshIcon.ShowBalloonHint;
  end;
end;


procedure TForm1.Timer1Timer(Sender: TObject);
begin
  ThreadAgente := THagente.Create(True); //Crea el Hilo en modo suspendido
  ThreadAgente.FreeOnTerminate := True; //Se asegura de liberar el Hilo al terminar
  ThreadAgente.Start; //Inicia efectivamente el Hilo

  ThreadServer := THServidor.Create(True); //Crea el Hilo en modo suspendido
  ThreadServer.FreeOnTerminate := True; //Se asegura de liberar el Hilo al terminar
  ThreadServer.Start; //Inicia efectivamente el Hilo
end;


procedure TForm1.FormCreate(Sender: TObject);
begin
  Form1.GetPublicIp;
  Form1.NombreEquipo;
  Form1.ObtieneServidor(nil);

  {check agente}
  ThreadAgente := THagente.Create(True);
  ThreadAgente.FreeOnTerminate := True;
  ThreadAgente.Start;
  {/check agente}

  {check server}
  ThreadServer := THServidor.Create(True);
  ThreadServer.FreeOnTerminate := True;
  ThreadServer.Start;
  {/check server}

  ServerUrl.Caption := RegServerStriped;
  TrayMeshIcon.Show;
end;




procedure TForm1.TrayMeshIconClick(Sender: TObject);
begin
  TrayMeshIcon.PopUpMenu.PopUp;
end;

procedure TForm1.SalirClick(Sender: TObject);
begin
  DialogoSalir.Caption := ' ';
  DialogoSalir.Text := 'Esto NO detendrá el servicio de Mesh Agent.';
  DialogoSalir.Title := '¿Salir de TrayMesh?';
  DialogoSalir.Execute;
  if DialogoSalir.ModalResult = mrOk then
    Application.Terminate;
end;

end.
