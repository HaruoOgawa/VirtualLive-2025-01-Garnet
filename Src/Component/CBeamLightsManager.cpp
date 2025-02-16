#include "CBeamLightsManager.h"
#include "../../Scene/CSceneController.h"
#include "../../Object/C3DObject.h"

namespace component
{
	CBeamLightsManager::CBeamLightsManager(const std::string& ComponentName, const std::string& RegistryName) :
		CComponent(ComponentName, RegistryName)
	{
		GetValueRegistry()->SetValue("BeamHeight", graphics::EUniformValueType::VALUE_TYPE_FLOAT, &glm::vec1(0.0f)[0], sizeof(float));
	}

	CBeamLightsManager::~CBeamLightsManager()
	{
	}

	bool CBeamLightsManager::OnLoaded(api::IGraphicsAPI* pGraphicsAPI, const std::shared_ptr<scene::CSceneController>& SceneController,
		const std::shared_ptr<object::C3DObject>& Object, const std::shared_ptr<object::CNode>& SelfNode)
	{
		const int NumOfLight = 16;

		for (int ID = 1; ID <= NumOfLight; ID++)
		{
			std::string Target = "BeamLight_" + std::to_string(ID);
			const auto& BeamLight = SceneController->FindObjectByName(Target);

			if (!BeamLight) continue;

			m_LightList.push_back(BeamLight);
		}

		// ƒV[ƒ“‚Å‘€ì‰Â”\‚ÈRegstry‚Æ‚µ‚Ä“o˜^
		SceneController->SetValueRegistry(GetRegistryName(), GetValueRegistry());

		return true;
	}

	bool CBeamLightsManager::Update(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker, const std::shared_ptr<camera::CCamera>& Camera, const std::shared_ptr<projection::CProjection>& Projection,
		const std::shared_ptr<graphics::CDrawInfo>& DrawInfo, const std::shared_ptr<input::CInputState>& InputState)
	{
		float BeamHeight = GetValueRegistry()->GetValueFloat("BeamHeight");

		for (const auto& Light : m_LightList)
		{
			for (const auto& Mesh : Light->GetMeshList())
			{
				for (const auto& Primitive : Mesh->GetPrimitiveList())
				{
					for (const auto& Renderer : Primitive->GetRendererList())
					{
						const auto& Material = std::get<1>(Renderer);
						if (!Material) continue;

						Material->SetUniformValue("BeamHeight", &glm::vec1(BeamHeight)[0], sizeof(float));
					}
				}
			}
		}

		return true;
	}
}