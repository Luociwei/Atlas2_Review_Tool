Script_Version = "1.0.12"

*****************************************************************

script Ver: 1.0.12
change date: 20211102
SW engineer: Jayson Ye

1. Add raiseErrorWhenFailed function to DUTCmd.sendCmdAndCreateRecord method.
2. Add hang detect function to DUTCmd.sendCmdAndCheckError method.
3. Add raiseErrorWhenNotFound function to Process.checkExpect method.
4. Add getting the pattern from AdditionalParameters in Smokey.smokeyPcieParse method.
5. Add USBC.checkXavierACEFW and USBC.checkLocalACEFW method to check the ace fw bin file.

*****************************************************************

*****************************************************************

script Ver: 1.0.11
change date: 20211029
SW engineer: Jayson Ye/Roy Fang/Ryan Gao

1. Add USBC.lua to support ACE FW download and ACE OTP download.

*****************************************************************


*****************************************************************

script Ver: 1.0.10
change date: 20211027
SW engineer: Jayson Ye/FX SW Team

1. Add .virtualportlog file at /OverlayRoot/private/etc/StationSetup/1stBoot/ToInstall/900_SpecialTools.root/Users/gdlocal.
2. Add checking RTOS&RBM SW version at SOC.lua.

*****************************************************************

*****************************************************************

script Ver: 1.0.9
change date: 20211021
SW engineer: Jayson Ye/FX SW Team

1. Add checking the expected value for SOC.getEnvVersion function if the expected value is define in test plan.

*****************************************************************

*****************************************************************

script Ver: 1.0.8
change date: 20211015
SW engineer: Jayson Ye

1. Add a new way which using the string.match function to get the Storage Size, because the Regex.groups function does not 
work after change the MT Sib board(Suspected that there are some error char in the beginning of the uart log file).

*****************************************************************

*****************************************************************

script Ver: 1.0.7
change date: 20211015
SW engineer: Jayson Ye

1. Update ref RunTest plugin version to v1.0.7 to fix the parse RTOS version failed issue.

*****************************************************************

*****************************************************************

script Ver: 1.0.6
change date: 20210928
SW engineer: Jayson Ye

1. Update the record creation in common.delay function.

*****************************************************************

*****************************************************************

script Ver: 1.0.5
change date: 20210927
SW engineer: Jayson Ye

1. Change the format of function description according to the station DRI requirement.

*****************************************************************

*****************************************************************

script Ver: 1.0.4
change date: 20210924
SW engineer: Jayson Ye/Ethan

1. As value in Condition.csv is string type, but output returned is number type, so update function “sendAndParseCommandWithPlugin” to return a string type vaule for condition ProductID.

*****************************************************************


*****************************************************************

script Ver: 1.0.3
change date: 20210922
SW engineer: Jayson Ye

1. Update addLogToInsight function, rename uart log file with the inputValue of paraTab(Serialnumber) and change the name of Archive "when" Constants according to Atlas2 version.
2. Update checkExpect function, check expect value from uart log when the input value is nil.
3. Update the parseFCE function, Change the attribute name to "NAND_FCE[i]" from "FCE[i]" and change the item name to "FCE[i]" from "FCE0[i]", remove the NAND_ID attribute in lua code.
4. Change to get the mlb_sn or mlb_cfg attribute name from AdditionalParameters.
5. Add getExpectedVersionWithKey function to get the expected version which define in verison compare file.
6. Remove creating the BBLib_Ver and BB_SNUM Attribute from smokeyRunAndParse function.

*****************************************************************

*****************************************************************

script Ver: 1.0.2
change date: 20210913
SW engineer: Jayson Ye

1. Move the fixture dylib as a mink module.

*****************************************************************

*****************************************************************

script Ver: 1.0.1
change date: 20210831
SW engineer: Jayson Ye

1. Update the initial version for DFU&SoC common overlay.

*****************************************************************















