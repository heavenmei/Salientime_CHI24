import os

def getfiles(file_path, fileEnd):
    getfiles = []
    sp = file_path
    for root, dirs, files in os.walk(sp):
        for file in files:
            getfile = os.path.join(root, file)
            if getfile.endswith(fileEnd):
                getfiles.append(getfile)
    return getfiles