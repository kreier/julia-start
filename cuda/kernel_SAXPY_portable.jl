using CUDA, KernelAbstractions

@kernel function saxpy_ka!(a, @Const(x), y)
    idx = @index(Global)
    @inbounds y[idx] = muladd(a, x[idx], y[idx])
end

N = 1_000_000
x_d = CUDA.rand(Float32, N)
y_d = CUDA.rand(Float32, N)

# Backend is inferred automatically from the CuArray arguments
kernel = saxpy_ka!(get_backend(y_d))
kernel(2.0f0, x_d, y_d; ndrange=N)
KernelAbstractions.synchronize(get_backend(y_d))