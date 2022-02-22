@echo off
REM Install Ghostscript 64bit from http://www.ghostscript.com/download/gsdnld.html
REM Shrink all pdfs files in the current directory where this script is run and output to the
REM compressed sub-folder
setlocal
set GS_BIN=C:\Program Files\gs\gs9.55.0\bin\gswin64c.exe
set GS_OUTPUT_DIR=compressed
mkdir %GS_OUTPUT_DIR% 
for %%i in (*.pdf) do "%GS_BIN%" -dNOPAUSE -dBATCH -dSAFER -dPDFSETTINGS=/printer -dCompatibilityLevel=1.4 -sDEVICE=pdfwrite -sOutputFile="%GS_OUTPUT_DIR%\%%i" "%%i"