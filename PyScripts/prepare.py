from ntpath import join
import os
import sys
from datetime import datetime
from datetime import date
from config import Paths
import shutil
import pathlib 
from pathlib import Path
import logging
from collections import namedtuple
from glob import glob


logging.basicConfig()
logger = logging.getLogger(__name__.upper())

###DEFINE DIRECTORY
os.chdir('C:\\Users\\baselj\Desktop\FDB_Automation')
cwd = os.getcwd()
print(cwd)
today = date.today()
today = today.strftime("%y%m%d")
now=datetime.now()
timestamp=now.strftime("%d/%m/%Y %H:%M:%S")
if len(sys.argv) > 1:
    rundate = sys.argv[1] 
else:
    rundate =today
print(timestamp +" ~~~~~~~~~~~~~~~~~~~~~~ Started Preparation ~~~~~~~~~~~~~~~~~~~~~~")

##IMPORT CONFIG FILE
try:
    import config
except ImportError:
    print(timestamp +"ERROR: Automation configuration file was not found.")
    exit(2)
###Creating a work directory with the relevant date
date = datetime.strptime('20200101','%Y%m%d')
path = Paths(date)
WORKDIR = path.workdir
print(WORKDIR)
cwd = os.getcwd()
print(cwd)
override = 0


def createfolder(path, override):
    if os.path.exists(path):
         if override == 0: 
            logger.error(f" Preparation failed since {path} directory already exists. ")
            exit(2)
         else:
            logger.warning(f" Override flag is on. Removing existing {path} directory...)")
         shutil.rmtree(path)
         os.mkdir(path)
    else:
         os.mkdir(path)
    logger.info('DONE')
    logger.info(f"{path} FOLDER HAS BEEN CREATED")
 



#####STORING FILEINFO INSIDE NAMED TUPLES
FileInfo = namedtuple('FileInfo', 'SourceDir FileName IsDated TargetDir')
input_files = []
#1
input_files.append(FileInfo(
    path.templatedir/'Input/External',
    'Manual',
    False,
    path.workdir/'Input/External',
))
#2
input_files.append(FileInfo(
    SourceDir=path.templatedir/'Input/Dummy',
    FileName='dummy_cs',
    IsDated=False,
    TargetDir=path.workdir/'Input/Dummy',
))
#3
input_files.append(FileInfo(
    SourceDir=path.templatedir/'Input/Positions',
    FileName='ExternalparametersLiq',
    IsDated=False,
    TargetDir=path.workdir/'Input/Positions',
))
#4
input_files.append(FileInfo(
    SourceDir=path.templatedir/'Input/Positions',
    FileName='ExternalparametersMarket',
    IsDated=False,
    TargetDir=path.workdir/'Input/Positions',
))
#5
input_files.append(FileInfo(
    SourceDir=path.templatedir/'Input/Positions',
    FileName='TREE-COVER',
    IsDated=False,
    TargetDir=path.workdir/'Input/Positions',
))
#6
input_files.append(FileInfo(
    SourceDir=path.templatedir/'Input/Market',
    FileName='Market_Curves_and_TP',
    IsDated=False,
    TargetDir=path.workdir/'Input/Market',
))
#7
input_files.append(FileInfo(
    SourceDir=path.templatedir/'Input/Market',
    FileName='HistoricCPI',
    IsDated=False,
    TargetDir=path.workdir/'Input/Market',
))
#8
input_files.append(FileInfo(
    SourceDir=path.datadir,
    FileName='ACCOUNT_BAL_FULL',
    IsDated=True,
    TargetDir=path.workdir/'Input/Positions',
))
#9
input_files.append(FileInfo(
    SourceDir=path.datadir,
    FileName='BaNCS_customer',
    IsDated=True,
    TargetDir=path.workdir/'Input/External',
))
#10
input_files.append(FileInfo(
    SourceDir=path.datadir,
    FileName='BaNCS_portfolio',
    IsDated=True,
    TargetDir=path.workdir/'Input/External',
))
#11
input_files.append(FileInfo(
    SourceDir=path.datadir,
    FileName='BaNCS_cards',
    IsDated=True,
    TargetDir=path.workdir/'Input/Positions',
))
#12
input_files.append(FileInfo(
    SourceDir=path.datadir,
    FileName='BaNCS_currentaccountbalance',
    IsDated=True,
    TargetDir=path.workdir/'Input/Positions',
))
#13
input_files.append(FileInfo(
    SourceDir=path.datadir,
    FileName='BaNCS_deposits',
    IsDated=True,
    TargetDir=path.workdir/'Input/Positions',
))
#####LOANS FILE MISSING ADD WHEN NEEDED


def find_source(source,name,IsDated,TargetDir):
    if IsDated == True:
         newpath= os.path.join(source, name + '*[0-9].*')
         finalpath = glob(str(newpath))
         print(finalpath)
         return (finalpath)
    else:
         newpath = os.path.join(source, name + '.*')
         finalpath = glob(str(newpath))
         print(finalpath)
         return (finalpath) 

for file in input_files:
     source = find_source(file.SourceDir,file.FileName,file.IsDated,file.TargetDir)[0]
     source = str(source)
     #target = str(target)
     print (file.TargetDir)
     print(source)
     os.makedirs(file.TargetDir, exist_ok=True)
     shutil.copy(source, file.TargetDir)

    
    ### if file.FileName.endswith('.crproj'):
    ###     pass