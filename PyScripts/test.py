##CREATING WORKDIR 
createfolder(WORKDIR,1)



###CREATING INPUT, OUTPUT AND LAYOUT FOLDERS AND THE FOLDERS INSIDE THEM.
folderspaths = []
###OUTPUT
folderspaths[0] = os.path.join(WORKDIR, "Output")
folderspaths[1] = os.path.join(folderspaths[0], "Liquidity")
folderspaths[3] = os.path.join(folderspaths[0], "Logs")
folderspaths[4] = os.path.join(folderspaths[0], "Reports")
folderspaths[5] = os.path.join(folderspaths[0], "Temp")
###INPUT
folderspaths[6] = os.path.join(WORKDIR, "Input")
folderspaths[7] = os.path.join(Input, "Dummy")
folderspaths[8] = os.path.join(Input, "External")
folderspaths[9] = os.path.join(Input, "Market")
folderspaths[10] = os.path.join(Input, "Positions")
###LAYOUTS
folderspaths[11]= os.path.join(WORKDIR, "Layouts")
###DATA BACK-UP
folderspaths[12] = os.path.join(WORKDIR, "TempDataDackup")

for ind, val in enumerate(folderspaths):
    createfolder(val,0)


tst = find_source(input_files[0][0],input_files[0][1])
print(tst)

for file_info in input_files:
        source = find_source()
    os.makedirs(file_info.TargetDir, exist_ok=True)
    shutil.copyfile(source, file_info.TargetDir/file_info.FileName)

    if file_info.FileName.endswith('.crproj'):
        pass


         finalpath = pathlib.Path(finalpath[0])
         print(finalpath)
         pathelements = os.path.split(finalpath)
         filename = pathelements[1]
         targetfilepath = pathlib.Path(TargetDir).joinpath(filename)