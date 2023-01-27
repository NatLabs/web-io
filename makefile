.PHONY: test compile-tests docs no-warn

# runs all tests using the moc interpreter (not all features in motoko are supported)
test: 
	$(shell vessel bin)/moc -r $(shell mops sources) -wasi-system-api ./tests/*.Test.mo

# compile all tests or selected test file by passing `file=filename`
compile-tests: 
	bash compile-tests.sh $(file)

# treats warnings as errors and prints them to stdout
no-warn:
	find src -type f -name '*.mo' -print0 | xargs -0 $(shell vessel bin)/moc -r $(shell mops sources) -Werror -wasi-system-api

docs: 
	$(shell vessel bin)/mo-doc
	$(shell vessel bin)/mo-doc --format plain