using Pkg
Pkg.activate(pwd())

# # More complex networks
# ## Preparing data

using MLDatasets
using MLDatasets: MNIST

T = Float32
X_train, y_train = MLDatasets.MNIST(T, :train)[:]
X_test, y_test = MLDatasets.MNIST(T, :test)[:]

# ### Exercise:
# Plot the first 15 images of the digit 0 from the training set.
#
# **Hints:**:
# - The `ImageInspector` package written earlier provides the function
# `imageplot(X_train, inds; nrows=3)`, where `inds` are the desired indices.
# - To find the correct indices, use the function `findall`.
#
# ---
# ### Solution:

using Plots
using ImageInspector

unique(y_train)
inds = findall(y_train .== 0)[1:15]

imageplot(1 .- X_train, inds; nrows=3, size=(800,480))

# ---
#
# ### Exercise:
# Write function `reshape_data`, which reshapes `X_train` and `X_test` into the correct
# size required by Flux.
#
# **Hint**: The function should work only on inputs with the correct size. This can be
# achieved by specifying the correct input type `X::AbstractArray{<:Real, 3}`.
#
# ---
# ### Solution:

typeof(X_train)
size(X_train)

function reshape_data(X::AbstractArray{<:Real, 3})
    s = size(X)
    return reshape(X, s[1], s[2], 1, s[3])
end

# ---

using Flux
using Flux: onehotbatch, onecold

function load_data(dataset; T=Float32, onehot=false, classes=0:9)
    X_train, y_train = dataset(T, :train)[:]
    X_test, y_test = dataset(T, :test)[:]

    X_train = reshape_data(X_train)
    X_test = reshape_data(X_test)

    if onehot
        y_train = onehotbatch(y_train, classes)
        y_test = onehotbatch(y_test, classes)
    end

    return X_train, y_train, X_test, y_test
end

#+

X_train, y_train, X_test, y_test = load_data(MLDatasets.MNIST; T=T, onehot=true)


# ### Exercise:
# Try to load the CIFAR10 dataset via the `load_data` function and fix the error in one
# line of code.
#
# **Hint**: Use ` dataset = MLDatasets.CIFAR10`.
#
# ---
# ### Solution:

load_data(MLDatasets.CIFAR10; T=T, onehot=true)

#+

reshape_data(X::AbstractArray{<:Real, 4}) = X

#+

typeof(load_data(MLDatasets.CIFAR10; T=T, onehot=true))

# ---
#
# ## Training and storing the network
# ### Exercise:
# Use the help of the function `DataLoader` to split the dataset into minibatches.
#
# **Hint**: It needs to be imported from Flux via `using Flux.Data: DataLoader`.
#
# ---
# ### Solution:

using Flux.Data: DataLoader

batchsize = 32
batches = DataLoader((X_train, y_train); batchsize, shuffle = true)

# ---

using Base.Iterators: partition
using Random

batches = map(partition(randperm(size(y_train, 2)), batchsize)) do inds
    return (X_train[:, :, :, inds], y_train[:, inds])
end

#+

batches2 = [(X_train[:, :, :, inds], y_train[:, inds]) for inds in partition(randperm(size(y_train, 2)), batchsize)]

#+

using Random
using BSON

Random.seed!(666)
m = Chain(
    Conv((2,2), 1=>16, relu),
    MaxPool((2,2)),
    Conv((2,2), 16=>8, relu),
    MaxPool((2,2)),
    flatten,
    Dense(288, size(y_train,1)),
    softmax,
)

#+

using Flux: crossentropy

L(X, y) = crossentropy(m(X), y)

#+

function train_model!(m, L, X, y;
        opt = Descent(0.1),
        batchsize = 128,
        n_epochs = 10,
        file_name = "")

    batches = DataLoader((X, y); batchsize, shuffle = true)

    for _ in 1:n_epochs
        Flux.train!(L, params(m), batches, opt)
    end

    !isempty(file_name) && BSON.bson(file_name, m=m)

    return
end

# ### Exercise:
# Train the model for one epoch and save it to `MNIST_simple.bson`. Print the accuracy on
# the testing set.
#
# ---
# ### Solution:

using Statistics

file_name = joinpath(pwd(), "lecture_11", "data", "mnist_simple.bson")
train_model!(m, L, X_train, y_train; n_epochs=1, file_name=file_name)

#+

accuracy(x, y) = mean(onecold(m(x)) .== onecold(y))

"Test accuracy = " * string(accuracy(X_test, y_test)) |> println

# ---
#
# ### Exercise:
# Write a function `train_or_load!(file_name, m, args...; ???)` checking whether the file
# `file_name` exists.
# - If it exists, it loads it and then copies its parameters into `m` using the function
# `Flux.loadparams!`.
# - If it does not exist, it trains it using `train_model!`.
# In both cases, the model `m` should be modified inside the `train_or_load!` function. Pay
# special attention to the optional arguments `???`.
#
# Use this function to load the model from `data/mnist.bson` and evaluate the performance
# at the testing set.
#
# ---
# ### Solution:

function train_or_load!(file_name, m, args...; force=false, kwargs...)

    !isdir(dirname(file_name)) && mkpath(dirname(file_name))

    if force || !isfile(file_name)
        train_model!(m, args...; file_name=file_name, kwargs...)
    else
        m_weights = BSON.load(file_name)[:m]
        Flux.loadparams!(m, params(m_weights))
    end
end

file_name = joinpath(pwd(), "lecture_11", "data", "mnist_simple.bson")
train_or_load!(file_name, m, L, X_train, y_train)

"Test accuracy = " * string(accuracy(X_test, y_test)) |> println
