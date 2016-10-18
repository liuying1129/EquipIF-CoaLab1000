unit UfrmMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms,
  LYTray, Menus, StdCtrls, Buttons, ADODB,
  ActnList, AppEvnts, ComCtrls, ToolWin, ExtCtrls,
  registry,inifiles,Dialogs,
  StrUtils, DB,ComObj,Variants;

type
  TfrmMain = class(TForm)
    LYTray1: TLYTray;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    ADOConnection1: TADOConnection;
    ApplicationEvents1: TApplicationEvents;
    CoolBar1: TCoolBar;
    ToolBar1: TToolBar;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ActionList1: TActionList;
    editpass: TAction;
    about: TAction;
    stop: TAction;
    ToolButton2: TToolButton;
    Memo1: TMemo;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Button1: TButton;
    ToolButton5: TToolButton;
    ToolButton9: TToolButton;
    OpenDialog1: TOpenDialog;
    Timer1: TTimer;
    SaveDialog1: TSaveDialog;
    procedure N3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    //���Ӳ�����Ϣ���м�¼,���ظü�¼��Ψһ�����Ϊ������������
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure N1Click(Sender: TObject);
    procedure ApplicationEvents1Activate(Sender: TObject);
    procedure ToolButton7Click(Sender: TObject);
    procedure ToolButton2Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure ToolButton5Click(Sender: TObject);
  private
    { Private declarations }
    procedure WMSyscommand(var message:TWMMouse);message WM_SYSCOMMAND;
    procedure UpdateConfig;{�����ļ���Ч}
    function LoadInputPassDll:boolean;
    function MakeDBConn:boolean;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses ucommfunction, USearchFile;

const
  CR=#$D+#$A;
  STX=#$2;ETX=#$3;ACK=#$6;NAK=#$15;
  sCryptSeed='lc';//�ӽ�������
  //SEPARATOR=#$1C;
  sCONNECTDEVELOP='����!���뿪������ϵ!' ;
  IniSection='Setup';

var
  ConnectString:string;
  GroupName:string;//
  SpecType:string ;//
  SpecStatus:string ;//
  CombinID:string;//
  LisFormCaption:string;//
  QuaContSpecNoG:string;
  QuaContSpecNo:string;
  QuaContSpecNoD:string;
  EquipChar:string;
  path_result:string;
//  big_result:string;

//  RFM:STRING;       //��������
  hnd:integer;
  bRegister:boolean;

{$R *.dfm}

function ifRegister:boolean;
var
  HDSn,RegisterNum,EnHDSn:string;
  configini:tinifile;
  pEnHDSn:Pchar;
begin
  result:=false;
  
  HDSn:=GetHDSn('C:\')+'-'+GetHDSn('D:\')+'-'+ChangeFileExt(ExtractFileName(Application.ExeName),'');

  CONFIGINI:=TINIFILE.Create(ChangeFileExt(Application.ExeName,'.ini'));
  RegisterNum:=CONFIGINI.ReadString(IniSection,'RegisterNum','');
  CONFIGINI.Free;
  pEnHDSn:=EnCryptStr(Pchar(HDSn),sCryptSeed);
  EnHDSn:=StrPas(pEnHDSn);

  if Uppercase(EnHDSn)=Uppercase(RegisterNum) then result:=true;

  if not result then messagedlg('�Բ���,��û��ע���ע�������,��ע��!',mtinformation,[mbok],0);
end;

function GetConnectString:string;
var
  Ini:tinifile;
  userid, password, datasource, initialcatalog: string;
  ifIntegrated:boolean;//�Ƿ񼯳ɵ�¼ģʽ

  pInStr,pDeStr:Pchar;
  i:integer;
begin
  result:='';
  
  Ini := tinifile.Create(ChangeFileExt(Application.ExeName,'.INI'));
  datasource := Ini.ReadString('�������ݿ�', '������', '');
  initialcatalog := Ini.ReadString('�������ݿ�', '���ݿ�', '');
  ifIntegrated:=ini.ReadBool('�������ݿ�','���ɵ�¼ģʽ',false);
  userid := Ini.ReadString('�������ݿ�', '�û�', '');
  password := Ini.ReadString('�������ݿ�', '����', '107DFC967CDCFAAF');
  Ini.Free;
  //======����password
  pInStr:=pchar(password);
  pDeStr:=DeCryptStr(pInStr,sCryptSeed);
  setlength(password,length(pDeStr));
  for i :=1  to length(pDeStr) do password[i]:=pDeStr[i-1];
  //==========

  result := result + 'user id=' + UserID + ';';
  result := result + 'password=' + Password + ';';
  result := result + 'data source=' + datasource + ';';
  result := result + 'Initial Catalog=' + initialcatalog + ';';
  result := result + 'provider=' + 'SQLOLEDB.1' + ';';
  if ifIntegrated then
    result := result + 'Integrated Security=SSPI;';
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  ctext        :string;
  reg          :tregistry;
begin
  ConnectString:=GetConnectString;
  
  UpdateConfig;
  if ifRegister then bRegister:=true else bRegister:=false;  

  lytray1.Hint:='���ݽ��շ���'+ExtractFileName(Application.ExeName);

//=============================��ʼ������=====================================//
    reg:=tregistry.Create;
    reg.RootKey:=HKEY_CURRENT_USER;
    reg.OpenKey('\sunyear',true);
    ctext:=reg.ReadString('pass');
    if ctext='' then
    begin
        reg:=tregistry.Create;
        reg.RootKey:=HKEY_CURRENT_USER;
        reg.OpenKey('\sunyear',true);
        reg.WriteString('pass','JIHONM{');
        //MessageBox(application.Handle,pchar('��л��ʹ�����ܼ��ϵͳ��'+chr(13)+'���ס��ʼ�����룺'+'lc'),
        //            'ϵͳ��ʾ',MB_OK+MB_ICONinformation);     //WARNING
    end;
    reg.CloseKey;
    reg.Free;
//============================================================================//
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    if LoadInputPassDll then action:=cafree else action:=caNone;
end;

procedure TfrmMain.N3Click(Sender: TObject);
begin
    if not LoadInputPassDll then exit;
    application.Terminate;
end;

procedure TfrmMain.N1Click(Sender: TObject);
begin
  show;
end;

procedure TfrmMain.ApplicationEvents1Activate(Sender: TObject);
begin
  hide;
end;

procedure TfrmMain.WMSyscommand(var message: TWMMouse);
begin
  inherited;
  if message.Keys=SC_MINIMIZE then hide;
  message.Result:=-1;
end;

procedure TfrmMain.ToolButton7Click(Sender: TObject);
begin
  if MakeDBConn then ConnectString:=GetConnectString;
end;

procedure TfrmMain.UpdateConfig;
var
  INI:tinifile;
  autorun:boolean;
begin
  ini:=TINIFILE.Create(ChangeFileExt(Application.ExeName,'.ini'));

  autorun:=ini.readBool(IniSection,'�����Զ�����',false);

  path_result:=ini.ReadString(IniSection,'�ӿ�Ŀ¼','');

  GroupName:=trim(ini.ReadString(IniSection,'���',''));
  EquipChar:=trim(uppercase(ini.ReadString(IniSection,'������ĸ','')));//�������Ǵ�д������һʧ��
  SpecType:=ini.ReadString(IniSection,'Ĭ����������','');
  SpecStatus:=ini.ReadString(IniSection,'Ĭ������״̬','');
  CombinID:=ini.ReadString(IniSection,'�����Ŀ����','');

  LisFormCaption:=ini.ReadString(IniSection,'����ϵͳ�������','');

  QuaContSpecNoG:=ini.ReadString(IniSection,'��ֵ�ʿ�������','9999');
  QuaContSpecNo:=ini.ReadString(IniSection,'��ֵ�ʿ�������','9998');
  QuaContSpecNoD:=ini.ReadString(IniSection,'��ֵ�ʿ�������','9997');

  ini.Free;

  OperateLinkFile(application.ExeName,'\'+ChangeFileExt(ExtractFileName(Application.ExeName),'.lnk'),15,autorun);

  if DirectoryExists(path_result) then
  BEGIN
    Timer1.Enabled:=true;
  END else memo1.Lines.Add('û���ҵ��ӿ�Ŀ¼'+path_result); 
end;

function TfrmMain.LoadInputPassDll: boolean;
TYPE
    TDLLFUNC=FUNCTION:boolean;
VAR
    HLIB:THANDLE;
    DLLFUNC:TDLLFUNC;
    PassFlag:boolean;
begin
    result:=false;
    HLIB:=LOADLIBRARY('OnOffLogin.dll');
    IF HLIB=0 THEN BEGIN SHOWMESSAGE(sCONNECTDEVELOP);EXIT; END;
    DLLFUNC:=TDLLFUNC(GETPROCADDRESS(HLIB,'showfrmonofflogin'));
    IF @DLLFUNC=NIL THEN BEGIN SHOWMESSAGE(sCONNECTDEVELOP);EXIT; END;
    PassFlag:=DLLFUNC;
    FREELIBRARY(HLIB);
    result:=passflag;
end;

function TfrmMain.MakeDBConn:boolean;
var
  newconnstr,ss: string;
  Label labReadIni;
begin
  result:=false;

  labReadIni:
  newconnstr := GetConnectString;
  
  try
    ADOConnection1.Connected := false;
    ADOConnection1.ConnectionString := newconnstr;
    ADOConnection1.Connected := true;
    result:=true;
  except
  end;
  if not result then
  begin
    ss:='������'+#2+'Edit'+#2+#2+'0'+#2+#2+#3+
        '���ݿ�'+#2+'Edit'+#2+#2+'0'+#2+#2+#3+
        '���ɵ�¼ģʽ'+#2+'CheckListBox'+#2+#2+'0'+#2+#2+#3+
        '�û�'+#2+'Edit'+#2+#2+'0'+#2+#2+#3+
        '����'+#2+'Edit'+#2+#2+'0'+#2+#2+'1';
    if ShowOptionForm('�������ݿ�','�������ݿ�',Pchar(ss),Pchar(ChangeFileExt(Application.ExeName,'.ini'))) then
      goto labReadIni else application.Terminate;
  end;
end;

procedure TfrmMain.ToolButton2Click(Sender: TObject);
var
  ss:string;
begin
  if LoadInputPassDll then
  begin
    ss:='�ӿ�Ŀ¼'+#2+'Dir'+#2+#2+'1'+#2+'ע:һ��ΪC:\labietc'+#2+#3+
      '���'+#2+'Edit'+#2+#2+'1'+#2+#2+#3+
      '������ĸ'+#2+'Edit'+#2+#2+'1'+#2+#2+#3+
      '����ϵͳ�������'+#2+'Edit'+#2+#2+'1'+#2+#2+#3+
      'Ĭ����������'+#2+'Edit'+#2+#2+'1'+#2+#2+#3+
      'Ĭ������״̬'+#2+'Edit'+#2+#2+'1'+#2+#2+#3+
      '�����Ŀ����'+#2+'Edit'+#2+#2+'1'+#2+#2+#3+
      '�����Զ�����'+#2+'CheckListBox'+#2+#2+'1'+#2+#2+#3+
      '��ֵ�ʿ�������'+#2+'Edit'+#2+#2+'2'+#2+#2+#3+
      '��ֵ�ʿ�������'+#2+'Edit'+#2+#2+'2'+#2+#2+#3+
      '��ֵ�ʿ�������'+#2+'Edit'+#2+#2+'2'+#2+#2;

  if ShowOptionForm('',Pchar(IniSection),Pchar(ss),Pchar(ChangeFileExt(Application.ExeName,'.ini'))) then
	  UpdateConfig;
  end;
end;

procedure TfrmMain.BitBtn2Click(Sender: TObject);
begin
  Memo1.Lines.Clear;
end;

procedure TfrmMain.BitBtn1Click(Sender: TObject);
begin
  SaveDialog1.DefaultExt := '.txt';
  SaveDialog1.Filter := 'txt (*.txt)|*.txt';
  if not SaveDialog1.Execute then exit;
  memo1.Lines.SaveToFile(SaveDialog1.FileName);
  showmessage('����ɹ�!');
end;

procedure TfrmMain.Button1Click(Sender: TObject);
var
  ls:Tstrings;
begin
  OpenDialog1.DefaultExt := '.txt';
  OpenDialog1.Filter := 'txt (*.txt)|*.txt';
  if not OpenDialog1.Execute then exit;
  ls:=Tstringlist.Create;
  ls.LoadFromFile(OpenDialog1.FileName);
  //ComDataPacket1Packet(nil,ls.Text);
  ls.Free;
end;

procedure TfrmMain.ToolButton5Click(Sender: TObject);
var
  ss:string;
begin
  ss:='RegisterNum'+#2+'Edit'+#2+#2+'0'+#2+'���ô���������ϵ��ַ�������������,�Ի�ȡע����'+#2;
  if bRegister then exit;
  if ShowOptionForm(Pchar('ע��:'+GetHDSn('C:\')+'-'+GetHDSn('D:\')+'-'+ChangeFileExt(ExtractFileName(Application.ExeName),'')),Pchar(IniSection),Pchar(ss),Pchar(ChangeFileExt(Application.ExeName,'.ini'))) then
    if ifRegister then bRegister:=true else bRegister:=false;
end;

procedure AFindCallBack(const filename:string;const info:tsearchrec;var quit:boolean);
var
  ls,sList:tstrings;
  i:integer;

  SpecNo:string;
  dlttype:string;
  FInts:OleVariant;
  ReceiveItemInfo:OleVariant;

  YXJB:string;//���ȼ���
  CheckDate:string;
  clot:string;
  clot_conv1:string;
  clot_conv2:string;
  dclot:double;
  dclot_conv1:double;
  dclot_conv2:double;
  kin_conv:string;
  dkin_conv:double;

  sName:string;//�ļ���
begin
  sName:=ExtractFileName(filename);
  
  sList:=TStringList.Create;
  ExtractStrings(['_'],[],PChar(sName),sList);
  if sList.Count<4 then begin sList.Free;exit;end;
  YXJB:=ifThen(pos('STAT',uppercase(sList[1]))>0,'����','����');
  dlttype:=sList[2];
  sList.Free;

  ls:=Tstringlist.Create;
  ls.LoadFromFile(filename);
  if ls.Count<=0 then begin ls.Free;exit;end;//���������û��csv�ļ���д�꣬��ȴ�д��
  for i :=0  to ls.Count-1 do
  begin
    if lowercase(leftstr(ls[i],14))='sample_no    ;' then
    begin
      SpecNo:=copy(ls[i],15,maxint);
      SpecNo:='0000'+trim(SpecNo);
      SpecNo:=rightstr(SpecNo,4);
    end;

    if lowercase(leftstr(ls[i],10))='date_time;' then
    begin
      CheckDate:=copy(ls[i],17,4)+'-'+copy(ls[i],14,2)+'-'+copy(ls[i],11,2)+' '+copy(ls[i],22,8);
    end;

    if lowercase(leftstr(ls[i],11))='clot      ;' then
    begin
      clot:=trim(copy(ls[i],12,maxint));
      clot:=stringreplace(clot,',','.',[]);
      if TryStrToFloatExt(pchar(clot),dclot) then clot:=floattostr(dclot);
    end;
    if lowercase(leftstr(ls[i],11))='clot-conv1;' then
    begin
      clot_conv1:=trim(copy(ls[i],12,maxint));
      clot_conv1:=stringreplace(clot_conv1,',','.',[]);
      if TryStrToFloatExt(pchar(clot_conv1),dclot_conv1) then clot_conv1:=floattostr(dclot_conv1);
    end;
    if lowercase(leftstr(ls[i],11))='clot-conv2;' then
    begin
      clot_conv2:=trim(copy(ls[i],12,maxint));
      clot_conv2:=stringreplace(clot_conv2,',','.',[]);
      if TryStrToFloatExt(pchar(clot_conv2),dclot_conv2) then clot_conv2:=floattostr(dclot_conv2);
    end;
    if lowercase(leftstr(ls[i],11))='kin-conv  ;' then
    begin
      kin_conv:=trim(copy(ls[i],12,maxint));
      kin_conv:=stringreplace(kin_conv,',','.',[]);
      if TryStrToFloatExt(pchar(kin_conv),dkin_conv) then kin_conv:=floattostr(dkin_conv);
    end;
  end;

  if SpecNo='' then SpecNo:=formatdatetime('nnss',now);//��������

  if uppercase(dlttype)='PT' then
  begin
    ReceiveItemInfo:=VarArrayCreate([0,1],varVariant);
    ReceiveItemInfo[0]:=VarArrayof([dlttype,clot,'','']);
    ReceiveItemInfo[1]:=VarArrayof(['INR',clot_conv2,'','']);
  end else
  if uppercase(dlttype)='FIB' then
  begin
    ReceiveItemInfo:=VarArrayCreate([0,0],varVariant);
    ReceiveItemInfo[0]:=VarArrayof([dlttype,clot_conv1,'','']);
  end else
  if uppercase(dlttype)='DD' then
  begin
    ReceiveItemInfo:=VarArrayCreate([0,0],varVariant);
    ReceiveItemInfo[0]:=VarArrayof([dlttype,kin_conv,'','']);
  end else//APTT//TT
  begin
    ReceiveItemInfo:=VarArrayCreate([0,0],varVariant);
    ReceiveItemInfo[0]:=VarArrayof([dlttype,clot,'','']);
  end;

  if length(frmMain.memo1.Lines.Text)>=60000 then frmMain.memo1.Lines.Clear;//memoֻ�ܽ���64K���ַ�
  frmMain.memo1.Lines.Add(filename);

  ls.Free;

  if bRegister then
  begin
    FInts :=CreateOleObject('Data2LisSvr.Data2Lis');
    FInts.fData2Lis(ReceiveItemInfo,(SpecNo),CheckDate,
      (GroupName),(SpecType),(SpecStatus),(EquipChar),
      (CombinID),'',(LisFormCaption),(ConnectString),
      (QuaContSpecNoG),(QuaContSpecNo),(QuaContSpecNoD),'',
      true,true,YXJB);
    if not VarIsEmpty(FInts) then FInts:= unAssigned;
    
    deletefile(filename);//��������ɾ�����ļ�
  end;
end;

procedure TfrmMain.Timer1Timer(Sender: TObject);
var
  qqq:boolean;
begin
  (Sender as TTimer).Enabled:=false;

  qqq:=false;
  findfile(qqq,PATH_RESULT,'*_*.csv',AFindCallBack,true,true);

  (Sender as TTimer).Enabled:=true;
end;

initialization
    hnd := CreateMutex(nil, True, Pchar(ExtractFileName(Application.ExeName)));
    if GetLastError = ERROR_ALREADY_EXISTS then
    begin
        MessageBox(application.Handle,pchar('�ó������������У�'),
                    'ϵͳ��ʾ',MB_OK+MB_ICONinformation);   
        Halt;
    end;

finalization
    if hnd <> 0 then CloseHandle(hnd);

end.
