import click
import pandas as pd
import os

@click.command()
@click.option('--directory', '-d', required=True, help='Path to the directory containing TSV files.')
@click.option('--output', '-o', required=True, help='Path to the output merged TSV file.')
@click.option('--sep', '-s', default='\t', help='Delimiter used in the TSV files.')
@click.option('--extension', '-e', default='tsv', help='Extension of the TSV files.')
def merge_tsv_files(directory, output, sep="\t", extension='tsv'):
    """
    Merge TSV files in a directory into a single TSV file.

    Args:
        directory (str): Path to the directory containing TSV files.
        output (str): Path to the output merged TSV file.
        sep (str, optional): Delimiter used in the TSV files. Defaults to '\t'.
        extension (str, optional): Extension of the TSV files. Defaults to 'tsv'.

    Returns:
        None
    """
    tsv_files = [os.path.join(directory, file) for file in os.listdir(directory) if file.endswith("." + extension)]

    dfs = [pd.read_csv(file, sep=sep) for file in tsv_files]
    merged_df = pd.concat(dfs, ignore_index=True)

    # Write the merged DataFrame to a new TSV file
    merged_df.to_csv(output, sep='\t', index=False)

if __name__ == '__main__':
    merge_tsv_files()