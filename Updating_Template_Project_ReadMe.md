FDB Automation - Updating Template Project
==========================================

1. (Optional) All paths in `FDB.crproj` should be relative to its location.
1. (Required) All file names, in batches, portfolio definitions and external files, should be without dates.
   E.g. "Input\Positions\BaNCS_cards.csv" instead of "Input\Positions\BaNCS_cards_20210404_223104.csv".
1. (Required) "Duration Date", "Price Date" and "Vol Date" in Settings section of Toolbox (on the right) should be the same.
   Also this date must also be defined under `CRPROJ_DATE_PLACEHOLDER` parameter in "ScriptsAndDocs\config.bat" file
   (with 00:00:00 in hours section, e.g. `set CRPROJ_DATE_PLACEHOLDER=24/03/2021 00:00:00`).
1. (Required) All dates in all batch files should either be placeholders, e.g. "Volatility Date", "Price Date" or "Duration Date",
   or the same as the date defined in the toolbox (see previous point).
   In particular, "StartDate" in CFRisk batch tasks cannot be a placeholder, and must be the same as the date in toolbox.
   > Note:
   >
   > In case of "StartDate", `01/01/0001` date, i.e. the default value when deleting the date, will also work, in addition to the date that is equal to the date in toolbox.
1. (Required) Any input files added to ETL portfolios or external files, must be added to `INPUT_FILES` array in "ScriptsAndDocs\config.bat".
   > Note:
   >
   > Any files in "Data" or "Template" folders, or "Template"'s subfolders will be disregarded in daily automation process, unless added to `INPUT_FILES` array.
1. (Required) Any output files added to batches, must be added to `OUTPUT_FILES` array in "ScriptsAndDocs\config.bat".
   > Note:
   > 
   > * Any file not added to this array, may still be outputed during will daily automation process,
   > but this will not be validated and file's name will not be prepended with execution date.
   > * Input files from "Data" folder, e.g. BaNCS files, can also be added to "Template\Input"'s subfolders (without dates) in order to make sure that the project in "Template" folder is fully defined and works correctly. E.g. you can run its batches to make sure.
1. (Required) New batches should also be added to one of `ETL_BATCHES`, `CONVERT_BATCHES` or `REPORT_BATCHES` parameters in "ScriptsAndDocs\config.bat".
   Otherwise, they will not be executed during daily automation.
1. (Required) All layouts used in batches should be located in the folder defined under `LAYOUTS_DIRNAME` parameter in "ScriptsAndDocs\config.bat" ("Template\Layouts" by default).
1. When moving the automation to another location, e.g. a different computer,
   make sure to update all the parameters that define paths in "ScriptsAndDocs\config.bat" (if needed).
1. After updating anything in `Template` folder or in `ScriptsAndDocs\config.bat` file,
   run `ScriptsAndDocs\test_for_yesterday.bat` (or `ScriptsAndDocs\test.bat`) to test that everything is working correctly.

Tips
----

1. After each daily automation run, the project for that run, including all input and output files, will be located in the folder defined by `WORK_DIR` parameter in "ScriptsAndDocs\config.bat" ("Archive\YYYYMMDD" by default, where YYYYMMDD stands for the date in the appropriate format).  
   This folder can be copied to any location and should be ready to work without a need to change any configurations.  
   Thus, if there is a need to update the project, one can replace "Template"'s contents with its contents, after which the required changes must ne made (make sure to backup "Template" folder beforehand).
1. In case of CompuRisk's license renewal, the new license may effect the Control-M automation, and the expired license may make it fail.
   Since updating the license for automation purposes may require logging in as `ctmuser` and/or `system` user, it may not be possible.
   In this case, one can log in with a regular user, with local administrative privileges, and
   * Update the license for that user.
   * Copy `%APPDATA%\Hedge-Tech\CompuRisk\CR New License.xml` file to `C:\Users\ctmuser\AppData\Roaming\Hedge-Tech\CompuRisk` folder.
   * (Optional) Previous, invalid Control-M agent's behavior configuration, resulted in CompuRisk running as `system`/`Administrator` user instead of `ctmuser`.
     For this user, `%APPDATA%\Hedge-Tech\CompuRisk\CR New License.xml` file should be copied to `C:\Windows\System32\config\systemprofile\AppData\Roaming\Hedge-Tech\CompuRisk` folder.
     The solution for this problem on Control-M's side is to configure locally installed Control-M app to "Run as User". Also, `ctmuser` may need to be configured as local administrator.
