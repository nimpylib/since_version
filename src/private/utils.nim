
from std/strutils import parseInt, split, formatFloat

const sep = '.'
template asVersion*(major, minor: int): string =
  bind sep
  $major & sep & $minor
template asVersion*(major, minor, patch: int): string =
  bind sep
  $major & sep & $minor & sep & $patch
func asVersion*(v: (int, int)): string = asVersion(v[0], v[1])
func asVersion*(v: (int, int, int)): string = asVersion(v[0], v[1], v[2])

import std/macros
proc newCallFrom*(sym, params: NimNode): NimNode =
  result = newCall(sym)
  for i in 1..<params.len:
    result.add params[i][0]


when defined(nimdoc):

  proc genWrapCall*(sym: NimNode): NimNode =
    result = sym.getImpl()         
    var call = sym.newCallFrom result.params
    case result.kind
    of nnkIteratorDef:
      call = quote do:
        for i in `call`: yield i
    of nnkMacroDef, nnkTemplateDef:
      var nres = newNimNode nnkTemplateDef
      nres.add postfix(ident result[0].strVal, "*") # get rid of
      #    Error: cannot use symbol of kind 'macro' as a 'template
      for i in 1..<result.len-1:  # skip body
        nres.add result[i]
      nres.add newEmptyNode()
      result = nres
    else: discard
    result.body = newStmtList call

  func preappendDoc(body: NimNode, doc: string) =
    let first = body[0]
    if first.kind == nnkCommentStmt:
        body[0] = newCommentStmtNode(doc & first.strVal)
    else:
        body.insert(0, newCommentStmtNode doc)
  func addDocImplAux*(doc: string; def: NimNode): NimNode =
    result = def
    case def.kind
    of RoutineNodes:
      preappendDoc result.body, doc
    else:
      error "not impl for node kind: " & $def.kind, def
      ## XXX: I even don't know how to add
      ##   as diagnosis tools like dumpTree just omit doc node of non-proc node
else:
  template unavail(def) = error "only can be used when defined(nimdoc)", def
  func addDocImplAux*(doc: string; def: NimNode): NimNode = unavail def
  proc genWrapCall*(sym: NimNode): NimNode = unavail sym

type MajorMinorVersion* = tuple[major, minor: int]
template toVer*(s: MajorMinorVersion): MajorMinorVersion = s
func toVer*(s: static float): MajorMinorVersion{.compileTime.} =
  result.major = int(s)
  let minorS = formatFloat(s, precision = -1).split('.')[1]
  let minor = parseInt minorS
  when sizeof(int) >= 8:
   assert minor < int 1e10,  # 1e10 is a picked not very strictly.
    "must be in format of major.minor, " & "but got " & $s
  result.minor =  minor

