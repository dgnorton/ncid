;NCIDpop Windows Client installer
;Written by Rich West 01/27/2006
;Updated by Lyman Epp 02/11/2006
;Updated by John Chmielewski 12/21/2008

;--------------------------------
;Include Modern UI

	!include "MUI.nsh"

;--------------------------------

;Application

	!define NAME            ncid
	!define VERSION         0.73
	!define PROG            "${NAME}.exe"
	!define LICENSE_FILE    "LICENSE.txt"
	!define WEB_PAGE        "http://ncid.sourceforge.net"
	!define SPLASH_IMAGE    "ncid_splash.bmp"
	!define INSTALLER_NAME  "${NAME}-${VERSION}-client_setup.exe"
	!define CONFIG          "${NAME}.ini"

	!define ROOT_KEY HKLM
	!define INSTALLER_KEY   "SOFTWARE\${NAME}"
	!define UNINSTALL_KEY \
	    "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${NAME}"
	!define AUTORUN_KEY    "SOFTWARE\Microsoft\Windows\CurrentVersion\Run"

	!define WNDCLASS       "${NAME}"
	!define TIMEOUT        2000
	!define SYNC_TERM      0x00100001

;--------------------------------
;General

	Name    "${NAME}"
	OutFile "${INSTALLER_NAME}"
;	Icon    "${NAME}.ico"

	SetCompressor lzma

;	WindowIcon On

	XPStyle on

	; Default installation folder
	InstallDir "$PROGRAMFILES\${NAME}"

	; Get installation folder from registry if available
	InstallDirRegKey "${ROOT_KEY}" ${INSTALLER_KEY} ""

;--------------------------------
!macro SplashPage
  # the plugins dir is automatically deleted when the installer exits
  InitPluginsDir
  
  File /oname=$PLUGINSDIR\splash.bmp "${SPLASH_IMAGE}"

  advsplash::show 1000 600 400 -1 $PLUGINSDIR\splash

  Pop $0 ; $0 has '1' if the user closed the splash screen early,
         ; '0' if everything closed normally, and '-1' if some error occurred.
!macroend

;--------------------------------
!macro TerminateApp
	Push $0 ; window handle
	Push $1
	Push $2 ; process handle

loop:
	FindWindow $0 "${WNDCLASS}" ""
	IntCmp $0 0 done

	System::Call 'user32.dll::GetWindowThreadProcessId(i r0, *i .r1) i .r2'
	System::Call 'kernel32.dll::OpenProcess(i ${SYNC_TERM}, i 0, i r1) i .r2'
	SendMessage $0 ${WM_CLOSE} 0 0 /TIMEOUT=${TIMEOUT}

	System::Call 'kernel32.dll::WaitForSingleObject(i r2, i ${TIMEOUT}) i .r1'
	IntCmp $1 0 close

	System::Call 'kernel32.dll::TerminateProcess(i r2, i 0) i .r1'

close:
	System::Call 'kernel32.dll::CloseHandle(i r2) i .r1'
	goto loop

done:
	Pop $2
	Pop $1
	Pop $0
!macroend

;--------------------------------
!macro CheckUserRights
	ClearErrors
	UserInfo::GetName
	IfErrors good
	Pop $0
	UserInfo::GetAccountType
	Pop $1
	StrCmp $1 "Admin" good
	StrCmp $1 "Power" good

	MessageBox MB_OK "Administrative rights are needed for that."
	Abort

good:
!macroend

;--------------------------------
Function .onInit
        !insertmacro SplashPage
	!insertmacro CheckUserRights
	!insertmacro MUI_INSTALLOPTIONS_EXTRACT "${CONFIG}"
FunctionEnd

;--------------------------------
Function un.onInit
	!insertmacro CheckUserRights
FunctionEnd

;--------------------------------
Function Config

        !insertmacro MUI_HEADER_TEXT "$(CONFIG_TITLE)" "$(CONFIG_SUBTITLE)"
        !insertmacro MUI_INSTALLOPTIONS_DISPLAY "${CONFIG}"

FunctionEnd

;--------------------------------
;Variables

	Var STARTMENU_FOLDER

;--------------------------------
;Interface Settings

	!define MUI_ABORTWARNING
	
	#!define MUI_ICON "${NAME}.ico"

	; where to store Start Menu directory name
	!define MUI_STARTMENUPAGE_REGISTRY_ROOT "${ROOT_KEY}"
	!define MUI_STARTMENUPAGE_REGISTRY_KEY "${INSTALLER_KEY}"
	!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu"

	!define MUI_FINISHPAGE_RUN "$INSTDIR\${PROG}"
	!define MUI_FINISHPAGE_RUN_PARAMETERS "$R0"

;--------------------------------
;Pages

	!insertmacro MUI_PAGE_WELCOME
	!insertmacro MUI_PAGE_LICENSE ${LICENSE_FILE}
	!insertmacro MUI_PAGE_COMPONENTS
	!insertmacro MUI_PAGE_DIRECTORY
	!insertmacro MUI_PAGE_STARTMENU Application $STARTMENU_FOLDER
	Page custom Config
	!insertmacro MUI_PAGE_INSTFILES
	!insertmacro MUI_PAGE_FINISH

	!insertmacro MUI_UNPAGE_WELCOME
	!insertmacro MUI_UNPAGE_CONFIRM
	!insertmacro MUI_UNPAGE_INSTFILES
	!insertmacro MUI_UNPAGE_FINISH

;--------------------------------
;Languages
 
	!insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Installer Sections

Section "${NAME} (Required)" Sec${NAME}
	
	!insertmacro TerminateApp

	SectionIn RO

	SetOutPath "$INSTDIR"
	SetShellVarContext all

	; Put file there
	File "${PROG}"
	File "README.txt"
	File "ncid.1.txt"
	File "ncid.1.htm"
	File "ncid.conf.5.txt"
	File "ncid.conf.5.htm"
	File "Install-Win.txt"
	File "ncid.gif"
	
	; Write the installation path into the registry
	WriteRegStr "${ROOT_KEY}" ${INSTALLER_KEY} "" "$INSTDIR"

	; Run at logon for all users
	; WriteRegStr "${ROOT_KEY}" ${AUTORUN_KEY} "${NAME}" "$INSTDIR\${PROG}"

	; Write the uninstall keys for Windows
	WriteRegStr "${ROOT_KEY}" ${UNINSTALL_KEY} "DisplayName" "${NAME}"
	WriteRegStr "${ROOT_KEY}" ${UNINSTALL_KEY} "UninstallString" \
		'"$INSTDIR\uninstall.exe"'
	WriteRegStr "${ROOT_KEY}" ${UNINSTALL_KEY} "HelpLink" ${WEB_PAGE}
	WriteRegDWORD "${ROOT_KEY}" ${UNINSTALL_KEY} "NoModify" 1
	WriteRegDWORD "${ROOT_KEY}" ${UNINSTALL_KEY} "NoRepair" 1
	
	; Create uninstaller
	WriteUninstaller "$INSTDIR\Uninstall.exe"

SectionEnd

Section -configure
        !insertmacro MUI_INSTALLOPTIONS_READ $R0 ${CONFIG} "Field 2" "State"
SectionEnd

Section -Shortcuts

	; Create shortcuts
	!insertmacro MUI_STARTMENU_WRITE_BEGIN Application
	CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"
	CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\${NAME}.lnk" \
		"$INSTDIR\${PROG}" "$R0"
        CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Uninstall.lnk" \
		"$INSTDIR\Uninstall.exe"
	CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\README.txt.lnk" \
		"$INSTDIR\README.txt"
        CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\NCID.1.txt.lnk" \
		"$INSTDIR\ncid.1.txt"
        CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\NCID.CONF.1.txt.lnk" \
		"$INSTDIR\ncid.conf.5.txt"
        CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\NCID.1.htm.lnk" \
		"$INSTDIR\ncid.1.htm"
        CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\NCID.CONF.5.htm.lnk" \
		"$INSTDIR\ncid.conf.5.htm"
	CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\NCID Web Page.lnk" \
		${WEB_PAGE}
        ; CreateShortCut "$SMPROGRAMS\Startup\${NAME}.lnk" "$INSTDIR\${PROG}" "$R0"
        CreateShortCut "$DESKTOP\${NAME}.lnk" "$INSTDIR\${PROG}" "$R0" ""
	!insertmacro MUI_STARTMENU_WRITE_END

SectionEnd

;--------------------------------
;Descriptions

	; Language strings
	LangString DESC_Sec${NAME} ${LANG_ENGLISH} "NCID is a Network Caller ID client"
	LangString CONFIG_TITLE ${LANG_ENGLISH} "Configure NCID Server IP Address"
	LangString CONFIG_SUBTITLE ${LANG_ENGLISH} "Client/Server on same computer is 127.0.0.1"
 
;--------------------------------
;Uninstaller Section

Section "Uninstall"

	!insertmacro TerminateApp

	SetShellVarContext all

	!insertmacro MUI_STARTMENU_GETFOLDER Application $STARTMENU_FOLDER

	ReadRegStr $INSTDIR "${ROOT_KEY}" ${INSTALLER_KEY} ""

	; Remove shortcuts
	Delete "$DESKTOP\${NAME}.lnk"
	Delete "$SMPROGRAMS\Startup\${NAME}.lnk"
	RMDir /r "$SMPROGRAMS\$STARTMENU_FOLDER"

	; Remove files
	RMDir /r "$INSTDIR"

	; Remove registry keys
	DeleteRegValue "${ROOT_KEY}" ${AUTORUN_KEY} "${NAME}"
	DeleteRegKey "${ROOT_KEY}" ${UNINSTALL_KEY}
	DeleteRegKey "${ROOT_KEY}" ${INSTALLER_KEY}

SectionEnd
