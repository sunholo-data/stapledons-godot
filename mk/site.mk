# Showcase website (website/, Docusaurus). Served at https://www.sunholo.com/stapledons-godot/
# from the gh-pages branch (legacy GitHub Pages, the org's custom domain). See website/README.md.
SITE_URL ?= https://www.sunholo.com
SITE_BASE ?= /stapledons-godot/
.PHONY: site site-serve site-deploy site-media site-media-publish

site:              ## build the website into website/build (SITE_URL, SITE_BASE; fails on any broken link)
	cd website && { [ -d node_modules ] || npm ci; } && SITE_URL=$(SITE_URL) BASE_URL=$(SITE_BASE) npm run build

site-serve: site   ## preview the built site at http://localhost:3000$(SITE_BASE)
	cd website && SITE_URL=$(SITE_URL) BASE_URL=$(SITE_BASE) npx docusaurus serve --no-open

site-deploy: site  ## publish website/build to the gh-pages branch through a temporary clone (no worktree; DRY=1 stops before the push)
	sh tools/site_deploy.sh

site-media:        ## website clips: render frames in Godot (GPU window) and encode MP4 + WebM + posters (CLIPS="hero voyage ..."; needs ffmpeg)
	GODOT="$(GODOT)" AILANG="$(AILANG)" sh tools/site_media.sh render $(CLIPS)
	sh tools/site_media.sh encode $(CLIPS)

site-media-publish: ## maintainers (gcloud): upload the clips to gs://stapledons-voyage-assets/site/<sha256>.<ext>, rewrite website/src/data/media.json
	sh tools/site_media.sh publish $(CLIPS)
