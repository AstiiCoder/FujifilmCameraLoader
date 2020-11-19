unit Main;

interface

uses
  Winapi.Windows, System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.Ani, FMX.Layouts, FMX.Gestures,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit, IniFiles, FMX.TabControl,
  FMX.ScrollBox, FMX.Memo, FMX.Objects, DateUtils;

type
  TForm_Main = class(TForm)
    StyleBook1: TStyleBook;
    ToolbarHolder: TLayout;
    ToolbarPopup: TPopup;
    ToolbarPopupAnimation: TFloatAnimation;
    ToolBar1: TToolBar;
    ToolbarApplyButton: TButton;
    ToolbarCloseButton: TButton;
    ToolbarAddButton: TButton;
    Edit_DestDir: TEdit;
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    Label1: TLabel;
    Button_Save: TButton;
    Button_SelDestDir: TButton;
    Edit_SourceDir: TEdit;
    Label2: TLabel;
    Button_SetSourceDir: TButton;
    Memo_Journal: TMemo;
    Panel2: TPanel;
    Panel3: TPanel;
    Rectangle1: TRectangle;
    Image1: TImage;
    AniIndicator1: TAniIndicator;
    Timer1: TTimer;
    procedure ToolbarCloseButtonClick(Sender: TObject);
    procedure FormGesture(Sender: TObject;
      const EventInfo: TGestureEventInfo; var Handled: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button_SaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button_SelDestDirClick(Sender: TObject);
    procedure Button_SetSourceDirClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    FGestureOrigin: TPointF;
    FGestureInProgress: Boolean;
    { Private declarations }
    procedure RunCoping;
    procedure ShowToolbar(AShow: Boolean);
    procedure GetAllFiles(Path: string);
  public
    { Public declarations }
  end;

var
  Form_Main: TForm_Main;

implementation

{$R *.fmx}

var
  DestDir     : String = '';
  SourceDir   : String = '';
  ErrNameList : TStringList;

procedure TForm_Main.GetAllFiles( Path: string);
var
  sRec    : TSearchRec;
  isFound : boolean;
begin
  isFound := FindFirst( Path + '\*.*', faAnyFile, sRec ) = 0;
  while isFound do
    begin
      if ( sRec.Name <> '.' ) and ( sRec.Name <> '..' ) then
      begin
        if ( sRec.Attr and faDirectory ) = faDirectory then
        if (Pos('_',sRec.Name)=5) and (Length(sRec.Name)=9) then ErrNameList.Add( sRec.Name );
      end;
      Application.ProcessMessages;
      isFound := FindNext( sRec ) = 0;
    end;
  FindClose( sRec );
end;

procedure TForm_Main.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkEscape then
    ShowToolbar(not ToolbarPopup.IsOpen);
end;

procedure TForm_Main.Timer1Timer(Sender: TObject);
begin
  RunCoping;
  AniIndicator1.Enabled := False;
  AniIndicator1.Visible := False;
  Timer1.Enabled := False;
end;

procedure TForm_Main.ToolbarCloseButtonClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm_Main.Button1Click(Sender: TObject);
begin
  //GetAllFiles(Edit1.Text);
end;

procedure TForm_Main.Button2Click(Sender: TObject);
var
  Dir1 : String;
begin
  Dir1 := 'E:\Rt\XE\1';
  if DirectoryExists(Dir1) then RenameFile(Dir1, 'E:\Rt\XE\3');
  //if DirectoryExists(Edit1.Text) then ShowMessage('существует');
end;

procedure TForm_Main.Button_SetSourceDirClick(Sender: TObject);
var
  TmpDir : String;
begin
  if SelectDirectory('Выберите папку-источник файлов:', '', TmpDir) then
    begin
      if TmpDir<>'' then DestDir := TmpDir;
      Edit_DestDir.Text := DestDir;
    end;
end;

procedure TForm_Main.Button_SelDestDirClick(Sender: TObject);
var
  TmpDir : String;
begin
  if SelectDirectory('Выберите папку-получатель файлов:', '', TmpDir) then
    begin
      if TmpDir<>'' then DestDir := TmpDir;
      Edit_DestDir.Text := DestDir;
    end;
end;

procedure TForm_Main.Button_SaveClick(Sender: TObject);
var
  IniFile : TIniFile;
  FName   : String;
begin
  DestDir := Edit_DestDir.Text;
  SourceDir := Edit_SourceDir.Text;
  if (DestDir<>'') and (SourceDir<>'') then
    begin
      FName := ExtractFilePath(ParamStr(0))+'config.ini';
      IniFile := TIniFile.Create(FName);
      IniFile.WriteString('Base', 'DestDir', Edit_DestDir.Text);
      IniFile.WriteString('Base', 'SourceDir', Edit_SourceDir.Text);
      IniFile.Free;
    end
  else
    ShowMessage('Не выбраны ресурсы: источник и/или получатель!');
end;

procedure TForm_Main.RunCoping;
var
  IniFile              : TIniFile;
  NewDirName           : String;
  i                    : Integer;
begin
  ErrNameList := TStringList.Create;
  if SourceDir<>'' then
    begin
      Edit_SourceDir.Text := SourceDir;
      if DirectoryExists(SourceDir) then
        begin
          Memo_Journal.Lines.Add('Обнаружен ресурс источник');
          NewDirName := FormatDateTime('dd',Date)+'-'+FormatDateTime('mm',Date)+'-'+FormatDateTime('yyyy',Date);
          if CreateDir(NewDirName) then
            begin
              Memo_Journal.Lines.Add('Создана папка "'+NewDirName+'"');
              //список файлов, которые нужно скопировать
              ErrNameList.Clear;
              GetAllFiles(SourceDir);
              if ErrNameList.Count>0 then
                for i := 0 to ErrNameList.Count-1 do
                  if CopyFile(PChar(SourceDir+'\'+ErrNameList[i]),PChar(DestDir+'\'+NewDirName+'\'+ErrNameList[i]),true) then
                    Memo_Journal.Lines.Add('Скопирован файл "'+ErrNameList[i]+'"')
                  else
                    Memo_Journal.Lines.Add('ВНИМАНИЕ: Произошла ошибка при копировании файла "'+ErrNameList[i]+'"')
            end;
        end
      else
        Memo_Journal.Lines.Add('ВНИМАНИЕ: Ресурс источник не обнаружен!');
    end;
  if DestDir<>'' then
    begin
      Edit_DestDir.Text := DestDir;
      if DirectoryExists(DestDir) then
        begin
          Memo_Journal.Lines.Add('Просмотр папки-получателя...');
          //список папок с неправильными именами
          ErrNameList.Clear;
          GetAllFiles(DestDir);
          if ErrNameList.Count>0 then
            begin
              Memo_Journal.Lines.Add('Обнаружены папки с именами не по заданной маске');
              for i := 0 to ErrNameList.Count-1 do
                begin
                  NewDirName := copy(ErrNameList[i],8,2)+'-'+copy(ErrNameList[i],6,2)+'-'+copy(ErrNameList[i],1,4);
                  if (DirectoryExists(DestDir+'\'+ErrNameList[i])) and (Not DirectoryExists(DestDir+'\'+NewDirName)) then
                    try
                      RenameFile(DestDir+'\'+ErrNameList[i], DestDir+'\'+NewDirName);
                      Memo_Journal.Lines.Add('Переименована папка "'+ErrNameList[i]+'" в "'+NewDirName+'"');
                    except
                      Memo_Journal.Lines.Add('ВНИМАНИЕ: Произошла ошибка при попытке переименования папки "'+ErrNameList[i]+'" в "'+NewDirName+'"');
                    end
                  else
                    Memo_Journal.Lines.Add('ВНИМАНИЕ: Уже есть папка с именем "'+NewDirName+'"')
                end;
            end
          else
            Memo_Journal.Lines.Add('Все имена папок корректны');
        end
      else
        Memo_Journal.Lines.Add('ВНИМАНИЕ: Папка-получатель файлов не доступна!');
    end;
  Memo_Journal.Lines.Add('Обработка закончена!');
end;

procedure TForm_Main.FormCreate(Sender: TObject);
var
  IniFile              : TIniFile;
  FName                : String;
begin
  Memo_Journal.Lines.Add('Добро пожаловать в программу автоматизации копирования файлов!');
  FName := ExtractFilePath(ParamStr(0))+'config.ini';
  if FileExists(FName) then
    begin
      IniFile := TIniFile.Create(FName);
      if IniFile.SectionExists('Base') then
        try
          DestDir := IniFile.ReadString('Base', 'DestDir', '');
          SourceDir := IniFile.ReadString('Base', 'SourceDir', '');
        finally
          IniFile.Free;
        end;
    end;
  Timer1.Enabled := True;
end;

procedure TForm_Main.FormGesture(Sender: TObject;
  const EventInfo: TGestureEventInfo; var Handled: Boolean);
var
  DX, DY : Single;
begin
  if EventInfo.GestureID = igiPan then
  begin
    if (TInteractiveGestureFlag.gfBegin in EventInfo.Flags)
      and ((Sender = ToolbarPopup)
        or (EventInfo.Location.Y > (ClientHeight - 70))) then
    begin
      FGestureOrigin := EventInfo.Location;
      FGestureInProgress := True;
    end;

    if FGestureInProgress and (TInteractiveGestureFlag.gfEnd in EventInfo.Flags) then
    begin
      FGestureInProgress := False;
      DX := EventInfo.Location.X - FGestureOrigin.X;
      DY := EventInfo.Location.Y - FGestureOrigin.Y;
      if (Abs(DY) > Abs(DX)) then
        ShowToolbar(DY < 0);
    end;
  end
end;

procedure TForm_Main.ShowToolbar(AShow: Boolean);
begin
  ToolbarPopup.Width := ClientWidth;
  ToolbarPopup.PlacementRectangle.Rect := TRectF.Create(0, ClientHeight-ToolbarPopup.Height, ClientWidth-1, ClientHeight-1);
  ToolbarPopupAnimation.StartValue := ToolbarPopup.Height;
  ToolbarPopupAnimation.StopValue := 0;

  ToolbarPopup.IsOpen := AShow;
end;

end.
