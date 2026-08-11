.SUFFIXES: .o .f90

#============================================================
# Compiler
#============================================================
FC = ifx

#============================================================
# NetCDF
#============================================================
NETCDF = /glade/u/apps/casper/25.10/spack/opt/spack/netcdf/4.9.3/intel-oneapi-compilers/2025.2.1/z4hi
#/glade/u/apps/casper/24.12/spack/opt/spack/netcdf/4.9.2/openmpi/5.0.6/oneapi/2024.2.1/tlt6
NETCDF_LIB = $(NETCDF)/lib
NETCDF_INC = $(NETCDF)/include

#============================================================
# CMAQ I/O API
#
# Set IOAPI_DIR to the directory containing BOTH:
#     libioapi.a
#     m3utilio.mod   (or M3UTILIO.mod)
#
# You may either edit the value below, or override it at build time:
#     make IOAPI_DIR=/path/to/ioapi/build
#============================================================
IOAPI_DIR = /glade/work/huiw16/lib/ioapi_casper/Linux2_x86_64ifx
IOAPI_INC = /glade/work/huiw16/lib/ioapi_casper/ioapi

#============================================================
# Include paths and libraries
#============================================================
INC = -I$(NETCDF_INC) \
      -I$(IOAPI_DIR) \
      -I./INCLDIR

# Keep I/O API before NetCDF because libioapi depends on NetCDF.
LIBS = -L$(IOAPI_DIR) -lioapi \
       -L$(NETCDF_LIB) -lnetcdff -lnetcdf \
       -lhdf5_hl -lhdf5 -lm

#============================================================
# Compiler / linker flags
#============================================================
#DEBUG = -g -traceback -check all -fpe0 -O0
DEBUG = -traceback

FCFLAGS = $(DEBUG) -O2 -extend-source 132
LDFLAGS = $(DEBUG) -O2 -qopenmp -shared-intel

#============================================================
# Source objects
#
# ioapi_output.o must be built before megan_driver.o because
# megan_driver.f90 uses ioapi_output_mod.
#============================================================
OBJS = constants_module.o \
       misc_definitions_module.o \
       bio_types.o \
       area_mapper_grw.o \
       datetime_module.o \
       prep_megan.o \
       megan_voc.o \
       ioapi_output.o \
       megan_driver.o

EXE = ../exe/megan_v3.3.exe

#============================================================
# Default target
#============================================================
.PHONY: all
all: check-ioapi $(EXE)

#============================================================
# Check I/O API installation before compiling ioapi_output.f90
#============================================================
.PHONY: check-ioapi
check-ioapi:
	@test -d "$(IOAPI_DIR)" || { \
	  echo "ERROR: IOAPI_DIR does not exist: $(IOAPI_DIR)"; \
	  echo "Set it with: make IOAPI_DIR=/path/to/ioapi/build"; \
	  exit 1; \
	}
	@test -f "$(IOAPI_DIR)/libioapi.a" || { \
	  echo "ERROR: libioapi.a not found in $(IOAPI_DIR)"; \
	  exit 1; \
	}
	@test -f "$(IOAPI_DIR)/m3utilio.mod" -o -f "$(IOAPI_DIR)/M3UTILIO.mod" || { \
	  echo "ERROR: m3utilio.mod not found in $(IOAPI_DIR)"; \
	  exit 1; \
	}

#============================================================
# Link
#============================================================
$(EXE): $(OBJS)
	@mkdir -p $(dir $@)
	$(FC) $(LDFLAGS) $(OBJS) $(LIBS) -o $@

#============================================================
# Compile
#============================================================
%.o: %.f90
	$(FC) -c $(FCFLAGS) $(INC) $< -o $@

# Explicit dependency for the module introduced by IOAPI output.
ioapi_output.o: | check-ioapi
megan_driver.o: ioapi_output.o

#============================================================
# Utility targets
#============================================================
.PHONY: print-config
print-config:
	@echo "FC          = $(FC)"
	@echo "NETCDF_INC  = $(NETCDF_INC)"
	@echo "NETCDF_LIB  = $(NETCDF_LIB)"
	@echo "IOAPI_DIR   = $(IOAPI_DIR)"
	@echo "EXE         = $(EXE)"

.PHONY: clean
clean:
	rm -f *.o *.mod
