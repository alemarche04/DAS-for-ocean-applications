import h5py
with h5py.File('095659.hdf5', 'r') as f:
   
   for key in f.keys():
      print(key)

   group = f['versions']

   if isinstance(group, h5py.Group):
      print(group)
      print(list(group.keys()))

      for name in group.keys():
         item = group[name]
         if isinstance(item, h5py.Dataset):
            print(f"Dataset: {name} | Forma: {item.shape} | Tipo: {item.dtype}")
            # .shape[0] ci dice quanto è lungo. Se è piccolo lo stampiamo.
            if item.size < 3: 
               print(f"  Valore: {item[()]}")
         else:
            print(f"Sottogruppo: {name}")

   elif isinstance(group, h5py.Dataset):
      print(f"Forma: {group.shape}")
      if group.size < 3: 
               print(f"  Valore: {group[()]}")