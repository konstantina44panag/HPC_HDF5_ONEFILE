#!/usr/bin/env python3.11
import pandas as pd
import argparse
import sys
import h5py

def append_data_to_hdf5(hdf5_path, group_name, type_name, csv_input, chunksize=1000000):
    reader = pd.read_csv(csv_input, chunksize=chunksize, low_memory=False, index_col=False, dtype=str)
    unique_keys = set()
    column_names = None
    with pd.HDFStore(hdf5_path, mode='a', complevel=9, complib='zlib') as store:
        for chunk in reader:
            if column_names is None:
                column_names = chunk.columns.tolist()
            if type_name == 'complete_nbbo':
                index_position = 2
            if type_name == 'ctm':
                index_position = 3
            if type_name == 'mastm':
                index_position = 1
            for unique_key, group_df in chunk.groupby(chunk.columns[index_position]):
                hdf5_key = f'{unique_key}/{group_name}/{type_name}'
                min_itemsize = {col: 30 for col in group_df.columns}
                store.append(hdf5_key, group_df, format='table', data_columns=True, index=False, min_itemsize=min_itemsize)
                unique_keys.add(hdf5_key)

    with h5py.File(hdf5_path, 'a') as hdf_file:
        for hdf5_key in unique_keys:
            if hdf5_key in hdf_file:
                dset = hdf_file[hdf5_key]
                dset.attrs['column_names'] = column_names


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Append CSV data to an HDF5 file, organized by unique values in the fourth column.")
    parser.add_argument("hdf5_path", help="Path to the HDF5 file.")
    parser.add_argument("group_name", help="Name of the group under which data should be stored.")
    parser.add_argument("type_name", help="Type of the data (e.g., ctm, mastm..).")
    parser.add_argument("csv_path", nargs='?', default=sys.stdin, help="Path to the input CSV file or '-' for stdin.")
    args = parser.parse_args()

    if args.csv_path is sys.stdin or args.csv_path == '-':
        if sys.stdin.isatty():
            print("Error: No data piped to script and no CSV file path provided.", file=sys.stderr)
            sys.exit(1)
        else:
            append_data_to_hdf5(args.hdf5_path, args.group_name, args.type_name, sys.stdin)
    else:
        append_data_to_hdf5(args.hdf5_path, args.group_name, args.type_name, args.csv_path)
