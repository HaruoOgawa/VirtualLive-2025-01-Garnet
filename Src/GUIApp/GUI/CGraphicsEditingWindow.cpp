#ifdef USE_GUIENGINE
#include "CGraphicsEditingWindow.h"
#include "../../Message/Console.h"
#include <Scene/CSceneWriter.h>
#include <Input/CInputState.h>

namespace gui
{
	CGraphicsEditingWindow::CGraphicsEditingWindow():
		m_ShowSavedDialog(false)
	{
	}

	CGraphicsEditingWindow::~CGraphicsEditingWindow()
	{
	}

	// ���[�h�����C�x���g
	bool CGraphicsEditingWindow::OnLoaded(api::IGraphicsAPI* pGraphicsAPI, const SGUIParams& GUIParams, const std::shared_ptr<gui::IGUIEngine>& GUIEngine)
	{
		if (!m_TimeLineView.Initialize(GUIParams)) return false;

		return true;
	}

	bool CGraphicsEditingWindow::Draw(api::IGraphicsAPI* pGraphicsAPI, const SGUIParams& GUIParams, const std::shared_ptr<gui::IGUIEngine>& GUIEngine)
	{
		// �E�B���h�E�̏����ʒu�E�T�C�Y
		float padding = 0.0f;
		ImGuiIO& io = ImGui::GetIO();

		const float MainMenuWidthRate = 0.25f;
		const float TimeLineHeightRate = 0.25f;

		// MainMenuView
		{
			ImGui::SetNextWindowPos(ImVec2(io.DisplaySize.x - padding, padding), ImGuiCond_Always, ImVec2(1.0f, 0.0f));
			ImGui::SetNextWindowSize(ImVec2(io.DisplaySize.x * MainMenuWidthRate, io.DisplaySize.y), ImGuiCond_Always);

			bool Open = true;
			if (ImGui::Begin("MainMenuView", &Open, ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoSavedSettings | ImGuiWindowFlags_NoTitleBar))
			{
				if (ImGui::BeginTabBar("MainMenuBar"))
				{
					if (!m_GUIObjectTab.Draw(pGraphicsAPI, GUIParams)) return false;
					if (!m_GUIResourcesTab.Draw(GUIParams.FileModifier)) return false;
					if (!m_MaterialFrameTab.Draw(pGraphicsAPI, GUIParams)) return false;
					if (!m_LogTab.Draw(pGraphicsAPI, GUIParams)) return false;
					if (!CGUIRenderingTab::Draw()) return false;
					if (!CGUICameraTab::Draw()) return false;
					if (!CGUICustomTab::Draw(pGraphicsAPI, GUIParams)) return false;
					if (!CGUIAnimationTab::DrawClipList(GUIParams)) return false;

					ImGui::EndTabBar();
				}
			}

			ImGui::End();
		}

		// TimeLineView
		{
			ImGui::SetNextWindowPos(ImVec2(padding, io.DisplaySize.y - padding), ImGuiCond_Always, ImVec2(0.0f, 1.0f));
			ImGui::SetNextWindowSize(ImVec2(io.DisplaySize.x * (1.0f - MainMenuWidthRate), io.DisplaySize.y * TimeLineHeightRate), ImGuiCond_Always);

			bool Open = true;
			if (ImGui::Begin("TimeLineView", &Open, ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoSavedSettings | ImGuiWindowFlags_NoTitleBar))
			{
				if (!m_TimeLineView.Draw(GUIParams)) return false;
			}

			ImGui::End();
		}

		// 3DView
		{
			ImGui::SetNextWindowPos(ImVec2(padding, io.DisplaySize.y * (1.0f - TimeLineHeightRate)), ImGuiCond_Always, ImVec2(0.0f, 1.0f));
			ImGui::SetNextWindowSize(ImVec2(io.DisplaySize.x * (1.0f - MainMenuWidthRate), io.DisplaySize.y * (1.0f - TimeLineHeightRate)), ImGuiCond_Always);

			bool Open = true;

			ImGuiWindowFlags flags = ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoSavedSettings |
				ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoInputs;

			if (ImGui::Begin("3DView", &Open, flags))
			{
				ImVec2 WindowSize = ImGui::GetWindowSize();
				ImVec2 ImageSize = ImVec2(io.DisplaySize.x * (1.0f - TimeLineHeightRate), io.DisplaySize.y * (1.0f - TimeLineHeightRate));

				if (!m_3DView.Draw(pGraphicsAPI, GUIParams, GUIEngine, WindowSize, ImageSize)) return false;
			}

			ImGui::End();
		}

		// �V�[���ۑ�
#ifdef USE_BINARY_WRITE
		if ( (ImGui::IsKeyDown(ImGuiKey_LeftCtrl) && ImGui::IsKeyReleased(ImGuiKey_S)) || (GUIParams.InputState->IsKeyDown(input::EKeyType::KEY_TYPE_CONTROL) && GUIParams.InputState->IsKeyUp(input::EKeyType::KEY_TYPE_S)) )
		{
			if (!scene::CSceneWriter::Write(GUIParams.SceneController.get(), GUIParams.TimelineController, GUIParams.pPhysicsEngine)) return false;

			m_ShowSavedDialog = true;
		}
#endif

		if (m_ShowSavedDialog)
		{
			ImVec2 DisplaySize = io.DisplaySize;
			ImVec2 WindowSize = ImVec2(DisplaySize.x * 0.25f, DisplaySize.y * 0.25f);
			ImVec2 WindowPos = ImVec2(DisplaySize.x * 0.5f - WindowSize.x * 0.5f, DisplaySize.y * 0.5f - WindowSize.y * 0.5f);

			ImGui::SetNextWindowPos(WindowPos, ImGuiCond_Appearing, ImVec2(0.0f, 0.0f));
			ImGui::SetNextWindowSize(WindowSize, ImGuiCond_Appearing);

			if (ImGui::Begin("##Timeline_SavedScene_Dialog", &m_ShowSavedDialog))
			{
				ImVec2 CursorPos = ImGui::GetCursorPos();

				ImGui::Text("The scene was saved successfully.");

				if (ImGui::Button("OK##Timeline_SavedScene_Dialog"))
				{
					m_ShowSavedDialog = false;
				}

				if (ImGui::IsKeyReleased(ImGuiKey_Enter) || GUIParams.InputState->IsKeyUp(input::EKeyType::KEY_TYPE_ENTER))
				{
					m_ShowSavedDialog = false;
				}
			}

			ImGui::End();
		}

		return true;
	}

	void CGraphicsEditingWindow::AddLog(gui::EGUILogType LogType, const std::string Msg)
	{
		m_LogTab.AddLog(LogType, Msg);
	}

	void CGraphicsEditingWindow::SetDefaultPass(const std::string& RenderPass, const std::string& DepthPass)
	{
		m_3DView.SetDefaultPass(RenderPass, DepthPass);
	}
}
#endif // USE_GUIENGINE