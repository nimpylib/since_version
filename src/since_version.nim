
import std/macros
import ./private/utils
export asVersion

template gen_since*(py: untyped; PyMajor, PyMinor, PyPatch){.dirty.} =
  bind MajorMinorVersion, toVer
  bind addDocImplAux, genWrapCall
  bind nnkStmtList, ntyProc
  bind kind, newCall, typeKind
  bind bindSym, newLit
  template `exportSince py`*(major, minor: int, sym: typed) =
    bind PyMajor, PyMinor
    when (PyMajor, PyMinor) >= (major, minor):
      export sym

  when defined(nimdoc):
    template descSince(ver: string): string =
      " .. admonition:: since Python " & ver & "\n\n"
    func addDocImpl(major, minor: int; def: NimNode): NimNode =
      addDocImplAux(asVersion(major, minor).descSince, def)
    macro `py since`*(major, minor: static int, def) =
      if kind(def) == nnkStmtList:
        result = def
      else:
        result = addDocImpl(major, minor, def)

    macro `wrapExportSince py`*(major, minor: static int, sym: typed) =
      if typeKind(sym) == ntyProc:  # includes template, macro
        let def = genWrapCall(sym)
        result = addDocImpl(major, minor, def)
      else:
        result = newCall(bindSym("exportSince" & astToStr(py)), newLit(major), newLit(minor), sym)

  else:
    template `py since`*(major, minor: int, def){.dirty.} =
      bind PyMajor, PyMinor
      when (PyMajor, PyMinor) >= (major, minor):
        def
    template `wrapExportSince py`*(major, minor: int, sym: typed) =
      #bind `exportSince py`
      `exportSince py`(major, minor, sym)


  template `py since`*[R](ver: MajorMinorVersion, defExpr, elseExpr: R): R =
    bind PyMajor, PyMinor
    when (PyMajor, PyMinor) >= ver: defExpr
    else: elseExpr


  func `py since`*[R](ver: static[float|MajorMinorVersion]; defExpr, elseExpr: R): R{.inline.} =
    bind PyMajor, PyMinor, toVer
    when (PyMajor, PyMinor) >= toVer(ver): defExpr
    else: elseExpr

when defined(nimdoc):
  const
    PyMajor = 3
    PyMinor = 10
    PyPatch = 0
  gen_since py, PyMajor, PyMinor, PyPatch

  proc demo*{.pysince(3,9).} =
    ## not public API. just demo for testing

