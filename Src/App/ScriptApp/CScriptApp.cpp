#include "CScriptApp.h"

#include <Graphics/CDrawInfo.h>
#include <Graphics/CFrameRenderer.h>

#include <Camera/CCamera.h>
#include <Camera/CTraceCamera.h>
#ifdef USE_VIEWER_CAMERA
#include <Camera/CViewerCamera.h>
#endif // USE_VIEWER_CAMERA

#include <LoadWorker/CLoadWorker.h>
#include <Projection/CProjection.h>
#include <Message/Console.h>
#include <Interface/IGUIEngine.h>
#include <Timeline/CTimelineController.h>
#include <Scene/CSceneController.h>

#include "../../GUIApp/GUI/CGraphicsEditingWindow.h"
#include "../../GUIApp/Model/CFileModifier.h"
#include "../../ImageEffect/CBloomEffect.h"

#include "../../Component/CBeamLightController.h"
#include "../../Component/CVATGenerator.h"
#include "../../Component/CBeamLightsManager.h"

namespace app
{
	CScriptApp::CScriptApp() :
		m_PlayMode(EPlayMode::Play),
		m_LocalTime(0.0f),
		m_LocalDeltaTime(0.0f),
		m_SceneController(std::make_shared<scene::CSceneController>()),
		m_CameraSwitchToggle(true),
		m_MainCamera(nullptr),
#ifdef USE_VIEWER_CAMERA
		m_ViewCamera(std::make_shared<camera::CViewerCamera>()),
#else
		m_ViewCamera(std::make_shared<camera::CCamera>()),
#endif // USE_VIEWER_CAMERA
		m_TraceCamera(std::make_shared<camera::CTraceCamera>()),
		m_Projection(std::make_shared<projection::CProjection>()),
		m_PRCamera(std::make_shared<camera::CCamera>()),
		m_PRProjection(std::make_shared<projection::CProjection>()),
		m_RPPlaneWorldMatrix(glm::mat4(1.0f)),
		m_RPPlanePos(glm::vec3(0.0f)),
		m_DrawInfo(std::make_shared<graphics::CDrawInfo>()),
#ifdef USE_GUIENGINE
		m_GraphicsEditingWindow(std::make_shared<gui::CGraphicsEditingWindow>()),
#endif // USE_GUIENGINE
		m_FileModifier(std::make_shared<CFileModifier>()),
		m_TimelineController(std::make_shared<timeline::CTimelineController>()),
		m_Liver(nullptr),
		m_BloomEffect(std::make_shared<imageeffect::CBloomEffect>("MainResultPass"))
	{
		m_ViewCamera->SetPos(glm::vec3(-7.0f, 1.0f, 0.0f));
		m_MainCamera = m_ViewCamera;

		m_DrawInfo->GetLightCamera()->SetPos(glm::vec3(0.5f, 1.5f, -1.0f));
		m_DrawInfo->GetLightProjection()->SetNear(1.0f);
		m_DrawInfo->GetLightProjection()->SetFar(10.0f);

		m_SceneController->SetDefaultPass("MainResultPass");

#ifdef _DEBUG
		m_PlayMode = EPlayMode::Stop;
#endif // _DEBUG

#ifdef USE_GUIENGINE
		m_GraphicsEditingWindow->SetDefaultPass("MainResultPass", "");
#endif
	}

	bool CScriptApp::Release(api::IGraphicsAPI* pGraphicsAPI)
	{
		return true;
	}

	bool CScriptApp::Initialize(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker)
	{
		//pLoadWorker->AddScene(std::make_shared<resource::CSceneLoader>("Resources\\Scene\\Sample.json", m_SceneController));
		pLoadWorker->AddScene(std::make_shared<resource::CSceneLoader>("Resources\\Scene\\VirtualLive.json", m_SceneController));
		//pLoadWorker->AddScene(std::make_shared<resource::CSceneLoader>("Resources\\Scene\\PBRTest.json", m_SceneController));

		// �I�t�X�N���[�������_�����O
		if (!pGraphicsAPI->CreateRenderPass("MainResultPass", api::ERenderPassFormat::COLOR_FLOAT_RENDERPASS, glm::vec4(0.0f, 0.0f, 0.0f, 1.0f), -1, -1, 1, true, false, true)) return false;
		if (!pGraphicsAPI->CreateRenderPass("ShadowPass", api::ERenderPassFormat::COLOR_FLOAT_RENDERPASS, glm::vec4(0.0f, 0.0f, 0.0f, 1.0f), -1, -1, 1, false, true, false)) return false;
		if (!pGraphicsAPI->CreateRenderPass("PlanerReflectionPass", api::ERenderPassFormat::COLOR_FLOAT_RENDERPASS, glm::vec4(0.0f, 0.0f, 0.0f, 1.0f), -1, -1, 1, true, false, false)) return false;

		// �u���[���G�t�F�N�g
		if (!m_BloomEffect->Initialize(pGraphicsAPI, pLoadWorker)) return false;

		m_MainFrameRenderer = std::make_shared<graphics::CFrameRenderer>(pGraphicsAPI, "", pGraphicsAPI->FindOffScreenRenderPass("MainResultPass")->GetFrameTextureList());
		if (!m_MainFrameRenderer->Create(pLoadWorker, "Resources\\MaterialFrame\\FrameTexture_MF.json")) return false;

		const auto& ShadowPass = pGraphicsAPI->FindOffScreenRenderPass("ShadowPass");
		if (ShadowPass)
		{
			m_SceneController->AddFrameTexture(ShadowPass->GetDepthTexture());
		}
		
		const auto& PlanerReflectionPass = pGraphicsAPI->FindOffScreenRenderPass("PlanerReflectionPass");
		if (PlanerReflectionPass)
		{
			m_SceneController->AddFrameTexture(PlanerReflectionPass->GetFrameTexture());
		}

		return true;
	}

	bool CScriptApp::ProcessInput(api::IGraphicsAPI* pGraphicsAPI)
	{
		return true;
	}

	bool CScriptApp::Resize(int Width, int Height)
	{
		m_Projection->SetScreenResolution(Width, Height);
		m_PRProjection->SetScreenResolution(Width, Height);

		m_DrawInfo->GetLightProjection()->SetScreenResolution(Width, Height);

		return true;
	}

	bool CScriptApp::Update(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker, const std::shared_ptr<input::CInputState>& InputState)
	{
		// �J�����̓��[�J�����Ԃ̉e�����󂯂����Ȃ��̂Ő�Ɍv�Z
		m_MainCamera->Update(m_DrawInfo->GetDeltaSecondsTime(), InputState);

		if (InputState->IsKeyUp(input::EKeyType::KEY_TYPE_SPACE))
		{
			m_CameraSwitchToggle = !m_CameraSwitchToggle;

			if (m_CameraSwitchToggle)
			{
				m_MainCamera = m_ViewCamera;
			}
			else
			{
				m_MainCamera = m_TraceCamera;
			}
		}

		// ���C�g�J�����̈ʒu�����҂𒆐S�Ɍ��肷��
		if(m_Liver)
		{
			glm::vec3 SceneCenter = m_Liver->GetPos();
			//glm::vec3 SceneCenter = glm::vec3(0.0f);

			const auto& LightCamera = m_DrawInfo->GetLightCamera();
			glm::vec3 LightViewDir = LightCamera->GetViewDir();

			m_DrawInfo->GetLightCamera()->SetCenter(SceneCenter);

			const float CameraLength = m_DrawInfo->GetLightProjection()->GetFar() * 0.5f;

			glm::vec3 LightPos = SceneCenter + (-1.0f) * CameraLength * LightViewDir;
			m_DrawInfo->GetLightCamera()->SetPos(LightPos);
		}

		// ���ʔ��˗p�J�����̈ʒu�����肷��
		// ���C���J�����Ɣ��˖ʂ��Ȃ�ViewDir��ʑΏۂɂ�������
		{
			glm::vec3 forwardWorldSpace = m_MainCamera->GetViewDir();
			glm::vec3 upWorldSpace = m_MainCamera->GetUpVector();
			glm::vec3 posWorldSpace = m_MainCamera->GetPos();
			glm::vec3 centerWorldSpace = m_MainCamera->GetCenter();

			// ���[���h���W�n���甽�˖ʍ��W�n�ɕϊ�
			glm::mat4 PlaneWorldMatrix = m_RPPlaneWorldMatrix;

			glm::vec3 forwardPlaneSpace = glm::inverse(PlaneWorldMatrix) * glm::vec4(forwardWorldSpace.x, forwardWorldSpace.y, forwardWorldSpace.z, 0.0f);
			glm::vec3 upPlaneSpace = glm::inverse(PlaneWorldMatrix) * glm::vec4(upWorldSpace.x, upWorldSpace.y, upWorldSpace.z, 0.0f);
			glm::vec3 posPlaneSpace = glm::inverse(PlaneWorldMatrix) * glm::vec4(posWorldSpace.x, posWorldSpace.y, posWorldSpace.z, 1.0f);
			glm::vec3 centerPlaneSpace = glm::inverse(PlaneWorldMatrix) * glm::vec4(centerWorldSpace.x, centerWorldSpace.y, centerWorldSpace.z, 1.0f);

			// �ʑΏ̂Ȉʒu�ɕϊ�
			forwardPlaneSpace.y *= -1.0f;
			upPlaneSpace.y *= -1.0f;
			posPlaneSpace.y *= -1.0f;
			centerPlaneSpace.y *= -1.0f;

			// ���˖ʍ��W�n���烏�[���h���W�n�ɖ߂�
			forwardWorldSpace = PlaneWorldMatrix * glm::vec4(forwardPlaneSpace.x, forwardPlaneSpace.y, forwardPlaneSpace.z, 0.0f);
			upWorldSpace = PlaneWorldMatrix * glm::vec4(upPlaneSpace.x, upPlaneSpace.y, upPlaneSpace.z, 0.0f);
			posWorldSpace = PlaneWorldMatrix * glm::vec4(posPlaneSpace.x, posPlaneSpace.y, posPlaneSpace.z, 1.0f);
			centerWorldSpace = PlaneWorldMatrix * glm::vec4(centerPlaneSpace.x, centerPlaneSpace.y, centerPlaneSpace.z, 1.0f);

			// ���˃J�����ɔ��˃x�N�g���𔽉f����
			m_PRCamera->SetPos(posWorldSpace);
			m_PRCamera->SetUpVector(upWorldSpace);
			m_PRCamera->SetCenter(centerWorldSpace);
		}

		//
		if (!m_FileModifier->Update(pLoadWorker)) return false;

		// �^�C�����C�������[�J�����Ԃ̉e�����󂯂����Ȃ�
		if (pLoadWorker->IsLoaded())
		{
			if (!m_TimelineController->Update(m_DrawInfo->GetDeltaSecondsTime(), InputState)) return false;
		}
		
		// �Đ�����
		{
			float PrevLocalTime = m_LocalTime;

			if (m_PlayMode == EPlayMode::Play)
			{
				// ��Ƀ^�C�����C������̍Đ����Ԃ�n��
				m_LocalTime = m_TimelineController->GetPlayBackTime();
			}

			m_LocalDeltaTime = m_LocalTime - PrevLocalTime;

			m_DrawInfo->SetSecondsTime(m_LocalTime);
			m_DrawInfo->SetDeltaSecondsTime(m_LocalDeltaTime);
		}

		if (!m_SceneController->Update(pGraphicsAPI, pPhysicsEngine, pLoadWorker, m_MainCamera, m_Projection, m_DrawInfo, InputState, m_TimelineController)) return false;

		if (!m_BloomEffect->Update(pGraphicsAPI, pPhysicsEngine, pLoadWorker, m_MainCamera, m_Projection, m_DrawInfo, InputState)) return false;
		if (!m_MainFrameRenderer->Update(pGraphicsAPI, pPhysicsEngine, pLoadWorker, m_MainCamera, m_Projection, m_DrawInfo, InputState)) return false;

		return true;
	}

	bool CScriptApp::LateUpdate(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker)
	{
		if (!m_SceneController->LateUpdate(pGraphicsAPI, pPhysicsEngine, pLoadWorker, m_DrawInfo)) return false;

		return true;
	}

	bool CScriptApp::FixedUpdate(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker)
	{
		if (!m_SceneController->FixedUpdate(pGraphicsAPI, pPhysicsEngine, pLoadWorker, m_DrawInfo)) return false;

		return true;
	}

	bool CScriptApp::Draw(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker, const std::shared_ptr<input::CInputState>& InputState,
		const std::shared_ptr<gui::IGUIEngine>& GUIEngine)
	{
		// ShadowPass
		{
			if (!pGraphicsAPI->BeginRender("ShadowPass")) return false;
			// Camera��Projection�ɂ̓��C�g�p�̒l���g�p����悤�ɒ��ӂ���
			if (!m_SceneController->Draw(pGraphicsAPI, m_DrawInfo->GetLightCamera(), m_DrawInfo->GetLightProjection(), m_DrawInfo)) return false;
			
			if (!pGraphicsAPI->EndRender()) return false;
		}

		// PlanerReflectionPass
		{
			m_DrawInfo->SetSpatialCulling(true);
			m_DrawInfo->SetSpatialCullPos(glm::vec4(m_RPPlanePos.x, m_RPPlanePos.y, m_RPPlanePos.z, 1.0f));

			if (!pGraphicsAPI->BeginRender("PlanerReflectionPass")) return false;
			if (!m_SceneController->Draw(pGraphicsAPI, m_PRCamera, m_PRProjection, m_DrawInfo)) return false;
			if (!pGraphicsAPI->EndRender()) return false;

			m_DrawInfo->SetSpatialCulling(false);
		}
		
		// MainResultPass
		{
			if (!pGraphicsAPI->BeginRender("MainResultPass")) return false;
			if (!m_SceneController->Draw(pGraphicsAPI, m_MainCamera, m_Projection, m_DrawInfo)) return false;
			if (!pGraphicsAPI->EndRender()) return false;
		}

		// BloomEffect
		if (!m_BloomEffect->Draw(pGraphicsAPI, m_MainCamera, m_Projection, m_DrawInfo)) return false;

		// Main FrameBuffer
		{
			if (!pGraphicsAPI->BeginRender()) return false;

			if (!m_MainFrameRenderer->Draw(pGraphicsAPI, m_MainCamera, m_Projection, m_DrawInfo)) return false;

			// GUIEngine
#ifdef USE_GUIENGINE
			if (pLoadWorker->IsLoaded())
			{
				gui::SGUIParams GUIParams = gui::SGUIParams(shared_from_this(), GetObjectList(), m_SceneController, m_FileModifier, m_TimelineController, pLoadWorker, {}, pPhysicsEngine);
				GUIParams.CameraMode = (m_CameraSwitchToggle) ? "ViewCamera" : "TraceCamera";
				GUIParams.Camera = m_MainCamera;
				GUIParams.InputState = InputState;
				GUIParams.ValueRegistryList.emplace(m_BloomEffect->GetRegistryName(), m_BloomEffect);

				if (!GUIEngine->BeginFrame(pGraphicsAPI)) return false;
				if (!m_GraphicsEditingWindow->Draw(pGraphicsAPI, GUIParams, GUIEngine))
				{
					Console::Log("[Error] InValid GUI\n");
					return false;
				}
				if (!GUIEngine->EndFrame(pGraphicsAPI)) return false;
			}
#endif // USE_GUIENGINE

			if (!pLoadWorker->Draw(pGraphicsAPI, m_MainCamera, m_Projection, m_DrawInfo)) return false;

			if (!pGraphicsAPI->EndRender()) return false;
		}

		return true;
	}

	std::shared_ptr<graphics::CDrawInfo> CScriptApp::GetDrawInfo() const
	{
		return m_DrawInfo;
	}

	// �R���|�[�l���g�쐬
	std::shared_ptr<scriptable::CComponent> CScriptApp::CreateComponent(const std::string& ComponentType, const std::string& ValueRegistry)
	{
		if (ComponentType == "BeamLightController")
		{
			return std::make_shared<component::CBeamLightController>(ComponentType, ValueRegistry);
		}
		else if (ComponentType == "VATGenerator")
		{
			return std::make_shared<component::CVATGenerator>(ComponentType, ValueRegistry);
		}
		else if (ComponentType == "BeamLightsManager")
		{
			return std::make_shared<component::CBeamLightsManager>(ComponentType, ValueRegistry);
		}

		return nullptr;
	}

	// �N����������
	bool CScriptApp::OnStartup(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker, const std::shared_ptr<gui::IGUIEngine>& GUIEngine)
	{
		const auto& TimelineFileName = m_SceneController->GetTimelineFileName();
		if (!TimelineFileName.empty()) pLoadWorker->AddLoadResource(std::make_shared<resource::CTimelineClipLoader>(TimelineFileName, m_TimelineController->GetClip()));

		return true;
	}

	// ���[�h�����C�x���g
	bool CScriptApp::OnLoaded(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker, const std::shared_ptr<gui::IGUIEngine>& GUIEngine)
	{
		if (!m_SceneController->Create(pGraphicsAPI, pPhysicsEngine)) return false;

		m_BloomEffect->OnLoaded(m_SceneController);

		if (!m_TimelineController->Initialize(shared_from_this())) return false;

#ifdef USE_GUIENGINE
		{
			gui::SGUIParams GUIParams = gui::SGUIParams(shared_from_this(), GetObjectList(), m_SceneController, m_FileModifier, m_TimelineController, pLoadWorker, {}, pPhysicsEngine);

			if (!m_GraphicsEditingWindow->OnLoaded(pGraphicsAPI, GUIParams, GUIEngine)) return false;
		}
#endif

		// �J����
		{
			const auto& Object = m_SceneController->FindObjectByName("CameraObject");
			if (Object)
			{
				const auto& Node = Object->FindNodeByName("CameraNode");

				if (Node)
				{
					m_TraceCamera->SetTargetNode(Node);
				}
			}
		}

		// �V���h�E�}�b�s���O
		{
			m_Liver = m_SceneController->FindObjectByName("Performer");
		}

		// ���ʔ��˂̍��W���w��
		{
			m_RPPlanePos = glm::vec3(0.0f, 0.125f, 0.0f);
			m_RPPlaneWorldMatrix = glm::translate(glm::mat4(1.0f), m_RPPlanePos);
		}

		return true;
	}

	// �t�H�[�J�X�C�x���g
	void CScriptApp::OnFocus(bool Focused, api::IGraphicsAPI* pGraphicsAPI, resource::CLoadWorker* pLoadWorker)
	{
		if (Focused && pLoadWorker)
		{
			m_FileModifier->OnFileUpdated(pLoadWorker);
		}
	}

	// �G���[�ʒm�C�x���g
	void CScriptApp::OnAssertError(const std::string& Message)
	{
#ifdef USE_GUIENGINE
		m_GraphicsEditingWindow->AddLog(gui::EGUILogType::Error, Message);
#endif
	}

	// �^�C�����C���Đ���~�C�x���g
	void CScriptApp::OnPlayedTimeline(bool IsPlay)
	{
		//
		if (IsPlay)
		{
			m_PlayMode = EPlayMode::Play;
			// �^�C�����C���̍Đ����Ԃ���ĊJ����
			m_LocalTime = m_TimelineController->GetPlayBackTime();
		}
		else
		{
			m_PlayMode = EPlayMode::Pause;
		}

		//
		const auto& Sound = m_SceneController->GetSound();
		const auto& SoundClip = std::get<0>(Sound);
		if (SoundClip)
		{
			if (IsPlay)
			{
				SoundClip->SetPlayPos(m_TimelineController->GetPlayBackTime());
				SoundClip->PlayOneShot();

				for (const auto& Object : m_SceneController->GetObjectList())
				{
					// Animation
					{
						const auto& Clip = Object->GetAnimationController()->GetCurrentClip();
						if (Clip)
						{
							Clip->SetCurrentTime(m_TimelineController->GetPlayBackTime());
						}
					}

					// BlendShape
					{
						const auto& PlayingBlendShapeSet = Object->GetBlendShapeController()->GetPlayingBlendShapeSet();
						const auto& BlendShapeClipMap = Object->GetBlendShapeController()->GetBlendShapeClipMap();

						for (const auto& Name : PlayingBlendShapeSet)
						{
							const auto& Clip = BlendShapeClipMap.find(Name);
							if (Clip == BlendShapeClipMap.end()) continue;

							Clip->second->SetCurrentTime(m_TimelineController->GetPlayBackTime());
						}
					}
				}
			}
			else
			{
				SoundClip->Stop();
			}
		}
	}

	// �V�[���Đ����[�h�ύX�C�x���g
	void CScriptApp::OnChangeScenePlayMode(const std::string& Mode)
	{
		if (Mode == "Play")
		{
			m_PlayMode = EPlayMode::Play;
			m_TimelineController->Play();
		}
		else if (Mode == "Stop")
		{
			m_PlayMode = EPlayMode::Stop;

			m_LocalTime = 0.0f;
			m_LocalDeltaTime = 0.0f;

			m_TimelineController->Stop();
			m_TimelineController->SetPlayBackTime(0.0f);
			m_SceneController->Reset();
		}
		else if (Mode == "Pause")
		{
			m_PlayMode = EPlayMode::Pause;

			m_TimelineController->Stop();
		}
	}

	// Getter
	std::vector<std::shared_ptr<object::C3DObject>> CScriptApp::GetObjectList() const
	{
		std::vector<std::shared_ptr<object::C3DObject>> ObjectList;

		for (const auto& Object : m_SceneController->GetObjectList())
		{
			ObjectList.push_back(Object);
		}

		return ObjectList;
	}

	std::shared_ptr<scene::CSceneController> CScriptApp::GetSceneController() const
	{
		return m_SceneController;
	}
}