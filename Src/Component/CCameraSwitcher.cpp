#include "CCameraSwitcher.h"

namespace component
{
	CCameraSwitcher::CCameraSwitcher(const std::string& ComponentName, const std::string& RegistryName) :
		CComponent(ComponentName, RegistryName)
	{
		GetValueRegistry()->SetValue("CameraIndex", graphics::EUniformValueType::VALUE_TYPE_INT, &glm::ivec1(-1)[0], sizeof(int));
	}

	CCameraSwitcher::~CCameraSwitcher()
	{
	}

	bool CCameraSwitcher::OnLoaded(api::IGraphicsAPI* pGraphicsAPI, const std::shared_ptr<scene::CSceneController>& SceneController,
		const std::shared_ptr<object::C3DObject>& Object, const std::shared_ptr<object::CNode>& SelfNode)
	{
		return true;
	}

	bool CCameraSwitcher::Update(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker, const std::shared_ptr<camera::CCamera>& Camera, const std::shared_ptr<projection::CProjection>& Projection,
		const std::shared_ptr<graphics::CDrawInfo>& DrawInfo, const std::shared_ptr<input::CInputState>& InputState)
	{
		return true;
	}
}