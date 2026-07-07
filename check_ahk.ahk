
dictContent := FileRead("dict.ini", "UTF-8")
val := ""
Loop Parse, dictContent, "`n", "`r"
{
    if (SubStr(A_LoopField, 1, 9) = "digitacao") {
        val := A_LoopField
        break
    }
}
FileAppend(val, "ahk_output_test.txt", "UTF-8")

