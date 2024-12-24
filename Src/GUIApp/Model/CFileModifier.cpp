#include "CFileModifier.h"
#include "../../LoadWorker/CLoadWorker.h"
#include "../../LoadWorker/CResourceManager.h"

namespace app
{
	CFileModifier::CFileModifier():
		m_UpdateReserved(false)
	{
	}

	void CFileModifier::AddEditingFileName(const std::string& FileName)
	{
		m_EditingFileNameSet.emplace(FileName);
	}

	bool CFileModifier::Update(resource::CLoadWorker* pLoadWorker)
	{
		if (m_UpdateReserved)
		{
			m_UpdateReserved = false;

			UpdateFile(pLoadWorker);
		}

		return true;
	}

	void CFileModifier::OnFileUpdated(resource::CLoadWorker* pLoadWorker)
	{
		m_UpdateReserved = true;
	}

	void CFileModifier::UpdateFile(resource::CLoadWorker* pLoadWorker)
	{
		const std::shared_ptr<resource::CResourceManager>& ResourceManager = pLoadWorker->GetResourceManager();

		const auto& OnMemoryResourceList = ResourceManager->GetOnMemoryResourceList();

		std::map<int, std::set<std::shared_ptr<resource::IResource>>> LoadPriorityUpdateResourceMap;

		for (const auto& EditingFileName : m_EditingFileNameSet)
		{
			// �t�@�C�������݂��邩�`�F�b�N
			const auto& it = OnMemoryResourceList.find(EditingFileName);
			if (it == OnMemoryResourceList.end()) continue;

			// �ŏI�ҏW�������ς���Ă��Ȃ����`�F�b�N
			const auto PrevEditTime = it->second.FinalEditTime;
			const auto FinalEditTime = std::filesystem::last_write_time(EditingFileName);

			if (PrevEditTime == FinalEditTime)
			{
				// �����Ȃ̂Ńt�@�C�����ҏW����Ă��Ȃ�
				continue;
			}

			// �t�@�C�����ҏW����Ă���̂ōăR���p�C���E�X�V�������s���K�v������
			// �ŏI�ҏW�������X�V
			ResourceManager->UpdateFinalEditTime(EditingFileName, FinalEditTime);

			// ���\�[�X���X�V�\�񃊃X�g�ɒǉ�
			const int LoadPriority = it->second.ResourceData->GetLoadPriority();

			if (LoadPriorityUpdateResourceMap.find(LoadPriority) == LoadPriorityUpdateResourceMap.end())
			{
				LoadPriorityUpdateResourceMap.emplace(LoadPriority, std::set<std::shared_ptr<resource::IResource>>());
			}

			LoadPriorityUpdateResourceMap[LoadPriority].emplace(it->second.ResourceData);
		}

		// �X�V�����s
		for (const auto& ReservedUpdateResourceSet : LoadPriorityUpdateResourceMap)
		{
			for (const auto& Resouce : ReservedUpdateResourceSet.second)
			{
				Resouce->Reload(pLoadWorker);
			}
		}

		// �\�񃊃X�g���N���A
		LoadPriorityUpdateResourceMap.clear();
	}
}