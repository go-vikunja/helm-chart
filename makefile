RELEASE_NAME=vikunja
NAMESPACE=$(RELEASE_NAME)
OUTPUT_DIR=output

template: values.yaml
	helm $@ \
		$(RELEASE_NAME) \
		. \
		-f $< \
		--debug \
		--namespace $(NAMESPACE) \
		--output-dir $(OUTPUT_DIR)

clean:
	rm -rf output

.PHONY: clean