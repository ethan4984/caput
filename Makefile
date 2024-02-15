CAPUT := caput
VCD := caput.vcd

build:
	@cd src && make

run: build
	@./$(CAPUT)

wave_run: build
	@./$(CAPUT)
	@gtkwave $(VCD)

clean:
	@rm -rf $(CAPUT) $(VCD)
