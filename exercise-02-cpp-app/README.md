# Exercise 02 — C++ Application Inside Docker

## Objective

The goal of this exercise is to understand how Docker builds a C++ application into an image and how a container runs that application.

The complete workflow is:

```text
Source Code + Makefile + Dockerfile
              ↓
         docker build
              ↓
    Docker executes Dockerfile
              ↓
      C++ program is compiled
              ↓
         Docker Image
              ↓
          docker run
              ↓
     A new container is created
              ↓
       The C++ program runs
              ↓
      The main process finishes
              ↓
       The container stops
```

---

## Project Structure

```text
exercise-02-cpp-app/
├── Dockerfile
├── .dockerignore
├── Makefile
├── README.md
└── src/
    └── main.cpp
```

---

# 1. Build the Docker Image

```bash
docker build -t cpp-docker-app:v1 .
```

The `docker build` command reads the `Dockerfile` and creates an image.

The `-t` option gives the image a name and a tag:

```text
cpp-docker-app → image name
v1             → image tag/version
```

The final `.` means:

```text
Use the current directory as the build context.
```

The build context contains the files that Docker can access during the build.

---

# 2. Check the Image

```bash
docker image ls
```

This command lists the Docker images stored locally.

Example:

```text
REPOSITORY         TAG    IMAGE ID       CREATED         SIZE
cpp-docker-app     v1     abc123456789   1 minute ago    300MB
```

The image is not a running program.

It is a read-only template containing everything needed to create containers.

---

# 3. Inspect the Image

```bash
docker image inspect cpp-docker-app:v1
```

This command returns detailed information about the image in JSON format.

Important information includes:

* Image ID
* Creation date
* Architecture
* Operating system
* Environment variables
* Working directory
* Startup command
* Image layers

For example, if the Dockerfile contains:

```dockerfile
WORKDIR /app
```

the inspection output should contain something similar to:

```text
"WorkingDir": "/app"
```

---

# 4. Check the Image History

```bash
docker image history cpp-docker-app:v1
```

This command shows how the image was built.

Example:

```text
IMAGE          CREATED BY
abc123         CMD ["./app"]
def456         RUN make
ghi789         COPY . .
jkl012         RUN apt-get update && apt-get install...
mno345         WORKDIR /app
pqr678         FROM debian:bookworm
```

The history helps us understand that a Docker image is built from a sequence of instructions.

Many Dockerfile instructions create filesystem layers or metadata changes in the final image.

---

# 5. Run the First Container

```bash
docker run --name cpp-app-1 cpp-docker-app:v1
```

The command performs two important operations:

```text
Docker Image
     ↓
Create a new Container
     ↓
Start the Container
```

The container runs the default command defined in the image.

The expected output is:

```text
Hello from inside a Docker container!
```

---

# 6. Check the Containers

Running containers:

```bash
docker ps
```

All containers, including stopped containers:

```bash
docker ps -a
```

The container appears in:

```bash
docker ps -a
```

but not in:

```bash
docker ps
```

because the C++ application finished executing.

The application is the container's main process.

The lifecycle is:

```text
Container starts
      ↓
./app starts
      ↓
Message is printed
      ↓
main() returns
      ↓
./app exits
      ↓
Container stops
```

A container normally remains running only while its main process is running.

---

# 7. Inspect the Container

```bash
docker inspect cpp-app-1
```

This command displays detailed information about the specific container.

The information includes:

* Container ID
* Container name
* Image used to create it
* Container state
* Exit code
* Created time
* Network configuration
* Filesystem configuration
* Startup command

The image and container are different objects.

```text
IMAGE
  └── cpp-docker-app:v1
         │
         ├── Container: cpp-app-1
         ├── Container: cpp-app-2
         └── Container: cpp-app-3
```

One image can create many independent containers.

---

# 8. Remove the Container

```bash
docker rm cpp-app-1
```

This removes the container.

Check:

```bash
docker ps -a
```

The container should no longer exist.

However, the image still exists:

```bash
docker image ls
```

This happens because containers and images are separate Docker objects.

```text
Image = template

Container = instance created from the template
```

Removing one container does not remove the image used to create it.

---

# 9. Create Another Container From the Same Image

```bash
docker run --name cpp-app-2 cpp-docker-app:v1
```

Docker creates a completely new container from the same image.

```text
cpp-docker-app:v1
        │
        ├── cpp-app-1
        │
        └── cpp-app-2
```

Both containers are created from the same image, but they are separate objects with different:

* Container IDs
* Names
* States
* Writable container layers

---

# Dockerfile Concepts

## What Does `WORKDIR` Do?

Example:

```dockerfile
WORKDIR /app
```

`WORKDIR` sets the current working directory inside the image for the Dockerfile instructions that follow it.

For example:

```dockerfile
WORKDIR /app

COPY . .
RUN make
CMD ["./app"]
```

After `WORKDIR /app`:

```text
COPY . .    → copies files into /app
RUN make    → executes from /app
CMD ./app   → starts from /app
```

It is similar to changing the current directory before running commands.

Conceptually:

```bash
cd /app
```

However, `WORKDIR` is a Dockerfile instruction that also records the working directory in the image configuration.

---

## What Is the Difference Between `COPY` and `RUN`?

### `COPY`

Example:

```dockerfile
COPY . .
```

`COPY` transfers files from the build context on the host into the filesystem of the image.

```text
Host Machine
    │
    │ COPY
    ↓
Docker Image
```

Example:

```text
Host:
src/main.cpp

        ↓ COPY

Image:
/app/src/main.cpp
```

`COPY` does not execute the files.

It only copies them.

---

### `RUN`

Example:

```dockerfile
RUN make
```

`RUN` executes a command during `docker build`.

```text
Image filesystem
       ↓
    RUN make
       ↓
Compiler executes
       ↓
Binary is created
       ↓
Result becomes part of the image
```

Therefore:

```text
COPY → moves files into the image

RUN  → executes a command while building the image
```

---

# When Is the C++ Application Compiled?

The application is compiled during:

```bash
docker build
```

because the Dockerfile contains:

```dockerfile
RUN make
```

The process is:

```text
docker build
     ↓
Docker reads Dockerfile
     ↓
COPY source code
     ↓
RUN make
     ↓
g++ compiles main.cpp
     ↓
Binary ./app is created
     ↓
Binary is stored in the image
```

When we later execute:

```bash
docker run cpp-docker-app:v1
```

Docker does not compile the application again.

It runs the binary that already exists inside the image.

```text
docker build → compile

docker run   → execute
```

---

# Why Does the Container Stop Immediately?

The container starts the C++ application:

```text
./app
```

The program prints:

```text
Hello from inside a Docker container!
```

Then `main()` finishes.

The main process of the container has exited, so the container stops.

```text
Container
    │
    └── Main process: ./app
              │
              ├── Print message
              │
              └── Exit
                     ↓
              Container stops
```

A container is not automatically a permanent virtual machine.

Its lifecycle is connected to the process it runs.

---

# What Does `.dockerignore` Do?

The `.dockerignore` file tells Docker which local files and directories should be excluded from the build context.

Example:

```text
.git
*.o
app
README.md
```

Without `.dockerignore`:

```text
Project directory
       ↓
Docker build context
       ↓
All unnecessary files may be available to the build
```

With `.dockerignore`:

```text
Project directory
       ↓
Remove ignored files
       ↓
Smaller build context
       ↓
Docker builder
```

Benefits include:

* Smaller build context
* Faster builds
* Avoiding unnecessary files
* Preventing local build artifacts from being copied accidentally

It works similarly to `.gitignore`, but it controls the Docker build context instead of Git tracking.

---

# What Is `docker image history` Showing?

Run:

```bash
docker image history cpp-docker-app:v1
```

Docker displays the history of instructions used to build the image.

For example:

```dockerfile
FROM debian:bookworm

WORKDIR /app

RUN apt-get update && apt-get install -y g++ make

COPY . .

RUN make

CMD ["./app"]
```

The history may show entries related to:

```text
Base image
    ↓
WORKDIR
    ↓
Install dependencies
    ↓
COPY project files
    ↓
Compile application
    ↓
Startup command
```

This helps us understand how the final image was produced and which instructions contribute to its filesystem or configuration.

---

# Bonus Challenge — Build Version 2

Change:

```cpp
std::cout << "Hello from inside a Docker container!" << std::endl;
```

to another message.

Then build:

```bash
docker build -t cpp-docker-app:v2 .
```

Now list the images:

```bash
docker image ls
```

The machine now contains:

```text
cpp-docker-app:v1
cpp-docker-app:v2
```

---

# Docker Build Cache

When building `v2`, Docker checks whether it can reuse results from the previous build.

Suppose the Dockerfile is:

```dockerfile
FROM debian:bookworm

WORKDIR /app

RUN apt-get update && apt-get install -y g++ make

COPY . .

RUN make

CMD ["./app"]
```

If only `src/main.cpp` changes:

```text
FROM debian:bookworm                    → CACHED
WORKDIR /app                            → CACHED
RUN apt-get install...                  → CACHED
COPY . .                                → CHANGED
RUN make                                → RUN AGAIN
CMD ["./app"]                           → processed after changed layer
```

Why?

The files used by:

```dockerfile
COPY . .
```

changed.

Therefore, Docker cannot reuse that previous result.

After one build step is invalidated, the following dependent steps also need to be processed again.

The general rule is:

```text
Unchanged instruction + unchanged inputs
                ↓
          Reuse cache

Changed instruction or changed copied files
                ↓
        Cache invalidated
                ↓
    Following steps are affected
```

---

# Final Mental Model

```text
Dockerfile
    │
    │ docker build
    ↓
Image
    │
    │ docker run
    ↓
Container
    │
    │ runs
    ↓
Main Process
    │
    │ exits
    ↓
Container Stops
```

And for the C++ application:

```text
main.cpp
    ↓
COPY
    ↓
Source code inside build
    ↓
RUN make
    ↓
Compiled binary
    ↓
Stored in Docker image
    ↓
docker run
    ↓
New container
    ↓
./app executes
```

---

# Commands Used

```bash
# Build the image
docker build -t cpp-docker-app:v1 .

# List images
docker image ls

# Inspect the image
docker image inspect cpp-docker-app:v1

# Check image history
docker image history cpp-docker-app:v1

# Create and run a container
docker run --name cpp-app-1 cpp-docker-app:v1

# List running containers
docker ps

# List all containers
docker ps -a

# Inspect the container
docker inspect cpp-app-1

# Remove the container
docker rm cpp-app-1

# Create another container
docker run --name cpp-app-2 cpp-docker-app:v1

# Build version 2
docker build -t cpp-docker-app:v2 .

# Compare images
docker image ls
docker image history cpp-docker-app:v1
docker image history cpp-docker-app:v2
```

---

# What I Learned

After completing this exercise, I understand:

* A Dockerfile contains instructions for building an image.
* `docker build` creates an image.
* `docker run` creates and starts a container from an image.
* `WORKDIR` sets the working directory for following instructions.
* `COPY` copies files into the image.
* `RUN` executes commands during the image build.
* The C++ application is compiled during `docker build`.
* The compiled binary becomes part of the image.
* A container stops when its main process exits.
* One image can create multiple independent containers.
* Removing a container does not remove its image.
* `.dockerignore` excludes unnecessary files from the build context.
* Docker can reuse cached build results when instructions and their inputs have not changed.
