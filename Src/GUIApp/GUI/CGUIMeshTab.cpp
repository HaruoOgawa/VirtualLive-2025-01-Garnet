#ifdef USE_GUIENGINE
#include "CGUIMeshTab.h"
#include "../../Scene/CSceneController.h"
#include "../../Interface/IGraphicsAPI.h"
#include "../../Object/C3DObject.h"

namespace gui
{
	bool CGUIMeshTab::Draw(api::IGraphicsAPI* pGraphicsAPI, const std::vector<std::shared_ptr<object::C3DObject>>& ObjectList, const std::shared_ptr<scene::CSceneController>& SceneController,
		int SelectedObjectIndex, int SelectedNodeIndex)
	{
		if (ImGui::BeginTabItem("Mesh"))
		{
			if (SelectedObjectIndex != -1)
			{
				if (SelectedNodeIndex == -1)
				{
					// Object�̃��b�V�����X�g
					if (!DrawMeshGUIOfObject(pGraphicsAPI, ObjectList, SceneController, SelectedObjectIndex)) return false;
				}
				else
				{
					// Node�̃��b�V�����X�g
					if (!DrawMeshGUIOfNode(pGraphicsAPI, ObjectList, SceneController, SelectedObjectIndex, SelectedNodeIndex)) return false;
				}
			}

			ImGui::EndTabItem();
		}

		return true;
	}

	bool CGUIMeshTab::DrawMeshGUIOfObject(api::IGraphicsAPI* pGraphicsAPI, const std::vector<std::shared_ptr<object::C3DObject>>& ObjectList,
		const std::shared_ptr<scene::CSceneController>& SceneController, int SelectedObjectIndex)
	{
		// Object���擾
		if (SelectedObjectIndex < 0 || SelectedObjectIndex >= static_cast<int>(ObjectList.size())) return true;

		const auto& Object = ObjectList[SelectedObjectIndex];

		// Create Mesh
		{
			ImGui::SeparatorText("CreateMesh");

			// PresetType
			static graphics::EPresetPrimitiveType PresetType = graphics::EPresetPrimitiveType::None;
			{
				if (ImGui::BeginCombo("PresetType##DrawMeshGUIOfObject_CGUIMeshTab", GetStrFromPresetPrimitiveType(PresetType).c_str()))
				{
					for (int i = 0; i < static_cast<int>(graphics::EPresetPrimitiveType::Max); i++)
					{
						graphics::EPresetPrimitiveType CurrentPresetType = static_cast<graphics::EPresetPrimitiveType>(i);

						const bool IsSelected = (PresetType == CurrentPresetType);

						if (ImGui::Selectable(GetStrFromPresetPrimitiveType(CurrentPresetType).c_str(), IsSelected) && !IsSelected)
						{
							PresetType = CurrentPresetType;
						}
					}

					ImGui::EndCombo();
				}
			}

			// Material
			// MaterialName
			static std::string MaterialName = std::string();
			{
				static char buf[256] = "";

				if (ImGui::InputText("MaterialName##DrawMeshGUIOfObject_CGUIMeshTab", buf, IM_ARRAYSIZE(buf)))
				{
					MaterialName = std::string(buf);
				}
			}

			static std::string CurrentMaterialFrameName = std::string();

			if (ImGui::BeginCombo("MaterialFrame##DrawMeshGUIOfObject_CGUIMeshTab", CurrentMaterialFrameName.c_str()))
			{
				const auto& MaterialFrameMap = SceneController->GetMaterialFrameMap();

				for (const auto& MaterialFrame : MaterialFrameMap)
				{
					std::string Name = MaterialFrame.second->GetMaterialFrameName();

					const bool IsSelected = (CurrentMaterialFrameName == Name);

					if (ImGui::Selectable(Name.c_str(), IsSelected) && !IsSelected)
					{
						CurrentMaterialFrameName = MaterialFrame.second->GetMaterialFrameName();
					}
				}

				ImGui::EndCombo();
			}

			//
			static graphics::ECullMode CullMode = graphics::ECullMode::CULL_BACK;
			if (ImGui::BeginCombo("CullMode##DrawMeshGUIOfObject_CGUIMeshTab", GetStrFromCullMode(CullMode).c_str()))
			{
				for (int i = 0; i < static_cast<int>(graphics::ECullMode::Max); i++)
				{
					graphics::ECullMode CurrentCullMode = static_cast<graphics::ECullMode>(i);

					const bool IsSelected = (CullMode == CurrentCullMode);

					if (ImGui::Selectable(GetStrFromCullMode(CurrentCullMode).c_str(), IsSelected) && !IsSelected)
					{
						CullMode = CurrentCullMode;
					}
				}

				ImGui::EndCombo();
			}

			// AddMesh
			{
				if (ImGui::Button("AddMesh##DrawMeshGUIOfObject_CGUIMeshTab"))
				{
					if (PresetType != graphics::EPresetPrimitiveType::None)
					{
						// Material����
						std::shared_ptr<graphics::CMaterial> NewMaterial = nullptr;
						std::shared_ptr<graphics::CMaterialFrame> CurrentMaterialFrame = SceneController->FindMaterialFrame(CurrentMaterialFrameName);
						if (CurrentMaterialFrame)
						{
							NewMaterial = CurrentMaterialFrame->CreateMaterial(pGraphicsAPI, CullMode);
							NewMaterial->SetMaterialName(MaterialName);

							// ToDO: ������������
							if (!NewMaterial->Create(Object->GetPassNameList(), Object->GetTextureSet())) return false;
						}

						MaterialName = std::string();
						CurrentMaterialFrameName = std::string();
						CullMode = graphics::ECullMode::CULL_BACK;

						//
						std::shared_ptr<graphics::CMesh> Mesh = std::make_shared<graphics::CMesh>();

						const auto& CreateInfo = graphics::CPresetPrimitive::CreateFromType(pGraphicsAPI, PresetType);
						Mesh->CreatePresetSimpleMesh(pGraphicsAPI, CreateInfo.first, CreateInfo.second, NewMaterial, PresetType);

						// �v���Z�b�g�Ȃ̂ő�������
						if (!Mesh->Create(Object->GetTextureSet(), Object->GetPassNameList())) return false;

						Object->AddMesh(Mesh);
					}

					PresetType = graphics::EPresetPrimitiveType::None;
				}
			}
		}

		// Draw Mesh
		{
			ImGui::SeparatorText("MeshList");

			const auto& MeshList = Object->GetMeshList();

			for (int MeshIndex = 0; MeshIndex < static_cast<int>(MeshList.size()); MeshIndex++)
			{
				const auto& Mesh = MeshList[MeshIndex];

				if (!DrawMeshGUI(pGraphicsAPI, Object, Mesh, MeshIndex, SceneController)) return false;
			}
		}

		return true;
	}

	bool CGUIMeshTab::DrawMeshGUIOfNode(api::IGraphicsAPI* pGraphicsAPI, const std::vector<std::shared_ptr<object::C3DObject>>& ObjectList, const std::shared_ptr<scene::CSceneController>& SceneController,
		int SelectedObjectIndex, int SelectedNodeIndex)
	{
		if (SelectedObjectIndex == -1 || SelectedNodeIndex == -1) return true;

		// Object���擾
		if (SelectedObjectIndex < 0 || SelectedObjectIndex >= static_cast<int>(ObjectList.size())) return true;

		const auto& Object = ObjectList[SelectedObjectIndex];

		// Node���擾
		const auto& NodeList = Object->GetNodeList();
		if (SelectedNodeIndex < 0 || SelectedNodeIndex >= static_cast<int>(NodeList.size())) return true;

		const auto& Node = NodeList[SelectedNodeIndex];

		// Mesh���擾
		const auto& MeshList = Object->GetMeshList();
		int MeshIndex = Node->GetMeshIndex();
		if (MeshIndex < 0 || MeshIndex >= static_cast<int>(MeshList.size())) return true;

		const auto& Mesh = MeshList[MeshIndex];

		if (!DrawMeshGUI(pGraphicsAPI, Object, Mesh, MeshIndex, SceneController)) return false;

		return true;
	}

	bool CGUIMeshTab::DrawMeshGUI(api::IGraphicsAPI* pGraphicsAPI, const std::shared_ptr<object::C3DObject>& Object, const std::shared_ptr<graphics::CMesh>& Mesh, int MeshIndex,
		const std::shared_ptr<scene::CSceneController>& SceneController)
	{
		int OperateButtonID = 0;

		std::string TreeNodeLabel_Mesh = "Mesh##" + std::to_string(MeshIndex) + "GUIMeshTab_DrawMeshGUI_TreeNodeEx_Mesh_" + Object->GetObjectName();
		if (ImGui::TreeNodeEx(TreeNodeLabel_Mesh.c_str(), ImGuiTreeNodeFlags_Framed))
		{
			const auto& PrimitiveList = Mesh->GetPrimitiveList();

			for (int PrimitiveIndex = 0; PrimitiveIndex < static_cast<int>(PrimitiveList.size()); PrimitiveIndex++)
			{
				const auto& Primitive = PrimitiveList[PrimitiveIndex];

				// OperateButton
				{
					std::string BoxLabel = "##" + std::to_string(OperateButtonID);
					bool Flag = Primitive->IsEnabled();
					if (ImGui::Checkbox(BoxLabel.c_str(), &Flag))
					{
						Primitive->SetEnabled(Flag);
					}

					OperateButtonID++;

					ImGui::SameLine();
				}

				// Primitive Tree
				{
					std::string TreeNodeLabel_Primitive = "Primitive_" + std::to_string(PrimitiveIndex) + "##" + "GUIMeshTab_DrawMeshGUI_TreeNodeEx_Primitive_" + Object->GetObjectName();
					if (ImGui::TreeNodeEx(TreeNodeLabel_Primitive.c_str(), ImGuiTreeNodeFlags_Framed))
					{
						{
							graphics::EPresetPrimitiveType PresetType = Primitive->GetPresetType();

							std::string Text = "PresetType: " + GetStrFromPresetPrimitiveType(PresetType);

							ImGui::Text("%s", Text.c_str());
						}

						for (const auto& Renderer : Primitive->GetRendererList())
						{
							const auto& Material = std::get<1>(Renderer);
							if (Material)
							{
								std::string Text = "MaterialName: " + Material->GetMaterialName();

								ImGui::Text("%s", Text.c_str());
							}
						}

						ImGui::TreePop();
					}
				}
			}

			ImGui::TreePop();
		}

		return true;
	}

	std::string CGUIMeshTab::GetStrFromPresetPrimitiveType(graphics::EPresetPrimitiveType PresetType)
	{
		std::string Text = "";

		switch (PresetType)
		{
		case graphics::EPresetPrimitiveType::None:
			Text = "None";
			break;
		case graphics::EPresetPrimitiveType::BOARD:
			Text = "BOARD";
			break;
		case graphics::EPresetPrimitiveType::CUBE:
			Text = "CUBE";
			break;
		case graphics::EPresetPrimitiveType::POINT:
			Text = "POINT";
			break;
		case graphics::EPresetPrimitiveType::SPHERE:
			Text = "SPHERE";
			break;
		default:
			break;
		}

		return Text;
	}

	std::string CGUIMeshTab::GetStrFromCullMode(graphics::ECullMode CullMode)
	{
		std::string Text = "";

		switch (CullMode)
		{
		case graphics::ECullMode::CULL_NONE:
			Text = "CULL_NONE";
			break;
		case graphics::ECullMode::CULL_BACK:
			Text = "CULL_BACK";
			break;
		case graphics::ECullMode::CULL_FRONT:
			Text = "CULL_FRONT";
			break;
		default:
			break;
		}

		return Text;
	}
}
#endif