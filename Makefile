BUCKET_NAME ?= your-s3-bucket
FRONTEND_BUCKET ?= your-front-end-bucket
ARTIFACTS_PATH ?= artifacts/path

build-front:
	cd ui && npm run build
sync-front:
	cd ui && aws s3 sync public/ s3://$(FRONTEND_BUCKET) --delete
build-back-rest:
	mkdir build
	pip install -r backend/rest-requirements.txt -t build
	cp backend/rest_server.py build
	cp backend/calcutta.py build
	cd build && zip -r ../artifacts/rest.zip ./* && cd ..
	rm -rf build
build-back-ws:
	mkdir build
	pip install -r backend/websocket-requirements.txt -t build
	cp backend/websocket_server.py build
	cd build && zip -r ../artifacts/websocket.zip ./* && cd ..
	rm -rf build
build-back: build-back-rest build-back-ws
deploy-back-rest:
	aws s3 cp artifacts/rest.zip s3://$(BUCKET_NAME)/$(ARTIFACTS_PATH)/rest.zip
	rm artifacts/rest.zip
	cd terraform && terraform apply
deploy-back-ws:
	aws s3 cp artifacts/websocket.zip s3://$(BUCKET_NAME)/$(ARTIFACTS_PATH)/websocket.zip
	rm artifacts/websocket.zip
	cd terraform && terraform apply
deploy-back:
	aws s3 cp artifacts/rest.zip s3://$(BUCKET_NAME)/$(ARTIFACTS_PATH)/rest.zip
	aws s3 cp artifacts/websocket.zip s3://$(BUCKET_NAME)/$(ARTIFACTS_PATH)/websocket.zip
clean:
	rm -rf build
	rm artifacts/*
	rm -rf ui/node_modules