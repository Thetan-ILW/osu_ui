local ffi = require("ffi")

ffi.cdef([[
	int pipe(int pipefd[2]);
	int fork(void);
	int dup2(int oldfd, int newfd);
	int close(int fd);
	int execlp(const char *file, const char *arg, ...);
	int waitpid(int pid, int *status_ptr, int options);
	ssize_t write(int fs, const void *buf, size_t N);
]])

local READ_END = 0
local WRTIE_END = 1
local STDIN_FILENO = 0

---@class FFmpegPipe
local FFmpegPipe = {}

---@param width number
---@param height number
---@param fps number
function FFmpegPipe:startRendering(width, height, fps)
	local pipefd = ffi.new("int[2]")

	if ffi.C.pipe(pipefd) < 0 then
		error("ERROR: could not create a pipe")
	end

	local child = ffi.C.fork()

	if child < 0 then
		error("ERROR: could not fork a child")
	end

	if child == 0 then
		if (ffi.C.dup2(pipefd[READ_END], STDIN_FILENO) < 0) then
			error("ERROR: could not reopen read end of pipe as stdin")
		end
		ffi.C.close(pipefd[WRTIE_END])

		local ret = ffi.C.execlp("ffmpeg",
			"ffmpeg",
			"-loglevel", "verbose",
			"-y",

			"-f", "rawvideo",
			"-pix_fmt", "rgba",
			"-s", ("%ix%i"):format(width, height),
			"-r", ("%i"):format(fps),
			"-i", "-",

			"-vf",
			"fps=50,scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse",
			"output.gif",
			nil
		)
		--[[
		local ret = ffi.C.execlp("ffmpeg",
			"ffmpeg",
			"-loglevel", "verbose",
			"-y",

			"-f", "rawvideo",
			"-pix_fmt", "rgba",
			"-s", resolution,
			"-r", framerate,
			"-i", "-",

			"-c:v", "gif",
			--"-vb", "2500k",
			--"-c:a", "aac",
			--"-ab", "200k",
			--"-pix_fmt", "yuv420p",
			"video.mp4",
			nil)
		]]

		if (ret < 0) then
			error("ERROR: could not run ffmpeg as a child process")
		end
	end

	ffi.C.close(pipefd[READ_END])
	self.pid = child
	self.pipe = pipefd[WRTIE_END]
end

---@param data ffi.cdata*
---@param width number
---@param height number
function FFmpegPipe:sendFrame(data, width, height)
	ffi.C.write(self.pipe, data, width * height * 4)
end

function FFmpegPipe:endRendering()
	ffi.C.close(self.pipe)
	ffi.C.waitpid(self.pid, nil, 0)
end

return ffmpeg
