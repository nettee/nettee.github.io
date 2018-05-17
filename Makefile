

.PHONY: serve serve-draft deploy

serve:
	hexo serve

serve-draft:
	hexo serve --draft

deploy:
	hexo generate
	hexo deploy

KNOWLEDGE_SOURCE := $(HOME)/projects/iknowledge
KNOWLEDGE_TARGET := source/knowledge/

.PHONY: knowledge

knowledge:
	-\rm -r $(KNOWLEDGE_TARGET)
	gitbook build $(KNOWLEDGE_SOURCE) $(KNOWLEDGE_TARGET)
