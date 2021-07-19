import os

def createFolders(HOME_FOLDER):
    for i in range(10):
            os.mkdir(HOME_FOLDER + str(i) + '-Dir')
    
createFolders('C:\\Users\\baselj\Desktop\FDB_Automation\ScriptsAndDocs\\tst\\alo')