HOST     ?= truenas.local
DEST     ?= /mnt/.ix-apps/app_mounts/homepage/config
CONFIG   ?= ./config
RENDERED ?= /tmp/homepage-rendered

.PHONY: deploy deploy-rendered pull diff clean-rendered

deploy:
	rsync -avz --delete \
	  --rsync-path="sudo rsync" \
	  --exclude='.git' \
	  --exclude='.env' \
	  --exclude='logs/' \
	  $(CONFIG)/ $(HOST):$(DEST)/

deploy-rendered: clean-rendered
	@mkdir -p $(RENDERED)
	@cp -r $(CONFIG)/* $(RENDERED)/
	@if [ -f .env ]; then \
	  while IFS='=' read -r key value; do \
	    [ -z "$$key" ] || [ "$${key#\#}" != "$$key" ] && continue; \
	    find $(RENDERED) -name '*.yaml' -exec sed -i '' "s|{{$$key}}|$$value|g" {} +; \
	  done < .env; \
	fi
	rsync -avz --delete \
	  --rsync-path="sudo rsync" \
	  --exclude='logs/' \
	  $(RENDERED)/ $(HOST):$(DEST)/
	@$(MAKE) clean-rendered

pull:
	rsync -avz \
	  --rsync-path="sudo rsync" \
	  $(HOST):$(DEST)/ $(CONFIG)/

diff:
	rsync -avzn --delete \
	  --rsync-path="sudo rsync" \
	  --exclude='.git' \
	  --exclude='.env' \
	  --exclude='logs/' \
	  $(CONFIG)/ $(HOST):$(DEST)/

clean-rendered:
	@rm -rf $(RENDERED)
