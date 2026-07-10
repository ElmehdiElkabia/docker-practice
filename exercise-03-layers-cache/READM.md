# Exercise 03 — Docker Layers & Build Cache

## Objective

The goal of this exercise is to understand:

* How Docker builds images layer by layer
* How Docker build cache works
* Why Dockerfile instruction order matters
* Why we copy dependency files before source code
* How `.dockerignore` works

---

## Project Structure

```text
exercise-03-layers-cache/
├── Dockerfile
├── .dockerignore
├── Makefile
├── README.md
└── src/
    ├── main.cpp
    └── message.cpp
```

---

## Requirements

Create a simple C++ application that prints:

```text
Docker cache experiment!
```

The Dockerfile must:

1. Use `debian:bookworm` as the base image.
2. Set `/app` as the working directory.
3. Install `g++` and `make`.
4. Copy the `Makefile` first.
5. Copy the `src/` directory after.
6. Compile the application with `make`.
7. Run the application when the container starts.
8. Do not use `COPY . .`.

---

## Dockerfile

```dockerfile
FROM debian:bookworm

WORKDIR /app

RUN apt-get update && \
    apt-get install -y g++ make && \
    rm -rf /var/lib/apt/lists/*

COPY Makefile .

COPY src/ ./src/

RUN make

CMD ["./app"]
```

---

## Build the Image

```bash
docker build -t ex03-cache .
```

Run the container:

```bash
docker run --rm ex03-cache
```

Expected output:

```text
Docker cache experiment!
```

---

## Cache Experiment

Build the image for the first time:

```bash
docker build -t ex03-cache .
```

Build it again without changing anything:

```bash
docker build -t ex03-cache .
```

Docker should reuse most or all previous layers.

Now change only:

```text
src/message.cpp
```

Build again:

```bash
docker build -t ex03-cache .
```

Observe which layers are cached and which layers are rebuilt.

---

## Questions and Answers

### 1. What is a Docker layer?

A Docker layer is a filesystem change created by a Dockerfile instruction.

For example:

```dockerfile
FROM debian:bookworm
RUN apt-get update
COPY src/ ./src/
RUN make
```

Each instruction can create or use a separate cached layer.

---

### 2. What is Docker build cache?

Docker build cache allows Docker to reuse the result of previous build steps.

If an instruction and everything it depends on have not changed, Docker can reuse the old result instead of executing the instruction again.

This makes builds faster.

---

### 3. What happens when `message.cpp` changes?

This instruction is affected:

```dockerfile
COPY src/ ./src/
```

Docker rebuilds this layer and every instruction after it:

```text
COPY src/ ./src/    → rebuilt
RUN make            → rebuilt
```

The previous instructions can remain cached:

```text
FROM                → cached
WORKDIR             → cached
RUN apt-get...      → cached
COPY Makefile .     → cached
```

---

### 4. Why do we copy the Makefile before the source code?

Because the Makefile changes less often than source code.

```dockerfile
COPY Makefile .
COPY src/ ./src/
```

When only a `.cpp` file changes, Docker can keep all earlier layers cached.

The order of Dockerfile instructions affects build performance.

---

### 5. Why should we avoid `COPY . .`?

```dockerfile
COPY . .
```

copies everything from the build context.

A change to any copied file can invalidate the cache for that layer.

It can also accidentally copy unnecessary files such as:

```text
.git/
build/
*.o
temporary files
```

Copying only what the image needs gives better control over the build.

---

### 6. What is `.dockerignore`?

`.dockerignore` tells Docker which files should not be sent as part of the build context.

Example:

```text
.git
*.o
app
README.md
```

It can make the build context smaller and prevent unnecessary files from affecting the build.

---

### 7. If an early layer changes, what happens?

All layers after it must be rebuilt.

Example:

```text
Layer 1 → cached
Layer 2 → changed
Layer 3 → rebuilt
Layer 4 → rebuilt
Layer 5 → rebuilt
```

This is why stable instructions are usually placed before frequently changing instructions.

---

## What I Learned

After this exercise, I understand:

* Docker images are built from layers
* Docker can cache previous build steps
* A changed layer invalidates following layers
* Dockerfile instruction order matters
* `COPY . .` is not always a good choice
* `.dockerignore` reduces unnecessary build context
