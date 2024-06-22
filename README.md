# FNA-VSCode-Template-Docker
Docker for running FNA-VSCode-Template

## Build the container
```bash
docker build -t my_popos_opengl_container --build-arg newProjectName=YourProjectName .
```

## Run the container
```bash
docker run -it --rm \
    --name opengl_container \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    my_popos_opengl_container
```
