#include <iostream>
#include <raylib.h>
#include <raymath.h>
#include <utility>
#include "window_h.h"
#include <fstream>
#include <string>

std::pair<int, int> GetGlobalMousePosition();
void CloseConsole();
void HideRaylibFromTaskBar();

bool isDragging = false;

void MoveScreen(Vector2 winPos)
{
	std::pair<int, int> MousePos = GetGlobalMousePosition();
	int x = MousePos.first; int y = MousePos.second;
	if (IsMouseButtonDown(MOUSE_BUTTON_LEFT))
	{
		isDragging = true;
	}
	if (IsMouseButtonReleased(MOUSE_BUTTON_LEFT))
	{
		isDragging = false;
	}
	if (isDragging)
	{
		winPos.x -= (winPos.x - x * 0.95) * 0.03;
		winPos.y -= (winPos.y - y * 0.95) * 0.03;
		SetWindowPosition(winPos.x, winPos.y);
	}
}

class CUBE
{
private:
	Model model;
	Vector3 position;
	Texture2D texture;
	float scale;
public:
	CUBE(Model *MODEL, Vector3 Position, float Scale, Texture2D text) : model(*MODEL), position(Position), scale(Scale), 
		texture(text) {}

	void DrawCube()
	{
		//SetMaterialTexture(&model.materials[0], MATERIAL_MAP_DIFFUSE, texture);
		model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = texture;
		model.materials[0].maps[MATERIAL_MAP_DIFFUSE].color = WHITE;
		DrawModel(model, position, scale, WHITE);
	}
	void RotateCube()
	{
		static float roll = 0.0, pitch = 0.0f, yaw = 0.0f;
		roll+= 0.005; pitch+= 0.005; yaw += 0.005;
		Matrix angle = MatrixMultiply(MatrixMultiply(MatrixRotateX(roll), MatrixRotateZ(pitch)), MatrixRotateY(yaw));
		model.transform = angle;
	}
	void UpdatePositon()
	{
		float y = sin(GetTime() / 1.5) * 0.75; //Creating the since wave to move the cube up and down sin(dt) * A; A is wave magnitude    
		position = { 0.0f, y, 0.0f };
	}
};

int main()
{
	std::string path;
	std::cout << "Enter the texture path for the cube: ";
	std::cin >> path;

	const int ScreenWidth = 300, ScreenHeight = 300;
	SetConfigFlags(FLAG_BORDERLESS_WINDOWED_MODE | FLAG_WINDOW_TRANSPARENT | FLAG_WINDOW_UNDECORATED);
	InitWindow(ScreenWidth, ScreenHeight, "DisplayCube");
	SetTargetFPS(GetMonitorRefreshRate(0));

	Texture2D texture = LoadTexture(path.c_str());
	if (texture.id == 0)
	{
		std::cout << "FLUFF" << std::endl;
		return -1;
	}
	CloseConsole();

	Mesh mesh = GenMeshCube(1.0f, 1.0f, 1.0f);
	Model model = LoadModelFromMesh(mesh);
	Vector3 position = { 0.0f, 0.0f, 0.0f };
	float scale = 1.0f;

	Camera cam; 
	cam.position = Vector3{ 10.0f,10.0f, 10.0f };
	cam.fovy = 25;
	cam.target = Vector3{ 0.0f, 0.0f,0.0f };
	cam.projection = CAMERA_PERSPECTIVE;
	cam.up = Vector3{ 0.0f, 1.0f, 0.0f };

	CUBE cube(&model, position, scale, texture);
	HideRaylibFromTaskBar(GetWindowHandle());

	while (!WindowShouldClose())
	{
		Vector2 winPos = GetWindowPosition();
		Vector2 MousePos = GetMousePosition();
		MoveScreen(winPos);
		BeginDrawing();
		ClearBackground(BLANK);
		BeginMode3D(cam);
		
		cube.RotateCube();
		cube.UpdatePositon();
		cube.DrawCube();
		EndMode3D();
		EndDrawing();
	}
	UnloadTexture(texture);
	CloseWindow();
}