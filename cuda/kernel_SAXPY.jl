using CUDA

# 1. Define the device kernel
function saxpy_kernel!(a::Float32, x, y)
    # 1-based global thread index
    idx = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    if idx <= length(y)
        @inbounds y[idx] = muladd(a, x[idx], y[idx])
    end
    return nothing
end

# 2. Allocate on GPU and launch
N = 1_000_000
a = 2.0f0
x_d = CUDA.rand(Float32, N)   # Allocated directly in VRAM
y_d = CUDA.rand(Float32, N)

threads = 256
blocks = cld(N, threads)      # Ceiling division for grid size

@cuda threads=threads blocks=blocks saxpy_kernel!(a, x_d, y_d)
CUDA.synchronize()            # Wait for asynchronous GPU execution to finish

# (Note: For simple elementwise ops in Julia, `y_d .= a .* x_d .+ y_d` fuses into this exact kernel automatically!)