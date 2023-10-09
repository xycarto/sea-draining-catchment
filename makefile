-include .creds

BASEIMAGE := xycarto/sea-draining
IMAGE := $(BASEIMAGE):2023-10-09

RUN ?= docker run -it --rm --net=host --user=$$(id -u):$$(id -g) \
	-e DISPLAY=$$DISPLAY \
	-e HOME=/work \
	--env-file .creds \
	-e RUN= -v$$(pwd):/work \
	-w /work $(IMAGE)

.PHONY: 

##### CATCHMENTS #####
select:
	$(RUN) python3 src/select-downsample.py

catchment:
	$(RUN) bash src/grass-build-catchment.sh

sea-drain:
	$(RUN) bash src/grass-build-sea-drain.sh

	

##### DOCKER #####
test-local: docker/Dockerfile
	docker run -it --rm  \
	--user=$$(id -u):$$(id -g) \
	-e DISPLAY=$$DISPLAY \
	--env-file .creds \
	-e RUN= -v$$(pwd):/work \
	-w /work $(IMAGE)
	bash
	
docker-local: docker/Dockerfile
	docker build --tag $(BASEIMAGE) - < docker/Dockerfile  && \
	docker tag $(BASEIMAGE) $(IMAGE)

docker-push: docker/Dockerfile
	echo $(DOCKER_PW) | docker login --username xycarto --password-stdin
	docker build --tag $(BASEIMAGE) - < docker/Dockerfile  && \
	docker tag $(BASEIMAGE) $(IMAGE) && \
	docker push $(IMAGE)

docker-pull:
	echo $(DOCKER_PW) | docker login --username xycarto --password-stdin
	docker pull $(IMAGE)