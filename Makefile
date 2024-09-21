
.PHONY: clean doc docker

docker:
	cd docker/; docker build -t design_work .

doc:
	doxygen
	./function_design.pl -m *.c
	pandoc *.c.md -f markdown -t html5 -o Detail_design_document.html -N \
		--toc -V toc-own-page=true -V toc-title="目次" --toc-depth=2 \
                -B detail_design_cover.md  -c detail_design_cover.css \
		--metadata pagetitle="詳細設計書"



clean:
	rm -rf html/ *.c.md *.pdf
