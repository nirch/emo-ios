import requests
import time
import zipfile
import os
import shutil

LOCALIZE_API_URL = "https://localise.biz/api/export/archive/strings.zip?filter=ios&key=5e31d04ef34ca004a6de866da3faa2ce"

def download_file(url):
    local_filename = "temp/localized_%d.zip" % int(time.time())
    # NOTE the stream=True parameter
    r = requests.get(url, stream=True)
    with open(local_filename, 'wb') as f:
        for chunk in r.iter_content(chunk_size=1024): 
            if chunk: # filter out keep-alive new chunks
                f.write(chunk)
                #f.flush() commented by recommendation from J.F.Sebastian
    return local_filename

def unzip(zipFilePath, destDir):
    zfile = zipfile.ZipFile(zipFilePath)
    for name in zfile.namelist():
        (dirName, fileName) = os.path.split(name)
        # Check if the directory exisits
        newDir = destDir + '/' + dirName
        if not os.path.exists(newDir):
            os.mkdir(newDir)
        if not fileName == '':
            # file
            fd = open(destDir + '/' + name, 'wb')
            fd.write(zfile.read(name))
            fd.close()
    zfile.close()

def grab_localization():
	print "Grabbing localization files zipped"
	try:
		shutil.rmtree('temp/emu-strings-archive')
	except:
		pass
	zip_file = download_file(LOCALIZE_API_URL)
	unzip(zip_file, "temp")

	# move files to project destination
	try:
		shutil.rmtree('../emu/localization')
	except:
		pass
	shutil.move('temp/emu-strings-archive/en.lproj', 'temp/emu-strings-archive/Base.lproj')
	os.rename('temp/emu-strings-archive', '../emu/localization')

	# remove temp files
	os.remove(zip_file)

if __name__ == "__main__":
	grab_localization()
