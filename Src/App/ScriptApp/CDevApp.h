#pragma once

#include <memory>
#include <AppCore/CApp.h>

namespace graphics { class CFrameRenderer; }
namespace gui { class CGraphicsEditingWindow; }
namespace timeline { class CTimelineController; }
namespace scene { class CSceneController; }
namespace camera { class CTraceCamera; }

namespace app
{
	enum class EPlayMode
	{
		Play,
		Stop,
		Pause,
	};

	class CFileModifier;

	class CDevApp : public CApp
	{
		EPlayMode m_PlayMode;
		float	  m_LocalTime;
		float	  m_LocalDeltaTime;

		std::shared_ptr<scene::CSceneController> m_SceneController;

		std::shared_ptr<camera::CCamera> m_MainCamera;
		std::shared_ptr<camera::CCamera> m_ViewCamera;
		std::shared_ptr<camera::CTraceCamera> m_TraceCamera;
		std::shared_ptr<projection::CProjection> m_Projection;
		std::shared_ptr<graphics::CDrawInfo> m_DrawInfo;
		std::shared_ptr<imageeffect::CBlurEffect> m_BlurEffect;
		std::shared_ptr<graphics::CFrameRenderer> m_DeferredRenderer;
		std::shared_ptr<graphics::CFrameRenderer> m_MainFrameRenderer;

		std::shared_ptr<CFileModifier> m_FileModifier;
#ifdef USE_GUIENGINE
		std::shared_ptr<gui::CGraphicsEditingWindow> m_GraphicsEditingWindow;
#endif // USE_GUIENGINE

		std::shared_ptr<timeline::CTimelineController> m_TimelineController;

		bool m_CameraSwitchToggle;

	public:
		CDevApp();
		virtual ~CDevApp() = default;

		virtual bool Release(api::IGraphicsAPI* pGraphicsAPI) override;

		virtual bool Initialize(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker) override;
		virtual bool ProcessInput(api::IGraphicsAPI* pGraphicsAPI) override;
		virtual bool Resize(int Width, int Height) override;
		virtual bool Update(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker, const std::shared_ptr<input::CInputState>& InputState) override;
		virtual bool LateUpdate(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker) override;
		virtual bool FixedUpdate(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker) override;

		virtual bool Draw(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker, const std::shared_ptr<input::CInputState>& InputState, 
			const std::shared_ptr<gui::IGUIEngine>& GUIEngine) override;

		virtual std::shared_ptr<graphics::CDrawInfo> GetDrawInfo() const override;

		// �N����������
		virtual bool OnStartup(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker, const std::shared_ptr<gui::IGUIEngine>& GUIEngine) override;

		// ���[�h�����C�x���g
		virtual bool OnLoaded(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker, const std::shared_ptr<gui::IGUIEngine>& GUIEngine) override;

		// �t�H�[�J�X�C�x���g
		virtual void OnFocus(bool Focused, api::IGraphicsAPI* pGraphicsAPI, resource::CLoadWorker* pLoadWorker) override;

		// �G���[�ʒm�C�x���g
		virtual void OnAssertError(const std::string& Message) override;

		// Getter
		virtual std::vector<std::shared_ptr<object::C3DObject>> GetObjectList() const override;
		virtual std::shared_ptr<scene::CSceneController> GetSceneController() const override;

		// �J�������[�h�ύX�C�x���g
		virtual void OnChangeCameraMode(const std::string& Mode) override;

		// �V�[���Đ����[�h�ύX�C�x���g
		virtual void OnChangeScenePlayMode(const std::string& Mode) override;
	};
}