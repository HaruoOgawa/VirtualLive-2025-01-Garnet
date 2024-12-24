#ifdef USE_GUIENGINE
#include "CGUIObjectTab.h"
#include "CGUIMaterialTab.h"
#include "CGUIBaseTab.h"
#include "CGUIMeshTab.h"
#include "CGUIAnimationTab.h"

#include <Scene/CSceneController.h>
#include <Object/C3DObject.h>
#include <Message/Console.h>
#include <LoadWorker/CLoadWorker.h>

namespace gui
{
	CGUIObjectTab::CGUIObjectTab():
		m_SelectedObjectIndex(-1),
		m_SelectedNodeIndex(-1),
		m_SelectedName(""),
		m_OperateButtonID(-1),
		m_ShowAddObjectDialog(false),
		m_ShowAddNodeDialog(false)
	{
	}

	void CGUIObjectTab::Reset()
	{
		m_OperateButtonID = -1;
	}

	bool CGUIObjectTab::Draw(api::IGraphicsAPI* pGraphicsAPI, const SGUIParams& GUIParams)
	{
		Reset();

		if (ImGui::BeginTabItem("Object"))
		{
			
			if (!DrawObjectList(pGraphicsAPI, GUIParams)) return false;
			if (!DrawObjectDetail(pGraphicsAPI, GUIParams)) return false;

			ImGui::EndTabItem();
		}

		if (m_ShowAddObjectDialog)
		{
			if (!DrawAddObjectDialog(pGraphicsAPI, GUIParams)) return false;
		}

		if (m_ShowAddNodeDialog)
		{
			if (!DrawAddNodeDialog(pGraphicsAPI, GUIParams)) return false;
		}

		return true;
	}

	bool CGUIObjectTab::DrawObjectList(api::IGraphicsAPI* pGraphicsAPI, const SGUIParams& GUIParams)
	{
		if (ImGui::BeginChild("ObjectListChild", ImVec2(ImGui::GetContentRegionAvail().x, ImGui::GetContentRegionAvail().y * 0.25f), ImGuiChildFlags_Border, 0))
		{
			for (int CurrentObjectIndex = 0; CurrentObjectIndex < static_cast<int>(GUIParams.ObjectList.size()); CurrentObjectIndex++)
			{
				const auto& Object = GUIParams.ObjectList[CurrentObjectIndex];

				// OperateButton
				{
					m_OperateButtonID++;

					std::string BoxLabel = "##" + std::to_string(m_OperateButtonID);
					bool Flag = Object->IsEnabled();
					if (ImGui::Checkbox(BoxLabel.c_str(), &Flag))
					{
						Object->SetEnabled(Flag);
					}

					ImGui::SameLine();
				}

				// Object��TreeNode��z�u
				const bool IsOpend = ImGui::TreeNodeEx(Object->GetObjectName().c_str(), ImGuiTreeNodeFlags_OpenOnArrow | ImGuiTreeNodeFlags_Framed);

				if (ImGui::IsItemClicked(0) || ImGui::IsItemClicked(1))
				{
					m_SelectedObjectIndex = CurrentObjectIndex;
					m_SelectedNodeIndex = -1;

					m_SelectedName = Object->GetObjectName();

					if (ImGui::IsMouseClicked(1))
					{
						m_ShowAddNodeDialog = true;
					}
				}

				if (IsOpend)
				{
					// NodeList��TreeNode�ɔz�u
					const auto& NodeList = Object->GetNodeList();

					const auto& RootNodeIndexList = Object->GetRootNodeIndexList();
					if (!RootNodeIndexList.empty())
					{
						for (const int RootNodeIndex : RootNodeIndexList)
						{
							if (RootNodeIndex < 0 || RootNodeIndex >= NodeList.size()) continue;

							const auto& RootNode = NodeList[RootNodeIndex];
							if (!DrawNodeGUI(m_SelectedObjectIndex, m_SelectedNodeIndex, CurrentObjectIndex, RootNodeIndex, RootNode, NodeList)) return false;
						}
					}
					else
					{
						for (int NodeIndex = 0; NodeIndex < static_cast<int>(NodeList.size()); NodeIndex++)
						{
							const auto& Node = NodeList[NodeIndex];

							if (!DrawNodeGUI(m_SelectedObjectIndex, m_SelectedNodeIndex, CurrentObjectIndex, NodeIndex, Node, NodeList)) return false;
						}
					}

					ImGui::TreePop();
				}
			}

			if (ImGui::Button("AddObject##ObjectList"))
			{
				m_ShowAddObjectDialog = true;
			}

			// �I�u�W�F�N�g�̍폜
			if (ImGui::IsKeyReleased(ImGuiKey_Delete) && ImGui::IsWindowHovered())
			{
				GUIParams.SceneController->RemoveObject(m_SelectedObjectIndex);

				m_SelectedObjectIndex = -1;
				m_SelectedNodeIndex = -1;
			}

			ImGui::EndChild();
		}

		return true;
	}

	bool CGUIObjectTab::DrawNodeGUI(int& SelectedObjectIndex, int& SelectedNodeIndex, int CurrentObjectIndex, int CurrentNodeIndex,
		const std::shared_ptr<object::CNode>& Node, const std::vector<std::shared_ptr<object::CNode>>& NodeList)
	{
		// GUI�̕`��
		// OperateButton
		{
			m_OperateButtonID++;

			std::string BoxLabel = "##" + std::to_string(m_OperateButtonID);
			bool Flag = Node->IsEnabled();
			if (ImGui::Checkbox(BoxLabel.c_str(), &Flag))
			{
				Node->SetEnabled(Flag);
			}

			ImGui::SameLine();
		}

		//
		const bool IsOpened = ImGui::TreeNodeEx(Node->GetName().c_str(), ImGuiTreeNodeFlags_OpenOnArrow | ImGuiTreeNodeFlags_Framed);

		if (ImGui::IsItemClicked(0) || ImGui::IsItemClicked(1))
		{
			SelectedObjectIndex = CurrentObjectIndex;
			SelectedNodeIndex = CurrentNodeIndex;

			m_SelectedName = Node->GetName();

			if (ImGui::IsMouseClicked(1))
			{
				m_ShowAddNodeDialog = true;
			}
		}

		if (IsOpened)
		{
			// �q�v�f�̑��j
			for (const int ChildIndex : Node->GetChildrenNodeIndexList())
			{
				if (ChildIndex < 0 || ChildIndex >= NodeList.size()) continue;

				const auto& ChildNode = NodeList[ChildIndex];
				if (!DrawNodeGUI(SelectedObjectIndex, SelectedNodeIndex, CurrentObjectIndex, ChildIndex, ChildNode, NodeList)) return false;
			}

			ImGui::TreePop();
		}

		return true;
	}

	bool CGUIObjectTab::DrawObjectDetail(api::IGraphicsAPI* pGraphicsAPI, const SGUIParams& GUIParams)
	{
		// ImGui::GetContentRegionAvail().y * 0.5�Ƃ��̌��0�ɂ�����Ȃ񂩂���񂪂��������ɂ҂�����̈ʒu�ɔz�u���Ă����
		if (ImGui::BeginChild("ObjectDetailChild", ImVec2(ImGui::GetContentRegionAvail().x, 0), ImGuiChildFlags_Border, 0))
		{
			if (!m_SelectedName.empty())
			{
				ImGui::Text("%s", m_SelectedName.c_str());
			}

			if (ImGui::BeginTabBar("ObjectDetail"))
			{
				if (!CGUIBaseTab::Draw(GUIParams.ObjectList, m_SelectedObjectIndex, m_SelectedNodeIndex)) return false;
				if (!CGUIMaterialTab::Draw(pGraphicsAPI, GUIParams.ObjectList, GUIParams.SceneController, m_SelectedObjectIndex, m_SelectedNodeIndex)) return false;
				if (!CGUIMeshTab::Draw(pGraphicsAPI, GUIParams.ObjectList, GUIParams.SceneController, m_SelectedObjectIndex, m_SelectedNodeIndex)) return false;
				
				if (m_SelectedObjectIndex >= 0 && m_SelectedObjectIndex < static_cast<int>(GUIParams.ObjectList.size()))
				{
					const auto& Object = GUIParams.ObjectList[m_SelectedObjectIndex];
					const auto& Skeleton = Object->GetAnimationController()->GetSkeleton();

					if (!CGUIAnimationTab::DrawTab(Skeleton)) return false;
				}

				ImGui::EndTabBar(); // ObjectDetail
			}

			ImGui::EndChild();
		}

		return true;
	}

	bool CGUIObjectTab::DrawAddObjectDialog(api::IGraphicsAPI* pGraphicsAPI, const SGUIParams& GUIParams)
	{
		ImGuiIO& io = ImGui::GetIO();

		ImVec2 WindowSize = ImVec2(io.DisplaySize.x * 0.15f, io.DisplaySize.y * 0.15f);

		ImGui::SetNextWindowPos(ImVec2(io.MousePos.x - WindowSize.x * 0.5f, io.MousePos.y - WindowSize.y * 0.5f), ImGuiCond_Appearing, ImVec2(0.0f, 0.0f));
		ImGui::SetNextWindowSize(WindowSize, ImGuiCond_Appearing);

		if (ImGui::Begin("AddObject##ObjectTab", &m_ShowAddObjectDialog))
		{
			ImGui::Text("%s", "Basic Info");
			ImGui::SameLine();
			ImGui::Separator();

			// ObjectName
			static std::string ObjectName = std::string();
			{
				static char buf[256] = "";

				if (ImGui::InputText("ObjectName##AddObjectDialog", buf, IM_ARRAYSIZE(buf)))
				{
					ObjectName = std::string(buf);
				}
			}

			static int PassNum = 1;
			std::string PassNumLabel = "PassNum##PassNumLabel_CGUIObjectTab_DrawAddObjectDialog";
			ImGui::InputInt(PassNumLabel.c_str(), &PassNum);

			// PassName
			static std::string PassName = std::string();
			{
				static char buf[256] = "";

				if (ImGui::InputText("PassName##AddObjectDialog", buf, IM_ARRAYSIZE(buf)))
				{
					PassName = std::string(buf);
				}
			}

			// RigType
			static std::string Rig = std::string();
			{
				static char buf[256] = "";

				if (ImGui::InputText("Rig##AddObjectDialog", buf, IM_ARRAYSIZE(buf)))
				{
					Rig = std::string(buf);
				}
			}

			// DefaultMaterialframe
			static std::string DefaultMaterialframe = std::string();
			if (ImGui::BeginCombo("DefaultMaterialframe##CGUIObjectTab_DrawAddObjectDialog", DefaultMaterialframe.c_str()))
			{
				for (const auto& MaterialFrame : GUIParams.SceneController->GetMaterialFrameMap())
				{
					std::string Name = MaterialFrame.second->GetMaterialFrameName();

					const bool IsSelected = (DefaultMaterialframe == Name);

					if (ImGui::Selectable(Name.c_str(), IsSelected) && !IsSelected)
					{
						DefaultMaterialframe = MaterialFrame.second->GetMaterialFrameName();
					}
				}

				ImGui::EndCombo();
			}

			ImGui::Text("%s", "Add");
			ImGui::SameLine();
			ImGui::Separator();

			// AddEmpty
			if (ImGui::Button("AddEmpty##ObjectTab") && !ObjectName.empty())
			{
				m_ShowAddObjectDialog = false;

				// Object�쐬
				std::shared_ptr<object::C3DObject> Object = std::make_shared<object::C3DObject>();
				Object->SetObjectName(ObjectName);
				Object->AddPassName(PassName);

				// ToDo: ������������
				if (!Object->Create(pGraphicsAPI, nullptr, nullptr)) return false;

				GUIParams.SceneController->AddObject(Object);

				ObjectName = std::string();
				PassName = std::string();
				Rig = std::string();
			}

			// AddFile
			{
				
				static std::string fileName = std::string();

				if (ImGui::Button("AddFile##ObjectTab") && !ObjectName.empty() && !fileName.empty())
				{
					m_ShowAddObjectDialog = false;

					// Object�쐬
					std::shared_ptr<object::C3DObject> Object = std::make_shared<object::C3DObject>();
					Object->SetObjectName(ObjectName);
					Object->AddPassName(PassName);

					animation::ERigType RigType = animation::ERigType::None;
					if (Rig == "humanoid")
					{
						RigType = animation::ERigType::Humanoid;
					}

					std::vector<std::string> defaultmaterialframeList;
					defaultmaterialframeList.push_back(DefaultMaterialframe);

					GUIParams.SceneController->AddObjectWithLoading(GUIParams.pLoadWorker, Object, fileName, defaultmaterialframeList, RigType);

					ObjectName = std::string();
					PassName = std::string();
					Rig = std::string();
				}

				ImGui::SameLine();

				// fileName
				{
					static char buf[256] = "";
					if (ImGui::InputText("##AddObjectDialog_FileName", buf, IM_ARRAYSIZE(buf)))
					{
						fileName = std::string(buf);
					}
				}
			}
		}

		ImGui::End();

		return true;
	}

	bool CGUIObjectTab::DrawAddNodeDialog(api::IGraphicsAPI* pGraphicsAPI, const SGUIParams& GUIParams)
	{
		if (m_SelectedObjectIndex == -1) return true;

		ImGuiIO& io = ImGui::GetIO();

		ImVec2 WindowSize = ImVec2(io.DisplaySize.x * 0.15f, io.DisplaySize.y * 0.15f);

		ImGui::SetNextWindowPos(ImVec2(io.MousePos.x - WindowSize.x * 0.5f, io.MousePos.y - WindowSize.y * 0.5f), ImGuiCond_Appearing, ImVec2(0.0f, 0.0f));
		ImGui::SetNextWindowSize(WindowSize, ImGuiCond_Appearing);

		if (ImGui::Begin("AddNode##ObjectTab", &m_ShowAddNodeDialog))
		{
			// NodeName
			static std::string NodeName = std::string();
			{
				static char buf[256] = "";

				if (ImGui::InputText("NodeName##AddNodeDialog", buf, IM_ARRAYSIZE(buf)))
				{
					NodeName = std::string(buf);
				}

				if (ImGui::Button("Add##DrawAddNodeDialog"))
				{
					const auto& Object = GUIParams.SceneController->FindObjectByIndex(m_SelectedObjectIndex);

					if (Object)
					{
						std::shared_ptr<object::CNode> Node = std::make_shared<object::CNode>(-1, static_cast<int>(Object->GetNodeList().size()));
						Node->SetName(NodeName);

						Object->AddNode(Node);

						if (m_SelectedNodeIndex >= 0)
						{
							// �q�m�[�h��ǉ�
							const auto& ParentNode = Object->FindNodeByIndex(m_SelectedNodeIndex);

							ParentNode->AddChildrenNodeIndex(Node->GetSelfNodeIndex());
						}
						else
						{
							// �I�u�W�F�N�g�����Ƀ��[�g�m�[�h��ǉ�
							Object->AddRootNodeIndex(Node->GetSelfNodeIndex());
						}
					}

					m_ShowAddNodeDialog = false;

					std::memset(buf, 0, sizeof(buf));
					NodeName = std::string();
				}
			}
		}

		ImGui::End();

		return true;
	}
}
#endif