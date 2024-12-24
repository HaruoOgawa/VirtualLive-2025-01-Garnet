#include "CCDIKTest.h"
#include <Object/C3DObject.h>
#include <Scene/CSceneController.h>
#include <Message/Console.h>

namespace component
{
	CCDIKTest::CCDIKTest(const std::string& ComponentName, const std::string& RegistryName):
		CComponent(ComponentName, RegistryName),
		m_TargetNode(nullptr)
	{
	}

	CCDIKTest::~CCDIKTest()
	{
	}

	bool CCDIKTest::OnLoaded(api::IGraphicsAPI* pGraphicsAPI, const std::shared_ptr<scene::CSceneController>& SceneController,
		const std::shared_ptr<object::C3DObject>& Object, const std::shared_ptr<object::CNode>& SelfNode)
	{
		if (!Object) return false;

		m_TargetNode = Object->FindNodeByName("Target");
		if (!m_TargetNode) return false;

		// Link0 ~ 4�̏���(���{�����[)�ɓ����Ă���0�����{�E4����[
		// Link���͐�[������đS����5
		for (int i = 0; i < 5; i++)
		{
			auto LinkNode = Object->FindNodeByName("Link.00" + std::to_string(i));
			if (!LinkNode) return false;

			m_LinkList.push_back(LinkNode);
		}

		return true;
	}

	bool CCDIKTest::Update(api::IGraphicsAPI* pGraphicsAPI, physics::IPhysicsEngine* pPhysicsEngine, resource::CLoadWorker* pLoadWorker, const std::shared_ptr<camera::CCamera>& Camera, const std::shared_ptr<projection::CProjection>& Projection,
		const std::shared_ptr<graphics::CDrawInfo>& DrawInfo, const std::shared_ptr<input::CInputState>& InputState)
	{
		if (!m_TargetNode || m_LinkList.empty()) return true;
		
		// �^�[�Q�b�g�̃A�j���[�V����
		{
			float r = 2.0f, t = DrawInfo->GetSecondsTime(), f = DrawInfo->GetSecondsTime();

			glm::vec3 Pos = m_TargetNode->GetPos();
			Pos.x = r * glm::sin(t) * glm::cos(f);
			Pos.y = r * glm::sin(t) * glm::sin(f);
			Pos.z = r * glm::cos(t);

			m_TargetNode->SetPos(Pos);
		}

		// ���ӓ_ ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// ����f���������Ă��܂��̂�CCDIK�̃����N�̃X�P�[���͕K��(1, 1, 1)�ɂȂ�悤�ɂ���
		// �܂蕡�����b�V�����e�q�m�[�h�֌W�ɂȂ��Ă���A���ꂼ��̃X�P�[���̃m����(�x�N�g���̒���)��1�o�Ȃ��ꍇ�A����f����������
		// ����f�Ƃ͗Ⴆ�Ύ��m�[�h��90�x��]�����Ă��Ȃ�����]���Ă��Ȃ�������A45�x�ɂ���ƌ`���΂߂ɂȂ��ĕ����悤�Ȍ����ڂɂȂ��Ԃ̂��Ƃł���
		// ���Ԃ񎩃m�[�h�̐e�m�[�h�̃X�P�[���m������1�ł͂Ȃ����ɁA���m�[�h����]����Ɣ�������̂�������Ȃ�
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		const glm::vec3 TargetPos = m_TargetNode->GetWorldPos();

		// ���̃m�[�h�����R�s�[���Ă���
		// CCDIK�̓R�s�[�m�[�h�ɑ΂��čs���Ō�ɔ��f���邽��
		std::vector<std::shared_ptr<object::CNode>> LocalLinkList;
		{
			std::shared_ptr<object::CNode> LocalParentNode = m_LinkList[0]->GetParentNode();

			for (auto& SrcNode : m_LinkList)
			{
				std::shared_ptr<object::CNode> LocalNode = std::make_shared<object::CNode>(-1, -1);

				LocalNode->SetParentNode(LocalParentNode);
				LocalNode->SetPos(SrcNode->GetPos());
				LocalNode->SetRot(SrcNode->GetRot());
				LocalNode->SetScale(SrcNode->GetScale());
				LocalNode->SetWorldMatrix(SrcNode->GetWorldMatrix());

				LocalLinkList.push_back(LocalNode);

				LocalParentNode = LocalNode;
			}
		}

		//
		int NumOfLink = static_cast<int>(LocalLinkList.size());

		int NumOfCicle = 64;
		int Count = 0;
		bool DoLoop = true;

		std::shared_ptr<object::CNode> EndNode = LocalLinkList[NumOfLink - 1];

		while(DoLoop && Count < NumOfCicle)
		{
			glm::vec3 EndPos = EndNode->GetWorldPos();

			for (int i = NumOfLink - 2; i >= 0; i--)
			{
				std::shared_ptr<object::CNode> LinkNode = LocalLinkList[i];

				glm::vec3 LinkPos = LinkNode->GetWorldPos();

				glm::vec3 e_i = glm::normalize(EndPos - LinkPos);
				glm::vec3 t_i = glm::normalize(TargetPos - LinkPos);

				// ����
				// �Ȃ���1������ɉz����NaN�ɂȂ��Ă��܂����Ƃ�����̂ł����ƃN�����v���Ă���
				float dot = glm::clamp(glm::dot(e_i, t_i), -1.0f, 1.0f);

				// �O��
				glm::vec3 axis = glm::cross(e_i, t_i);

				glm::quat rot;
				
				if (glm::length(axis) < 1e-6f)
				{
					if (glm::sign(dot) == 1.0f)
					{
						// ���������ɕ��s�Ȏ��͉�]�̕K�v���Ȃ�
						continue;
					}
					else
					{
						// ���Ε����ɕ��s�Ȃ̂ŔC�ӂ̐�������180�x��]����
						glm::vec3 XAxis = glm::vec3(1.0f, 0.0f, 0.0f);
						glm::vec3 YAxis = glm::vec3(0.0f, 1.0f, 0.0f);
						
						glm::vec3 SubAxis = glm::cross(XAxis, e_i);

						if (glm::length(SubAxis) < 1e-6f)
						{
							// X���Ƃ����s�Ȃ̂�Y���̕����g��(��������X��Y������Α��v�Ȃ͂��H)
							SubAxis = glm::cross(YAxis, e_i);
						}

						rot = glm::angleAxis(3.1415f, glm::normalize(SubAxis)); // ��]�p�x�����������Ȃ��Ă��܂��̂ŉ�]�擾�O�ɂ����Ǝ��𐳋K�����Ă���
					}
				}
				else
				{
					// �ʏ�ʂ���ό��ʂ����]
					float angle = glm::acos(dot);
					rot = glm::angleAxis(angle, glm::normalize(axis)); // ��]�p�x�����������Ȃ��Ă��܂��̂ŉ�]�擾�O�ɂ����Ǝ��𐳋K�����Ă���
				}

				if (std::isnan(rot.x) || std::isnan(rot.y) || std::isnan(rot.z) || std::isnan(rot.w))
				{
					Console::Log("[Error] CCDIK - found NaN value in ik rot.\n");
					return false;
				}

				LinkNode->SetRot(rot * LinkNode->GetRot());

				// ��]�p�x����
				{
					// �܂��N�H�[�^�j�I������]���Ɗp�x�ɂ΂炷
					// �N�H�[�^�j�I���̒�`�͈ȉ�
					// (��x, ��y, ��z): ��]��, theta: ��]�p�x
					// quat.x = ��x * sin(theta / 2.0)
					// quat.y = ��y * sin(theta / 2.0)
					// quat.z = ��z * sin(theta / 2.0)
					// quat.w = cos(theta / 2.0)
					glm::quat q = LinkNode->GetRot();

					float LinkTheta = 2.0f * glm::acos(q.w);

					// w��1�̎��͔C�ӎ���]�ł���
					glm::vec3 LinkAxis = glm::vec3(0.0f, 1.0f, 0.0f);
					
					if (q.w != 1.0f)
					{
						LinkAxis = glm::vec3(q.x, q.y, q.z) / glm::sin(LinkTheta / 2.0f);
					}

					// ��]�p�x���N�����v����
					LinkTheta = glm::clamp(LinkTheta, -3.1415f * 0.5f, 3.1415f * 0.5f);

					// �N�H�[�^�j�I���ɒ���
					q = glm::angleAxis(LinkTheta, LinkAxis);

					// ���񂾂�c�����܂��Ă���NaN�ɂȂ��Ă��܂��̂ł�����ƍŌ�ɂ͐��K�����Ă���
					q = glm::normalize(q);

					// �Đݒ�
					LinkNode->SetRot(q);
				}

				if (std::isnan(rot.x) || std::isnan(rot.y) || std::isnan(rot.z) || std::isnan(rot.w))
				{
					Console::Log("[Error] CCDIK - found NaN value in ik rot. when clamp rotation.\n");
					return false;
				}

				// Link�m�[�h�̃��[���h�s����Čv�Z����
				for (int n = i; n < NumOfLink; n++)
				{
					std::shared_ptr<object::CNode> ReCalcNode = LocalLinkList[n];

					const auto& ParentNode = ReCalcNode->GetParentNode();
					if (!ParentNode)
					{
						// �e�m�[�h���Ȃ����̓��[�J���s������[���h�s��Ƃ��ēn��
						ReCalcNode->SetWorldMatrix(ReCalcNode->GetLocalMatrix());

						continue;
					}

					glm::mat4 NewWorldMatrix = ParentNode->GetWorldMatrix() * ReCalcNode->GetLocalMatrix();
					ReCalcNode->SetWorldMatrix(NewWorldMatrix);
				}

				// EndNode�̍��W���X�V
				EndPos = EndNode->GetWorldPos();

				if (glm::distance2(TargetPos, EndPos) < 0.01f)
				{
					// �I��
					DoLoop = false;
					break;
				}
			}
			
			Count++;
		}

		// CCDIK�̉��Z���ʂ����̃m�[�h�ɔ��f����
		for (int i = 0; i < static_cast<int>(m_LinkList.size()); i++)
		{
			auto& LocalNode = LocalLinkList[i];
			auto& SrcNode = m_LinkList[i];

			// ���[���h�s�񂾂��𔽉f����
			// ���[�J�����W�ɔ��f���Ȃ����ƂŎ��̃t���[����CCDIK���Z����T-Pose(���̎p��)�Ƀ��Z�b�g���ĉ��Z���s�����Ƃ��ł��A���Z���ʂ����肷��悤�ɂȂ�
			// ���̂悤�ɂ��Ȃ��Ɠr���ŕςȕ�������������Ԃ�Ԃ邵���肵�ĕs����ɂȂ�
			SrcNode->SetWorldMatrix(LocalNode->GetWorldMatrix());

			/*// ��]�Ƀ��[�p�X�t�B���^�������ċ}���ɕω����Ȃ��悤�ɂ���
			float t = DrawInfo->GetDeltaSecondsTime() * 8.0f;
			glm::quat filterRot = glm::slerp(SrcNode->GetRot(), LocalNode->GetRot(), t);

			SrcNode->SetRot(filterRot);

			//
			const auto& ParentNode = SrcNode->GetParentNode();
			if (!ParentNode)
			{
				// �e�m�[�h���Ȃ����̓��[�J���s������[���h�s��Ƃ��ēn��
				SrcNode->SetWorldMatrix(SrcNode->GetLocalMatrix());

				continue;
			}

			glm::mat4 NewWorldMatrix = ParentNode->GetWorldMatrix() * SrcNode->GetLocalMatrix();
			SrcNode->SetWorldMatrix(NewWorldMatrix);*/
		}

		// �A���S���Y���I�ɂ͍����Ă��邪�A���h���̂��߂�Target��End�̐�[�ɕ\�������悤�ɂ���
		// EndNode�̈ʒu�ɕ\�������΂����̂ō����ɕ`�悳���͍̂����Ă���̂����A���f�����O�I�ɂǂ��Ώ������炢���̂��킩��Ȃ�
		// WorldMatrix�͎��̃t���[���ő����Z�b�g�����̂�CCDIK�̌v�Z�ɂ͉e���Ȃ��͂�
		{
			glm::quat EndWorldRot;
			math::CTransform::CastModelMatrixToRotation(EndNode->GetWorldMatrix(), EndWorldRot);

			m_TargetNode->SetWorldPos(m_TargetNode->GetPos() + EndWorldRot * glm::vec3(0.0f, 1.0f, 0.0f));
		}

		return true;
	}
}