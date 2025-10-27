# Nuclear Surface Patch Generator

This Python script divides a 3D binary mask of a nuclear envelope (single voxel thick nucleus surface) into approximately 100 angular patches, each assigned a unique intensity value. In the context of Mathiowetz et al, Nature 2025 paper, these labeled patches were then imported into *Arivis Pro* to quantify the spatial distribution of nuclear pores or blebs across the nuclear surface. Please refer to the methods section of the publication for detailed information.

---

## Overview

The script performs the following steps:
1. Loads 3D binary masks of the nuclear membrane and nuclear pores.  
2. Defines angular divisions (`theta_divisions × phi_divisions`) in spherical coordinates centered on the nucleus.  
3. Assigns each surface voxel to an angular patch and labels it with a unique intensity.  
4. Identifies each nuclear pore and assigns it to the nearest surface patch.  
5. Outputs:
   - A TIFF stack showing labeled surface patches (`spherical_patch_labels_output.tif`)
   - A CSV file reporting the number of pores per patch (`pore_counts_per_patch.csv`)
   - A final labeled TIFF for visualization (`final_patch_density_output.tif`)

---

## Inputs

| File | Description |
|------|--------------|
| `ko_nuclear_membrane_3D.tif` | 3D binary mask (1 = nuclear surface voxels) |
| `ko_nuclear_pore.tif` | 3D binary mask (1 = nuclear pore voxels) |

Both files must have identical dimensions.

---

## Outputs

| File | Description |
|------|--------------|
| `spherical_patch_labels_output.tif` | Nuclear surface labeled with unique patch indices |
| `pore_counts_per_patch.csv` | CSV table of pore counts per surface patch |
| `final_patch_density_output.tif` | Final labeled stack (identical to above for visualization) |

---

## Parameters

- `theta_divisions`: Number of latitude divisions (default: 10)  
- `phi_divisions`: Number of longitude divisions (default: 10)  
Together these define a total of `theta_divisions × phi_divisions` patches (default = 100).

You can adjust these to change patch resolution.

---

## Usage

```bash
python nuclear_surface_patch_generator.py
```

Before running:
- Update file paths for your TIFF stacks in the script.
- Ensure both masks are 3D binary images with the same voxel dimensions.

Example output files will be saved to:
```
C:/Users/arrud/OneDrive/Desktop/Alyssa/
```

---

## Dependencies

Python ≥ 3.8  
Required libraries:
```bash
pip install numpy scipy scikit-image tifffile
```

---

## Context of Use

Nuclear pores were manually annotated in *Napari* and reconstructed in *Arivis Pro*. The generated surface patches from this script were imported into *Arivis Pro* to quantify nuclear pore and bleb densities per patch. False or truncated surfaces (e.g., near dataset borders) were excluded from analysis, and pore counts were normalized to the surface area of each patch.

---

## Citation

If you use this script, please cite:

**Mathiowetz AJ\*, Meymand ES\*, Parlakgül G, van Hilten N, Doubravsky CE, Deol KK, Lange M, Pang SP, Roberts MA, Torres EF, Jorgens DM, Zalpuri R, Kang M, Boone C, Artico LL, Parks BW, Zhang Y, Morgens DW, Tso E, Zhou Y, Talukdar S, Grabe M, Ku G, Levine TP, Arruda AP#, Olzmann JA#.**  
*CLCC1 promotes hepatic neutral lipid flux and nuclear pore complex assembly.*  
**Nature**, 2025. *bioRxiv*, 2024. [doi:10.1101/2024.06.07.597858](https://doi.org/10.1101/2024.06.07.597858)

---
