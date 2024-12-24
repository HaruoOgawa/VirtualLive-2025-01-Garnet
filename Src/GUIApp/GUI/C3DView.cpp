#ifdef USE_GUIENGINE
#include "C3DView.h"
#include <AppCore/CApp.h>
#include <Camera/CCamera.h>

namespace gui
{
	C3DView::C3DView():
		m_IsFullScreen(true),
		m_SelectedPassName(std::string()),
		m_SelectedTextureIndex(0)
	{
	}

	bool C3DView::IsFullScreen() const
	{
		return m_IsFullScreen;
	}

	void C3DView::SetDefaultPass(const std::string& RenderPass, const std::string& DepthPass)
	{
		m_SelectedPassName = RenderPass;
	}

	bool C3DView::Draw(api::IGraphicsAPI* pGraphicsAPI, const SGUIParams& GUIParams, const std::shared_ptr<gui::IGUIEngine>& GUIEngine, const ImVec2& WindowSize, const ImVec2& FullImageSize)
	{
		// F2�L�[�Ńt���X�N���[���`�悩���X�g�`�悩��؂�ւ���
		if (ImGui::IsKeyReleased(ImGuiKey_F2))
		{
			m_IsFullScreen = !m_IsFullScreen;
		}

		const float Rate = 0.025f;

		if (!DrawOption(ImVec2(WindowSize.x , WindowSize.y * Rate), GUIParams)) return false;

		if (m_IsFullScreen)
		{
			if (!DrawFullScreen(pGraphicsAPI, GUIParams, GUIEngine, ImVec2(WindowSize.x, WindowSize.y * (1.0f - Rate)), FullImageSize)) return false;
		}
		else
		{
			if (!DrawPassList(pGraphicsAPI, GUIParams, GUIEngine, ImVec2(WindowSize.x, WindowSize.y * (1.0f - Rate)), FullImageSize)) return false;
		}

		return true;
	}

	bool C3DView::DrawOption(const ImVec2& WindowSize, const SGUIParams& GUIParams)
	{
		if (ImGui::BeginChild("C3DView::DrawOption", WindowSize))
		{
			{
				// Play
				std::string PlayLabel = "Play##C3DView::DrawOption";
				if (ImGui::Button(PlayLabel.c_str(), ImVec2(0, WindowSize.y)))
				{
					GUIParams.App->OnChangeScenePlayMode("Play");
				}

				// Stop
				ImGui::SameLine();
				std::string StopLabel = "Stop##C3DView::DrawOption";
				if (ImGui::Button(StopLabel.c_str(), ImVec2(0, WindowSize.y)))
				{
					GUIParams.App->OnChangeScenePlayMode("Stop");
				}

				// Pause
				ImGui::SameLine();
				std::string PauseLabel = "Pause##C3DView::DrawOption";
				if (ImGui::Button(PauseLabel.c_str(), ImVec2(0, WindowSize.y)))
				{
					GUIParams.App->OnChangeScenePlayMode("Pause");
				}
			}

			{
				ImGui::SameLine();

				// ���Ԃ�{�^���̍ŏ��T�C�Y�݂����Ȃ̂�Window����������������ƌ����Ȃ��Ȃ�݂���(��������d�l�Ƃ���B���i�g���ɂ͎x�Ⴊ�Ȃ�����)
				std::string WindowModeLavel = (m_IsFullScreen ? "FrameBuffers" : "3DView");
				WindowModeLavel += "##C3DView::DrawOption";

				if (ImGui::Button(WindowModeLavel.c_str(), ImVec2(0, WindowSize.y)))
				{
					m_IsFullScreen = !m_IsFullScreen;
				}
			}

			{
				// ���Ԃ�{�^���̍ŏ��T�C�Y�݂����Ȃ̂�Window����������������ƌ����Ȃ��Ȃ�݂���(��������d�l�Ƃ���B���i�g���ɂ͎x�Ⴊ�Ȃ�����)
				ImGui::SameLine();
				
				std::string WindowModeLavel = GUIParams.CameraMode;
				WindowModeLavel += "##C3DView::DrawOption_CameraMode";

				if (ImGui::Button(WindowModeLavel.c_str(), ImVec2(0, WindowSize.y)))
				{
					GUIParams.App->OnChangeCameraMode(std::string());
				}
			}

			if(GUIParams.Camera)
			{
				ImGui::SameLine();

				const auto& CameraPos = GUIParams.Camera->GetPos();
				ImGui::Text("[CameraPos] x: %f, y: %f, z: %f", CameraPos.x, CameraPos.y, CameraPos.z);
			}

			ImGui::EndChild();
		}

		return true;
	}

	bool C3DView::DrawFullScreen(api::IGraphicsAPI* pGraphicsAPI, const SGUIParams& GUIParams, const std::shared_ptr<gui::IGUIEngine>& GUIEngine, const ImVec2& WindowSize, const ImVec2& FullImageSize)
	{
		// �t���X�N���[�����̓C���v�b�g���󂯎��Ȃ�
		ImGuiWindowFlags flags = ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoSavedSettings |
			ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoInputs;

		if(ImGui::BeginChild("C3DView::DrawFullScreen", ImVec2(0, 0), 0, flags))
		{
			auto RenderPass = pGraphicsAPI->FindOffScreenRenderPass(m_SelectedPassName);

			auto Core = GUIEngine->GetImGuiCore();

			if (RenderPass && Core)
			{
				// �e�E�B���h�E�̒��S�ɔz�u
				ImVec2 ImagePos = ImVec2(
					(WindowSize.x - FullImageSize.x) * 0.5f,
					(WindowSize.y - FullImageSize.y) * 0.5f
				);
				ImGui::SetCursorPos(ImagePos);

				ImVec2 UV0 = ImVec2(0.0f, 0.0f);
				ImVec2 UV1 = ImVec2(1.0f, 1.0f);
#ifdef USE_OPENGL
				// OpenGL���͏㉺���]����̂ŕ␳����
				UV0 = ImVec2(0.0f, 1.0f);
				UV1 = ImVec2(1.0f, 0.0f);
#endif // USE_OPENGL

				const auto& FrameTexture = RenderPass->GetFrameTexture(m_SelectedTextureIndex);
				if (!FrameTexture) return true;

				ImGui::Image(Core->CastTexID(FrameTexture.get()), FullImageSize, UV0, UV1);
			}

			ImGui::EndChild();
		}

		return true;
	}

	bool C3DView::DrawPassList(api::IGraphicsAPI* pGraphicsAPI, const SGUIParams& GUIParams, const std::shared_ptr<gui::IGUIEngine>& GUIEngine, const ImVec2& WindowSize, const ImVec2& FullImageSize)
	{
		ImGuiWindowFlags flags = ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoSavedSettings |
			ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoScrollbar;

		if (ImGui::BeginChild("C3DView::DrawPassList", ImVec2(0, 0), 0, flags))
		{
			auto Core = GUIEngine->GetImGuiCore();
			if (!Core) return true;

			// ���ɉ����܂ŕ��ׂ邩
			const float SideOrderCount = 5.0f;

			ImVec2 UV0 = ImVec2(0.0f, 0.0f);
			ImVec2 UV1 = ImVec2(1.0f, 1.0f);
#ifdef USE_OPENGL
			// OpenGL���͏㉺���]����̂ŕ␳����
			UV0 = ImVec2(0.0f, 1.0f);
			UV1 = ImVec2(1.0f, 0.0f);
#endif // USE_OPENGL

			const ImVec2 ImageSize = ImVec2(FullImageSize.x / SideOrderCount, FullImageSize.y / SideOrderCount);

			//
			int RenderPassIndex = 0;
			float TexCount = 0.0f;

			const ImVec2 CursorScreenPos = ImGui::GetCursorScreenPos();

			float XIndex = 0.0f;
			float YIndex = 0.0f;

			// PassName�̃T�C�Y
			const float PassNameHeight = 25.0f;

			for (const auto& RenderPassPair : pGraphicsAPI->GetOffScreenRenderPassMap())
			{
				const auto& PassName = RenderPassPair.first;
				const auto& RenderPass = RenderPassPair.second;

				const auto& FrameTextureList = RenderPass->GetFrameTextureList();

				for (int TextureIndex = 0; TextureIndex < static_cast<int>(FrameTextureList.size()); TextureIndex++)
				{
					const auto& FrameTexture = FrameTextureList[TextureIndex];

					//
					ImVec2 DrawCursorScreenPos = ImVec2(CursorScreenPos.x + ImageSize.x * XIndex, CursorScreenPos.y + (ImageSize.y + PassNameHeight * 1.5f) * YIndex);
					ImGui::SetCursorScreenPos(DrawCursorScreenPos);

					if (ImGui::ImageButton(Core->CastTexID(FrameTexture.get()), ImageSize, UV0, UV1, 1))
					{
						m_IsFullScreen = true;

						m_SelectedPassName = PassName;
						m_SelectedTextureIndex = TextureIndex;
					}

					//
					DrawCursorScreenPos.y += (ImageSize.y + PassNameHeight * 0.5f);
					ImGui::SetCursorScreenPos(DrawCursorScreenPos);

					std::string LabelText = PassName + "_" + std::to_string(TextureIndex);
					ImGui::Text(LabelText.c_str());

					TexCount++;

					XIndex++;
					if (XIndex >= SideOrderCount)
					{
						XIndex = 0.0f;
						YIndex++;
					}
				}

				RenderPassIndex++;
			}

			ImGui::EndChild();
		}

		return true;
	}
}
#endif // USE_GUIENGINE