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
		const auto& ClipList = Object->GetAnimationClipList();
		if (ClipList.empty()) return false;

		const auto& TargetClip = ClipList[0];
		TargetClip->SetIsLoop(false); // ループはしない

		// 最初のクリップを再生
		const auto& AnimationController = Object->GetAnimationController();
		if (!AnimationController) return false;
		AnimationController->ChangeMotion(0);

		const auto& Skeleton = AnimationController->GetSkeleton();

		// VATを焼く
		// データ整形
		float LocalTime = 0.0f;
		const float FPS = 30.0f;
		const float DeltaTime = 1.0f / FPS;

		std::vector<float> TextureData;

		for (;;)
		{
			if (!AnimationController->IsPlayingAnimation()) break;

			// アニメーションを更新
			if (!AnimationController->Update(DeltaTime)) break;

			// ワールド行列再計算
			Object->CalcWorldMatrix();

			// SkinMatrixを取得
			std::vector<glm::mat4> SkinMatrixList;
			AnimationController->CalCSkinMatrixList(SkinMatrixList, glm::mat4(1.0f));

			// SkinMatrixをテクスチャ用のデータとしてストレージする
			size_t Offset = TextureData.size();
			TextureData.resize(TextureData.size() + 16 * SkinMatrixList.size());
			std::memcpy(&TextureData[Offset], &SkinMatrixList[0][0], sizeof(float) * 16 * SkinMatrixList.size());
		}

		return true;
	}
}