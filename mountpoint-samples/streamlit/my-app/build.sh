#!/bin/bash

uri=#{ecr_image_uri}

docker build -t my-app ./my-app
docker tag my-app:latest $uri:latest
docker push $uri:latest
