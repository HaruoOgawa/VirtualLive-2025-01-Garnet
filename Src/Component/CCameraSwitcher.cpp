#include "CCameraSwitcher.h"

namespace component
{
	CCameraSwitcher::CCameraSwitcher(const std::string& ComponentName, const std::string& RegistryName) :
		CComponent(ComponentName, RegistryName)
	{
		GetValueRegistry()->SetValue("CameraIndex", graphics::EUniformValueType::VALUE_TYPE_INT, &glm::ivec1(-1)[0], sizeof(int));
	}

	CCameraSwitcher::~CCameraSwitcher()
	{
	}
}