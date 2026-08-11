# MEGAN v3.3 Fortran

A Fortran implementation of **MEGAN v3.3** for calculating gridded biogenic VOC emissions driven by WRF meteorology.

## Main Features

- Hourly vegetation VOC emission calculations
- WRF meteorological forcing
- PREP-MEGAN preprocessing for vegetation, LAI, ecotype, and emission factors
- Canopy light- and temperature-response calculations
- Optional flower and litter emission adjustments
- Mapping of MEGAN emission groups to chemical mechanisms
- NetCDF or CMAQ/IOAPI output

Supported chemical mechanisms:

`CB05`, `CB6`, `CB6_ae7`, `RACM2`, `SAPRC07`, `SAPRC07T`, and `CRACMM`.

> **Soil VOC and soil NOx emissions are under development.**  
> Use `soil_on = .false.` for the current standard vegetation-VOC calculation. Setting `soil_on = .true.` activates the soil-data interface, but soil emissions are not yet added to the model output.

## Workflow

```text
User vegetation / LAI data
          |
      PREP-MEGAN
          |
          +--> prep_mgn_static.nc
          +--> prep_mgn_dynamic.nc
          |
WRF meteorology
          |
      MEGAN VOC
          |
Chemical mechanism mapping
          |
    NetCDF / IOAPI
```

If the PREP-MEGAN files are missing, or `prep_megan_flag = .true.`, the preprocessing step is run first. The program then stops. Run the executable again to start the emission calculation.

## Namelist

The model reads three namelist groups:

```fortran
&megan_nl
&prep_megan_nl
&windowdefs
```

### `&megan_nl`

Main runtime options:

| Option | Description |
|---|---|
| `start_date` | First simulation hour, `YYYY-MM-DD HH:MM:SS` |
| `end_date` | End boundary of the simulation |
| `met_files` | WRF filename template; `<date>` is replaced by `YYYY-MM-DD` and `<time>` by `HH:00:00` |
| `wrf_static_file` | WRF file used for grid and projection information |
| `mechanism` | Chemical mechanism used for species mapping |
| `static_file` | PREP-MEGAN static file |
| `dynamic_file` | PREP-MEGAN dynamic file |
| `prep_megan_flag` | Force PREP-MEGAN preprocessing when `.true.` |
| `run_flower` | Enable flower emission adjustment (Under development) |
| `run_litter` | Enable litter emission adjustment (Under development) |
| `soil_on` | Enable the soil-emission development interface |
| `output_format` | `NETCDF` or `IOAPI` |
| `output_dir` | Output directory |
| `griddesc_file` | CMAQ `GRIDDESC` file for IOAPI output |
| `ioapi_gridname` | Grid name in `GRIDDESC` |
| `write_megan_group` | Write optional MEGAN-group diagnostic output |

Example:

```fortran
soil_on = .false.
output_format = 'IOAPI'
```

There is **no LSM option** in the namelist.

### `&prep_megan_nl`

Vegetation and LAI inputs:

| Option | Description |
|---|---|
| `nlai` | Number of LAI records in the LAI input file |
| `lai_scale_factor` | Scale factor applied to LAI |
| `eco_glb` | Ecotype dataset |
| `ctf_glb` | Tree-type fraction dataset |
| `grf_glb` | Growth-form fraction dataset |
| `lai_glb` | User-prepared LAI dataset |
| `GtEcoEF` | Emission-factor lookup table |

LAI is always provided through `lai_glb`.

The following datasets are used only when `soil_on = .true.` and are reserved for future soil VOC and soil NOx development:

- `clim_glb` — arid-soil information
- `land_glb` — soil/land-type information
- `ndep_glb` — nitrogen deposition
- `fert_glb` — fertilizer input

When `soil_on = .true.`, PREP-MEGAN also prepares `arid`, `landtype`, `NDEP`, and `NFERT`. The driver can read WRF soil-support fields for future soil-emission routines.

### `&windowdefs`

Defines the selected WRF grid window:

| Option | Description |
|---|---|
| `x0` | Starting west-east index |
| `y0` | Starting south-north index |
| `ncolsin` | Number of west-east grid cells |
| `nrowsin` | Number of south-north grid cells |

`x0` and `y0` are used directly by the Fortran NetCDF `start=` argument and are therefore **1-based**. These parameters should be consistant with your subdomain in CMAQ when you use the `IOAPI` output.

## Running

```bash
./megan_v3.3.exe < namelist_megan
```

Example simulation period:

```fortran
start_date = '2021-05-28 00:00:00'
end_date   = '2021-05-31 00:00:00'
```

This produces daily emissions for May 28, May 29, and May 30.

## Output

For standard NetCDF output:

```fortran
output_format = 'NETCDF'
```

For CMAQ/IOAPI output:

```fortran
output_format  = 'IOAPI'
griddesc_file  = 'GRIDDESC_Kai'
ioapi_gridname = 'M_04_08CA'
```

IOAPI files are written directly by the Fortran program; an external shell script is not required to define the grid during execution.

## Development Status

The current model calculates **vegetation VOC emissions**. The soil interface is retained for future development of:

- Soil VOC emissions
- Soil NOx emissions

These soil emissions are currently disabled and are not included in model output.
