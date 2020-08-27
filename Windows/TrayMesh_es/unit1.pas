unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Menus, opensslsockets, LCLType,
  fphttpclient, ServiceManager, JwaWinSvc, StrUtils, registry, LazUTF8;

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
    ServerUrl: TMenuItem;
    SystemName: TMenuItem;
    NameTitle: TMenuItem;
    MenuItem4: TMenuItem;
    IpTitle: TMenuItem;
    IpMenu: TMenuItem;
    MenuItem7: TMenuItem;
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
  Services: TServiceManager;
  ServiceStatus: TServiceStatus;
begin
  Services := TServiceManager.Create(nil);
  try
    try
      Services.Acces := SC_MANAGER_CONNECT;
      Services.Connect;
      Services.GetServiceStatus('Mesh Agent', ServiceStatus);
      IsRunning := (ServiceStatus.dwCurrentState = SERVICE_RUNNING);
      Services.Disconnect;
    except
      on E: EServiceManager do
      begin
        IsRunning := False;
        raise;
      end;
      on E: Exception do
      begin
        IsRunning := False;
        raise;
      end;
    end;
  finally
    Synchronize(@ActualizaEstadoAgente);
    Services.Free;
  end;
end;

//sincroniza hilo anterior con este procedimiento
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



{Hilo para verificación periódica del servidor}
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
  Services: TServiceManager;
  ServiceStatus: TServiceStatus;
  dwWaitTime: integer;
begin
  Services := TServiceManager.Create(nil);
  try
    try
      Services.Acces := SC_MANAGER_CONNECT; //Note typo in property.
      Services.Connect;
      Services.StartService(ServiceName, nil);
      while (ServiceStatus.dwCurrentState = SERVICE_START_PENDING) do
      begin
        dwWaitTime := ServiceStatus.dwWaitHint div 10;
        if (dwWaitTime < 1000) then
          dwWaitTime := 1000
        else if (dwWaitTime > 10000) then
          dwWaitTime := 10000;
        Sleep(dwWaitTime);
        Result := (ServiceStatus.dwCurrentState = SERVICE_RUNNING);
      end;
      Services.Disconnect;
    except
      on E: EServiceManager do
      begin
        Result := False;
        ShowMessage('Error al iniciar el servicio de Mesh Agent. Compruebe su instalación');
      end;
      on E: Exception do
      begin
        Result := False;
        ShowMessage('Error al iniciar el servicio de Mesh Agent. Compruebe su instalación');
      end;
    end;
  finally
    Services.Free;
  end;
end;

{/Inicia servicio de MeshAgent}


{Detiene servicio de MeshAgent}
function StopService(ServiceName: string): boolean;
var
  Services: TServiceManager;
  ServiceStatus: TServiceStatus;
  dwWaitTime: integer;
begin
  Services := TServiceManager.Create(nil);
  try
    try
      Services.Acces := SC_MANAGER_CONNECT;
      Services.Connect;
      Services.StopService(ServiceName, False);
      while (ServiceStatus.dwCurrentState = SERVICE_STOP_PENDING) do
      begin
        dwWaitTime := ServiceStatus.dwWaitHint div 10;
        if (dwWaitTime < 1000) then
          dwWaitTime := 1000
        else if (dwWaitTime > 10000) then
          dwWaitTime := 10000;
        Sleep(dwWaitTime);
        Result := (ServiceStatus.dwCurrentState = SERVICE_STOPPED);
      end;
      Services.Disconnect;
    except
      on E: EServiceManager do
      begin

        Result := False;
        ShowMessage('Error al detener el servicio de Mesh Agent.');
      end;
      on E: Exception do
      begin
        Result := False;
        ShowMessage('Error al detener el servicio de Mesh Agent.');
      end;
    end;
  finally
    Services.Free;
  end;
end;

{/Detiene servicio de MeshAgent}



{Obtiene nombre del equipo}
procedure tform1.NombreEquipo;
var
  PCNAME: string;
begin
  PCNAME := GetEnvironmentVariable('COMPUTERNAME');
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


{Obtiene nombre del servidor}
procedure TForm1.ObtieneServidor(Sender: TObject);
var
  reg: TRegistry;
begin
  try
    reg := TRegistry.Create(KEY_READ or KEY_WOW64_64KEY);
    reg.RootKey := HKEY_LOCAL_MACHINE;
    if reg.OpenKeyReadOnly('\SOFTWARE\Open Source\MeshAgent2') then
    begin
      RegServer := reg.ReadString('MeshServerUrl');
      if RegServer <> 'local' then
      begin
        RegServerStriped := stringreplace(RegServer, 'wss://', '', [rfReplaceAll, rfIgnoreCase]);
        RegServerStriped := stringreplace(RegServerStriped, '/agent.ashx', '', [rfReplaceAll, rfIgnoreCase]);
        reg.CloseKey;
      end
      else
        RegServerStriped := RegServer;
    end
  except
    ShowMessage('Error al obtener dirección del servidor. Compruebe la instalación del Mesh Agent');
    raise;
  end;
  reg.Free;
end;

{/Obtiene nombre del servidor}



procedure TForm1.RestartAgentClick(Sender: TObject);
begin
  if StopService('Mesh Agent') then
  begin
    Sleep(1000); //workaround porque se pisaban los procesos. Ver como mejorarlo
    if StartService('Mesh Agent') then
    begin
      Form1.TrayMeshIcon.AnimateInterval := 200;
      Form1.TrayMeshIcon.BalloonTitle := 'Mesh Agent';
      Form1.TrayMeshIcon.BalloonHint := 'Servicio reiniciado correctamente';
      Form1.TrayMeshIcon.BalloonFlags := bfInfo;
      Form1.TrayMeshIcon.ShowBalloonHint;
    end;
  end;
end;



procedure TForm1.StartAgentClick(Sender: TObject);
begin
  if StartService('Mesh Agent') then
  begin
    Form1.TrayMeshIcon.AnimateInterval := 200;
    Form1.TrayMeshIcon.BalloonTitle := 'Mesh Agent';
    Form1.TrayMeshIcon.BalloonHint := 'Servicio iniciado correctamente';
    Form1.TrayMeshIcon.BalloonFlags := bfInfo;
    Form1.TrayMeshIcon.ShowBalloonHint;
  end;
end;

procedure TForm1.StopAgentClick(Sender: TObject);
begin
  if StopService('Mesh Agent') then
  begin
    Form1.TrayMeshIcon.AnimateInterval := 200;
    Form1.TrayMeshIcon.BalloonTitle := 'Mesh Agent';
    Form1.TrayMeshIcon.BalloonHint := 'Servicio detenido correctamente';
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
  ThreadServer := THServidor.Create(True); //Crea el Hilo en modo suspendido
  ThreadServer.FreeOnTerminate := True; //Se asegura de liberar el Hilo al terminar
  ThreadServer.Start; //Inicia efectivamente el Hilo
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
    DialogoSalir.Caption:=' ';
    DialogoSalir.Text:= 'Esto NO detendrá el servicio de Mesh Agent.';
    DialogoSalir.Title:= '¿Salir de TrayMesh?';
    DialogoSalir.Execute;
    if DialogoSalir.ModalResult = mrOk then Application.Terminate;
end;

end.
