#pragma once

#ifdef USE_GUIENGINE
#include <imgui.h>
#include <string>
#include <memory>
#include <vector>
#include <unordered_map>
#include <set>
#include <tuple>

#include <Timeline/CTimelineController.h>
#include "SGUIParams.h"

namespace object { 
	class C3DObject; 
	class CNode;
}

namespace graphics { class CMaterial; }
namespace timeline { class CTimelineController; }
namespace scriptable { class CValueRegistry; }

namespace gui
{
	class CTimeLineView
	{
		//
		const int m_MaxLargeMemoryCount = 20; // �����������̍ő吔�B�������̐��͒萔�B�����������ƒ����������̊ԂɒZ����������2�{����̂Œ��Z���킹�čő�60�{
		const float m_MemoryBarHeight = 40.0f;

		float m_LeftSideMemory; // �^�C�����C���������̍��[�̎���
		float m_RightSideMemory; // �^�C�����C���������̉E�[�̎���

		ImVec2 m_LeftSideScreenPos; // ���[�̃������̃X�N���[�����W
		ImVec2 m_RightSideScreenPos; // �E�[�̃������̃X�N���[�����W

		float m_LargeMemoryWidth; // ���݂̒����������̊Ԋu. 0.01, 0.1, 1.0, 10.0, 100.0�Ƃ����������ŕω�����
		float m_MemoryExpandRate; // �������̊g�嗦

		bool m_FirstClicked;
		ImVec2 m_PrevMousePos;

		bool m_ClickedIndicator;
		float m_IndicatorRate;

		ImVec2 m_MemoryBarCursorPos;
		ImVec2 m_MemoryBarSize;
		ImVec2 m_MemoryBarAvailableSize;

		std::string m_ClickedKeyFrameLabel; // �N���b�N����Ă���L�[�t���[��UI�̖��O
		std::tuple<std::shared_ptr<animation::CAnimationSampler>, std::shared_ptr<animation::CKeyFrame>> m_ClickedSamplerKeyFramePair; // �N���b�N����Ă���L�[�t���[�����̂���

		// �g���b�N�Ŏg�p���Ă���I�u�W�F�N�g���X�g
		std::set<std::shared_ptr<object::C3DObject>> m_TrackObjectList;

		// �g���b�N�Ŏg�p���Ă���ValueRegistry���X�g
		std::set<std::shared_ptr<scriptable::CValueRegistry>> m_TrackValueRegistryList;

		// �c���[���J���Ă���g���b�N�ƕ`��ʒu�̃}�b�v
		std::unordered_map<std::shared_ptr<timeline::CTimelineTrack>, ImVec2> m_OpenedTrackPosMap;

		// �_�C�A���O�̊J��
		bool m_ShowAddPropertyDialog;
		std::shared_ptr<object::C3DObject> m_SelectedObjectForAddObj;

		// Object
		bool m_ShowAddTrackDialog;
		std::shared_ptr<object::C3DObject> m_ClickedObjectForAddObjectTrack;
		std::shared_ptr<object::CNode> m_SelectedNodeForAddTrack;
		std::shared_ptr<graphics::CMaterial> m_SelectedMaterialForAddTrack;

		// Custom(ValueRegistry)
		bool m_ShowAddCustomTrackDialog;
		std::shared_ptr<scriptable::CValueRegistry> m_SelectedValueRegistry;

		//
		std::string m_RemovedTrackID;
	private:
		bool DrawTimeBar(const std::shared_ptr<timeline::CTimelineController>& TimelineController);
		
		bool DrawHierarchyWindow(const std::shared_ptr<timeline::CTimelineController>& TimelineController);
		bool DrawTrackProperty(const std::shared_ptr<timeline::CTimelineController>& TimelineController, const std::string& TrackID, const std::shared_ptr<timeline::CTimelineTrack>& Track,
			const std::vector<std::shared_ptr<animation::CAnimationSampler>>& SamplerList, ImVec2& DstCursorPos);

		bool DrawKeyFrameWindow(const std::shared_ptr<timeline::CTimelineController>& TimelineController);

		bool DrawMemoryBar(const std::shared_ptr<timeline::CTimelineController>& TimelineController);
		bool CalcIndicator(const std::shared_ptr<timeline::CTimelineController>& TimelineController, const ImVec2& cursorPos, const ImVec2& barSize);
		bool DrawIndicator(const ImVec2& cursorPos, const ImVec2& availableSize, const ImVec2& barSize);
		bool DrawKeyFrameList(const std::shared_ptr<timeline::CTimelineController>& TimelineController);

		bool DrawAddPropertyDialog(const std::shared_ptr<timeline::CTimelineController>& TimelineController, const std::vector<std::shared_ptr<object::C3DObject>>& ObjectList, 
			const std::map<std::string, std::shared_ptr<scriptable::CValueRegistry>>& ValueRegistryList);
		
		bool DrawAddObjectTrackDialog(const std::shared_ptr<timeline::CTimelineController>& TimelineController);
		bool DrawNodeDialogView(const std::shared_ptr<timeline::CTimelineController>& TimelineController);
		bool DrawMaterialDialogView(const std::shared_ptr<timeline::CTimelineController>& TimelineController);

		bool DrawAddCustomTrackDialog(const std::shared_ptr<timeline::CTimelineController>& TimelineController, const std::map<std::string, std::shared_ptr<scriptable::CValueRegistry>>& ValueRegistryList);
		bool DrawAddCustomValueDialog(const std::shared_ptr<timeline::CTimelineController>& TimelineController, const std::map<std::string, std::shared_ptr<scriptable::CValueRegistry>>& ValueRegistryList);

		bool CheckWheelExpand();
		bool CheckMemoryDrag(const std::shared_ptr<timeline::CTimelineController>& TimelineController, const ImVec2& availableSize, float DrawMemorySpace, float MaxTime);

		bool CheckIsClickedObjectTree(const std::shared_ptr<object::C3DObject>& Object);
		bool CheckIsClickedCustomTree(const std::shared_ptr<scriptable::CValueRegistry>& ValueRegistry);

		bool UpdateCurrentTimeFromMemoryBar(const std::shared_ptr<timeline::CTimelineController>& TimelineController);
		bool UpdateMemoryFromTimeBar(const std::shared_ptr<timeline::CTimelineController>& TimelineController);

		float GetFirstLargeMemory(float SrcValue, std::vector<bool>& IsLongMemory);
		float GetFirstMemory(float SrcValue);

		float CalcXPosFromFrameTime(float FrameTime);
		float CalcFrameTimeFromXPos(float XPos);

		std::vector<float> GetDefaultValue(math::EValueType ValueType);
		
	public:
		CTimeLineView();
		virtual ~CTimeLineView() = default;

		bool Initialize(const SGUIParams& GUIParams);

		bool Draw(const SGUIParams& GUIParams);
	};
}
#endif