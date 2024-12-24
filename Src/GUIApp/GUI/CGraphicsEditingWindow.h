#pragma once

#ifdef USE_GUIENGINE

#include <string>
#include <memory>
#include <imgui.h>

#include "CTimeLineView.h"
#include "C3DView.h"

#include "CGUIObjectTab.h"
#include "CGUIRenderingTab.h"
#include "CGUICameraTab.h"
#include "CGUIResourcesTab.h"
#include "CGUIMaterialFrameTab.h"
#include "CGUILogTab.h"
#include "CGUICustomTab.h"
#include "CGUIAnimationTab.h"

#include "SGUIParams.h"

#include <Interface/IGUIEngine.h>
#include <AppCore/CApp.h>

namespace api { class IGraphicsAPI; }

namespace gui
{
	class CGraphicsEditingWindow
	{
		CGUIObjectTab m_GUIObjectTab;
		CGUIResourcesTab m_GUIResourcesTab;
		CGUIMaterialFrameTab m_MaterialFrameTab;
		CGUILogTab m_LogTab;

		CTimeLineView m_TimeLineView;
		C3DView m_3DView;

		bool m_ShowSavedDialog;
	public:
		CGraphicsEditingWindow();
		virtual ~CGraphicsEditingWindow();

		// ���[�h�����C�x���g
		bool OnLoaded(api::IGraphicsAPI* pGraphicsAPI, const SGUIParams& GUIParams, const std::shared_ptr<gui::IGUIEngine>& GUIEngine);

		bool Draw(api::IGraphicsAPI* pGraphicsAPI, const SGUIParams& GUIParams,  const std::shared_ptr<gui::IGUIEngine>& GUIEngine);

		void AddLog(gui::EGUILogType LogType, const std::string Msg);

		void SetDefaultPass(const std::string& RenderPass, const std::string& DepthPass);
	};
}
#endif // USE_GUIENGINE