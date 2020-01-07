; All WIA_ Methods are from https://www.autohotkey.com/boards/viewtopic.php?t=7254
; Press Up/Down/Left/Right optionally with either Shift, Control, or Control+Shift to move the Crop window
#SingleInstance,Force
DetectHiddenWindows,On
BIE:=New BasicImageEdit(800,600)
BIE.Exit:=1						;If you are not using this as a part of a larger project it will ExitApp when you hit escape or close the window
BIE.SaveFile:=A_ScriptDir "\temp.jpg"	;Default Save File Location (Will not ask where to save if it is set)
BIE.SaveWidth:=500					;Default Maximum Save Width
BIE.SaveHeight:=500					;Default Maximum Save Height
if(1)							;If you want to show the crop window without having to click on the button put a 1 in this if() statement.
	SetTimer,FixCrop,-1
return
FixCrop:
BIE.Crop()
return
Class BasicImageEdit{
	static Keep:=[]
	__New(W:=400,H:=400,Title:="Basic Image Editor"){
		Gui,Resize:Destroy
		Gui,Resize:Default
		Gui,Color,0,0
		Gui,+HWNDMain +Resize +LabelBasicImageEdit.
		Gui,Add,Text,w%W% h%H% HWNDPic +0xE
		SysGet,Caption,4
		SysGet,Border,33
		SetWinDelay,-1
		Gui,Add,Button,HWNDOpen,&Open
		Gui,Add,Button,x+m HWNDCrop Default,Cro&p
		Gui,Add,Button,x+m HWNDSave,&Save
		Gui,Add,Button,x+m HWNDRotate,&Rotate
		for a,b in {Open:[Open,this.Open.Bind(this)],Crop:[Crop,(BoundCrop:=this.Crop.Bind(this))],Save:[Save,this.Save.Bind(this)],Rotate:[Rotate,this.Rotate.Bind(this)]}{
			this.AllCtrl[a]:={HWND:b.1,Bound:b.2},Bound:=b.2
			GuiControl,+g,% b.1,%Bound%
		}Gui,Show,,%Title%
		Gui,2:Destroy
		Gui,2:Default
		Gui,+HWNDCrop +Owner%Main% +LabelBasicImageEdit. +Resize +ToolWindow
		Gui,2:Show,Hide w200 h200,Crop
		this.MoveBound:=this.EnterSizeMove.Bind(this),this.MoveExitBound:=this.ExitSizeMove.Bind(this),OnMessage(0x231,this.MoveBound,-1),OnMessage(0x232,this.MoveExitBound,-1),this.CropID:="ahk_id" Crop,this.CropHWND:=Crop,BasicImageEdit.Keep.Push(this),Adjust:=this.Adjust.Bind(this),this.IP:=ComObjCreate("WIA.ImageProcess"),this.RedrawBound:=this.Redraw.Bind(this),this.SWidth:=W,this.SHeight:=H,this.Caption:=Caption,this.Border:=Border,this.PicID:="ahk_id" Pic,this.PicHWND:=Pic,this.W:=W,this.H:=H,this.MainHWND:=Main,this.MainID:="ahk_id" Main,this.WinDelay:=A_WinDelay
		Hotkey,IfWinActive,% this.CropID
		for a,b in ["Up","Down","Left","Right"]
			for c,d in ["","+","^+","^"]
				Hotkey,% d b,%Adjust%,On
		for a,b in {Enter:BoundCrop}
			Hotkey,%a%,%b%,On
		ControlFocus,Button2,% this.MainID
	}Adjust(){
		Key:=RegExReplace(A_ThisHotkey,"\W"),Pos:=this.WinPos(this.CropHWND),Adjust:=GetKeyState("CTRL","P")?20:1,Shift:=GetKeyState("Shift","P")
		if(!Shift)
			(Key="Left")?Pos.X-=Adjust:Key="Right"?Pos.X+=Adjust:Key="Down"?Pos.Y+=Adjust:Key="Up"?Pos.Y-=Adjust:""
		else if(Shift)
			(Key="Left")?Pos.W-=Adjust:Key="Right"?Pos.W+=Adjust:Key="Up"?Pos.H-=Adjust:Key="Down"?Pos.H+=Adjust:""
		this.WinMove(this.CropID,Pos.X,Pos.Y,Pos.W+this.Border*2,Pos.H+this.Border*2+this.Caption),this.ExitSizeMove(0,0,0,this.CropHWND)
	}Close(){
		HWND:=this,(HWND=(this:=BasicImageEdit.Keep.1).CropHWND)?this.CropVis:=0:""
		if(A_Gui="Resize"){
			if(this.Exit)
				ExitApp
			OnMessage(0x231,this.MoveBound,0)
			SetWinDelay,% this.WinDelay
		}
	}Crop(){
		if(!this.Img.Width)
			return
		WinGet,Style,Style,% this.CropID
		if(Style&0x10000000=0){
			Pos:=this.WinPos(this.CropHWND),this.Size("Startup",Pos.W,Pos.H),this.CropVis:=1,PP:=this.WinPos(this.PicHWND),this.WinMove(this.CropID,PP.X-this.Border,PP.Y-this.Border-this.Caption)
			if(!this.Init)
				this.Init:=1,this.WinMove(this.CropID,PP.X-this.Border,PP.Y-this.Border-this.Caption,PP.W+this.Border*2,PP.H+this.Border*2+this.Caption)
			this.WinShow(this.CropID)
		}else
			this.Hide(this.CropID),ScaleW:=this.SWidth/this.OWidth,ScaleH:=this.SHeight/this.OHeight,this.CropVis:=0,Pic:=this.WinPos(this.PicHWND),Crop:=this.WinPos(this.CropHWND),Right:=((Pic.X+Pic.W)-(Crop.X+Crop.W+this.Border))//ScaleW,Bottom:=((Pic.Y+Pic.H)-(Crop.Y+Crop.H+this.Border+this.Caption))//ScaleH,Left:=((Crop.X+this.Border)-Pic.X)//ScaleW,Top:=((Crop.Y+this.Border+this.Caption)-Pic.Y)//ScaleH,this.WIA_CropImage(Left,Top,Right,Bottom),this.WIA_ScaleImage(this.W,this.H),this.DisplayImage()
	}DisplayImage(){
		PicObj:=this.WIA_GetImageBitmap(this.Scaled)
		for a,b in {OWidth:this.Img.Width,OHeight:this.Img.Height,SWidth:this.Scaled.Width,SHeight:this.Scaled.Height}
			this[a]:=b
		HBM:=PicObj.Handle
		SendMessage,(STM_SETIMAGE:=0x172),(IMAGE_BITMAP:=0x0),%HBM%,,% this.PicID
	}EnterSizeMove(a,b,c,d){
		if(d=this.MainHWND)
			Pic:=this.WinPos(this.PicHWND),Crop:=this.WinPos(this.CropHWND),this.Hide(this.CropID),this.Offset:={X:Pic.X-Crop.X,Y:Pic.Y-Crop.Y}
		return 0 ;Needed :)
	}Escape(a*){
		tt:=BasicImageEdit.Keep.1
		if(A_Gui=2){
			Gui,2:Hide
			tt.CropVis:=0
		}else if(A_Gui="Resize"){
			if(tt.Exit)
				ExitApp
			OnMessage(0x231,tt.MoveBound,0)
			SetWinDelay,% this.WinDelay
	}}ExitSizeMove(a,b,c,d){
		if(d=this.MainHWND){
			if(this.CropVis)
				Pic:=this.WinPos(this.PicHWND),this.WinMove(this.CropID,Pic.X-this.Offset.X,Pic.Y-this.Offset.Y),this.WinShow(this.CropID)
			this.Redraw()
		}else if(d=this.CropHWND)
			this.FixCrop()
		return 0 ;Needed :)
	}FixCrop(){
		Obj:=this.WinPos(this.CropHWND),Obj1:=this.WinPos(this.PicHWND),X:=Obj1.X-this.Border,Y:=Obj1.Y-(this.Border+this.Caption),NewX:=Obj.X<X?X:Obj.X,NewY:=Obj.Y<Y?Y:Obj.Y
		if(Obj.X+this.Border*2>(MaxX:=Obj1.X+Obj1.W))
			NewX:=MaxX-Obj.W-this.Border
		if(Obj.Y+this.Border*2+this.Caption>(MaxY:=Obj1.Y+Obj1.H))
			NewY:=MaxY-Obj.H-this.Border-this.Caption
		NewW:=NewX+Obj.W+this.Border>Obj1.X+Obj1.W?Obj1.W-(NewX-Obj1.X)+this.Border:Obj.W+this.Border*2
		if(NewW<40)
			NewW:=40,NewX:=Obj1.X+Obj1.W-40 ;-this.Border
		NewH:=NewY+Obj.H+this.Caption+this.Border>Obj1.Y+Obj1.H?Obj1.H-((NewY-Obj1.Y)+this.Border*2-this.Caption-1):Obj.H+this.Border*2+this.Caption
		this.WinMove(this.CropID,NewX,NewY,NewW,NewH)
	}Hide(ID){
		WinHide,%ID%
	}Open(File:=""){
		if(!FileExist(File))
			FileSelectFile,File,,,Image,*.jpg;*.bmp
		if(!FileExist(File))
			return
		this.Init:=0,this.OFile:=File,this.WIA_LoadImage(File),this.WIA_ScaleImage(this.W,this.H),this.DisplayImage()
	}Redraw(){
		this.WIA_ScaleImage(this.W,this.H),this.DisplayImage(),this.FixCrop()
	}Resize(Width,Height,Ratio:=1){
		this.WIA_ImageProcess(),this.IP.Filters.Add(this.IP.FilterInfos("Scale").FilterID),this.IP.Filters[1].Properties("MaximumWidth"):=Width,this.IP.Filters[1].Properties("MaximumHeight"):=Height,this.IP.Filters[1].Properties("PreserveAspectRatio"):=Ratio,this.Img:=this.IP.Apply(this.Img)
	}Rotate(){
		this.WIA_ImageProcess(),this.IP.Filters.Add(this.IP.FilterInfos("RotateFlip").FilterID),this.IP.Filters[1].Properties("RotationAngle"):=90,this.Img:=this.IP.Apply(this.Img),this.WIA_ScaleImage(this.W,this.H),this.DisplayImage()
	}Save(){
		File:=this.OFile
		SplitPath,File,,,OExt
		if(!File:=this.SaveFile)
			FileSelectFile,File,S16,,Save Cropped As,*.jpg;*.png;*.bmp;*.tiff;*.gif
		if(ErrorLevel)
			return
		SplitPath,File,,,Ext
		if(!Ext){
			File.=!Ext?"." OExt:""
			SplitPath,File,,,Ext
		}if(this.Img.FileExtension!=Ext)
			this.WIA_ConvertImage(Ext)
		if(this.SaveWidth)
			this.Resize(this.SaveWidth,this.SaveHeight)
		if(FileExist(File))
			FileDelete,%File%
		this.Img.SaveFile(File)
	}Size(Action,W,H){
		static Last:=[]
		HWND:=this,this:=BasicImageEdit.Keep.1
		if(HWND=this.MainHWND){
			GuiControl,MoveDraw,% this.PicHWND,% "h" H-35 " w" W-20
			for a,b in this.AllCtrl
				GuiControl,MoveDraw,% b.HWND,% "y" H-27
			this.W:=W-20,this.H:=H-35
		}else if(HWND=this.CropHWND||Action="Startup"){
			Width:=W+this.Border*2,Height:=H+this.Border+this.Caption+this.Border,Left:=this.Border,Right:=Width-this.Border,Bottom:=Height-this.Border,Top:=this.Caption+this.Border
			WinSet,Region,0-0 0-%Height% %Width%-%Height% %Width%-0 0-0 %Left%-%Top% %Right%-%Top% %Right%-%Bottom% %Left%-%Bottom% %Left%-%Top%,% this.CropID
		}if(Last.W!=W||Last.H!=H),Last.W:=W,Last.H:=H
			if(Redraw:=this.RedrawBound)
				SetTimer,%Redraw%,-200
	}WIA_ConvertImage(NewFormat,Quality:=100,Compression:="LZW") {
		static FormatID:={BMP:"{B96B3CAB-0728-11D3-9D7B-0000F81EF32E}",JPG:"{B96B3CAE-0728-11D3-9D7B-0000F81EF32E}",GIF:"{B96B3CB0-0728-11D3-9D7B-0000F81EF32E}",PNG:"{B96B3CAF-0728-11D3-9D7B-0000F81EF32E}",TIFF:"{B96B3CB1-0728-11D3-9D7B-0000F81EF32E}"},Comp:={CCITT3:1,CCITT4:1,LZW:1,RLE:1,Uncompressed:1}
		if Quality Not Between 1 And 100
			return 0
		if(Comp[Compression]="")
			return 0
		if(!NewFormat:=FormatID[NewFormat])
			return
		this.WIA_ImageProcess(),this.IP.Filters.Add(this.IP.FilterInfos("Convert").FilterID),this.IP.Filters[1].Properties("FormatID"):=NewFormat,this.IP.Filters[1].Properties("Quality"):=Quality,this.IP.Filters[1].Properties("Compression"):=Compression,this.Img:=this.IP.Apply(this.Img)
	}WIA_CropImage(Left,Top,Right,Bottom){
		this.WIA_ImageProcess(),this.IP.Filters.Add(this.IP.FilterInfos("Crop").FilterID),this.IP.Filters[1].Properties("Left"):=Left,this.IP.Filters[1].Properties("Top"):=Top,this.IP.Filters[1].Properties("Right"):=Right,this.IP.Filters[1].Properties("Bottom"):=Bottom,this.Img:=this.IP.Apply(this.Img)
	}WIA_GetImageBitmap(ImgObj) {
		return (ComObjType(ImgObj,"Name")="IImageFile")?ImgObj.Filedata.Picture:0
	}WIA_ImageProcess() {
		while(this.IP.Filters.Count)
			this.IP.Filters.Remove(1)
	}WIA_LoadImage(ImgPath){
		this.Img:=ComObjCreate("WIA.ImageFile"),ComObjError(0),this.Img.LoadFile(ImgPath),ComObjError(1)
	}WIA_ScaleImage(PxWidth,PxHeight,KeepRatio:=1){
		if(this.Img.Width)
			this.WIA_ImageProcess(),this.IP.Filters.Add(this.IP.FilterInfos("Scale").FilterID),this.IP.Filters[1].Properties("MaximumWidth"):=PxWidth>0?PxWidth:PxHeight,this.IP.Filters[1].Properties("MaximumHeight"):=PxHeight>0?PxHeight:PxWidth,this.IP.Filters[1].Properties("PreserveAspectRatio"):=KeepRatio,this.Scaled:=this.IP.Apply(this.Img)
	}WinMove(Title,X,Y,W:="",H:=""){
		WinMove,%Title%,,%X%,%Y%,%W%,%H%
	}WinPos(HWND){
		VarSetCapacity(Rect,16),DllCall("GetClientRect",PTR,HWND,PTR,&Rect)
		WinGetPos,x,y,,,% "ahk_id" HWND
		return {x:x,y:y,w:(w:=NumGet(Rect,8)),h:(h:=NumGet(Rect,12)),text:"x" x " y" y " w" w " h" h}
	}WinShow(ID){
		WinShow,%ID%
	}
}