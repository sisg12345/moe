import os
import sequtils
import terminal
import strutils
import editorstatus
import ui
import fileutils
import editorview
import gapbuffer

proc refreshDirList(): seq[(PathComponent, string)] =
  result = newSeq[(PathComponent, string)]()
  result = @[(pcDir, "../")]
  for list in walkDir("./"):
    result.add list

proc writeFillerView(win: var Window, dirList: seq[(PathComponent, string)], currentLine: int) =
  var ch = newStringOfCap(1)
  for i in 0 ..< dirList.len:
    for j in 0 ..< dirList[i][1].len:
      if j > terminalWidth() - 2:
        if i == currentLine:
          win.write(i, j, "~", brightGreenDefault)
        else:
          win.write(i, j, "~")
        break
      else:
        ch[0] = dirList[i][1][j]
        if i == currentLine:
          win.write(i, j, ch, brightGreenDefault)
        else:
          win.write(i, j, ch)
        if j == dirList[i][1].len - 1 and i != 0 and dirList[i][0] == pcDir:
          if i == currentLine:
            win.write(i, j + 1, "/", brightGreenDefault)
          else:
            win.write(i, j + 1, "/")
  win.refresh

proc filerMode*(status: var EditorStatus) =
  setCursor(false)
  var viewUpdate = true
  var updateDirList = true
  var dirList = newSeq[(PathComponent, string)]()
  var key: int 
  var currentLine = 0

  while status.mode == Mode.filer:
    if updateDirList == true:
      dirList = @[]
      dirList.add refreshDirList()
      updateDirList = false

    if viewUpdate == true:
      status.mainWindow.erase
      writeStatusBar(status)
      status.mainWindow.writeFillerView(dirList, currentLine)
      viewUpdate = false

    key = getKey(status.mainWindow)
    if key == ord(':'):
      status.prevMode = status.mode
      status.mode = Mode.ex
    elif isResizekey(key):
      status.resize
      viewUpdate = true

    elif key == ord('j') and currentLine < dirList.len - 1:
      inc(currentLine)
      viewUpdate = true
    elif key == ord('k') and 0 < currentLine:
      dec(currentLine)
      viewUpdate = true
    elif isEnterKey(key):
      if dirList[currentLine][0] == pcFile:
        status = initEditorStatus()
        status.filename = dirList[currentLine][1]
        status.buffer = openFile(status.filename)
        status.view = initEditorView(status.buffer, terminalHeight()-2, terminalWidth()-status.buffer.len.intToStr.len-2)
        setCursor(true)
      elif dirList[currentLine][0] == pcDir:
        setCurrentDir(dirList[currentLine][1])
        currentLine = 0
        viewUpdate = true
        updateDirList = true
