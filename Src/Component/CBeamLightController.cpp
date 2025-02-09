#include "CBeamLightController.h"
#include "../../Scene/CSceneController.h"
#include "../../Object/C3DObject.h"

namespace component
{
	CBeamLightController::CBeamLightController(const std::string& ComponentName, const std::string& RegistryName):
		CComponent(ComponentName, RegistryName),
		m_Base_RotYaw(nullptr),
		m_Base_RotPitch(nullptr)
	{
		GetValueRegistry()->SetValue("Rot_Yaw", graphics::EUniformValueType::VALUE_TYPE_FLOAT, &glm::vec1(0.0f)[0], sizeof(float));
		GetValueRegistry()->SetValue("Rot_Pitch", graphics::EUniformValueType::VALUE_TYPE_FLOAT, &glm::vec1(-90.0f)[0], sizeof(float));
	}

	CBeamLightController::~CBeamLightController()
	{
	}

	bool CBeamLightController::OnLoaded(api::IGraphicsAPI* pGraphicsAPI, const std::shared_ptr<scene::CSceneController>& SceneController,
		const std::shared_ptr<object::C3DObject>& Object, const std::shared_ptr<object::CNode>& SelfNode)
	{
		const auto& Value = GetValueRegistry()->GetValue("LightName");
		if (Value.Buffer.empty()) return true;

		std::string LightName = std::string();
		LightName.resize(Value.Buffer.size());
		std::memcpy(&LightName[0], &Value.Buffer[0], Value.ByteSize);

		const auto& BeamLight = SceneController->FindObjectByName(LightName);

		if (!BeamLight) return true;

		m_Base_RotYaw = BeamLight->FindNodeByName("Base_RotYaw");
		m_Base_RotPitch = BeamLight->FindNodeByName("Beam_Origin");

		return true;
	}

	bool CBeamLightController::Update(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker, const std::shared_ptr<camera::CCamera>& Camera,
		const std::shared_ptr<projection::CProjection>& Projection,
		const std::shared_ptr<graphics::CDrawInfo>& DrawInfo, const std::shared_ptr<input::CInputState>& InputState)
	{
		if (!m_Base_RotYaw || !m_Base_RotPitch) return true;

		float Yaw = glm::sin(DrawInfo->GetSecondsTime()) * 45.0f;
		float Pitch = (glm::sin(DrawInfo->GetSecondsTime()) * 0.5f + 0.5f) * 90.0f;

		m_Base_RotYaw->SetRot(glm::angleAxis(glm::radians(Yaw), glm::vec3(0.0f, 1.0f, 0.0f)));
		m_Base_RotPitch->SetRot(glm::angleAxis(glm::radians(Pitch), glm::vec3(1.0f, 0.0f, 0.0f)));

		return true;
	}
}