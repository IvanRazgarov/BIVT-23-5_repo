;=======================================================================================================
; Домашняя работа Разгарова Ивана Павловича, группа БИВТ-23-5 2023 года. Запускать на свой страх и риск!
;=======================================================================================================

; Настройки компилятора и подключаемые файлы

.386                   							;полный набор инструкций и режим для 80386 
.model flat, stdcall							;модель расположения кода в регистрах. flat - самая большая.
option casemap:none								;делаем код нечувствительным к регистру букв (кроме обращений к системным именам

;Подключаемые файлы - заголовки и библиотеки, которые понадобятся позже

include \masm32\include\windows.inc 			;главный файл с заголовками в самой операционной системе
include \masm32\include\user32.inc 				;способы взаимодействия с пользователем
include \masm32\include\kernel32.inc 			;обработчики, пути, модули и подобное
include \masm32\include\gdi32.inc 				;графическое отображение

;библиотеки DLL - информация, необходимая для связи бинарника с вызовами системных DLL

includelib \masm32\lib\kernel32.lib 			;Kernel32.dll
includelib \masm32\lib\user32.lib				;User32.dll
includelib \masm32\lib\gdi32.lib 				;GDI32.dll

;компилятор собирает код в два этапа, при первом проходе компилятор определяет, сколько места займёт каждая команда
;и куда в памяти попадут их ярлыки. Помимо этого компилятор также запоминает все вызываемые функции, отводя по ним место

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD 	;Резервирования места под главную функцию

;Константы и данные

WindowWidth 			equ 640 
WindowHeight 		equ 480

.DATA 											;Данные не будут изменятся в процессе выполнения программы
												;поэтому записываются в сегмент read only

ClassName			db "MyWinClass", 0			;Имя класса окна приложения
AppName 			db "Ivan Razgarov homeworck", 0		;Имя, отображаемое в заголовке окна

.DATA? 											;Не использованные данные (по сути резервиврование места на будущее)

hInstance 			HINSTANCE ? 				;Место под обработчик процесса (по типу процесс ID)
CommandLine 		LPSTR     ? 				;Указатель на аргументы командной строки,
												;с которыми мы будем запускать приложение

;------------------------------------------------------------------------------------------
.CODE											;непосредственно блок самого кода
;------------------------------------------------------------------------------------------

MainEntry proc

		push		NULL 						;получаем обработчик экземпляр нашего приложения (NULL указывает на самого себя)
		call		GetModuleHandle 			;GetModuleHandle возвращает экземпляр в EAX
		mov			hInstance, eax 				;Сохраняем инстанс в глобальную переменную
		
		call 		GetCommandLine 			;Получаем информацию из командной строки снова в eax
		mov 		CommandLine, eax 			;Сохраняем в перменную
		
				;Вызываем главную функцию и выходим из процесса с полученным результатом
			
		push		SW_SHOWDEFAULT 				;игнорирует настройку выравнивания окна от родительского процесса
		lea			eax, CommandLine			;помещаем адресс из переменной в eax
		push 		CommandLine						;отправляем адресс в стек
		push 		NULL						;отправляем в стек ссылку на самих себя
		push 		hInstance					;инстанс нашего приложения
		call		WinMain						;и наконец вызываем главную функцию, для которой ранее резервировали место
		
		push 		eax							;помещаем результат работы функции в стек
		call		ExitProcess					;Выходим из процесса
		
MainEntry endp
;
;WinMain - традиционное название для главной функции приложения как для точки входа в него
;

;Самая интересная часть. В строгом порядке запихиваем в стак параметры для нашего приложения.

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
		
		LOCAL		wc:WNDCLASSEX 				;создание локальных переменных
		LOCAL 		msg:MSG						;память резервируется на время жизни функции
		LOCAL		hwnd:HWND					;наверху стека, но не инициализируется и не очищается
		
		mov 		wc.cbSize, SIZEOF WNDCLASSEX		;Заполняем значения членов класса окна
		mov 		wc.style, CS_HREDRAW or CS_VREDRAW	;Перерисовываем если окно начинают растягивать
		mov 		wc.lpfnWndProc, OFFSET WndProc		;Обратная функция для обработки сообщений винды
		mov 		wc.cbClsExtra, 0					;Без дополнительных данных класса
		mov 		wc.cbWndExtra, 0					;Без дополнительных данных окна
		mov 		eax, hInstance
		mov 		wc.hInstance, eax					;записали экземпляр приложения
		mov			wc.hbrBackground, COLOR_3DSHADOW+1	;задаём стандартный цвет кисти как "цвет тени"+1
		mov 		wc.lpszMenuName, NULL				;меню отсутствует
		mov 		wc.lpszClassName, OFFSET ClassName	;имя классаиложения (сдвигаемся в памяти на указанную метку)
		
		push 		IDI_APPLICATION 					;используем стандартную иконку приложения из системы
		push 		NULL 								;снова свой инстанс
		call 		LoadIcon 							;команда загрузить иконку
		mov 		wc.hIcon, eax						;положили загруженную иконку в переменную
		mov 		wc.hIconSm, eax						;обеих размеров
		
		push		IDC_ARROW 							;вытаскиваем изображение стрелки-курсора
		push 		NULL 								
		call 		LoadCursor
		mov 		wc.hCursor, eax 					
		
		lea 		eax, wc								;загружаем все переменные в регистр
		push 		eax
		call 		RegisterClassEx						;Регистрируем класс окна
		
		push 		NULL								;дополнительная информация(её у нас нет
		push 		hInstance							;экземпляр обработчика(опять)
		push 		NULL								;обработчик меню(отсутствует)
		push 		NULL								;Родительское окно(его тоже нет)
		push 		WindowHeight						;
		push 		WindowWidth 						;
		push		CW_USEDEFAULT						;X
		push 		CW_USEDEFAULT						;Y
		push 		WS_OVERLAPPEDWINDOW + WS_VISIBLE	;Стиль окна (нормальный + видимый)
		push 		OFFSET AppName 						;Заголовок окна, берём из переменной
		push 		OFFSET ClassName 					;Название класса из переменной
		push 		0									;биты для расширенной формы(их тоже нет
		call 		CreateWindowExA
		cmp 		eax, NULL
		je 			WinMainRet 							;Если вернули NULL - спасайся кто может
		mov 		hwnd, eax 							;Обработчик окна помещаем в eax
		
		push 		eax 								
		call 		UpdateWindow 						;заставляем окно отрисоваться сразу
		
MessageLoop:
		
		push 		0
		push 		0
		push 		NULL
		lea 		eax, msg
		push 		eax
		call 		GetMessage							;получаем сообщение от приложения
		
		cmp 		eax, 0
		je 			DoneMessages						;когда GetMessage возвращает 0, выход
		
		lea 		eax, msg
		push 		eax
		call 		TranslateMessage					;преобразовываем сообщение
		
		lea 		eax, msg 
		push 		eax
		call 		DispatchMessage						;отправляем это же сообщение
		
		jmp 		MessageLoop 						;конец цикла
		
DoneMessages:
		
		mov 		eax, msg.wParam 					;берём парметры последнего сообщения
		
WinMainRet: 		

		ret
		
WinMain endp 											;конец программы

;
;WndProc - главная процедура, обрабатывающая отрисовку и выход
;

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

		LOCAL 		ps:PAINTSTRUCT						;переменные из локального стека
		LOCAL 		rect:RECT
		LOCAL 		hdc:HDC 
		
		cmp 		uMsg, WM_DESTROY
		jne 		NotWMDestroy
		
		push 		0								;получили команду на выход
		call 		PostQuitMessage						;Выходим из приложения
		xor 		eax, eax							;возвращаем 0 чтобы подтвердить
		ret
		
NotWMDestroy:

		cmp 		uMsg, WM_PAINT
		jne 		NotWMPaint
		
		lea 		eax, ps								;WM_PAINT сообщение получено
		push		eax
		push 		hWnd
		call 		BeginPaint							;получаем параметры устройства
		mov 		hdc, eax
		
		push 		TRANSPARENT							
		push 		hdc
		call 		SetBkMode							;делаем фон текста прозрачным
		
		lea 		eax, rect 							;получаем размер
		push 		eax 								;центрируем текст
		push 		hWnd
		call 		GetClientRect 
		
		push 		DT_SINGLELINE + DT_CENTER + DT_VCENTER
		lea 		eax, rect
		push 		eax
		push 		-1
		push 		OFFSET AppName
		push 		hdc
		call 		DrawText 							;Отрисовываем текст с параметрами стека
		
		lea 		eax, ps 
		push 		eax
		push 		hWnd
		call 		EndPaint						;заканчиваем отрисовку
		
		xor 		eax, eax 							;вернуть 0
		ret
		
NotWMPaint:

		push 		lParam
		push 		wParam
		push 		uMsg
		push 		hWnd
		call 		DefWindowProc						;Получаем сообщение и возвращаем 
		ret												; всё без изменений
		
WndProc endp

;Указываем какую точку входа заканчивать. Иначе прерывает _WinMainCRTStartup

END MainEntry