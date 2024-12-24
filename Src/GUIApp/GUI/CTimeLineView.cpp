#ifdef USE_GUIENGINE
#include "CTimeLineView.h"
#include <Object/C3DObject.h>
#include <Message/Console.h>
#include <Scriptable/CValueRegistry.h>
#include <Timeline/CNodeTrack.h>
#include <Timeline/CMaterialTrack.h>
#include <Timeline/CCustomTrack.h>

namespace gui
{
	CTimeLineView::CTimeLineView():
		m_LargeMemoryWidth(1.0f),
		m_MemoryExpandRate(0.0f),
		m_LeftSideScreenPos(ImVec2()),
		m_RightSideScreenPos(ImVec2()),
		m_FirstClicked(true),
		m_PrevMousePos(ImVec2(0.0f, 0.0f)),
		m_ClickedIndicator(false),
		m_IndicatorRate(0.0f),
		m_MemoryBarCursorPos(ImVec2()),
		m_MemoryBarSize(ImVec2()),
		m_MemoryBarAvailableSize(ImVec2()),
		m_ClickedKeyFrameLabel(std::string()),
		m_ClickedSamplerKeyFramePair(std::make_tuple(nullptr, nullptr)),
		m_ShowAddPropertyDialog(false),
		m_ShowAddTrackDialog(false),
		m_SelectedObjectForAddObj(nullptr),
		m_ClickedObjectForAddObjectTrack(nullptr),
		m_SelectedNodeForAddTrack(nullptr),
		m_SelectedMaterialForAddTrack(nullptr),
		m_ShowAddCustomTrackDialog(false),
		m_SelectedValueRegistry(nullptr),
		m_RemovedTrackID(std::string())
	{
		m_LeftSideMemory = 0.0f;
		m_RightSideMemory = static_cast<float>(m_MaxLargeMemoryCount) * m_LargeMemoryWidth;
	}

	bool CTimeLineView::Initialize(const SGUIParams& GUIParams)
	{
		for (const auto& Object : GUIParams.ObjectList)
		{
			if (!Object->HasTLTrackContent()) continue;

			m_TrackObjectList.emplace(Object);
		}

		for (const auto& ValueRegistry : GUIParams.ValueRegistryList)
		{
			if (ValueRegistry.second->GetRefTrackIDList().empty()) continue;

			m_TrackValueRegistryList.emplace(ValueRegistry.second);
		}

		return true;
	}

	bool CTimeLineView::Draw(const SGUIParams& GUIParams)
	{
		if (!GUIParams.TimelineController) return true;

		if (!DrawTimeBar(GUIParams.TimelineController)) return false;
		if (!DrawHierarchyWindow(GUIParams.TimelineController)) return false;
		if (!DrawKeyFrameWindow(GUIParams.TimelineController)) return false;
		if (m_ShowAddPropertyDialog && !DrawAddPropertyDialog(GUIParams.TimelineController, GUIParams.ObjectList, GUIParams.ValueRegistryList)) return false;
		if (m_ShowAddTrackDialog && !DrawAddObjectTrackDialog(GUIParams.TimelineController)) return false;
		if (m_ShowAddCustomTrackDialog && !DrawAddCustomValueDialog(GUIParams.TimelineController, GUIParams.ValueRegistryList)) return false;

		// �g���b�N�ƃT���v���[���폜
		{
			const auto& TLClip = GUIParams.TimelineController->GetClip();

			if (TLClip && !m_RemovedTrackID.empty())
			{
				TLClip->RemoveTrackAndSampler(m_RemovedTrackID);

				m_RemovedTrackID = std::string();
			}
		}

		return true;
	}

	bool CTimeLineView::DrawTimeBar(const std::shared_ptr<timeline::CTimelineController>& TimelineController)
	{
		// PlayButton
		{
			std::string Name = (TimelineController->IsPlay()) ? "Stop##Timeline" : "Play##Timeline";
			if (ImGui::Button(Name.c_str()))
			{
				bool IsPlay = !TimelineController->IsPlay();

				if (IsPlay)
				{
					TimelineController->Play();
				}
				else
				{
					TimelineController->Stop();
				}
			}
		}

		// MaxTime
		{
			// �Đ��{�^���Ɠ����ʒu�ɔz�u����
			ImGui::SameLine();

			float MaxTime = TimelineController->GetMaxTime();

			std::string Name = "##TimelineMaxPlaytime";
			ImGui::PushItemWidth(50.0f);
			if (ImGui::InputFloat(Name.c_str(), &MaxTime))
			{
				TimelineController->SetMaxTime(MaxTime);
			}
			ImGui::PopItemWidth();
		}

		// Playback Time Slider
		{
			// �Đ��{�^���Ɠ����ʒu�ɔz�u����
			ImGui::SameLine();

			float CurrentTime = TimelineController->GetPlayBackTime();

			std::string Name = "##TimelinePlaybackTime";
			ImGui::PushItemWidth(ImGui::GetContentRegionAvail().x); // ���݂̃E�B���h�E�̗��p�\�Ȕ͈͂܂ŃX���C�_�[���������΂�. GetContentRegionAvail�͌��ݒn�ł̗��p�\�ȃT�C�Y��Ԃ�
			if (ImGui::SliderFloat(Name.c_str(), &CurrentTime, 0.0f, TimelineController->GetMaxTime()))
			{
				TimelineController->SetPlayBackTime(CurrentTime);

				// �^�C���o�[�̍X�V�ƍ��킹�ă������o�[���X�V
				if (!UpdateMemoryFromTimeBar(TimelineController)) return false;
			}
			ImGui::PopItemWidth();

			// �Đ���
			if (TimelineController->IsPlay())
			{
				// �^�C���o�[�̍X�V�ƍ��킹�ă������o�[���X�V
				if (!UpdateMemoryFromTimeBar(TimelineController)) return false;
			}
		}

		return true;
	}

	bool CTimeLineView::DrawHierarchyWindow(const std::shared_ptr<timeline::CTimelineController>& TimelineController)
	{
		// ���Z�b�g����
		m_OpenedTrackPosMap.clear();

		ImVec2 availableSize = ImGui::GetContentRegionAvail();

		ImGui::BeginChild("HierarchyWindow##Timeline", ImVec2(availableSize.x * 0.25f, availableSize.y));
		
		ImDrawList* draw_list = ImGui::GetWindowDrawList();
		ImVec2 window_pos = ImGui::GetWindowPos();
		ImVec2 window_size = ImGui::GetWindowSize();

		draw_list->AddRectFilled(window_pos, ImVec2(window_pos.x + window_size.x, window_pos.y + window_size.y), ImGui::ColorConvertFloat4ToU32(ImGui::GetStyle().Colors[ImGuiCol_Tab]));

		const auto& TLClip = TimelineController->GetClip();
		if (!TLClip) return true;

		const auto& TrackList = TLClip->GetTrackList();
		const auto& SamplerList = TLClip->GetSamplerList();

		ImVec2 CursorPos = ImGui::GetCursorPos();
		
		// Object�ǉ��_�C�A���O�\��
		const bool Clicked_AddProperty_Btn = ImGui::Button("AddProperty##Timeline_HierarchyWindow_AddProperty", ImVec2(availableSize.x * 0.25f, m_MemoryBarHeight));
		
		// �������o�[�̍�������J�n����
		ImGui::SetCursorPos(ImVec2(CursorPos.x, CursorPos.y + m_MemoryBarHeight));
		
		bool IsOpenAndClickedObj = false;
		bool IsOpenAndClickedCustom = false;

		// Object
		for (const auto& Object : m_TrackObjectList)
		{
			std::string ObjectTreeLabel = Object->GetObjectName() + "##TimeLineView_Hierarchy_ObjectTree";

			if (ImGui::TreeNodeEx(ObjectTreeLabel.c_str()))
			{
				// Track�ǉ��_�C�A���O�\���BTree�̓��O�����ɕK�v
				if (CheckIsClickedObjectTree(Object))
				{
					IsOpenAndClickedObj = true;
				}
				
				// Node Track
				{
					std::string TrackLabel = "NodeTrack##Timeline_" + Object->GetObjectName();

					if (ImGui::TreeNodeEx(TrackLabel.c_str()))
					{
						if (CheckIsClickedObjectTree(Object))
						{
							IsOpenAndClickedObj = true;
						}

						for (const auto& Node : Object->GetTLNodeList())
						{
							std::string NodeTrackLabel = Node->GetName() + "##TimeLineView_Hierarchy_NodeTree";
							if (ImGui::TreeNodeEx(NodeTrackLabel.c_str()))
							{
								for (const auto& TrackID : Node->GetRefTrackIDList())
								{
									const auto& Track = TrackList.find(TrackID);
									if (Track == TrackList.end()) continue;
									
									ImVec2 DstCursorPos = ImVec2();
									if (!DrawTrackProperty(TimelineController, Track->first, Track->second, SamplerList, DstCursorPos)) return false;

									if (m_RemovedTrackID == TrackID)
									{
										Node->RemoveRefTrackID(TrackID);
									}

									// �g���b�N�ƕ`��ʒu(�J�[�\���ʒu)��o�^
									m_OpenedTrackPosMap.emplace(Track->second, DstCursorPos);
								}

								ImGui::TreePop();
							}
						}

						ImGui::TreePop();
					}

					if (CheckIsClickedObjectTree(Object))
					{
						IsOpenAndClickedObj = true;
					}
				}

				// MaterialTrack
				{
					std::string TrackLabel = "MaterialTrack##Timeline_" + Object->GetObjectName();

					if (ImGui::TreeNodeEx(TrackLabel.c_str()))
					{
						if (CheckIsClickedObjectTree(Object))
						{
							IsOpenAndClickedObj = true;
						}

						for (const auto& Material : Object->GetTLMaterial())
						{
							std::string MaterialTrackLabel = Material->GetMaterialName() + "##TimeLineView_Hierarchy_MaterialTree";
							if (ImGui::TreeNodeEx(MaterialTrackLabel.c_str()))
							{
								for (const auto& TrackID : Material->GetRefTrackIDList())
								{
									const auto& Track = TrackList.find(TrackID);
									if (Track == TrackList.end()) continue;

									ImVec2 DstCursorPos = ImVec2();
									if (!DrawTrackProperty(TimelineController, Track->first, Track->second, SamplerList, DstCursorPos)) return false;

									if (m_RemovedTrackID == TrackID)
									{
										Material->RemoveRefTrackID(TrackID);
									}

									// �g���b�N�ƕ`��ʒu(�J�[�\���ʒu)��o�^
									m_OpenedTrackPosMap.emplace(Track->second, DstCursorPos);
								}

								ImGui::TreePop();
							}
						}

						ImGui::TreePop();
					}

					if (CheckIsClickedObjectTree(Object))
					{
						IsOpenAndClickedObj = true;
					}
				}

				ImGui::TreePop();
			}

			// Track�ǉ��_�C�A���O�\���BTree�̓��O�����ɕK�v
			CheckIsClickedObjectTree(Object);
		}

		// ValueRegistry
		for (const auto& ValueRegistry : m_TrackValueRegistryList)
		{
			std::string ValueRegistryTreeLabel = ValueRegistry->GetRegistryName() + "##TimeLineView_Hierarchy_ValueRegistryTree";

			// CustomTrack
			if (ImGui::TreeNodeEx(ValueRegistryTreeLabel.c_str()))
			{
				std::string TrackLabel = "CustomTrack##Timeline_" + ValueRegistry->GetRegistryName();

				if (ImGui::TreeNodeEx(TrackLabel.c_str()))
				{
					if (CheckIsClickedCustomTree(ValueRegistry))
					{
						IsOpenAndClickedCustom = true;
					}

					for (const auto& TrackID : ValueRegistry->GetRefTrackIDList())
					{
						const auto& Track = TrackList.find(TrackID);
						if (Track == TrackList.end()) continue;

						ImVec2 DstCursorPos = ImVec2();
						if (!DrawTrackProperty(TimelineController, Track->first, Track->second, SamplerList, DstCursorPos)) return false;

						// �g���b�N�ƕ`��ʒu(�J�[�\���ʒu)��o�^
						m_OpenedTrackPosMap.emplace(Track->second, DstCursorPos);
					}

					ImGui::TreePop();
				}

				if (CheckIsClickedCustomTree(ValueRegistry))
				{
					IsOpenAndClickedCustom = true;
				}

				ImGui::TreePop();
			}
		}

		// AddProperty�̉�����Hierarchy�E�B���h�E�̂ǂ�������̉E�N���b�N�Ń_�C�A���O���J���B
		if (Clicked_AddProperty_Btn || (ImGui::IsWindowHovered() && ImGui::IsMouseClicked(1) && !ImGui::IsItemHovered() && !IsOpenAndClickedObj))
		{
			m_ShowAddPropertyDialog = true;
		}
		/*else if (Clicked_AddProperty_Btn || (ImGui::IsWindowHovered() && ImGui::IsMouseClicked(1) && !ImGui::IsItemHovered() && !IsOpenAndClickedCustom))
		{
			m_ShowAddCustomTrackDialog = true;
		}*/

		ImGui::EndChild();

		return true;
	}

	bool CTimeLineView::DrawTrackProperty(const std::shared_ptr<timeline::CTimelineController>& TimelineController, const std::string& TrackID, const std::shared_ptr<timeline::CTimelineTrack>& Track,
		const std::vector<std::shared_ptr<animation::CAnimationSampler>>& SamplerList, ImVec2& DstCursorPos)
	{
		int SamplerIndex = Track->GetSamplerIndex();
		if (SamplerIndex < 0 || SamplerIndex >= SamplerList.size()) return false;

		//
		animation::EInterpolateValueType InterpolateValueType = animation::EInterpolateValueType::NONE;
		if (Track->GetSamplerTarget() == timeline::ETimelineSamplerTarget::ROTATION)
		{
			InterpolateValueType = animation::EInterpolateValueType::QUATERNION;
		}
		else if (Track->GetSamplerTarget() == timeline::ETimelineSamplerTarget::MODELMATRIX)
		{
			InterpolateValueType = animation::EInterpolateValueType::MODELMATRIX;
		}

		// �T���v���[�ƍĐ����Ԃ��猻�݂̃L�[�t���[���̒l���擾
		math::EValueType ValueType = Track->GetValueType();

		auto& Sampler = SamplerList[SamplerIndex];
		std::vector<float> Value;

		if (std::get<0>(m_ClickedSamplerKeyFramePair) == Sampler)
		{
			// �L�[�t���[�����I������Ă���̂ł��̒l�𔽉f����
			const auto& SelectedKeyFrame = std::get<1>(m_ClickedSamplerKeyFramePair);

			Value = SelectedKeyFrame->GetOutput();
		}
		else
		{
			// ��Ԃ��ꂽ���݂̒l���擾
			if (!Sampler->ComputeCurrentFrame(TimelineController->GetPlayBackTime(), false, Value, InterpolateValueType)) return false;

			if (Value.empty()) Value = GetDefaultValue(ValueType);
		}

		if (Value.empty()) return true;

		//
		ImGui::SeparatorText(Track->GetTrackName().c_str());

		// GUI�ɕ`��
		std::string Label = "##Timeline_TrackProperty_" + Track->GetTrackName();
		
		bool ExistInput = false;

		// Input��CursorPos���擾
		DstCursorPos = ImGui::GetCursorScreenPos();

		if (InterpolateValueType == animation::EInterpolateValueType::QUATERNION && ValueType == math::EValueType::VALUE_TYPE_VEC4)
		{
			// ��]�̓I�C���[�p�ŕ\������
			glm::quat Rot = glm::quat(Value[3], Value[0], Value[1], Value[2]);
			
			glm::vec3 Euler = glm::eulerAngles(Rot);
			glm::vec3 Degree = glm::vec3(glm::degrees(Euler.x), glm::degrees(Euler.y), glm::degrees(Euler.z));
			//const glm::vec3 PreDegree = Degree;

			// IsItemDeactivatedAfterEdit�͒��O�̃C���v�b�g�̃t�H�[�J�X���O�ꂽ���ǂ���
			ExistInput = (ImGui::InputFloat3(Label.c_str(), &Degree[0], "%.3f", ImGuiInputTextFlags_EnterReturnsTrue) || ImGui::IsItemDeactivatedAfterEdit());

			if (ExistInput)
			{
				//if (PreDegree.x != Degree.x || PreDegree.y != Degree.y || PreDegree.z != Degree.z)
				{
					// quat�̃R���X�g���N�^�ɃI�C���[�p��(glm::vec3)�n���Ƃ��������ɓ����ł��������ɂ��Ă����炵��(x, y, z, w�̎l������n���R���X�g���N�^���ʂɑ��݂���)
					Rot = glm::quat(glm::vec3(glm::radians(Degree.x), glm::radians(Degree.y), glm::radians(Degree.z)));
					
					// �N�H�[�^�j�I���ɓn���I�C���[�p��Yaw(Y) - Pitch(X) - Roll(Z)�̏��Ԃœn��
					// �N�H�[�^�j�I���͂��̏��Ԃŉ�]����Ƃ������Ƃ���������o���Ă������ƁI
					//float yaw = glm::radians(Degree.y); // ���[(Y����])
					//float pitch = glm::radians(Degree.x); // �s�b�`(X����])
					//float roll = glm::radians(Degree.z); // ���[��(Z����])

					//Rot = glm::quat(glm::vec3(yaw, pitch, roll));
					 
					//Rot = glm::angleAxis(glm::radians(Degree.z), glm::vec3(0.0f, 0.0f, 1.0f)) * glm::angleAxis(glm::radians(Degree.y), glm::vec3(0.0f, 1.0f, 0.0f)) * glm::angleAxis(glm::radians(Degree.x), glm::vec3(1.0f, 0.0f, 0.0f));
					// Yaw(Y) - Pitch(X) - Roll(Z)�Ő����������Ƃ��Ԃ񂱂�Ȋ���(�Ȃ̂ł���܂ł̃A�j���[�V�����n�̏����͑S���Ԉ���Ă����)
					/*Rot = 
						glm::angleAxis(glm::radians(Degree.y), glm::vec3(0.0f, 1.0f, 0.0f)) * 
						glm::angleAxis(glm::radians(Degree.x), glm::vec3(1.0f, 0.0f, 0.0f)) *
						glm::angleAxis(glm::radians(Degree.z), glm::vec3(0.0f, 0.0f, 1.0f))
						;*/
				}

				Value[0] = Rot.x;
				Value[1] = Rot.y;
				Value[2] = Rot.z;
				Value[3] = Rot.w;
			}
		}
		else
		{
			switch (ValueType)
			{
			case math::EValueType::VALUE_TYPE_NONE:
				break;
			case math::EValueType::VALUE_TYPE_SCALAR:
				ExistInput = ImGui::InputFloat(Label.c_str(), &Value[0]);
				break;
			case math::EValueType::VALUE_TYPE_VEC2:
				ExistInput = ImGui::InputFloat2(Label.c_str(), &Value[0]);
				break;
			case math::EValueType::VALUE_TYPE_VEC3:
				ExistInput = ImGui::InputFloat3(Label.c_str(), &Value[0]);
				break;
			case math::EValueType::VALUE_TYPE_VEC4:
				ExistInput = ImGui::InputFloat4(Label.c_str(), &Value[0]);
				break;
			case math::EValueType::VALUE_TYPE_MAT2:
				break;
			case math::EValueType::VALUE_TYPE_MAT3:
				break;
			case math::EValueType::VALUE_TYPE_MAT4:
				break;
			case math::EValueType::VALUE_TYPE_VECTOR:
				break;
			case math::EValueType::VALUE_TYPE_MATRIX:
				break;
			default:
				break;
			}
		}

		std::string RemoveLavel = "Remove##" + Label;
		if (ImGui::Button(RemoveLavel.c_str()))
		{
			m_RemovedTrackID = TrackID;
		}

		// �l���ς���Ă��L�[�t���[�����I�𒆂Ȃ�f�[�^���L�[�t���[���ɔ��f����
		if (ExistInput && std::get<0>(m_ClickedSamplerKeyFramePair) == Sampler)
		{
			const auto& SelectedKeyFrame = std::get<1>(m_ClickedSamplerKeyFramePair);
			SelectedKeyFrame->SetOutput(Value);
		}

		return true;
	}

	bool CTimeLineView::DrawKeyFrameWindow(const std::shared_ptr<timeline::CTimelineController>& TimelineController)
	{
		ImGui::SameLine();

		ImVec2 availableSize = ImGui::GetContentRegionAvail();
		
		ImGui::BeginChild("KeyFrameWindow##Timeline", availableSize, 0, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);

		// �^�C�����C���̃������o�[��`��
		if (!DrawMemoryBar(TimelineController)) return false;

		// �L�[�t���[����`��
		if (!DrawKeyFrameList(TimelineController)) return false;

		// �C���W�P�[�^�[�̕`��
		if (!DrawIndicator(m_MemoryBarCursorPos, m_MemoryBarAvailableSize, m_MemoryBarSize)) return false;

		ImGui::EndChild();

		return true;
	}

	bool CTimeLineView::DrawMemoryBar(const std::shared_ptr<timeline::CTimelineController>& TimelineController)
	{
		// �^�C�����C���̃������o�[��`��
		m_MemoryBarAvailableSize = ImGui::GetContentRegionAvail();

		m_MemoryBarSize = ImVec2(m_MemoryBarAvailableSize.x, m_MemoryBarHeight);

		// �������ƃ������̊Ԋu
		const float DrawMemorySpace = m_MemoryBarAvailableSize.x / (m_MaxLargeMemoryCount * 3);

		ImDrawList* drawList = ImGui::GetWindowDrawList(); // �`��}�l�[�W���[�H ���R�ɔ|���Ƃ����Ƃ�������`��ł����炵��

		ImGuiStyle& style = ImGui::GetStyle();

		// ���݂�GUI�̕`��ʒu���擾(�X�N���[�����W�n)
		m_MemoryBarCursorPos = ImGui::GetCursorScreenPos();

		// �C���W�P�[�^�[�̑O�v�Z�B�K���������o�[������Ɍv�Z���Ă����K�v������
		if (!CalcIndicator(TimelineController, m_MemoryBarCursorPos, m_MemoryBarSize)) return false;

		// �w�i�̕`��
		ImGui::SetCursorScreenPos(m_MemoryBarCursorPos);
		ImGui::InvisibleButton("##TimelineMemoryBar", m_MemoryBarSize);

		// ���E�̃������̃X�N���[�����W��ݒ�
		m_LeftSideScreenPos = m_MemoryBarCursorPos;
		m_RightSideScreenPos = ImVec2(m_MemoryBarCursorPos.x + m_MemoryBarAvailableSize.x, m_MemoryBarCursorPos.y);

		// Item(�����ł�InvisibleButton)�Ƀz�o�[���Ă��邩�������肷��̂ŕK�����̌�Ƀ}�E�X�z�C�[����h���b�O���`�F�b�N����
		if (!CheckWheelExpand()) return false;
		if (!CheckMemoryDrag(TimelineController, m_MemoryBarAvailableSize, DrawMemorySpace, TimelineController->GetMaxTime())) return false;

		drawList->AddRectFilled(m_MemoryBarCursorPos, ImVec2(m_MemoryBarCursorPos.x + m_MemoryBarSize.x, m_MemoryBarCursorPos.y + m_MemoryBarSize.y), ImGui::ColorConvertFloat4ToU32(style.Colors[ImGuiCol_Tab])); // ��`��`��

		// �������̊J�n�l
		std::vector<bool> IsLongMemory;
		float LargeMemoryValue = GetFirstLargeMemory(m_LeftSideMemory, IsLongMemory);
		const float FirstMemoryValue = GetFirstMemory(m_LeftSideMemory);

		float MemoryOffset = (FirstMemoryValue - m_LeftSideMemory) * DrawMemorySpace;

		// �������̕`��(�g�厞�Ɍ��Ԃ������Ȃ��悤�ɂ������]���ɕ`��)
		for (int i = 0; i < (m_MaxLargeMemoryCount * 3 + 4); i++)
		{
			int LoopCounter = i % 3;

			float x = m_MemoryBarCursorPos.x + static_cast<float>(i) * DrawMemorySpace * (1.0f + m_MemoryExpandRate) + MemoryOffset;

			if (IsLongMemory[LoopCounter])
			{
				// �����j�ƃ������e�L�X�g��`��
				drawList->AddLine(ImVec2(x, m_MemoryBarCursorPos.y), ImVec2(x, m_MemoryBarCursorPos.y + 20.0f), IM_COL32(255, 255, 255, 255));

				std::string label = math::CMath::GetFloatWithPrecision(LargeMemoryValue, 3);
				drawList->AddText(ImVec2(x, m_MemoryBarCursorPos.y + 22.0f), IM_COL32(255, 255, 255, 255), label.c_str());

				// �����������̒l���X�V
				LargeMemoryValue += m_LargeMemoryWidth;
			}
			else
			{
				// �Z���������̂�
				drawList->AddLine(ImVec2(x, m_MemoryBarCursorPos.y), ImVec2(x, m_MemoryBarCursorPos.y + 10.0f), IM_COL32(255, 255, 255, 255));
			}
			
		}

		return true;
	}

	bool CTimeLineView::CalcIndicator(const std::shared_ptr<timeline::CTimelineController>& TimelineController, const ImVec2& cursorPos, const ImVec2& barSize)
	{
		bool IsClicked = (ImGui::IsMouseDown(0));

		float DrawPos = cursorPos.x + m_IndicatorRate * barSize.x;

		// ToDo: ��������s�v
		/*if (m_ClickedIndicator && !IsClicked)
		{
			// �������߂��L�[�t���[������������PlayBackTime�����̃L�[�t���[���ɂ҂����荇���悤�ɂ���
			const auto& TLClip = TimelineController->GetClip();
			if (TLClip)
			{
				const auto& SamplerList = TLClip->GetSamplerList();

				float MinDist = std::numeric_limits<float>::max();

				for (const auto& OpenedTrackAndCursor : m_OpenedTrackPosMap)
				{
					const auto& Track = OpenedTrackAndCursor.first;
					const auto& OpenedTrackPos = OpenedTrackAndCursor.second;

					// Y���W���`��͈͊O�������珜�O����
					//if(OpenedTrackPos.y > )

					// �L�[�t���[��
					int SamplerIndex = Track->GetSamplerIndex();
					if (SamplerIndex < 0 || SamplerIndex >= SamplerList.size()) return false;

					// �T���v���[����w�莞�ԓ��̃L�[�t���[�����X�g���擾
					auto& Sampler = SamplerList[SamplerIndex];

					const auto& KeyFrameList = Sampler->GetKeyFrameListFromRange(m_LeftSideMemory, m_RightSideMemory);

					for (const auto& KeyFrame : KeyFrameList)
					{
						float FrameTime = KeyFrame->GetInput();

						// �Đ����Ԃ���L�[�t���[���̍��W�����߂�
						float XPos = CalcXPosFromFrameTime(FrameTime);

						// �ł��߂����̂��擾����
						const float Dist = glm::abs(DrawPos - XPos);
						if (Dist <= 0.01f && Dist < MinDist)
						{
							MinDist = Dist;
						}
					}
				}
			}
		}*/

		float btnW = 10.0f;
		ImGui::SetCursorScreenPos(ImVec2(DrawPos - btnW * 0.5f, cursorPos.y));
		
		if (!m_ClickedIndicator)
		{
			ImGui::InvisibleButton("##TimelineIndicator", ImVec2(btnW, barSize.y));
			if (ImGui::IsItemHovered() && IsClicked)
			{
				m_ClickedIndicator = true;
			}
		}

		if (m_ClickedIndicator)
		{
			if (IsClicked)
			{
				ImVec2 mousePos = ImGui::GetMousePos();

				m_IndicatorRate = (mousePos.x - cursorPos.x) / barSize.x;
				m_IndicatorRate = glm::clamp(m_IndicatorRate, 0.0f, 1.0f);

				// �������o�[�̍X�V�ɍ��킹�čĐ����Ԃ��X�V����
				UpdateCurrentTimeFromMemoryBar(TimelineController);
			}
			else
			{
				m_ClickedIndicator = false;
			}
		}

		return true;
	}

	bool CTimeLineView::DrawIndicator(const ImVec2& cursorPos, const ImVec2& availableSize, const ImVec2& barSize)
	{
		ImDrawList* drawList = ImGui::GetWindowDrawList();

		float DrawPos = cursorPos.x + m_IndicatorRate * barSize.x;
		drawList->AddLine(ImVec2(DrawPos, cursorPos.y), ImVec2(DrawPos, cursorPos.y + availableSize.y), IM_COL32(255, 0, 0, 255));

		return true;
	}

	bool CTimeLineView::DrawKeyFrameList(const std::shared_ptr<timeline::CTimelineController>& TimelineController)
	{
		ImVec2 ScreenCursorPos = ImGui::GetCursorScreenPos();

		ImVec2 availableSize = ImGui::GetContentRegionAvail();

		ImGui::BeginChild("KeyFrameList##Timeline", availableSize);

		const auto& TLClip = TimelineController->GetClip();
		if (!TLClip) return true;

		const auto& SamplerList = TLClip->GetSamplerList();

		auto& style = ImGui::GetStyle();

		// �P�ɑI�������������̎�������̂ŕK���t���[��������̃h���b�O�ʂ��`�F�b�N����B��������h���b�O���Ă���Ȃ�0�ȊO�ɂȂ�͂�
		const bool IsDragging = (ImGui::GetMouseDragDelta().x != 0.0);

		for (const auto& OpenedTrackAndCursor : m_OpenedTrackPosMap)
		{
			const auto& Track = OpenedTrackAndCursor.first;
			const auto& OpenedTrackPos = OpenedTrackAndCursor.second;

			const float TrackHeight = 10.0f;

			// �L�[�t���[��
			int SamplerIndex = Track->GetSamplerIndex();
			if (SamplerIndex < 0 || SamplerIndex >= SamplerList.size()) return false;

			// �T���v���[����w�莞�ԓ��̃L�[�t���[�����X�g���擾
			auto& Sampler = SamplerList[SamplerIndex];

			// ToDo:�o�O�Ȃ̂����Ȃ̂��킩��Ȃ����A�قȂ�Q�̃{�^�����d�˂Ĕz�u���d�Ȃ����������N���b�N�������A�R�[�h�I�ɂ���ɏ�����ĉ��ɕ`�悳��Ă���{�^���̃N���b�N���D�悳��Ă��܂��̂�
			// ��ɓ����ȃ{�^����`�悵�Ă����A���Ƃ�Rect���x�[�X�̏�ɂ���ɕ`�悷��
			std::vector<float> KeyXPosList;
			std::vector<ImVec4> ColList;
			{
				const auto& KeyFrameList = Sampler->GetKeyFrameListFromRange(m_LeftSideMemory, m_RightSideMemory);

				// �e�L�[�t���[�����Y�����鎞�Ԃ̍��W�ɕ`�悷��
				for (const auto& KeyFrame : KeyFrameList)
				{
					float FrameTime = KeyFrame->GetInput();

					std::string KeyFrameLabel = "##Timeline_KeyFrame_" + Track->GetTrackName() + "_" + std::to_string(FrameTime);

					// �`��ʒu������
					float XPos = 0.0f;
					
					if (!m_ClickedKeyFrameLabel.empty() && m_ClickedKeyFrameLabel == KeyFrameLabel && IsDragging)
					{
						// �}�E�X��X���W�����蓖�Ă�
						XPos = ImGui::GetMousePos().x;
					}
					else
					{
						// �Đ����Ԃ���L�[�t���[���̍��W�����߂�
						XPos = CalcXPosFromFrameTime(FrameTime);
					}

					ImGui::SetCursorScreenPos(ImVec2(XPos, OpenedTrackPos.y));
					
					ImGui::InvisibleButton(KeyFrameLabel.c_str(), ImVec2(TrackHeight, TrackHeight));
					
					// �L�[�t���[�����N���b�N���ꂽ
					if (ImGui::IsItemClicked())
					{
						if (std::get<1>(m_ClickedSamplerKeyFramePair) == KeyFrame)
						{
							// �����L�[�t���[�����N���b�N���ꂽ��I������������
							m_ClickedSamplerKeyFramePair = std::make_tuple(nullptr, nullptr);
						}
						else
						{
							// �V�����I������
							m_ClickedSamplerKeyFramePair = std::make_tuple(Sampler, KeyFrame);
						}
					}

					// �L�[�t���[�����h���b�O���ꂽ
					if (ImGui::IsItemActive())
					{
						// �͂�ł���
						m_ClickedKeyFrameLabel = KeyFrameLabel;
					}
					else if (!m_ClickedKeyFrameLabel.empty() && m_ClickedKeyFrameLabel == KeyFrameLabel)
					{
						// �������̂Ń��Z�b�g����
						m_ClickedKeyFrameLabel = std::string();

						if (IsDragging)
						{
							// MousePos.x(XPos)����t�v�Z���ăL�[�t���[���̎��Ԃ����߂�
							float NewFrameTime = CalcFrameTimeFromXPos(ImGui::GetMousePos().x);

							Sampler->SetKeyFrameInput(KeyFrame, NewFrameTime);
						}
					}

					// �{�^���̐F��I��
					ImVec4 Col = ImVec4();
					//if (ImGui::IsItemActive())
					if (std::get<1>(m_ClickedSamplerKeyFramePair) == KeyFrame)
					{
						Col = style.Colors[ImGuiCol_Button];
					}
					else if (ImGui::IsItemHovered())
					{
						Col = ImVec4(0.42f, 0.42f, 0.42f, 1.0f);
					}
					else
					{
						Col = ImVec4(0.42f, 0.42f, 0.42f, 1.0f);
					}

					// �e�����o�^
					KeyXPosList.push_back(XPos);
					ColList.push_back(Col);
				}
			}

			// �x�[�X�̕`��
			{
				ImGui::SetCursorScreenPos(ImVec2(ScreenCursorPos.x, OpenedTrackPos.y));

				// �{�^���̐F��I��
				ImGui::PushStyleColor(ImGuiCol_Button, style.Colors[ImGuiCol_Tab]); // �ʏ펞�̐F
				ImGui::PushStyleColor(ImGuiCol_ButtonHovered, style.Colors[ImGuiCol_Tab]); // �z�o�[�̐F
				ImGui::PushStyleColor(ImGuiCol_ButtonActive, style.Colors[ImGuiCol_Tab]); // �������̐F

				std::string Lebal = "##Timeline_KeyFrameBar_" + Track->GetTrackName();
				ImGui::Button(Lebal.c_str(), ImVec2(availableSize.x, TrackHeight));

				if (ImGui::IsItemClicked(1)) // �E�N���b�N�ŃL�[�t���[���̒ǉ�
				{
					// MousePos.x(XPos)����t�v�Z���ăL�[�t���[���̎��Ԃ����߂�
					float NewFrameTime = CalcFrameTimeFromXPos(ImGui::GetMousePos().x);

					// �O��̃L�[�t���[�����擾
					std::shared_ptr<animation::CKeyFrame> PrevKeyFrame = nullptr;
					std::shared_ptr<animation::CKeyFrame> NextKeyFrame = nullptr;

					if (Sampler->GetNeedKeyFrame(NewFrameTime, PrevKeyFrame, NextKeyFrame))
					{
						std::vector<float> Value;

						// �߂�����Output�̏����l�Ƃ��Ďg�p����
						const float PrevDeltaTime = (PrevKeyFrame) ? glm::abs(NewFrameTime - PrevKeyFrame->GetInput()) : std::numeric_limits<float>::max();
						const float NextDeltaTime = (NextKeyFrame) ? glm::abs(NewFrameTime - NextKeyFrame->GetInput()) : std::numeric_limits<float>::max();
						math::EValueType ValueType = math::EValueType::VALUE_TYPE_NONE;

						if (PrevKeyFrame && PrevDeltaTime <= NextDeltaTime)
						{
							Value = PrevKeyFrame->GetOutput();
							ValueType = PrevKeyFrame->GetType();
						}
						else if (NextKeyFrame && NextDeltaTime <= PrevDeltaTime)
						{
							Value = NextKeyFrame->GetOutput();
							ValueType = NextKeyFrame->GetType();
						}

						// �T���v���[�Ƀ\�[�g�t���ŐV�����L�[�t���[����ǉ�����
						if (!Value.empty())
						{
							std::shared_ptr<animation::CKeyFrame> NewKeyFrame = std::make_shared<animation::CKeyFrame>(ValueType);
							NewKeyFrame->SetInput(NewFrameTime);
							NewKeyFrame->SetOutput(Value);

							Sampler->AddKeyFrameWithSort(NewKeyFrame);
						}
					}
					else
					{
						// �L�[�t���[�����X�g���܂���Ȃ̂ŏ����l��0�Ƃ��ēn��
						int NumComponents = math::CMath::GetNumComponentsInType(Track->GetValueType());

						std::vector<float> Value;
						Value.resize(NumComponents, 0.0f);

						std::shared_ptr<animation::CKeyFrame> NewKeyFrame = std::make_shared<animation::CKeyFrame>(Track->GetValueType());
						NewKeyFrame->SetInput(NewFrameTime);
						NewKeyFrame->SetOutput(Value);

						Sampler->AddKeyFrameWithSort(NewKeyFrame);
					}
				}
				else if (ImGui::IsItemClicked(0)) // ���N���b�N�ŃL�[�t���[���̑I������
				{
					m_ClickedSamplerKeyFramePair = std::make_tuple(nullptr, nullptr);
				}

				// �F�̐ݒ�����ɖ߂�
				ImGui::PopStyleColor(3); // 3���̃J���[�X�^�b�N���|�b�v����
			}

			// �L�[�t���[����UI����h�肷��
			{
				if (KeyXPosList.size() == ColList.size())
				{
					ImDrawList* DrawList = ImGui::GetWindowDrawList();

					for (size_t i = 0; i < KeyXPosList.size(); i++)
					{
						float XPos = KeyXPosList[i];
						const ImVec4& Col = ColList[i];

						ImU32 Col32 = IM_COL32(
							static_cast<int>((255.0f * Col.x)),
							static_cast<int>((255.0f * Col.y)),
							static_cast<int>((255.0f * Col.z)),
							static_cast<int>((255.0f * Col.w))
						);

						DrawList->AddRectFilled(ImVec2(XPos, OpenedTrackPos.y), ImVec2(XPos + TrackHeight, OpenedTrackPos.y + TrackHeight), Col32);
					}
				}
			}
		}

		// Input���`�F�b�N
		if (ImGui::IsKeyReleased(ImGuiKey_Delete) && ImGui::IsWindowHovered())
		{
			// �I�𒆂̃L�[�t���[�����폜����
			const auto& SelectedSampler = std::get<0>(m_ClickedSamplerKeyFramePair);
			const auto& SelectedKeyFrame = std::get<1>(m_ClickedSamplerKeyFramePair);

			if (SelectedSampler && SelectedKeyFrame)
			{
				SelectedSampler->RemoveKeyFrame(SelectedKeyFrame);
			}
		}

		ImGui::EndChild();

		return true;
	}

	bool CTimeLineView::DrawAddPropertyDialog(const std::shared_ptr<timeline::CTimelineController>& TimelineController, const std::vector<std::shared_ptr<object::C3DObject>>& ObjectList, 
		const std::map<std::string, std::shared_ptr<scriptable::CValueRegistry>>& ValueRegistryList)
	{
		ImGuiIO& io = ImGui::GetIO();

		ImVec2 WindowSize = ImVec2(io.DisplaySize.x * 0.1f, io.DisplaySize.y * 0.1f);
		
		ImGui::SetNextWindowPos(ImVec2(io.MousePos.x - WindowSize.x * 0.5f, io.MousePos.y - WindowSize.y * 0.5f), ImGuiCond_Appearing, ImVec2(0.0f, 0.0f));
		ImGui::SetNextWindowSize(WindowSize, ImGuiCond_Appearing);

		if (ImGui::Begin("AddProperty##Timeline", &m_ShowAddPropertyDialog))
		{
			if (ImGui::BeginTabBar("##Timeline_DrawAddPropertyDialog_TabBar"))
			{
				if (ImGui::BeginTabItem("Object##Timeline_DrawAddPropertyDialog_TabBar"))
				{
					// Object
					std::string CurrentValue = (m_SelectedObjectForAddObj) ? m_SelectedObjectForAddObj->GetObjectName() : "";

					if (ImGui::BeginCombo("ObjectList##Timeline_AddObjectDialog", CurrentValue.c_str()))
					{
						for (const auto& Object : ObjectList)
						{
							std::string LabelSelectable = Object->GetObjectName() + "##Timeline_Selectable";

							const bool IsSelected = (m_SelectedObjectForAddObj == Object);

							if (ImGui::Selectable(LabelSelectable.c_str(), IsSelected) && !IsSelected)
							{
								m_SelectedObjectForAddObj = Object;
							}
						}

						ImGui::EndCombo();
					}

					if (ImGui::Button("Add##Timeline_AddObjectDialog"))
					{
						m_TrackObjectList.emplace(m_SelectedObjectForAddObj);

						m_SelectedObjectForAddObj = nullptr;
						m_ShowAddPropertyDialog = false;
					}

					ImGui::EndTabItem();
				}

				if (ImGui::BeginTabItem("Custom##Timeline_DrawAddPropertyDialog_TabBar"))
				{
					// Custom
					if (!DrawAddCustomTrackDialog(TimelineController, ValueRegistryList)) return false;

					ImGui::EndTabItem();
				}

				ImGui::EndTabBar();
			}
		}

		ImGui::End();

		return true;
	}

	bool CTimeLineView::DrawAddObjectTrackDialog(const std::shared_ptr<timeline::CTimelineController>& TimelineController)
	{
		ImGuiIO& io = ImGui::GetIO();

		ImVec2 WindowSize = ImVec2(io.DisplaySize.x * 0.1f, io.DisplaySize.y * 0.1f);

		ImGui::SetNextWindowPos(ImVec2(io.MousePos.x, io.MousePos.y - WindowSize.y * 0.5f), ImGuiCond_Appearing, ImVec2(0.0f, 0.0f));
		ImGui::SetNextWindowSize(WindowSize, ImGuiCond_Appearing);

		if (ImGui::Begin("AddTrack##Timeline", &m_ShowAddTrackDialog))
		{
			if (ImGui::BeginTabBar("##Timeline_AddObjectTrackDialog_TabBar"))
			{
				if (!DrawNodeDialogView(TimelineController)) return false;
				if (!DrawMaterialDialogView(TimelineController)) return false;

				ImGui::EndTabBar();
			}
		}

		ImGui::End();

		return true;
	}

	bool CTimeLineView::DrawNodeDialogView(const std::shared_ptr<timeline::CTimelineController>& TimelineController)
	{
		// NodeTrack
		if (ImGui::BeginTabItem("NodeTrack##Timeline_AddObjectTrackDialog_TabItem"))
		{
			static timeline::ENodeTrackTarget SelectedType = timeline::ENodeTrackTarget::NodeTrackTarget_None;
			std::string SelectedName = timeline::CNodeTrack::CastNodeTrackTarget_Str(SelectedType);

			static std::string SelectedName_Node = std::string();

			// Target
			if (m_ClickedObjectForAddObjectTrack)
			{
				if (ImGui::BeginCombo("Node##Timeline_AddObjectTrackDialog_NodeTrack_Combo", SelectedName_Node.c_str()))
				{
					for (const auto& Node : m_ClickedObjectForAddObjectTrack->GetNodeList())
					{
						std::string NodeName = std::to_string(Node->GetSelfNodeIndex()) + "_" + Node->GetName();

						std::string LabelSelectable = NodeName + "##Timeline_AddObjectTrackDialog_NodeItem_Selectable";

						const bool IsSelected = (m_SelectedNodeForAddTrack == Node);

						if (ImGui::Selectable(LabelSelectable.c_str(), IsSelected) && !IsSelected)
						{
							SelectedName_Node = NodeName;
							m_SelectedNodeForAddTrack = Node;
						}
					}

					ImGui::EndCombo();
				}
			}

			// Type
			if (ImGui::BeginCombo("Type##Timeline_AddObjectTrackDialog_NodeTrack_Combo", SelectedName.c_str()))
			{
				for (int i = 0; i < static_cast<int>(timeline::ENodeTrackTarget::NodeTrackTarget_Max); i++)
				{
					timeline::ENodeTrackTarget Type = static_cast<timeline::ENodeTrackTarget>(i);

					const bool IsSelected = (SelectedType == Type);

					std::string LabelSelectable = timeline::CNodeTrack::CastNodeTrackTarget_Str(Type) + "##Timeline_AddObjectTrackDialog_NodeTrack_Selectable";

					if (ImGui::Selectable(LabelSelectable.c_str(), IsSelected) && !IsSelected)
					{
						SelectedType = Type;
					}
				}

				ImGui::EndCombo();
			}

			// Add
			if (ImGui::Button("Add##Timeline_AddObjectTrackDialog"))
			{
				const auto& Clip = TimelineController->GetClip();
				if (Clip && m_SelectedNodeForAddTrack)
				{
					int SamplerIndex = static_cast<int>(Clip->GetSamplerList().size());
					std::string TrackID = timeline::CTimelineTrack::GenerateUUID();

					timeline::ETimelineSamplerTarget SamplerTarget = timeline::ETimelineSamplerTarget::NONE;
					animation::EInterpolationType InterpolationType = animation::EInterpolationType::LINEAR;

					if (SelectedType == timeline::ENodeTrackTarget::NodeTrackTarget_Rotation)
					{
						SamplerTarget = timeline::ETimelineSamplerTarget::ROTATION;
					}
					else if (SelectedType == timeline::ENodeTrackTarget::NodeTrackTarget_EnabledFlag)
					{
						// �I���I�t�t���O�̎���Step�ŕ⊮����
						InterpolationType = animation::EInterpolationType::STEP;
					}

					// Sampler
					std::shared_ptr<animation::CAnimationSampler> Sampler = std::make_shared<animation::CAnimationSampler>(InterpolationType);
					Clip->AddSampler(Sampler);

					// Track
					std::shared_ptr<timeline::CNodeTrack> Track = std::make_shared<timeline::CNodeTrack>(TrackID, SamplerIndex, SamplerTarget, SelectedType);
					Clip->AddTrack(Track);

					// TrackID���^�[�Q�b�g�Ɋ��蓖�Ă�
					m_SelectedNodeForAddTrack->AddRefTrackID(TrackID);
					Track->AssignTrackContent(m_SelectedNodeForAddTrack);

					// Object�ɎQ�ƒǉ�
					m_ClickedObjectForAddObjectTrack->AddTLNode(m_SelectedNodeForAddTrack);
				}

				m_ShowAddTrackDialog = false;
				m_ClickedObjectForAddObjectTrack = nullptr;
				m_SelectedNodeForAddTrack = nullptr;
				m_SelectedMaterialForAddTrack = nullptr;

				// static�ϐ��̃��Z�b�g
				SelectedType = timeline::ENodeTrackTarget::NodeTrackTarget_None;
				SelectedName_Node = std::string();
			}

			ImGui::EndTabItem();
		}

		return true;
	}

	bool CTimeLineView::DrawMaterialDialogView(const std::shared_ptr<timeline::CTimelineController>& TimelineController)
	{
		// MaterialTrack
		if (ImGui::BeginTabItem("MaterialTrack##Timeline_AddObjectTrackDialog_TabItem"))
		{
			static timeline::EMaterialTrackTarget SelectedType = timeline::EMaterialTrackTarget::MaterialTrackTarget_None;
			std::string SelectedName = timeline::CMaterialTrack::CastMaterialTrackTarget_Str(SelectedType);

			static std::string SelectedMaterialName = "";
			static std::string SelectedUniformName = "";
			static math::EValueType SelectedValueType = math::EValueType::VALUE_TYPE_NONE;

			// Target
			if (m_ClickedObjectForAddObjectTrack)
			{
				// Select Material
				if (ImGui::BeginCombo("Material##Timeline_AddObjectTrackDialog_Material_Combo", SelectedMaterialName.c_str()))
				{
					for (const auto& Mesh : m_ClickedObjectForAddObjectTrack->GetMeshList())
					{
						for (const auto& Primitive : Mesh->GetPrimitiveList())
						{
							for (const auto& Renderer : Primitive->GetRendererList())
							{
								const auto& Material = std::get<1>(Renderer);

								if (!Material) continue;

								const bool IsSelected = (m_SelectedMaterialForAddTrack == Material);

								std::string LabelSelectable = Material->GetMaterialName() + "##Timeline_AddObjectTrackDialog_Material_Selectable";

								if (ImGui::Selectable(LabelSelectable.c_str(), IsSelected) && !IsSelected)
								{
									SelectedMaterialName = Material->GetMaterialName();
									m_SelectedMaterialForAddTrack = Material;
								}
							}
						}
					}

					ImGui::EndCombo();
				}

				// Select Uniform
				if (ImGui::BeginCombo("Uniform##Timeline_AddObjectTrackDialog_Uniform_Combo", SelectedUniformName.c_str()))
				{
					if (m_SelectedMaterialForAddTrack)
					{
						// Uniform
						const auto& ShaderBufferList = m_SelectedMaterialForAddTrack->GetShaderBufferList();

						for (auto& UniformBuffer : ShaderBufferList)
						{
							const auto& BufferData = UniformBuffer->GetBuffer();

							const auto& Descriptor = UniformBuffer->GetDescriptor();

							for (const auto& UniformDataMap : Descriptor->GetDataList())
							{
								const auto& UniformData = UniformDataMap.second;
								const auto ValueInput = UniformData.ValueInput;

								const std::string& UniformName = UniformData.UniformName;
								math::EValueType ValueType = graphics::CUniformValueType::CastUniformToValueType(UniformData.ValueType);

								const bool IsSelected = (SelectedUniformName == UniformName);

								std::string LabelSelectable = UniformName + "##Timeline_AddObjectTrackDialog_Uniform_Selectable";

								if (ImGui::Selectable(LabelSelectable.c_str(), IsSelected) && !IsSelected)
								{
									SelectedUniformName = UniformName;
									SelectedValueType = ValueType;
								}
							}
						}
					}

					ImGui::EndCombo();
				}
			}

			if (ImGui::BeginCombo("Type##Timeline_AddObjectTrackDialog_MaterialTrack_Combo", SelectedName.c_str()))
			{
				for (int i = 0; i < static_cast<int>(timeline::EMaterialTrackTarget::MaterialTrackTarget_Max); i++)
				{
					timeline::EMaterialTrackTarget Type = static_cast<timeline::EMaterialTrackTarget>(i);

					const bool IsSelected = (SelectedType == Type);

					std::string LabelSelectable = timeline::CMaterialTrack::CastMaterialTrackTarget_Str(Type) + "##Timeline_AddObjectTrackDialog_MaterialTrack_Selectable";

					if (ImGui::Selectable(LabelSelectable.c_str(), IsSelected) && !IsSelected)
					{
						SelectedType = Type;
					}
				}

				ImGui::EndCombo();
			}

			if (ImGui::Button("Add##Timeline_AddObjectTrackDialog"))
			{
				const auto& Clip = TimelineController->GetClip();
				if (Clip && m_SelectedMaterialForAddTrack && !SelectedUniformName.empty() && SelectedValueType != math::EValueType::VALUE_TYPE_NONE)
				{
					int SamplerIndex = static_cast<int>(Clip->GetSamplerList().size());
					std::string TrackID = timeline::CTimelineTrack::GenerateUUID();

					timeline::ETimelineSamplerTarget SamplerTarget = timeline::ETimelineSamplerTarget::NONE;

					// Sampler
					std::shared_ptr<animation::CAnimationSampler> Sampler = std::make_shared<animation::CAnimationSampler>(animation::EInterpolationType::LINEAR);
					Clip->AddSampler(Sampler);

					// Track
					std::shared_ptr<timeline::CMaterialTrack> Track = std::make_shared<timeline::CMaterialTrack>(TrackID, SamplerIndex, SamplerTarget, SelectedType, SelectedUniformName, SelectedValueType);
					Clip->AddTrack(Track);

					// TrackID���^�[�Q�b�g�Ɋ��蓖�Ă�
					m_SelectedMaterialForAddTrack->AddRefTrackID(TrackID);
					Track->AssignTrackContent(m_SelectedMaterialForAddTrack);

					// Object�ɎQ�ƒǉ�
					m_ClickedObjectForAddObjectTrack->AddTLMaterial(m_SelectedMaterialForAddTrack);
				}

				m_ShowAddTrackDialog = false;
				m_ClickedObjectForAddObjectTrack = nullptr;
				m_SelectedNodeForAddTrack = nullptr;
				m_SelectedMaterialForAddTrack = nullptr;

				// static�ϐ��̃��Z�b�g
				SelectedType = timeline::EMaterialTrackTarget::MaterialTrackTarget_None;
				SelectedMaterialName = "";
				SelectedUniformName = "";
				SelectedValueType = math::EValueType::VALUE_TYPE_NONE;
			}

			ImGui::EndTabItem();
		}

		return true;
	}

	bool CTimeLineView::DrawAddCustomTrackDialog(const std::shared_ptr<timeline::CTimelineController>& TimelineController, const std::map<std::string, std::shared_ptr<scriptable::CValueRegistry>>& ValueRegistryList)
	{
		static std::string CurrentRegistry = std::string();

		if (ImGui::BeginCombo("ValueRegistryList##Timeline_AddCustomTrackDialog", CurrentRegistry.c_str()))
		{
			for (const auto& ValueRegistry : ValueRegistryList)
			{
				std::string RegistryName = ValueRegistry.first;

				const bool IsSelected = (RegistryName == CurrentRegistry);

				if (ImGui::Selectable(RegistryName.c_str(), IsSelected) && !IsSelected)
				{
					CurrentRegistry = RegistryName;

					
				}
			}

			ImGui::EndCombo();
		}

		if (ImGui::Button("Add##Timeline_AddCustomTrackDialog"))
		{
			if (!CurrentRegistry.empty())
			{
				const auto it = ValueRegistryList.find(CurrentRegistry);

				if (it != ValueRegistryList.end())
				{
					m_TrackValueRegistryList.emplace(it->second);
					CurrentRegistry = std::string();
				}
			}
		}

		return true;
	}

	bool CTimeLineView::DrawAddCustomValueDialog(const std::shared_ptr<timeline::CTimelineController>& TimelineController, const std::map<std::string, std::shared_ptr<scriptable::CValueRegistry>>& ValueRegistryList)
	{
		ImGuiIO& io = ImGui::GetIO();

		ImVec2 WindowSize = ImVec2(io.DisplaySize.x * 0.1f, io.DisplaySize.y * 0.1f);

		ImGui::SetNextWindowPos(ImVec2(io.MousePos.x, io.MousePos.y - WindowSize.y * 0.5f), ImGuiCond_Appearing, ImVec2(0.0f, 0.0f));
		ImGui::SetNextWindowSize(WindowSize, ImGuiCond_Appearing);

		if (ImGui::Begin("AddCustomTrack##Timeline", &m_ShowAddCustomTrackDialog))
		{
			static std::string SelectedValueName = std::string();
			
			if (m_SelectedValueRegistry)
			{
				// Target
				if (ImGui::BeginCombo("ValueName##Timeline_AddCustomValueDialog_CustomTrack_Combo", SelectedValueName.c_str()))
				{
					for (const auto& Value : m_SelectedValueRegistry->GetValueList())
					{
						std::string ValueName = Value.second.Name;

						const bool IsSelected = (SelectedValueName == ValueName);

						if (ImGui::Selectable(ValueName.c_str(), IsSelected) && !IsSelected)
						{
							SelectedValueName = ValueName;
						}
					}

					ImGui::EndCombo();
				}

				// Add
				if (ImGui::Button("Add##Timeline_AddCustomValueDialog"))
				{
					const auto& Clip = TimelineController->GetClip();
					if (Clip && !SelectedValueName.empty())
					{
						int SamplerIndex = static_cast<int>(Clip->GetSamplerList().size());
						std::string TrackID = timeline::CTimelineTrack::GenerateUUID();

						timeline::ETimelineSamplerTarget SamplerTarget = timeline::ETimelineSamplerTarget::NONE;
						animation::EInterpolationType InterpolationType = animation::EInterpolationType::LINEAR;

						// Sampler
						std::shared_ptr<animation::CAnimationSampler> Sampler = std::make_shared<animation::CAnimationSampler>(InterpolationType);
						Clip->AddSampler(Sampler);

						// Track
						std::shared_ptr<timeline::CCustomTrack> Track = std::make_shared<timeline::CCustomTrack>(TrackID, SamplerIndex, SamplerTarget, SelectedValueName);
						Clip->AddTrack(Track);

						// TrackID���^�[�Q�b�g�Ɋ��蓖�Ă�
						m_SelectedValueRegistry->AddRefTrackID(TrackID);
						Track->AssignTrackContent(m_SelectedValueRegistry);
					}

					m_ShowAddCustomTrackDialog = false;
					m_SelectedValueRegistry = nullptr;

					// static�ϐ��̃��Z�b�g
					SelectedValueName = std::string();
				}
			}
		}

		ImGui::End();

		return true;
	}

	bool CTimeLineView::CheckWheelExpand()
	{
		// �C���W�P�[�^�[�ƈꏏ�ɓ����Ȃ��悤�ɂ���
		if (m_ClickedIndicator) return true;

		// �}�E�X�z�C�[���ʂŊg�嗦���X�V
		ImGuiIO& io = ImGui::GetIO();
		const float MouseWheel = io.MouseWheel;

		if (ImGui::IsWindowHovered() && MouseWheel != 0.0f)
		{
			if (glm::sign(MouseWheel) == 1.0f && m_LargeMemoryWidth >= 100.0f)
			{
				// �ő�l��100.0
				return true;
			}
			else if (glm::sign(MouseWheel) == -1.0f && m_LargeMemoryWidth <= 0.01f)
			{
				// �ŏ��l��0.01
				return true;
			}

			const float Speed = 0.05f;
			const float Width = 0.1f;

			m_MemoryExpandRate += MouseWheel * Speed;

			if (m_MemoryExpandRate >= Width)
			{
				// �����������̒l��傫������
				m_LargeMemoryWidth *= 10.0f; 
				m_MemoryExpandRate = 0.0f;
			}
			else if (m_MemoryExpandRate <= -Width)
			{
				// �����������̒l������������
				m_LargeMemoryWidth *= 0.1f; 
				m_MemoryExpandRate = 0.0f;
			}
		}

		return true;
	}

	bool CTimeLineView::CheckMemoryDrag(const std::shared_ptr<timeline::CTimelineController>& TimelineController, const ImVec2& availableSize, float DrawMemorySpace, float MaxTime)
	{
		// �C���W�P�[�^�[�ƈꏏ�ɓ����Ȃ��悤�ɂ���
		if (m_ClickedIndicator) return true;

		const bool IsMemoryHovered = (ImGui::IsItemHovered() && ImGui::IsMouseDragging(0));
		const bool IsTLMiddleDrag = (ImGui::IsWindowHovered() && ImGui::IsMouseDragging(2));

		// �}�E�X�h���b�O�Ń������̍��[�ƉE�[�̒l���X�V
		if (IsMemoryHovered || IsTLMiddleDrag)
		{
			ImVec2 MousePos = ImGui::GetMousePos();

			if (!m_FirstClicked)
			{
				// �}�E�X�̈ړ��ʁB�`��\�͈͂Ő��K������
				float OffsetX = (MousePos.x - m_PrevMousePos.x) / availableSize.x; // ���[����E�[�ɍs������P���Ԃ�
				// ��. �������̒��j�̃T�C�Y��1.0�b�Ƃ���2.0�b���炩��3.0�b�Ɉړ������Ƃ���1.0�����悤�ɂ���
				//OffsetX = OffsetX * DrawMemorySpace * 4.0f;
				//OffsetX = OffsetX * DrawMemorySpace;
				OffsetX = OffsetX * DrawMemorySpace / 4.0f;

				// ���j�T�C�Y�Ŋg��k������
				OffsetX *= m_LargeMemoryWidth;

				m_LeftSideMemory -= OffsetX;
				m_RightSideMemory -= OffsetX;

				if (m_LeftSideMemory < 0.0f)
				{
					// 0�������ɍs���Ȃ��悤�ɂ���
					m_LeftSideMemory = 0.0f;
					m_RightSideMemory = static_cast<float>(m_MaxLargeMemoryCount) * m_LargeMemoryWidth;
				}

				// �������o�[�̍X�V�ɍ��킹�čĐ����Ԃ��X�V����
				UpdateCurrentTimeFromMemoryBar(TimelineController);
			}

			m_PrevMousePos = MousePos;
			m_FirstClicked = false;
		}
		else
		{
			m_FirstClicked = true;
		}

		return true;
	}

	bool CTimeLineView::CheckIsClickedObjectTree(const std::shared_ptr<object::C3DObject>& Object)
	{
		// Track�ǉ��_�C�A���O�\��
		// ObjectTreeNode�̉E�N���b�N�Ń_�C�A���O���J��
		if (ImGui::IsItemHovered() && ImGui::IsMouseClicked(1))
		{
			m_ShowAddTrackDialog = true;
			m_ClickedObjectForAddObjectTrack = Object;

			return true;
		}

		return false;
	}

	bool CTimeLineView::CheckIsClickedCustomTree(const std::shared_ptr<scriptable::CValueRegistry>& ValueRegistry)
	{
		// Track�ǉ��_�C�A���O�\��
		// CustomTreee�̉E�N���b�N�Ń_�C�A���O���J��
		if (ImGui::IsItemHovered() && ImGui::IsMouseClicked(1))
		{
			m_ShowAddCustomTrackDialog = true;
			m_SelectedValueRegistry = ValueRegistry;

			return true;
		}

		return false;
	}

	bool CTimeLineView::UpdateCurrentTimeFromMemoryBar(const std::shared_ptr<timeline::CTimelineController>& TimelineController)
	{
		// �������o�[�̏�񂩂�Đ����Ԃ��X�V
		float CurrentTime = glm::mix(m_LeftSideMemory, m_RightSideMemory, m_IndicatorRate);
		CurrentTime = glm::clamp(CurrentTime, 0.0f, TimelineController->GetMaxTime());

		TimelineController->SetPlayBackTime(CurrentTime);

		return true;
	}

	bool CTimeLineView::UpdateMemoryFromTimeBar(const std::shared_ptr<timeline::CTimelineController>& TimelineController)
	{
		// �^�C���o�[�̍X�V�ƍ��킹�ă������o�[���X�V
		const float CurrentTime = TimelineController->GetPlayBackTime();

		// �������o�[�̎��Ԃ̑S��
		const float TimeWidth = static_cast<float>(m_MaxLargeMemoryCount) * m_LargeMemoryWidth;

		m_LeftSideMemory = CurrentTime - TimeWidth * m_IndicatorRate;
		m_LeftSideMemory = glm::clamp(m_LeftSideMemory, 0.0f, TimelineController->GetMaxTime());

		m_RightSideMemory = m_LeftSideMemory + TimeWidth;

		return true;
	}

	float CTimeLineView::GetFirstLargeMemory(float SrcValue, std::vector<bool>& IsLongMemory)
	{
		// ��ԏ��߂ɏo�Ă��钷���������̒l���擾
		float DecimalPoint = SrcValue - floorf(SrcValue);
		
		float DstValue = 0.0f;

		if (DecimalPoint == 0.0f)
		{
			DstValue = SrcValue;
			IsLongMemory = std::vector<bool>({ true, false, false });
		}
		else if (DecimalPoint > 0.0f && DecimalPoint <= 0.3f)
		{
			DstValue = floorf(SrcValue) + 1.0f;
			IsLongMemory = std::vector<bool>({ false, false, true });
		}
		else if (DecimalPoint > 0.3f && DecimalPoint <= 6.0f)
		{
			DstValue = floorf(SrcValue) + 1.0f;
			IsLongMemory = std::vector<bool>({ false, true, false });
		}
		else if (DecimalPoint > 0.6f && DecimalPoint < 1.0f)
		{
			DstValue = floorf(SrcValue) + 1.0f;
			IsLongMemory = std::vector<bool>({ true, false, false });
		}

		return DstValue;
	}

	float CTimeLineView::GetFirstMemory(float SrcValue)
	{
		// ��ԏ��߂ɏo�Ă��郁�����̒l���擾(���Z�֌W�Ȃ�)
		float DecimalPoint = SrcValue - floorf(SrcValue);

		float DstValue = 0.0f;

		if (DecimalPoint == 0.0f)
		{
			DstValue = SrcValue;
		}
		else if (DecimalPoint > 0.0f && DecimalPoint <= 0.3f)
		{
			DstValue = floorf(SrcValue) + 0.3f;
		}
		else if (DecimalPoint > 0.3f && DecimalPoint <= 6.0f)
		{
			DstValue = floorf(SrcValue) + 0.6f;
		}
		else if (DecimalPoint > 0.6f && DecimalPoint < 1.0f)
		{
			DstValue = floorf(SrcValue) + 1.0f;
		}

		return DstValue;
	}

	float CTimeLineView::CalcXPosFromFrameTime(float FrameTime)
	{
		// �L�[�t���[���̎��Ԃ����E�̃������̎��Ԃɑ΂��Ăǂꂭ�炢�̊�����
		float t = (FrameTime - m_LeftSideMemory) / (m_RightSideMemory - m_LeftSideMemory);

		// ����������W�����߂�
		float XPos = glm::mix(m_LeftSideScreenPos.x, m_RightSideScreenPos.x, t);

		return XPos;
	}

	float CTimeLineView::CalcFrameTimeFromXPos(float XPos)
	{
		// XPos����t�v�Z���ăL�[�t���[���̎��Ԃ����߂�
		float t = (XPos - m_LeftSideScreenPos.x) / (m_RightSideScreenPos.x - m_LeftSideScreenPos.x);

		//float FrameTime = (1.0f - t) * m_LeftSideMemory + t * m_RightSideMemory;
		float FrameTime = glm::mix(m_LeftSideMemory, m_RightSideMemory, t);

		return FrameTime;
	}

	std::vector<float> CTimeLineView::GetDefaultValue(math::EValueType ValueType)
	{
		std::vector<float> Value;

		switch (ValueType)
		{
		case math::EValueType::VALUE_TYPE_NONE:
			break;
		case math::EValueType::VALUE_TYPE_SCALAR:
			Value = std::vector<float>({ 0.0f });
			break;
		case math::EValueType::VALUE_TYPE_VEC2:
			Value = std::vector<float>({ 0.0f, 0.0f });
			break;
		case math::EValueType::VALUE_TYPE_VEC3:
			Value = std::vector<float>({ 0.0f, 0.0f, 0.0f });
			break;
		case math::EValueType::VALUE_TYPE_VEC4:
			Value = std::vector<float>({ 0.0f, 0.0f, 0.0f, 0.0f });
			break;
		case math::EValueType::VALUE_TYPE_MAT2:
			Value = std::vector<float>({ 
				1.0f, 0.0f,
				0.0f, 1.0f
			});
			break;
		case math::EValueType::VALUE_TYPE_MAT3:
			Value = std::vector<float>({
				1.0f, 0.0f, 0.0f,
				0.0f, 1.0f, 0.0f,
				0.0f, 0.0f, 1.0f
			});
			break;
		case math::EValueType::VALUE_TYPE_MAT4:
			Value = std::vector<float>({
				1.0f, 0.0f, 0.0f, 0.0f,
				0.0f, 1.0f, 0.0f, 0.0f,
				0.0f, 0.0f, 1.0f, 0.0f,
				0.0f, 0.0f, 0.0f, 1.0f
			});
			break;
		case math::EValueType::VALUE_TYPE_VECTOR:
			break;
		case math::EValueType::VALUE_TYPE_MATRIX:
			break;
		default:
			break;
		}

		return Value;
	}
}
#endif