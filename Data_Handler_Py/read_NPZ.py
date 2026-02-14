import npz_handler as NPZ

input_file = "ellyandcable-thirdrun.npz"
output_file = "ellyandcable_run3.mat"
    
NPZ.npz_to_mat(input_file, output_file)