# Sea Draining Catchments

Method to derive Sea Draining Catchments from LINZ 8m DEM.  Output is a single GPKG file containing only non-overlapping sea draining catchments. In this method, the largest catchment in a region is used.

**This method begins with downsampling the LINZ 8m to 100m resolution.**

The LINZ 8m DEM can be found [here](https://data.linz.govt.nz/layer/51768-nz-8m-digital-elevation-model-2012/)

## Base Method

Downsample LINZ 8m

```
make select
```

Create all catchments

```
make catchment
```

Filter to only sea draining catchments

```
make sea-drain
```

