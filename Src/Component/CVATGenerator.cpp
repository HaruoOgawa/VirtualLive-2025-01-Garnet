#include "CVATGenerator.h"
#include "../../Scene/CSceneController.h"
#include "../../Object/C3DObject.h"
#include "../../Debug/Message/Console.h"

namespace component
{
	CVATGenerator::CVATGenerator(const std::string& ComponentName, const std::string& RegistryName) :
		CComponent(ComponentName, RegistryName)
	{
	}

	CVATGenerator::~CVATGenerator()
	{
	}

	bool CVATGenerator::OnLoaded(api::IGraphicsAPI* pGraphicsAPI, const std::shared_ptr<scene::CSceneController>& SceneController,
		const std::shared_ptr<object::C3DObject>& Object, const std::shared_ptr<object::CNode>& SelfNode)
	{
		Console::Log("[CPP] CVATGenerator::OnLoaded\n");

		return true;
	}
}