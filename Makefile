#!/usr/bin/env make
.PHONY: run_website

run_website:
	docker build -t website_kube . && \
		docker run -p 5000:80 -d --name website_kube --rm website_kube
