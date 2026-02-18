program Atl;

{$APPTYPE CONSOLE}

uses
  SysUtils, Windows, IniFiles,System.Classes;

var
  ARQUIVO_INI: String;

procedure ExecutarComando(const Comando: string);
begin
  Writeln('Executando: ', Comando);
  WinExec(PAnsiChar(AnsiString('cmd.exe /c ' + Comando)), SW_HIDE);
  Sleep(1000);
end;

procedure ExecutarComandoWait(const Comando: string);
var
  StartUpInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  Command: string;
begin
  FillChar(StartUpInfo, SizeOf(StartUpInfo), 0);
  StartUpInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartUpInfo.wShowWindow := SW_HIDE;

  Command := 'cmd.exe /C '+Comando;

  if CreateProcess(nil, PChar(Command), nil, nil, False, 0, nil, nil, StartUpInfo, ProcessInfo) then
  begin
    // Aguarda a conclusão do processo
    WaitForSingleObject(ProcessInfo.hProcess, INFINITE);

    // Fecha os handles do processo
    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
  end;
end;

procedure MostrarExemplo;
begin
  Writeln('Uso: Atl <nome>');
  Writeln('Adicionar comandos:');
  Writeln('  Atl add nome "<comando>" "<descrição>"');
  Writeln('  Exemplo: Atl add git.c "git commit -m ''%1'' " "commitando git" ');
  Writeln('  Ao digitar: Atl git.c mensagem ou "mensagem aqui"');
  Writeln('Deletar comandos:');
  Writeln('  Atl delete nome ');
  Writeln('  Exemplo: Atl delete git.c');
  Writeln;
end;

procedure ListaComandos(nome:String='');
var semDesc:Boolean;
    xnome:String;
begin
  xnome   := nome;
  semDesc := false;

  if nome.EndsWith('*') then begin
    semDesc := true;
    xnome   := nome.Replace('*','');
  end;

  if nome = '' then begin
    MostrarExemplo();
    Writeln('Comandos disponíveis:');
  end else
   Writeln('Comandos disponíveis: '+nome+' ...');

  var Ini := TIniFile.Create(ARQUIVO_INI);
  try
    var Lista: TStringList := TStringList.Create;
    try
      Ini.ReadSections(Lista);
      var tem := 0;
      for var i := 0 to Lista.Count - 1 do begin

        if (xnome = '') or Lista[i].StartsWith(xnome,true) then begin
          Writeln(Lista[i].PadRight(20),' -> ', Ini.ReadString(Lista[i], 'Comando', ''));
          if not semDesc then
            Writeln(''.PadRight(20)      ,'    ', Ini.ReadString(Lista[i], 'Descricao', '') );
          inc(tem);
        end;

      end;

      Writeln('Total listados: '+tem.ToString);

    finally
      Lista.Free;
    end;

    Writeln('');

  finally
    Ini.Free;
  end;
end;

procedure AdicionarComando;
var
  nome, Descricao, Comando: string;
  Ini: TIniFile;
begin

  if ParamCount < 4 then
  begin
    MostrarExemplo();
    Exit;
  end;

  nome      := ParamStr(2);
  Comando   := ParamStr(3);
  Descricao := ParamStr(4);

  Ini := TIniFile.Create(ARQUIVO_INI);
  try
    Ini.WriteString(nome, 'Comando', Comando);
    Ini.WriteString(nome, 'Descricao', Descricao);
    Writeln('Comando adicionado: ', nome, ' - ', Descricao);
    Writeln('');
  finally
    Ini.Free;
  end;
end;

procedure DeletarComando;
var nome: string;
    Ini: TIniFile;
begin
  if ParamCount < 2 then
  begin
    MostrarExemplo();
    Exit;
  end;
  nome := ParamStr(2);
  Ini := TIniFile.Create(ARQUIVO_INI);
  try
    Ini.EraseSection(nome);
    Writeln('Comando deletado: ', nome);
    Writeln('');
  finally
    Ini.Free;
  end;
end;

procedure ExecutarComandoPorNome(const Parans: Array of string);
var
  Ini: TIniFile;
  Comando: string;
begin
  Ini := TIniFile.Create(ARQUIVO_INI);
  try
    Comando := Ini.ReadString(Parans[0].ToLower, 'Comando', '');
    if Comando = '' then begin
      Writeln('Comado Atl "' +Parans[0]+ '" não encontrato!');
      Writeln('');
      ListaComandos(Parans[0].ToLower);
    end else
    begin
      Comando := Comando.Replace('''','"');
      for var I :=  1 to High(Parans) do
        Comando := Comando.Replace('%'+I.ToString,Parans[I]);

      Writeln('Comando: '+Comando);
      ExecutarComandoWait(Comando);
    end;
  finally
    Ini.Free;
  end;
end;

{ inicio }

begin
  ARQUIVO_INI := ExtractFilePath(ParamStr(0)) + 'Atl.ini';

  if ParamCount = 0 then
  begin
    ListaComandos();
    Exit;
  end;

  if ParamStr(1).ToLower = 'add' then
  begin
    AdicionarComando;
    Exit;
  end;

  if ParamStr(1).ToLower = 'delete' then
  begin
    DeletarComando;
    Exit;
  end;

  var prs := [''];
  SetLength(prs,ParamCount);

  for var p := 1 to ParamCount do
    prs[p-1] := ParamStr(p);

  ExecutarComandoPorNome(prs);
end.
