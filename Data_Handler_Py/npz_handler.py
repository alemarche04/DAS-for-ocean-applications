import numpy as np
from scipy.io import savemat

def npz_to_mat(npz_file, mat_file):
    """
    Converter from NPT to MAT.
    
    Input parameters:
    npz_file: path to .npz file (input)
    mat_file: path to .mat file (output)
    """
    # load NPZ file
    data = np.load(npz_file)
    
    # creats dict with data
    mat_dict = {}
    
    print(f"Converting {npz_file} in {mat_file}...")
    print(f"\nVariables found in NPZ file:")
    
    for key in data.files:
        mat_dict[key] = data[key]
        print(f"  - {key} -> Shape: {data[key].shape} | Type: {data[key].dtype}")
    
    # save MAT file
    savemat(mat_file, mat_dict)
    
    print(f"\nFile saved successfully: {mat_file}")
    
    # close NPZ file
    data.close()