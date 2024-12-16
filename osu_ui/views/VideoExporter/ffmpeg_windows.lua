local ffi = require("ffi")

ffi.cdef([[
	typedef void* HANDLE;
	typedef HANDLE* PHANDLE;
	typedef void * LPVOID;
	typedef unsigned short WORD;
	typedef unsigned long DWORD;
	typedef int BOOL;
	typedef char CHAR;
	typedef CHAR* LPSTR;
	typedef unsigned char BYTE;
	typedef BYTE *LPBYTE;

	typedef unsigned long ULONG_PTR;
	typedef ULONG_PTR SIZE_T;
	typedef void *PVOID;
	typedef CHAR *LPCSTR;
	typedef DWORD *LPDWORD;
	typedef const void *LPCVOID;

	typedef struct _SECURITY_ATTRIBUTES {
		DWORD  nLength;
		LPVOID lpSecurityDescriptor;
		BOOL   bInheritHandle;
	} SECURITY_ATTRIBUTES, *PSECURITY_ATTRIBUTES, *LPSECURITY_ATTRIBUTES;

	typedef struct _STARTUPINFOA {
		DWORD  cb;
		LPSTR  lpReserved;
		LPSTR  lpDesktop;
		LPSTR  lpTitle;
		DWORD  dwX;
		DWORD  dwY;
		DWORD  dwXSize;
		DWORD  dwYSize;
		DWORD  dwXCountChars;
		DWORD  dwYCountChars;
		DWORD  dwFillAttribute;
		DWORD  dwFlags;
		WORD   wShowWindow;
		WORD   cbReserved2;
		LPBYTE lpReserved2;
		HANDLE hStdInput;
		HANDLE hStdOutput;
		HANDLE hStdError;
	} STARTUPINFOA, *LPSTARTUPINFOA;

	typedef struct _PROCESS_INFORMATION {
		HANDLE hProcess;
		HANDLE hThread;
		DWORD  dwProcessId;
		DWORD  dwThreadId;
	} PROCESS_INFORMATION, *PPROCESS_INFORMATION, *LPPROCESS_INFORMATION;

	typedef struct _OVERLAPPED {
	  ULONG_PTR Internal;
	  ULONG_PTR InternalHigh;
	  union {
	    struct {
	      DWORD Offset;
	      DWORD OffsetHigh;
	    } DUMMYSTRUCTNAME;
	    PVOID Pointer;
	  } DUMMYUNIONNAME;
	  HANDLE    hEvent;
	} OVERLAPPED, *LPOVERLAPPED;

	BOOL CreatePipe(PHANDLE hReadPipe, PHANDLE hWritePipe, LPSECURITY_ATTRIBUTES lpPipeAttributes, DWORD nSize);
	BOOL SetHandleInformation(HANDLE hObject, DWORD dwMask, DWORD dwFlags);
	HANDLE GetStdHandle(DWORD nStdHandle);
	BOOL CreateProcessA(
		LPCSTR                lpApplicationName,
		LPSTR                 lpCommandLine,
		LPSECURITY_ATTRIBUTES lpProcessAttributes,
		LPSECURITY_ATTRIBUTES lpThreadAttributes,
		BOOL                  bInheritHandles,
		DWORD                 dwCreationFlags,
		LPVOID                lpEnvironment,
		LPCSTR                lpCurrentDirectory,
		LPSTARTUPINFOA        lpStartupInfo,
		LPPROCESS_INFORMATION lpProcessInformation
	);

	BOOL WriteFile(
		HANDLE       hFile,
		LPCVOID      lpBuffer,
		DWORD        nNumberOfBytesToWrite,
		LPDWORD      lpNumberOfBytesWritten,
		LPOVERLAPPED lpOverlapped
	);

	BOOL FlushFileBuffers(HANDLE hFile);
	BOOL CloseHandle(HANDLE hObject);
	DWORD WaitForSingleObject(HANDLE hHandle, DWORD  dwMilliseconds);
	BOOL GetExitCodeProcess(HANDLE  hProcess, LPDWORD lpExitCode);
	void *malloc(size_t size);
	void free(void *memblock);
	void *memset(void *str, int c, size_t n);
]])

-- https://stackoverflow.com/questions/24112779/how-can-i-create-a-pointer-to-existing-data-using-the-luajit-ffi
local function SafeHeapAlloc(typestr, finalizer)
	-- use free as the default finalizer
	if not finalizer then finalizer = ffi.C.free end

	-- automatically construct the pointer type from the base type
	local ptr_typestr = ffi.typeof(("%s *"):format(typestr))

	-- how many bytes to allocate?
	local typesize    = ffi.sizeof(typestr)

	-- do the allocation and cast the pointer result
	local ptr = ffi.cast(ptr_typestr, ffi.C.malloc(typesize))

	-- install the finalizer
	ffi.gc( ptr, finalizer )

	return ptr
end

local ffmpeg = {}

local HANDLE_FLAG_INHERIT = 1
local STD_ERROR_HANDLE = 4294967284
local STD_OUTPUT_HANDLE = 4294967285
local STARTF_USESTDHANDLES = 256
local INFINITE = 4294967295
local WAIT_FAILED = 4294967295

function ffmpeg:startRendering()
	local pipe_read = SafeHeapAlloc("HANDLE")
	local pipe_write = SafeHeapAlloc("HANDLE")

	local sa_attr = ffi.new("SECURITY_ATTRIBUTES")
	sa_attr.nLength = ffi.sizeof("SECURITY_ATTRIBUTES")
	sa_attr.bInheritHandle = true

	if ffi.C.CreatePipe(pipe_read, pipe_write, sa_attr, 0) == 0 then
		print("ERROR: Could not create pipe")
	end

	if ffi.C.SetHandleInformation(pipe_write[0], HANDLE_FLAG_INHERIT, 0) == 0 then
		print("ERROR: Could not SetHandleInformation")
	end

	local start_info = SafeHeapAlloc("STARTUPINFOA")

	ffi.C.memset(start_info, 0, ffi.sizeof("STARTUPINFOA"))
	start_info.cb = ffi.sizeof("STARTUPINFOA")
	start_info.hStdError = ffi.C.GetStdHandle(STD_ERROR_HANDLE)
	start_info.hStdOutput = ffi.C.GetStdHandle(STD_OUTPUT_HANDLE)
	start_info.hStdInput = pipe_read
	start_info.dwFlags = STARTF_USESTDHANDLES

	local proc_info = SafeHeapAlloc("PROCESS_INFORMATION")
	ffi.C.memset(proc_info, 0, ffi.sizeof("PROCESS_INFORMATION"))

	local cmd = [[ffmpeg.exe -loglevel verbose -y -f rawvideo -pix_fmt rgba -s 1280x720 -r 60 -i pipe:0 -c:v libx264 -vb 2500k -c:a aac -ab 200k -pix_fmt yuv420p output.mp4]]
	local c_cmd = ffi.new("char[?]", #cmd + 1)
	ffi.copy(c_cmd, cmd)

	local bSuccess = ffi.C.CreateProcessA(
		nil,
		c_cmd,
		nil,
		nil,
		true,
		0,
		nil,
		nil,
		start_info,
		proc_info
	);

	if bSuccess == 0 then
		print("ERROR: Could not create child process")
	end

	self.hProcess = proc_info.hProcess
	self.hPipeWrite = pipe_write

	ffi.C.WaitForSingleObject(self.hProcess, INFINITE)
end

function ffmpeg:sendFrame(data, width, height)
	ffi.C.WriteFile(self.hPipeWrite, data, width * height * 4, nil, nil)
end

function ffmpeg:endRendering()
	ffi.C.FlushFileBuffers(self.hPipeWrite)
	ffi.C.CloseHandle(self.hPipeWrite)

	local result = ffi.C.WaitForSingleObject(self.hProcess, INFINITE)

	if result == WAIT_FAILED then
		print("ERROR: could not wait on child proces")
		return
	end

	ffi.C.CloseHandle(self.hProcess)
end

return ffmpeg
