import shutil


if __name__ == '__main__':
	print "will update framework files"
	try:
		shutil.rmtree("HomageSDKCore.framework")
	except:
		pass

	try:
		shutil.rmtree("HomageSDKFlow.framework")
	except:
		pass

	shutil.copytree("/Users/aviv/Library/Developer/Xcode/DerivedData/HomageSDK-frvsrndvdzevnofmbzqzgumyngkl/Build/Products/Debug-iphoneos/HomageSDKCore.framework", "HomageSDKCore.framework")
	shutil.copytree("/Users/aviv/Library/Developer/Xcode/DerivedData/HomageSDK-frvsrndvdzevnofmbzqzgumyngkl/Build/Products/Debug-iphoneos/HomageSDKFlow.framework", "HomageSDKFlow.framework")