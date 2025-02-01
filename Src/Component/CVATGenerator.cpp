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
		TargetClip->SetIsLoop(false); // ���[�v�͂��Ȃ�

		// �ŏ��̃N���b�v���Đ�
		const auto& AnimationController = Object->GetAnimationController();
		if (!AnimationController) return false;
		AnimationController->ChangeMotion(0);

		const auto& Skeleton = AnimationController->GetSkeleton();

		// VAT���Ă�
		// �f�[�^���`
		float LocalTime = 0.0f;
		const float FPS = 30.0f;
		const float DeltaTime = 1.0f / FPS;

		std::vector<unsigned char> TextureData;

		int NumOfFrame = 0;

		for (;;)
		{
			if (!AnimationController->IsPlayingAnimation()) break;

			// �A�j���[�V�������X�V
			if (!AnimationController->Update(DeltaTime)) break;

			// ���[���h�s��Čv�Z
			Object->CalcWorldMatrix();

			// SkinMatrix���擾
			std::vector<glm::mat4> SkinMatrixList;
			AnimationController->CalCSkinMatrixList(SkinMatrixList, glm::mat4(1.0f));

			// SkinMatrix���e�N�X�`���p�̃f�[�^�Ƃ��ăX�g���[�W����
			size_t ByteOffset = TextureData.size();
			size_t ByteSize = sizeof(float) * 16 * SkinMatrixList.size();

			TextureData.resize(TextureData.size() + ByteSize);
			std::memcpy(&TextureData[ByteOffset], &SkinMatrixList[0][0], ByteSize);

			// �t���[����
			NumOfFrame++;
		}

		// vec4��1��1�s�N�Z���Ƃ���̂�mat4�^(�܂�1��SkinMatrix)��4�s�N�Z���ō\�������
		// ���ꂪ�{�[�����������݂���̂ł������l���������̂��e�N�X�`���̕��ƂȂ�
		int TextureWidth = static_cast<int>(Skeleton->GetBoneList().size()) * (16 / 4);

		// �c�Ƀ{�[���̃t���[�����Ƃ̃f�[�^�����Ԃ̂Ńt���[���������̂܂܃e�N�X�`���̍����ɂȂ�
		int TextureHeight = NumOfFrame;

		// �e�N�X�`���𐶐�
		auto VertexAnimationTexture = pGraphicsAPI->CreateTexture();
		if (!VertexAnimationTexture->Create(TextureData, TextureWidth, TextureHeight, 4)) return false;

		// �I�u�W�F�N�g�ɓn��
		int TextureIndex = static_cast<int>(Object->GetTextureSet()->Get2DTextureList().size());
		Object->GetTextureSet()->Add2DTexture(VertexAnimationTexture);

		// �}�e���A���ɃA�T�C������
		for (const auto& Mesh : Object->GetMeshList())
		{
			for (const auto& Primitive : Mesh->GetPrimitiveList())
			{
				for (const auto& Renderer : Primitive->GetRendererList())
				{
					std::get<1>(Renderer)->ReplaceTextureIndex("vertexAnimationTexture", TextureIndex);
					std::get<1>(Renderer)->SetUniformValue("texW", &glm::vec1(static_cast<float>(TextureWidth))[0], sizeof(float));
					std::get<1>(Renderer)->SetUniformValue("texH", &glm::vec1(static_cast<float>(TextureHeight))[0], sizeof(float));
					std::get<1>(Renderer)->SetUniformValue("frameNum", &glm::vec1(static_cast<float>(NumOfFrame))[0], sizeof(float));
				}
			}
		}

		return true;
	}
}