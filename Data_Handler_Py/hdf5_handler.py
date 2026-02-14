import data_handle
import numpy as np
import h5py

def hdf5_DAS_data_handler(input_file, output_file):
    data = data_handle.get_acquisition_parameters(input_file, "asn")
    # fs: the sampling frequency (Hz)\n
    # dx: interval between two virtual sensing points also called channel spacing (m)\n
    # nx: the number of spatial samples also called channels\n
    # ns: the number of time samples\n
    # GL: the gauge length (m)\n
    # scale_factor: the value to convert DAS data from strain rate to strain
    print(f"\nVariables found in NPZ file:")
    print(data.keys())
    for name in data.keys():
        item = data[name]
        print(f"  - {name} -> Shape: {item.shape} | Type: {item.dtype}")
        if item.size < 3: 
            print(f"  Value: {item[()]}")

    channels = [0, 1200, 1]
    [trace, tx, dist, file_begin_time_utc] = data_handle.load_das_data("122403.hdf5", channels, data, "asn")
    print(trace.shape)
    print(tx.shape)
    print(dist.shape)
    print(file_begin_time_utc)

    with h5py.File(output_file, 'w') as hf:

        meta_group = hf.create_group('metadata')
        for key, value in data.items():
            meta_group.create_dataset(key, data=value)
        
        hf.create_dataset('trace', data=trace)
        hf.create_dataset('tx', data=tx)
        hf.create_dataset('dist', data=dist)
        

        dt = h5py.special_dtype(vlen=str)
        ds_time = hf.create_dataset('file_begin_time_utc', (1,), dtype=dt)
        ds_time[0] = str(file_begin_time_utc)

    print(f"\nFile saved successfully: {output_file}")