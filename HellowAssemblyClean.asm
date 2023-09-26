;=======================================================================================================
; Домашняя работа Разгарова Ивана Павловича, группа БИВТ-23-5 2023 года. Запускать на свой страх и риск!
;=======================================================================================================

.386                   							
.model flat, stdcall							
option casemap:none								

include \masm32\include\windows.inc 			
include \masm32\include\user32.inc 				
include \masm32\include\kernel32.inc 			
include \masm32\include\gdi32.inc 				

includelib \masm32\lib\kernel32.lib 			
includelib \masm32\lib\user32.lib				
includelib \masm32\lib\gdi32.lib 				

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD 	

WindowWidth 			equ 640 
WindowHeight 		equ 480

.DATA 											

ClassName			db "MyWinClass", 0			
AppName 			db "Домашня работа Разгарова Ивана БИВТ-23-5", 0

.DATA? 											

hInstance 			HINSTANCE ? 				
CommandLine 		LPSTR     ? 				
												
;------------------------------------------------------------------------------------------
.CODE											;непосредственно блок самого кода
;------------------------------------------------------------------------------------------

MainEntry proc

		push		NULL 						
		call		GetModuleHandle 			
		mov			hInstance, eax 				
		
		call 		GetCommandLine 			
		mov 		CommandLine, eax 			
			
		push		SW_SHOWDEFAULT 				
		lea			eax, CommandLine			
		push 		CommandLine						
		push 		NULL						
		push 		hInstance					
		call		WinMain						
		
		push 		eax							
		call		ExitProcess					
		
MainEntry endp
;
;WinMain - традиционное название для главной функции приложения как для точки входа в него
;

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
		
		LOCAL		wc:WNDCLASSEX 				
		LOCAL 		msg:MSG						
		LOCAL		hwnd:HWND					
		
		mov 		wc.cbSize, SIZEOF WNDCLASSEX		
		mov 		wc.style, CS_HREDRAW or CS_VREDRAW	
		mov 		wc.lpfnWndProc, OFFSET WndProc		
		mov 		wc.cbClsExtra, 0					
		mov 		wc.cbWndExtra, 0					
		mov 		eax, hInstance
		mov 		wc.hInstance, eax					
		mov			wc.hbrBackground, COLOR_3DSHADOW+1	
		mov 		wc.lpszMenuName, NULL				
		mov 		wc.lpszClassName, OFFSET ClassName	
		
		push 		IDI_APPLICATION 					
		push 		NULL 								
		call 		LoadIcon 							
		mov 		wc.hIcon, eax						
		mov 		wc.hIconSm, eax						
		
		push		IDC_ARROW 							
		push 		NULL 								
		call 		LoadCursor
		mov 		wc.hCursor, eax 					
		
		lea 		eax, wc								
		push 		eax
		call 		RegisterClassEx						
		
		push 		NULL								
		push 		hInstance							
		push 		NULL								
		push 		NULL								
		push 		WindowHeight						
		push 		WindowWidth 						
		push		CW_USEDEFAULT						
		push 		CW_USEDEFAULT						
		push 		WS_OVERLAPPEDWINDOW + WS_VISIBLE	
		push 		OFFSET AppName 						
		push 		OFFSET ClassName 					
		push 		0									
		call 		CreateWindowExA
		cmp 		eax, NULL
		je 			WinMainRet 							
		mov 		hwnd, eax 							
		
		push 		eax 								
		call 		UpdateWindow 						
		
MessageLoop:
		
		push 		0
		push 		0
		push 		NULL
		lea 		eax, msg
		push 		eax
		call 		GetMessage							
		
		cmp 		eax, 0
		je 			DoneMessages						
		
		lea 		eax, msg
		push 		eax
		call 		TranslateMessage					
		
		lea 		eax, msg 
		push 		eax
		call 		DispatchMessage						
		
		jmp 		MessageLoop 						
		
DoneMessages:
		
		mov 		eax, msg.wParam 					
		
WinMainRet: 		

		ret
		
WinMain endp 											

;
;WndProc - главная процедура, обрабатывающая отрисовку и выход
;

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

		LOCAL 		ps:PAINTSTRUCT						
		LOCAL 		rect:RECT
		LOCAL 		hdc:HDC 
		
		cmp 		uMsg, WM_DESTROY
		jne 		NotWMDestroy
		
		push 		0								
		call 		PostQuitMessage						
		xor 		eax, eax							
		ret
		
NotWMDestroy:

		cmp 		uMsg, WM_PAINT
		jne 		NotWMPaint
		
		lea 		eax, ps								
		push		eax
		push 		hWnd
		call 		BeginPaint							
		mov 		hdc, eax
		
		push 		TRANSPARENT							
		push 		hdc
		call 		SetBkMode							
		
		lea 		eax, rect 							
		push 		eax 								
		push 		hWnd
		call 		GetClientRect 
		
		push 		DT_SINGLELINE + DT_CENTER + DT_VCENTER
		lea 		eax, rect
		push 		eax
		push 		-1
		push 		OFFSET AppName
		push 		hdc
		call 		DrawText 							
		
		lea 		eax, ps 
		push 		eax
		push 		hWnd
		call 		EndPaint						
		
		xor 		eax, eax 							
		ret
		
NotWMPaint:

		push 		lParam
		push 		wParam
		push 		uMsg
		push 		hWnd
		call 		DefWindowProc						
		ret												
		
WndProc endp

;Указываем какую точку входа заканчивать. Иначе прерывает _WinMainCRTStartup

END MainEntry