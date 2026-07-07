
dictContent := FileRead("dict.ini")
FileAppend(SubStr(dictContent, 1, 100), "out.txt", "UTF-8")

