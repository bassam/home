import lldb, os, sys, StringIO

def stop_reason_to_str(enum):
    """Returns the stopReason string given an enum."""
    if enum == lldb.eStopReasonInvalid:
        return "invalid"
    elif enum == lldb.eStopReasonNone:
        return "none"
    elif enum == lldb.eStopReasonTrace:
        return "trace"
    elif enum == lldb.eStopReasonBreakpoint:
        return "breakpoint"
    elif enum == lldb.eStopReasonWatchpoint:
        return "watchpoint"
    elif enum == lldb.eStopReasonSignal:
        return "signal"
    elif enum == lldb.eStopReasonException:
        return "exception"
    elif enum == lldb.eStopReasonPlanComplete:
        return "plancomplete"
    elif enum == lldb.eStopReasonThreadExiting:
        return "threadexiting"
    else:
        raise Exception("Unknown StopReason enum")
def get_args_as_string(frame, showFuncName=True):
    vars = frame.GetVariables(True, False, False, True) # type of SBValueList
    args = [] # list of strings
    for var in vars:
        args.append("(%s)%s=%s" % (var.GetTypeName(),
                                   var.GetName(),
                                   var.GetValue()))
    if frame.GetFunction():
        name = frame.GetFunction().GetName()
    elif frame.GetSymbol():
        name = frame.GetSymbol().GetName()
    else:
        name = ""
    if showFuncName:
        return "%s(%s)" % (name, ", ".join(args))
    else:
        return "(%s)" % (", ".join(args))
def get_function_names(thread):
    def GetFuncName(i):
        return thread.GetFrameAtIndex(i).GetFunctionName()
    return map(GetFuncName, range(thread.GetNumFrames()))
def get_symbol_names(thread):
    def GetSymbol(i):
        return thread.GetFrameAtIndex(i).GetSymbol().GetName()
    return map(GetSymbol, range(thread.GetNumFrames()))
def get_pc_addresses(thread):
    def GetPCAddress(i):
        return thread.GetFrameAtIndex(i).GetPCAddress()
    return map(GetPCAddress, range(thread.GetNumFrames()))
def get_filenames(thread):
    def GetFilename(i):
        return thread.GetFrameAtIndex(i).GetLineEntry().GetFileSpec().GetFilename()
    return map(GetFilename, range(thread.GetNumFrames()))
def get_line_numbers(thread):
    def GetLineNumber(i):
        return thread.GetFrameAtIndex(i).GetLineEntry().GetLine()
    return map(GetLineNumber, range(thread.GetNumFrames()))
def get_module_names(thread):
    def GetModuleName(i):
        return thread.GetFrameAtIndex(i).GetModule().GetFileSpec().GetFilename()
    return map(GetModuleName, range(thread.GetNumFrames()))
def get_stack_frames(thread):
    def GetStackFrame(i):
        return thread.GetFrameAtIndex(i)
    return map(GetStackFrame, range(thread.GetNumFrames()))
def print_stacktrace(thread, string_buffer = False):
    output = StringIO.StringIO() if string_buffer else sys.stdout
    target = thread.GetProcess().GetTarget()
    depth = thread.GetNumFrames()
    mods = get_module_names(thread)
    funcs = get_function_names(thread)
    symbols = get_symbol_names(thread)
    files = get_filenames(thread)
    lines = get_line_numbers(thread)
    addrs = get_pc_addresses(thread)

    if thread.GetStopReason() != lldb.eStopReasonInvalid:
        desc =  "stop reason=" + stop_reason_to_str(thread.GetStopReason())
    else:
        desc = ""
    print >> output, "Stack trace for thread id={0:#x} name={1} queue={2} ".format(
        thread.GetThreadID(), thread.GetName(), thread.GetQueueName()) + desc

    for i in range(depth):
        frame = thread.GetFrameAtIndex(i)
        function = frame.GetFunction()

        load_addr = addrs[i].GetLoadAddress(target)
        if str(frame.GetPCAddress())[0] == '0':
            monoframe=frame.EvaluateExpression('(char*)mono_pmip((void*)' + str(frame.GetPCAddress()) + ')')
            print >> output, "  frame #{num}: {addr:#016x} {value}".format(num=i, addr=load_addr, value=monoframe.GetSummary())
        elif not function:
            file_addr = addrs[i].GetFileAddress()
            start_addr = frame.GetSymbol().GetStartAddress().GetFileAddress()
            symbol_offset = file_addr - start_addr
            print >> output, "  frame #{num}: {addr:#016x} {mod}`{symbol} + {offset}".format(
                num=i, addr=load_addr, mod=mods[i], symbol=symbols[i], offset=symbol_offset)
        else:
            print >> output, "  frame #{num}: {addr:#016x} {mod}`{func} at {file}:{line} {args}".format(
                num=i, addr=load_addr, mod=mods[i],
                func='%s [inlined]' % funcs[i] if frame.IsInlined() else funcs[i],
                file=files[i], line=lines[i],
                args=get_args_as_string(frame, showFuncName=False) if not frame.IsInlined() else '()')

    if string_buffer:
        return output.getvalue()
def print_stacktraces(p, string_buffer = False):
    output = StringIO.StringIO() if string_buffer else sys.stdout
    print >> output, "Stack traces for " + str(p)
    for thread in p:
        print >> output, print_stacktrace(thread, string_buffer=True)
    if string_buffer:
        return output.getvalue()

def monobacktrace(debugger, args, result, dict):
  print_stacktraces(debugger.GetTargetAtIndex(0).GetProcess())
  return None

def __lldb_init_module (debugger, dict):
  debugger.HandleCommand('command script add -f monobacktrace.monobacktrace monobacktrace')
