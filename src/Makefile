CAPUT := caput

PKG_SV := $(shell find . -type f -name '*_pkg.sv')
SV_FILES := $(filter-out $(PKG_SV),$(shell find . -type f -name '*.sv'))

build:
	@iverilog -g2012 -Wall $(PKG_SV) $(SV_FILES) -o ../$(CAPUT)
