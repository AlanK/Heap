# Heap

`Heap` is a property wrapper that manages the heap allocation and lifecycle of imported C types like POSIX locks. You tell it what to initialize and any special setup or teardown, and it ensures your instance is allocated on the heap and that initialization, setup, teardown, and deinitialization occur at logical times.

iOS developers don’t often need to work with POSIX locks (use lib dispatch instead). If you do need to use them, though, they are easy to get wrong. POSIX locks must never be moved or copied, but Swift imports them as value types, so moves and copies happen automatically and implicitly. They require setup and teardown to avoid crashes and kernel resource leaks, but those steps are verbose and inconvenient. POSIX locks must be heap allocated, but the most common method for declaring them will occasionally send them to the stack due to compiler optimizations, causing rare (1:1000) crashes. Worst of all, these gotchas are poorly documented, and best practices have changed along with compiler behavior and language improvements over the past few years, so old resources with good page rank are not reliable.

With Heap, the boilerplate is hidden, the type-specific setup and teardown are isolated to the property declaration, and the instance is guaranteed to be heap allocated. The risk of accidentally using a pointer while it is in an unsafe state is also minimized.

You can download the entire playground or look at the code in `Heap.playground` > `Contents.swift`.
