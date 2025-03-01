#pragma once

#include <Scriptable/CComponent.h>
#include <vector>
#include <memory>

namespace object { class C3DObject; }
namespace object { class CNode; }

namespace component
{
	class CBeamLightsManager : public scriptable::CComponent
	{
		std::vector<std::shared_ptr<object::C3DObject>> m_LightList;
	public:
		CBeamLightsManager(const std::string& ComponentName, const std::string& RegistryName);
		virtual ~CBeamLightsManager();

		virtual bool OnLoaded(api::IGraphicsAPI* pGraphicsAPI, const std::shared_ptr<scene::CSceneController>& SceneController,
			const std::shared_ptr<object::C3DObject>& Object, const std::shared_ptr<object::CNode>& SelfNode);

		virtual bool Update(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker, const std::shared_ptr<camera::CCamera>& Camera, const std::shared_ptr<projection::CProjection>& Projection,
			const std::shared_ptr<graphics::CDrawInfo>& DrawInfo, const std::shared_ptr<input::CInputState>& InputState);
	};
}