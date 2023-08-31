local ffi = require("ffi")

local fftw3 = ffi.os == "Windows" and ffi.load("libfftw3-3") or ffi.load("fftw3")

ffi.cdef[[
	typedef double fftw_complex[2];
	typedef struct fftw_plan_s *fftw_plan;
	extern void fftw_execute(const fftw_plan p);
	extern fftw_plan fftw_plan_dft_1d(int n, fftw_complex *in, fftw_complex *out, int sign, unsigned flags);
	extern void fftw_destroy_plan(fftw_plan p);
]]

local Fftw = {}
Fftw.__index = Fftw

function Fftw:execute()
	assert(not self.destroyed, "plan is destroyed")
	fftw3.fftw_execute(self.plan)
end

function Fftw:destroy()
	fftw3.fftw_destroy_plan(self.plan)
	self.destroyed = true
end

local fftw = {}

---@param size number
---@return table
function fftw.new(size)
	local f = {}

	f.buffer_in = ffi.new("complex[?]", ffi.sizeof("complex") * size)
	f.buffer_out = ffi.new("complex[?]", ffi.sizeof("complex") * size)
	f.plan = fftw3.fftw_plan_dft_1d(size, f.buffer_in, f.buffer_out, -1, 64)

	return setmetatable(f, Fftw)
end

return fftw
