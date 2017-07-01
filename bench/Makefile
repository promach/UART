TARGET=Tx
.PHONY: $(TARGET)
RTLSRC=../rtl
all: $(TARGET)

DESIGN_FILES=$(TARGET)_top.v TxUART.v baud_generator.v shift_register.v
LDFLAGS=
CFLAGS=-g -O3

$(TARGET):
	verilator -Wno-fatal -I$(RTLSRC)/ --cc $(DESIGN_FILES) --trace --exe ../$(@).cpp  -Mdir $(@) -CFLAGS "$(CFLAGS)"
	make -C $(@) -f V$(@)_top.mk
clean:: 
	rm -rf *.o $(TARGET)
distclean:: clean
	rm -rf *~ *.txt *.vcd *.mif *.orig