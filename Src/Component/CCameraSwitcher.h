#pragma once

#include <Scriptable/CComponent.h>
#include <vector>
#include <memory>

namespace object { class C3DObject; }
namespace object { class CNode; }

namespace component
{
	class CCameraSwitcher : public scriptable::CComponent
	{
	public:
		CCameraSwitcher(const std::string& ComponentName, const std::string& RegistryName);
		virtual ~CCameraSwitcher();
	};
}