#pragma once

#include <Scriptable/CComponent.h>

namespace object { class CNode; }

namespace component
{
	class CBeamLightController : public scriptable::CComponent
	{
		std::shared_ptr<object::CNode> m_Base_RotYaw;
		std::shared_ptr<object::CNode> m_Base_RotPitch;
	public:
		CBeamLightController(const std::string& ComponentName, const std::string& RegistryName);
		virtual ~CBeamLightController();

		virtual bool OnLoaded(api::IGraphicsAPI* pGraphicsAPI, const std::shared_ptr<scene::CSceneController>& SceneController,
			const std::shared_ptr<object::C3DObject>& Object, const std::shared_ptr<object::CNode>& SelfNode);

		virtual bool Update(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker, const std::shared_ptr<camera::CCamera>& Camera, const std::shared_ptr<projection::CProjection>& Projection,
			const std::shared_ptr<graphics::CDrawInfo>& DrawInfo, const std::shared_ptr<input::CInputState>& InputState);
	};
}