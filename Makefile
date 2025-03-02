#!/usr/bin/env make
.PHONY: run_website stop_website upload_image

run_website:
	docker build -t website_kube . && \
		docker run -p 5000:80 -d --name website_kube --restart=always website_kube

stop_website:
	docker stop website_kube

upload_image:
	echo "${DOCKER_HUB_PASS}" | docker login -u "${DOCKER_HUB_USER}" --password-stdin
	docker push aiservers/website_kube:v2