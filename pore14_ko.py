import numpy as np
from skimage import io
import tifffile as tiff
import csv
from scipy.ndimage import label
from scipy.spatial import KDTree

# Set parameters for angular patching
theta_divisions = 10  # Number of latitude divisions
phi_divisions = 10    # Number of longitude divisions

# Load the single TIFF stack files for surface and pores
surface_voxels = io.imread('C:/Users/arrud/OneDrive/Desktop/Alyssa/ko_nuclear_membrane_3D.tif')
pores_stack = io.imread('C:/Users/arrud/OneDrive/Desktop/Alyssa/ko_nuclear_pore.tif')

# Create a binary mask of surface voxels
surface_mask = (surface_voxels > 0)
output_stack = np.zeros_like(surface_voxels, dtype=np.uint8)  # Output stack to label patches
labeled_pores, num_pores = label(pores_stack > 0)  # Label pores as 3D objects

# Step 1: Find the bounding box of the nucleus region
coords = np.argwhere(surface_mask)
z_min, y_min, x_min = coords.min(axis=0)
z_max, y_max, x_max = coords.max(axis=0)

# Extract the nucleus region
nucleus_mask = surface_mask[z_min:z_max+1, y_min:y_max+1, x_min:x_max+1]
output_nucleus = output_stack[z_min:z_max+1, y_min:y_max+1, x_min:x_max+1]

# Calculate the center of the nucleus bounding box
z_center, y_center, x_center = np.array(nucleus_mask.shape) // 2

# Initialize patch index and center storage
patch_centers = []
patch_index = 1  # Start labeling patches from 1

# Debugging: Print bounding box information
print(f"Nucleus bounding box: z({z_min}-{z_max}), y({y_min}-{y_max}), x({x_min}-{x_max})")
print(f"Nucleus center within bounding box: (z={z_center}, y={y_center}, x={x_center})")

# Iterate through theta and phi to define patches
for theta_step in range(theta_divisions):
    for phi_step in range(phi_divisions):
        # Calculate angular bounds for this patch
        theta_min = (theta_step / theta_divisions) * np.pi
        theta_max = ((theta_step + 1) / theta_divisions) * np.pi
        phi_min = (phi_step / phi_divisions) * 2 * np.pi
        phi_max = ((phi_step + 1) / phi_divisions) * 2 * np.pi
        
        # Select surface voxels within this angular range
        patch_voxels = []
        for z, y, x in np.argwhere(nucleus_mask):
            # Convert Cartesian coordinates to spherical
            dz, dy, dx = z - z_center, y - y_center, x - x_center
            r = np.sqrt(dx**2 + dy**2 + dz**2)
            if r == 0:
                continue  # Skip the center to avoid division by zero
            
            theta = np.arccos(dz / r)  # Polar angle (angle from z-axis)
            phi = np.arctan2(dy, dx)  # Azimuthal angle (angle in x-y plane)
            if phi < 0:
                phi += 2 * np.pi  # Ensure phi is in [0, 2*pi]

            # Check if the voxel is within the current angular range
            if theta_min <= theta < theta_max and phi_min <= phi < phi_max:
                patch_voxels.append((z, y, x))
                output_nucleus[z, y, x] = patch_index  # Label with the patch index

        # Store the center of geometry for the patch if there are voxels
        if patch_voxels:
            patch_voxels_array = np.array(patch_voxels)
            center_of_geometry = np.mean(patch_voxels_array, axis=0)
            patch_centers.append(center_of_geometry)
            print(f"Patch {patch_index} created with {len(patch_voxels)} voxels.")
        else:
            print(f"Patch {patch_index} created with 0 voxels (skipped).")
        
        patch_index += 1

# Place the patch-labeled nucleus back into the full output stack
output_stack[z_min:z_max+1, y_min:y_max+1, x_min:x_max+1] = output_nucleus

# Save the intermediate TIFF stack with unique intensity values for each patch
tiff.imwrite('C:/Users/arrud/OneDrive/Desktop/Alyssa/spherical_patch_labels_output.tif', output_stack)
print("Intermediate output saved as spherical_patch_labels_output.tif")

# Step 2: Assign each pore to the closest patch center using a KD-Tree for fast nearest-neighbor search
pore_counts = [0] * len(patch_centers)
pore_labels = np.unique(labeled_pores)

# Build a KD-Tree from patch centers
kd_tree = KDTree(patch_centers)

for pore_label in pore_labels:
    if pore_label == 0:
        continue  # Skip background label

    # Get any voxel from the pore (we'll just use the first voxel for simplicity)
    pore_voxel = np.argwhere(labeled_pores == pore_label)[0]

    # Find the closest patch using the KD-Tree
    _, closest_patch = kd_tree.query(pore_voxel)
    pore_counts[closest_patch] += 1  # Increment the pore count for the closest patch

# Save the pore counts per patch to a CSV file
with open('C:/Users/arrud/OneDrive/Desktop/Alyssa/pore_counts_per_patch.csv', mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(["Patch Index", "Pore Count"])
    for i, count in enumerate(pore_counts):
        writer.writerow([i + 1, count])  # Patches are indexed starting from 1

print("Pore counts per patch saved as pore_counts_per_patch.csv")

# Save the final output stack as a TIFF file
tiff.imwrite('C:/Users/arrud/OneDrive/Desktop/Alyssa/final_patch_density_output.tif', output_stack)
print("Final output saved as final_patch_density_output.tif")
