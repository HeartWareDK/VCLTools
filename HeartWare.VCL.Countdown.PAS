UNIT HeartWare.VCL.Countdown;

INTERFACE

USES
  WinAPI.Windows,
  System.Types, System.Classes, System.SysUtils, System.Math, System.DateUtils, System.UITypes,
  VCL.Controls, VCL.Forms, VCL.StdCtrls, VCL.ExtCtrls;

TYPE TModalResults = SET OF BYTE;

CONST MilliSecsPerSecond = 1000;

FUNCTION CurrentModalForm : TCustomForm;

FUNCTION Countdown(CONST Title,Caption : STRING ; ms : Integer ; AllowIgnore : BOOLEAN = TRUE ; AllowClose : BOOLEAN = FALSE ; AllowAbort : BOOLEAN = FALSE) : TModalResult; OVERLOAD;
FUNCTION Countdown(CONST Title,Caption : STRING ; ms : Integer ; CONST Buttons : TModalResults) : TModalResult; OVERLOAD;

FUNCTION Countdown(CONST Title,Caption : STRING ; Time : TTime ; AllowIgnore : BOOLEAN = TRUE ; AllowClose : BOOLEAN = FALSE ; AllowAbort : BOOLEAN = FALSE) : TModalResult; OVERLOAD;
FUNCTION Countdown(CONST Title,Caption : STRING ; Time : TTime ; CONST Buttons : TModalResults) : TModalResult; OVERLOAD;

FUNCTION Countdown(CONST Title,Caption,CheckBoxText : STRING ; VAR Checked : BOOLEAN ; ms : Integer ; AllowIgnore : BOOLEAN = TRUE ; AllowClose : BOOLEAN = FALSE ; AllowAbort : BOOLEAN = FALSE) : TModalResult; OVERLOAD;
FUNCTION Countdown(CONST Title,Caption,CheckBoxText : STRING ; VAR Checked : BOOLEAN ; ms : Integer ; CONST Buttons : TModalResults) : TModalResult; OVERLOAD;

FUNCTION Countdown(CONST Title,Caption,CheckBoxText : STRING ; VAR Checked : BOOLEAN ; Time : TTime ; AllowIgnore : BOOLEAN = TRUE ; AllowClose : BOOLEAN = FALSE ; AllowAbort : BOOLEAN = FALSE) : TModalResult; OVERLOAD;
FUNCTION Countdown(CONST Title,Caption,CheckBoxText : STRING ; VAR Checked : BOOLEAN ; Time : TTime ; CONST Buttons : TModalResults) : TModalResult; OVERLOAD;

FUNCTION Countdown(CONST Title,Caption : STRING ; CheckBox : TCheckBox ; ms : Integer ; AllowIgnore : BOOLEAN = TRUE ; AllowClose : BOOLEAN = FALSE ; AllowAbort : BOOLEAN = FALSE) : TModalResult; OVERLOAD;
FUNCTION Countdown(CONST Title,Caption : STRING ; CheckBox : TCheckBox ; ms : Integer ; CONST Buttons : TModalResults) : TModalResult; OVERLOAD;

FUNCTION Countdown(CONST Title,Caption : STRING ; CheckBox : TCheckBox ; Time : TTime ; AllowIgnore : BOOLEAN = TRUE ; AllowClose : BOOLEAN = FALSE ; AllowAbort : BOOLEAN = FALSE) : TModalResult; OVERLOAD;
FUNCTION Countdown(CONST Title,Caption : STRING ; CheckBox : TCheckBox ; Time : TTime ; CONST Buttons : TModalResults) : TModalResult; OVERLOAD;

FUNCTION CaptionWidth(L : TLabel) : Integer; OVERLOAD; INLINE;
FUNCTION CaptionWidth(L : TLabel ; CONST Caption : STRING) : Integer; OVERLOAD;

FUNCTION ModalStr(R : TModalResult) : STRING;

IMPLEMENTATION

FUNCTION ModalStr(R : TModalResult) : STRING;
  BEGIN
    CASE R OF
      mrNone     : Result:='None';
      mrOK       : Result:='OK';
      mrCancel   : Result:='Cancel';
      mrAbort    : Result:='Abort';
      mrRetry    : Result:='Retry';
      mrIgnore   : Result:='Ignore';
      mrYes      : Result:='Yes';
      mrNo       : Result:='No';
      mrClose    : Result:='Close';
      mrHelp     : Result:='Help';
      mrTryAgain : Result:='Try Again';
      mrContinue : Result:='Continue';
      mrAll      : Result:='All';
      mrNoToAll  : Result:='NoToAll';
      mrYesToAll : Result:='YesToAll'
    ELSE // OTHERWISE //
      Result:='Custom: '+IntToStr(R)
    END
  END;

FUNCTION CaptionWidth(L : TLabel ; CONST Caption : STRING) : Integer;
  VAR
    DC      : HDC;
    OldFont : HGDIOBJ;
    Size    : TSize;

  BEGIN
    DC:=GetDC(0);
    TRY
      OldFont:=SelectObject(DC,L.Font.Handle);
      TRY
        IF GetTextExtentPoint32(DC,PChar(Caption),Length(Caption),Size) THEN
          Result:=Size.cx
        ELSE
          Result:=0
      FINALLY
        SelectObject(DC,OldFont)
      END
    FINALLY
      ReleaseDC(0,DC)
    END
  END;

FUNCTION CaptionWidth(L : TLabel) : Integer;
  BEGIN
    Result:=CaptionWidth(L,L.Caption)
  END;

FUNCTION CurrentModalForm : TCustomForm;
  VAR
    Wnd     : HWND;
    Control : TWinControl;

  BEGIN
    Wnd:=GetTopWindow(0);
    WHILE Wnd<>0 DO BEGIN
      Control:=FindControl(Wnd);
      IF (Control IS TCustomForm) AND (fsModal IN TCustomForm(Control).FormState) THEN EXIT(TCustomForm(Control));
      Wnd:=GetWindow(Wnd,GW_HWNDNEXT)
    END;
    Result:=NIL
  END;

TYPE
  TCountdownHandler = CLASS
                      PRIVATE
                        Form            : TForm;
                        TimerLabel      : TLabel;
                        Timer           : TTimer;
                        Deadline        : UInt64;
                        FUNCTION        CountdownText(Seconds : Cardinal) : STRING;
                        PROCEDURE       UpdateTimer;
                        PROCEDURE       TimerTimer(Sender : TObject);
                        PROCEDURE       FormCloseQuery(Sender : TObject ; VAR CanClose : BOOLEAN);
                      PUBLIC
                        PROCEDURE       Start(ms : Cardinal);
                      END;

FUNCTION TCountdownHandler.CountdownText(Seconds : Cardinal) : STRING;
  VAR
    Hours   : Cardinal;
    Minutes : Cardinal;

  FUNCTION UnitName(Value : Cardinal ; CONST Singular,Plural : STRING) : STRING; OVERLOAD;
    BEGIN
      Result:=IF Value=1 THEN Singular ELSE Plural
    END;

  FUNCTION UnitName(Value : Cardinal ; CONST Singular : STRING) : STRING; OVERLOAD; INLINE;
    BEGIN
      Result:=UnitName(Value,Singular,Singular+'s')
    END;

 BEGIN
    Hours:=Seconds DIV SecsPerHour; Seconds:=Seconds MOD SecsPerHour;
    Minutes:=Seconds DIV SecsPerMin; Seconds:=Seconds MOD SecsPerMin;
    Result:=IF Hours<>0 THEN
              Format('%d %s, %d %s, %d %s',[Hours,UnitName(Hours,'hour'),Minutes,UnitName(Minutes,'minute'),Seconds,UnitName(Seconds,'second')])
            ELSE IF Minutes<>0 THEN
              Format('%d %s, %d %s',[Minutes,UnitName(Minutes,'minute'),Seconds,UnitName(Seconds,'second')])
            ELSE
              Format('%d %s',[Seconds,UnitName(Seconds,'second')])
  END;

PROCEDURE TCountdownHandler.UpdateTimer;
  VAR
    NowTick     : UInt64;
    Remaining   : UInt64;
    SecondsLeft : Cardinal;

  BEGIN
    NowTick:=GetTickCount64;
    IF NowTick>=Deadline THEN BEGIN
      Timer.Enabled:=FALSE;
      Form.ModalResult:=mrOK;
      EXIT
    END;
    Remaining:=Deadline-NowTick;
    SecondsLeft:=Cardinal((Remaining+999) DIV 1000);
    TimerLabel.Caption:=CountdownText(SecondsLeft)
  END;

PROCEDURE TCountdownHandler.TimerTimer(Sender : TObject);
  BEGIN
    UpdateTimer
  END;

PROCEDURE TCountdownHandler.FormCloseQuery(Sender : TObject ; VAR CanClose : BOOLEAN);
  BEGIN
    CanClose:=Form.ModalResult IN [mrOK,mrIgnore,mrAbort];
    IF NOT CanClose THEN Form.ModalResult:=mrNone
  END;

PROCEDURE TCountdownHandler.Start(ms : Cardinal);
  BEGIN
    Deadline:=GetTickCount64+UInt64(ms);
    UpdateTimer;
    IF Form.ModalResult=mrNone THEN Timer.Enabled:=TRUE
  END;

FUNCTION Countdown(CONST Title,Caption,CheckBoxText : STRING ; VAR Checked : BOOLEAN ; ms : Integer ; AllowIgnore : BOOLEAN = TRUE ; AllowClose : BOOLEAN = FALSE ; AllowAbort : BOOLEAN = FALSE) : TModalResult;
  CONST
    DefaultButtonWidth  = 75;
    DefaultButtonHeight = 25;

    Margin              = 12;
    LabelGap            = 8;
    ButtonGap           = 8;
    ButtonTopGap        = 16;

  VAR
    Form             : TForm;
    CaptionLabel     : TLabel;
    TimerLabel       : TLabel;
    CheckBoxControl  : TCheckBox;
    Timer            : TTimer;
    IgnoreButton     : TButton;
    AbortButton      : TButton;
    Handler          : TCountdownHandler;
    OwnerForm        : TCustomForm;
    Monitor          : TMonitor;
    PPI              : Integer;
    ButtonWidth      : Integer;
    ButtonHeight     : Integer;
    ClientWidth      : Integer;
    ButtonsWidth     : Integer;
    CheckBoxWidth    : Integer;
    BottomRowHeight  : Integer;
    TimerWidth       : Integer;
    InitialSecs      : Cardinal;
    InitialHours     : Cardinal;
    InitialMins      : Cardinal;
    HourDigits       : Integer;
    Sample           : STRING;
    WorkArea         : TRect;

  FUNCTION Scale(Value : Integer) : Integer;
    BEGIN
      Result:=MulDiv(Value,PPI,96)
    END;

  FUNCTION CheckBoxSize(CheckBox : TCheckBox) : TSize;
    CONST
      CheckBoxGlyphWidth  = 17;
      CheckBoxGlyphHeight = 17;

    VAR
      DC       : HDC;
      OldFont  : HGDIOBJ;
      TextRect : TRect;

    BEGIN
      DC:=GetDC(0);
      TRY
        OldFont:=SelectObject(DC,CheckBox.Font.Handle);
        TRY
          TextRect:=Rect(0,0,0,0);
          DrawText(DC,PChar(CheckBox.Caption),Length(CheckBox.Caption),TextRect,DT_CALCRECT OR DT_SINGLELINE);
          Result.cx:=TextRect.Width+Scale(CheckBoxGlyphWidth);
          Result.cy:=Max(TextRect.Height,Scale(CheckBoxGlyphHeight))
        FINALLY
          SelectObject(DC,OldFont)
        END
      FINALLY
        ReleaseDC(0,DC)
      END
    END;

  BEGIN
    IF ms<=0 THEN EXIT(mrOK);

    OwnerForm:=CurrentModalForm;
    IF NOT Assigned(OwnerForm) THEN OwnerForm:=Screen.ActiveCustomForm;
    Monitor:=IF Assigned(OwnerForm) THEN OwnerForm.Monitor ELSE Screen.PrimaryMonitor;
    PPI:=Monitor.PixelsPerInch;

    ButtonWidth:=Scale(DefaultButtonWidth);
    ButtonHeight:=Scale(DefaultButtonHeight);
    ButtonsWidth:=IF AllowAbort THEN ButtonWidth*2+Scale(ButtonGap) ELSE ButtonWidth;

    Form:=TForm.CreateNew(OwnerForm);
    TRY
      Form.Caption:=Title;
      Form.BorderStyle:=bsDialog;
      Form.BorderIcons:=IF AllowClose THEN [TBorderIcon.biSystemMenu] ELSE [];
      Form.Position:=poDesigned;
      Form.Scaled:=FALSE;
      Form.OnCloseQuery:=NIL;

      CaptionLabel:=TLabel.Create(Form);
      CaptionLabel.Parent:=Form;
      CaptionLabel.Left:=Scale(Margin);
      CaptionLabel.Top:=Scale(Margin);
      CaptionLabel.AutoSize:=TRUE;
      CaptionLabel.ShowAccelChar:=FALSE;
      CaptionLabel.Caption:=Caption;

      TimerLabel:=TLabel.Create(Form);
      TimerLabel.Parent:=Form;

      {
        Determine a safe maximum width for the countdown label.

        "88" is deliberately used because it is normally the widest
        pair of decimal digits in proportional UI fonts.
      }
      InitialSecs:=Cardinal((UInt64(ms)+999) DIV 1000);
      InitialMins:=(InitialSecs MOD SecsPerHour) DIV SecsPerMin;
      InitialHours:=InitialSecs DIV SecsPerHour;

      IF InitialHours<>0 THEN BEGIN
        HourDigits:=Length(IntToStr(InitialHours));
        Sample:=StringOfChar('8',HourDigits)+' hours, 88 minutes, 88 seconds'
      END ELSE IF InitialMins<>0 THEN
        Sample:='88 minutes, 88 seconds'
      ELSE
        Sample:='88 seconds';

      TimerWidth:=CaptionWidth(TimerLabel,Sample);
      ClientWidth:=Max(Max(Scale(DefaultButtonWidth*3),CaptionWidth(CaptionLabel)+Scale(Margin*2)),TimerWidth+Scale(Margin*2));

      TimerLabel.ShowAccelChar:=FALSE;
      TimerLabel.AutoSize:=FALSE;
      TimerLabel.Top:=CaptionLabel.Top+CaptionLabel.Height+Scale(LabelGap);
      TimerLabel.Alignment:=TAlignment.taCenter;
      TimerLabel.Left:=Scale(Margin);
      TimerLabel.Width:=ClientWidth-TimerLabel.Left*2;

      IF CheckBoxText.IsEmpty THEN BEGIN
        CheckBoxControl:=NIL; CheckBoxWidth:=0
      END ELSE BEGIN
        CheckBoxControl:=TCheckBox.Create(Form);
        CheckBoxControl.Parent:=Form;
        CheckBoxControl.Caption:=CheckBoxText;
        CheckBoxControl.Checked:=Checked;
        VAR Size:=CheckBoxSize(CheckBoxControl);
        CheckBoxControl.Width:=Size.cx;
        CheckBoxControl.Height:=Size.cy;
        CheckBoxWidth:=CheckBoxControl.Width;
        ClientWidth:=Max(ClientWidth,Scale(Margin*2)+CheckBoxWidth+Scale(ButtonGap)+ButtonsWidth)
      END;

      Form.ClientWidth:=ClientWidth;
      TimerLabel.Width:=ClientWidth-TimerLabel.Left*2;

      IgnoreButton:=TButton.Create(Form);
      IgnoreButton.Parent:=Form;
      IgnoreButton.Width:=ButtonWidth;
      IgnoreButton.Height:=ButtonHeight;
      IgnoreButton.Caption:='&Ignore';
      IgnoreButton.ModalResult:=mrIgnore;
      IgnoreButton.Default:=TRUE;
      IgnoreButton.Cancel:=TRUE;

      IF AllowAbort THEN BEGIN
        AbortButton:=TButton.Create(Form);
        AbortButton.Parent:=Form;
        AbortButton.Width:=ButtonWidth;
        AbortButton.Height:=ButtonHeight;
        AbortButton.Caption:='&Abort';
        AbortButton.ModalResult:=mrAbort;

        IF Assigned(CheckBoxControl) THEN
          IgnoreButton.Left:=ClientWidth-Scale(Margin)-ButtonsWidth
        ELSE
          IgnoreButton.Left:=(ClientWidth-ButtonsWidth) DIV 2;

        AbortButton.Left:=IgnoreButton.Left+ButtonWidth+Scale(ButtonGap)
      END ELSE BEGIN
        AbortButton:=NIL;

        IF Assigned(CheckBoxControl) THEN
          IgnoreButton.Left:=ClientWidth-Scale(Margin)-ButtonWidth
        ELSE
          IgnoreButton.Left:=(ClientWidth-ButtonWidth) DIV 2
      END;

      IgnoreButton.Top:=TimerLabel.Top+TimerLabel.Height+Scale(ButtonTopGap);
      IgnoreButton.Enabled:=AllowIgnore;

      IF Assigned(AbortButton) THEN AbortButton.Top:=IgnoreButton.Top;

      BottomRowHeight:=ButtonHeight;
      IF Assigned(CheckBoxControl) THEN BEGIN
        CheckBoxControl.Left:=Scale(Margin);
        CheckBoxControl.Top:=IgnoreButton.Top+(ButtonHeight-CheckBoxControl.Height) DIV 2;
        BottomRowHeight:=Max(BottomRowHeight,CheckBoxControl.Height)
      END;

      Form.ClientHeight:=IgnoreButton.Top+BottomRowHeight+Scale(Margin);

      {
        Centre it on the active form or on the primary monitor
      }
      WorkArea:=IF Assigned(OwnerForm) THEN OwnerForm.BoundsRect ELSE Monitor.WorkareaRect;
      Form.Left:=WorkArea.Left+(WorkArea.Width-Form.Width) DIV 2;
      Form.Top:=WorkArea.Top+(WorkArea.Height-Form.Height) DIV 2;

      Timer:=TTimer.Create(Form);
      Timer.Enabled:=FALSE;
      Timer.Interval:=100;

      Handler:=TCountdownHandler.Create;
      TRY
        Handler.Form:=Form;
        Handler.TimerLabel:=TimerLabel;
        Handler.Timer:=Timer;

        Timer.OnTimer:=Handler.TimerTimer;
        IF NOT AllowClose THEN Form.OnCloseQuery:=Handler.FormCloseQuery;

        Handler.Start(ms);

        Result:=IF Form.ModalResult=mrNone THEN Form.ShowModal ELSE Form.ModalResult;
        IF Assigned(CheckBoxControl) THEN Checked:=CheckBoxControl.Checked
      FINALLY
        Timer.Enabled:=FALSE;
        Timer.OnTimer:=NIL;
        Form.OnCloseQuery:=NIL;
        Handler.Free
      END
    FINALLY
      Form.Free
    END
  END;

FUNCTION Countdown(CONST Title,Caption : STRING ; ms : Integer ; AllowIgnore : BOOLEAN = TRUE ; AllowClose : BOOLEAN = FALSE ; AllowAbort : BOOLEAN = FALSE) : TModalResult;
  VAR
    Checked : BOOLEAN;

  BEGIN
    Checked:=FALSE;
    Result:=Countdown(Title,Caption,'',Checked,ms,AllowIgnore,AllowClose,AllowAbort)
  END;

FUNCTION Countdown(CONST Title,Caption : STRING ; ms : Integer ; CONST Buttons : TModalResults) : TModalResult;
  BEGIN
    Result:=Countdown(Title,Caption,ms,mrIgnore IN Buttons,mrClose IN Buttons,mrAbort IN Buttons)
  END;

FUNCTION Countdown(CONST Title,Caption : STRING ; Time : TTime ; AllowIgnore : BOOLEAN = TRUE ; AllowClose : BOOLEAN = FALSE ; AllowAbort : BOOLEAN = FALSE) : TModalResult;
  BEGIN
    Result:=IF Time<0.0 THEN
              mrOK
            ELSE IF FRAC(Time)=0.0 THEN
              Countdown(Title,Caption,Integer(TRUNC(Time)),AllowIgnore,AllowClose,AllowAbort)
            ELSE
              Countdown(Title,Caption,(HourOf(Time)*SecsPerHour+MinuteOf(Time)*SecsPerMin+SecondOf(Time))*MilliSecsPerSecond+MilliSecondOf(Time),AllowIgnore,AllowClose,AllowAbort)
  END;

FUNCTION Countdown(CONST Title,Caption : STRING ; Time : TTime ; CONST Buttons : TModalResults) : TModalResult;
  BEGIN
    Result:=IF Time<0.0 THEN
              mrOK
            ELSE IF FRAC(Time)=0.0 THEN
              Countdown(Title,Caption,Integer(TRUNC(Time)),Buttons)
            ELSE
              Countdown(Title,Caption,(HourOf(Time)*SecsPerHour+MinuteOf(Time)*SecsPerMin+SecondOf(Time))*MilliSecsPerSecond+MilliSecondOf(Time),Buttons)
  END;

FUNCTION Countdown(CONST Title,Caption,CheckBoxText : STRING ; VAR Checked : BOOLEAN ; ms : Integer ; CONST Buttons : TModalResults) : TModalResult;
  BEGIN
    Result:=Countdown(Title,Caption,CheckBoxText,Checked,ms,mrIgnore IN Buttons,mrClose IN Buttons,mrAbort IN Buttons)
  END;

FUNCTION Countdown(CONST Title,Caption,CheckBoxText : STRING ; VAR Checked : BOOLEAN ; Time : TTime ; AllowIgnore : BOOLEAN = TRUE ; AllowClose : BOOLEAN = FALSE ; AllowAbort : BOOLEAN = FALSE) : TModalResult;
  BEGIN
    Result:=IF Time<0.0 THEN
              mrOK
            ELSE IF FRAC(Time)=0.0 THEN
              Countdown(Title,Caption,CheckBoxText,Checked,Integer(TRUNC(Time)),AllowIgnore,AllowClose,AllowAbort)
            ELSE
              Countdown(Title,Caption,CheckBoxText,Checked,(HourOf(Time)*SecsPerHour+MinuteOf(Time)*SecsPerMin+SecondOf(Time))*MilliSecsPerSecond+MilliSecondOf(Time),AllowIgnore,AllowClose,AllowAbort)
  END;

FUNCTION Countdown(CONST Title,Caption,CheckBoxText : STRING ; VAR Checked : BOOLEAN ; Time : TTime ; CONST Buttons : TModalResults) : TModalResult;
  BEGIN
    Result:=IF Time<0.0 THEN
              mrOK
            ELSE IF FRAC(Time)=0.0 THEN
              Countdown(Title,Caption,CheckBoxText,Checked,Integer(TRUNC(Time)),Buttons)
            ELSE
              Countdown(Title,Caption,CheckBoxText,Checked,(HourOf(Time)*SecsPerHour+MinuteOf(Time)*SecsPerMin+SecondOf(Time))*MilliSecsPerSecond+MilliSecondOf(Time),Buttons)
  END;

FUNCTION Countdown(CONST Title,Caption : STRING ; CheckBox : TCheckBox ; ms : Integer ; AllowIgnore : BOOLEAN = TRUE ; AllowClose : BOOLEAN = FALSE ; AllowAbort : BOOLEAN = FALSE) : TModalResult;
  VAR
    B : BOOLEAN;

  BEGIN
    B:=CheckBox.Checked;
    Result:=Countdown(Title,Caption,CheckBox.Caption,B,ms,AllowIgnore,AllowClose,AllowAbort);
    CheckBox.Checked:=B
  END;

FUNCTION Countdown(CONST Title,Caption : STRING ; CheckBox : TCheckBox ; ms : Integer ; CONST Buttons : TModalResults) : TModalResult;
  VAR
    B : BOOLEAN;

  BEGIN
    B:=CheckBox.Checked;
    Result:=Countdown(Title,Caption,CheckBox.Caption,B,ms,Buttons);
    CheckBox.Checked:=B
  END;

FUNCTION Countdown(CONST Title,Caption : STRING ; CheckBox : TCheckBox ; Time : TTime ; AllowIgnore : BOOLEAN = TRUE ; AllowClose : BOOLEAN = FALSE ; AllowAbort : BOOLEAN = FALSE) : TModalResult;
  VAR
    B : BOOLEAN;

  BEGIN
    B:=CheckBox.Checked;
    Result:=Countdown(Title,Caption,CheckBox.Caption,B,Time,AllowIgnore,AllowClose,AllowAbort);
    CheckBox.Checked:=B
  END;

FUNCTION Countdown(CONST Title,Caption : STRING ; CheckBox : TCheckBox ; Time : TTime ; CONST Buttons : TModalResults) : TModalResult;
  VAR
    B : BOOLEAN;

  BEGIN
    B:=CheckBox.Checked;
    Result:=Countdown(Title,Caption,CheckBox.Caption,B,Time,Buttons);
    CheckBox.Checked:=B
  END;

END.
