#pragma once
#include <memory>
#include <AppCore/CApp.h>

namespace graphics { class CFrameRenderer; }
namespace gui { class CGraphicsEditingWindow; }
namespace timeline { class CTimelineController; }
namespace scene { class CSceneController; }
namespace camera { class CTraceCamera; }
namespace imageeffect {
	class CBloomEffect;
}

namespace app
{
	enum class EPlayMode
	{
		Play,
		Stop,
		Pause,
	};

	class CFileModifier;

	class CScriptApp : public CApp
	{
		std::shared_ptr<scene::CSceneController> m_SceneController;

		//
		std::shared_ptr<camera::CCamera> m_MainCamera;
		std::shared_ptr<camera::CCamera> m_ViewCamera;
		std::shared_ptr<camera::CTraceCamera> m_TraceCamera;
		std::shared_ptr<projection::CProjection> m_Projection;

		// 平面反射(Planer Reflection)
		std::shared_ptr<camera::CCamera>		 m_PRCamera;
		std::shared_ptr<projection::CProjection> m_PRProjection;
		glm::mat4								 m_RPPlaneWorldMatrix;
		glm::vec3								 m_RPPlanePos;

		//
		std::shared_ptr<graphics::CDrawInfo> m_DrawInfo;

		std::shared_ptr<graphics::CFrameRenderer> m_MainFrameRenderer;

		std::shared_ptr<CFileModifier> m_FileModifier;
#ifdef USE_GUIENGINE
		std::shared_ptr<gui::CGraphicsEditingWindow> m_GraphicsEditingWindow;
#endif // USE_GUIENGINE

		std::shared_ptr<timeline::CTimelineController> m_TimelineController;

		bool m_CameraSwitchToggle;

		EPlayMode m_PlayMode;
		float	  m_LocalTime;
		float	  m_LocalDeltaTime;

		std::shared_ptr<object::C3DObject> m_Liver;

		std::shared_ptr<imageeffect::CBloomEffect> m_BloomEffect;

	public:
		CScriptApp();
		virtual ~CScriptApp() = default;

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

		// 起動準備完了
		virtual bool OnStartup(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker, const std::shared_ptr<gui::IGUIEngine>& GUIEngine) override;

		// ロード完了イベント
		virtual bool OnLoaded(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker, const std::shared_ptr<gui::IGUIEngine>& GUIEngine) override;

		// フォーカスイベント
		virtual void OnFocus(bool Focused, api::IGraphicsAPI* pGraphicsAPI, resource::CLoadWorker* pLoadWorker) override;

		// エラー通知イベント
		virtual void OnAssertError(const std::string& Message) override;

		// タイムライン再生停止イベント
		virtual void OnPlayedTimeline(bool IsPlay) override;

		// シーン再生モード変更イベント
		virtual void OnChangeScenePlayMode(const std::string& Mode) override;

		// Getter
		virtual std::vector<std::shared_ptr<object::C3DObject>> GetObjectList() const override;
		virtual std::shared_ptr<scene::CSceneController> GetSceneController() const override;
	};
}