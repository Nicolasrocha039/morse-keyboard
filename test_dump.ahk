
dictContent := FileRead("dict.ini", "UTF-8")
val := ""
Loop Parse, dictContent, "`n", "`r"
{
    if (SubStr(A_LoopField, 1, 9) = "digitacao") {
        parts := StrSplit(A_LoopField, "=")
        val := parts[2]
        break
    }
}
FileAppend(val, "ahk_output_test2.txt", "UTF-8")

