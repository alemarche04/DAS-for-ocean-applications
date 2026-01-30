import data_handle
import numpy as np
import h5py

data = data_handle.get_acquisition_parameters("095659.hdf5", "asn")
# fs: the sampling frequency (Hz)\n
# dx: interval between two virtual sensing points also called channel spacing (m)\n
# nx: the number of spatial samples also called channels\n
# ns: the number of time samples\n
# GL: the gauge length (m)\n
# scale_factor: the value to convert DAS data from strain rate to strain
print(data.keys())
for name in data.keys():
    item = data[name]
    print(f"Dataset: {name} | Forma: {item.shape} | Tipo: {item.dtype}")
    if item.size < 3: 
        print(f"  Valore: {item[()]}")

channels = [0, 1200, 1]
[trace, tx, dist, file_begin_time_utc] = data_handle.load_das_data("095659.hdf5", channels, data, "asn")
#print(trace)
#print(tx)
#print(dist)
print(trace.shape)
print(tx.shape)
print(dist.shape)
print(file_begin_time_utc)


output_filename = "das_norway.hdf5"

with h5py.File(output_filename, 'w') as hf:

    meta_group = hf.create_group('metadata')
    for key, value in data.items():
        meta_group.create_dataset(key, data=value)
    
    hf.create_dataset('trace', data=trace)
    hf.create_dataset('tx', data=tx)
    hf.create_dataset('dist', data=dist)
    

    dt = h5py.special_dtype(vlen=str)
    ds_time = hf.create_dataset('file_begin_time_utc', (1,), dtype=dt)
    ds_time[0] = str(file_begin_time_utc)

print(f"Salvataggio completato in {output_filename}")