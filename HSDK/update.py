import shutil
import os
import sys

def print_description():
	print """update.py <env>
	Where <env> may be:
	debug   - Will copy from the debug build folder.
	release - Will copy from the release build folder.
	"""

if __name__ == '__main__':
	try:
		env = sys.argv[1]
	except:
		env = None

	if env != "debug" and env != "release":
		print_description()
		sys.exit(0)

	print "will update framework files for %s sdk build" % env

	try:
		shutil.rmtree("HomageSDKCore.framework")
	except:
		pass

	try:
		shutil.rmtree("HomageSDKFlow.framework")
	except:
		pass

	if env == "debug":
		# DEBUG
		shutil.copytree("/Users/aviv/Library/Developer/Xcode/DerivedData/HomageSDK-frvsrndvdzevnofmbzqzgumyngkl/Build/Products/Debug-iphoneos/HomageSDKCore.framework", "HomageSDKCore.framework")
		shutil.copytree("/Users/aviv/Library/Developer/Xcode/DerivedData/HomageSDK-frvsrndvdzevnofmbzqzgumyngkl/Build/Products/Debug-iphoneos/HomageSDKFlow.framework", "HomageSDKFlow.framework")

	else:
		# RELEASE
		shutil.copytree("/Users/aviv/Library/Developer/Xcode/DerivedData/HomageSDK-frvsrndvdzevnofmbzqzgumyngkl/Build/Products/Release-iphoneos/HomageSDKCore.framework", "HomageSDKCore.framework")
		shutil.copytree("/Users/aviv/Library/Developer/Xcode/DerivedData/HomageSDK-frvsrndvdzevnofmbzqzgumyngkl/Build/Products/Release-iphoneos/HomageSDKFlow.framework", "HomageSDKFlow.framework")
