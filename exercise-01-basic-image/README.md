# Exercise 01 — Basic Docker Image & Container

## Objective

Learn the basic Docker workflow:

```text
Dockerfile → Image → Container
```

In this exercise, I will:

- Create my first Dockerfile
- Build a Docker image
- Run a container from the image
- Inspect images and containers
- Stop and remove a container
- Reuse the same image to create another container

---

## Project Structure

```text
exercise-01-basic-image/
├── Dockerfile
└── README.md
```

---

## 1. Create the Dockerfile

The image must:

- Use `debian:bookworm` as the base image
- Install `curl`
- Print:

```text
Hello from my first Docker image!
```

---

## 2. Build the Image

```bash
docker build -t my-first-image:v1 .
```

### Check the image

```bash
docker image ls
```

### My image ID

```text
4359ab206fb4
```

---

## 3. Inspect the Image

```bash
docker image inspect my-first-image:v1
```

### What I noticed

```text
"Id": "sha256:4359ab206fb45a95ff453be1f77b5d38dd22098e853c53758400d83ed4e69eea",
"RepoTags": [
            "my-first-image:v1"
        ],
"Cmd": [
                "echo",
                "Hello from my first Docker image!"
            ],

```

---

## 4. Run the First Container

```bash
docker run --name my-first-container my-first-image:v1
```

### Output

```text
Hello from my first Docker image!
```

---

## 5. List Containers

### Running containers

```bash
docker ps
```

### All containers

```bash
docker ps -a
```

### Question

Why does the container appear in `docker ps -a` but not in `docker ps`?

```text
"docker ps" just list only  the containers running , but "docker ps -a" for all containres currently stopped or exited
```

---

## 6. Inspect the Container

```bash
docker inspect my-first-container
```

### What I noticed

```text
I get full detail JSON, learn same Basic Identification, Key data points, size and more
```

---

## 7. Remove the Container

```bash
docker rm my-first-container
```

Check that it was removed:

```bash
docker ps -a
```

---

## 8. Prove the Image Still Exists

```bash
docker image ls
```

### Question

Why does deleting a container not delete the image?

```text
A container is a running instance of an image that includes a writable layer of the read-only image layer, whereas the image itself serves as the immmutable template or blueprint 
```

---

## 9. Create Another Container From the Same Image

```bash
docker run --name my-second-container my-first-image:v1
```

Check it:

```bash
docker ps -a
```

---

## What I Learned

After completing this exercise, I understand:

- The difference between a Docker image and a container
- How `docker build` creates an image
- How `docker run` creates a new container
- The difference between `docker ps` and `docker ps -a`
- How to inspect Docker objects
- Why one image can create multiple containers

---

## Useful Commands

```bash
docker build -t my-first-image:v1 .
docker image ls
docker image inspect my-first-image:v1

docker run --name my-first-container my-first-image:v1
docker ps
docker ps -a
docker inspect my-first-container

docker rm my-first-container
```
