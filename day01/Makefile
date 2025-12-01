.PHONY: test clean update

test : expected.txt results.txt
	diff expected.txt results.txt && echo results MATCH

PROGRAMS = one.awk two.awk
INPUTS = sample.txt input.txt

results.txt : $(PROGRAMS) $(INPUTS)
	./one.awk sample.txt > $@
	./one.awk input.txt >> $@
	./two.awk sample.txt >> $@
	./two.awk input.txt >> $@
	cat $@

clean:
	$(RM) results.txt

update: results.txt
	cp $< expected.txt
