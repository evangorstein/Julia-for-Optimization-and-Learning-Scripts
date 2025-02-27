using Pkg
Pkg.activate(pwd())

# # Unconstrained Optimization
# ## Visualization of gradients
# 
# ### Exercise: Contour plot
# Write a function `g(x)` which computes the derivative of `f` at a point  `x`.
# Plot the contours of `f` on the domain. 
#  
# **Hint:** Use the optional argument `color = :jet` for better visualization.
# 
# ---
# ### Solution:



# ---
# 
# ## Computation of gradients
# 
# ### Exercise: Finite difference approximation
# Write a function `finite_difference` which computes the approximation of $f'(x)$ by
# finite differences. The inputs are a function $f:\mathbb R\to\mathbb R$ and a point
# $x \in \mathbb{R}$. It should have an optional input $h \in \mathbb{R}$, for which
# you need to choose a reasonable value.
# 
# ---
# ### Solution:



# ---
# 
# ### Exercise: Finite difference approximation
# Fix a point $x = (-2,-1)$. For a proper discretization of $h \in [10^{-15}, 10^{-1}]$
# compute the finite difference approximation of the partial derivative of $f$ with 
# respect to the second variable.
# 
# Plot the dependence of this approximation on $h$. Add the true derivative computed
# from $g$.
# 
# ---
# ### Solution:



# ---

x = 1;
h = 1e-13;
(x+h)^2 - x^2
2*x*h + h^2

# ### Exercise: Direction of gradients
# Plot the contours of $f$ and its gradient at $(-2,-1)$.
# 
# ---
# ### Solution:



# ---
# 
# ## Numerical Methods
# ### Gradient Descent
# 
# ### Exercise: Gradient descent
# Implement function `optim`, which takes as inputs function $f$, its gradient,
# starting point $x^0$ and fixed stepsize $\alpha$ and runs the gradient descent.
# Its output should be the first 100 iterations.
# 
# This example is rather artificial because usually only the last iteration is returned
# and some stopping criterion is employed instead of the fixed number of iterations.
# We want to get all iterations to make visualizations.
# 
# ---
# ### Solution:



# ---

using Random

function create_anim(
    f,
    path,
    xlims,
    ylims,
    file_name = joinpath(pwd(), randstring(12) * ".gif");
    xbounds = xlims,
    ybounds = ylims,
    fps = 15,
)
    xs = range(xlims...; length = 100)
    ys = range(ylims...; length = 100)
    plt = contourf(xs, ys, f; color = :jet)

    # add constraints if provided
    if !(xbounds == xlims && ybounds == ylims)
        x_rect = [xbounds[1]; xbounds[2]; xbounds[2]; xbounds[1]; xbounds[1]]
        y_rect = [ybounds[1]; ybounds[1]; ybounds[2]; ybounds[2]; ybounds[1]]

        plot!(x_rect, y_rect; line = (2, :dash, :red), label="")
    end

    # add an empty plot
    plot!(Float64[], Float64[]; line = (4, :arrow, :black), label = "")

    # extract the last plot series
    plt_path = plt.series_list[end]

    # create the animation and save it
    anim = Animation()
    for x in eachcol(path)
        push!(plt_path, x[1], x[2]) # add a new point
        frame(anim)
    end
    gif(anim, file_name; fps = fps, show_msg = false)
    return nothing
end

# ### Exercise: Gradient descent
# Use the implementation of the gradient descent to minimize the function
# $$
# f(x) = \sin(x_1 + x_2) + \cos(x_1)^2
# $$
# from the starting point $x^0 = (0,-1)$. Use the constant stepsize $\alpha = 0.1$. 
# Store all iterations into matrix $xs$.
# 
# Use the `create_anim` function to plot the iteration into a gif file.
# 
# Use one line of code to evaluate the function values for all iterations $xs$ and plot 
# these function values.
# 
# **Hint:** to evaluate all $xs$ in one line, use iterate either via `eachcol(xs)` or
# `eachrow(xs)`.
# 
# ---
# ### Solution:



# ---
# $\alpha = 0.01$

x_gd = optim([], g, [0; -1], 0.01)
create_anim(f, x_gd, xlims, ylims, joinpath(pwd(), "lecture_08", "anim2.gif"))

# $\alpha = 1$

x_gd = optim([], g, [0; -1], 1)
create_anim(f, x_gd, xlims, ylims, joinpath(pwd(), "lecture_08", "anim3.gif"))

# ### Adaptive Stepsize

abstract type Step end

struct GD <: Step
    α::Float64
end

optim_step(s::GD, f, g, x) = -s.α*g(x)

function optim(f, g, x, s::Step; max_iter=100)
    xs = zeros(length(x), max_iter+1)
    xs[:,1] = x
    for i in 1:max_iter
        x += optim_step(s, f, g, x)
        xs[:,i+1] = x
    end
    return xs
end

gd = GD(0.1)
x_opt = optim(f, g, [0;-1], gd)

create_anim(f, x_opt, xlims, ylims, joinpath(pwd(), "lecture_08", "anim4.gif"))

# ### Exercise: Armijo condition
# Implement the `Armijo` subclass of the `Step` class. It should have two parameters 
# `c` from the definition and `α_max` which will be the initial value of $\alpha$.
# The value $\alpha$ should be divided by two until the Armijo condition is satisfied.
# 
# Then run the optimization with the Armijo stepsize selection and plot the animation.
# 
# ---
# ### Solution:
