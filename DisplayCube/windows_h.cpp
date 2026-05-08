#include <Windows.h>
#include "window_h.h"
#include <iostream>
#include <utility>


std::pair<int, int> GetGlobalMousePosition()
{
	POINT p;
	GetCursorPos(&p);
	return { (int)p.x,(int)p.y };
}
void CloseConsole()
{
	HWND console = GetConsoleWindow(); //GetConsoleWindow -  this is getting the ID number of the window and giving it to console obj
	ShowWindow(console, SW_HIDE);
}
void HideRaylibFromTaskBar(void* hwnd_)
{
	HWND hwnd = (HWND)hwnd_;
	LONG splFlags = GetWindowLong(hwnd, GWL_EXSTYLE);   // that GWL_EXSTYLE is actually an int which points to the no.of the spl flag
	SetWindowLong(hwnd, GWL_EXSTYLE, splFlags | WS_EX_TOOLWINDOW);
	//ShowWindow(hwnd, SW_HIDE);
}