HOST     ?= truenas.local
DEST     ?= /mnt/.ix-apps/app_mounts/homepage/config
CONFIG   ?= ./config
RENDERED ?= /tmp/homepage-rendered

.PHONY: deploy deploy-rendered pull diff fix-perms clean-rendered

deploy:
	rsync -avz \
	  --rsync-path="sudo rsync" \
	  --exclude='.git' \
	  --exclude='.env' \
	  --exclude='logs/' \
	  $(CONFIG)/ $(HOST):$(DEST)/
	@$(MAKE) fix-perms

deploy-rendered: clean-rendered
	@mkdir -p $(RENDERED)
	@cp -r $(CONFIG)/* $(RENDERED)/
	@if [ -f .env ]; then \
	  while IFS='=' read -r key value; do \
	    [ -z "$$key" ] || [ "$${key#\#}" != "$$key" ] && continue; \
	    find $(RENDERED) -name '*.yaml' -exec sed -i '' "s|{{$$key}}|$$value|g" {} +; \
	  done < .env; \
	fi
	rsync -avz \
	  --rsync-path="sudo rsync" \
	  --exclude='logs/' \
	  $(RENDERED)/ $(HOST):$(DEST)/
	@$(MAKE) fix-perms
	@$(MAKE) clean-rendered

pull:
	rsync -avz \
	  --rsync-path="sudo rsync" \
	  $(HOST):$(DEST)/ $(CONFIG)/

diff:
	rsync -avzn \
	  --rsync-path="sudo rsync" \
	  --exclude='.git' \
	  --exclude='.env' \
	  --exclude='logs/' \
	  $(CONFIG)/ $(HOST):$(DEST)/

fix-perms:
	@ssh $(HOST) 'sudo -n chown -R 1000:1000 $(DEST)'

clean-rendered:
	@rm -rf $(RENDERED)
