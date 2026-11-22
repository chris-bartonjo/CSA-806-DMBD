# K-Means vs DBSCAN on Kenyan sub-county demographics

Two clustering algorithms are compared on 333 Kenyan sub-counties using the 2019 Kenya Population and Housing Census.

## Data

The census tables come from the [rKenyaCensus](https://github.com/Shelmith-Kariuki/rKenyaCensus) repository (MIT licence), which packages the KNBS 2019 census reports. The notebook downloads the eight tables it needs (about 340 KB) into `data/` on first run.

Eight indicators are built for each sub-county:

- population density (log scale);
- average household size;
- share of people under 15;
- share of households lit by mains electricity;
- share of households with piped water;
- share of households cooking with firewood;
- share of people using the internet;
- share of people owning a mobile phone.

Eleven forest and national park units with fewer than 1,000 households are removed.

## Results

| | K-Means (k = 3) | DBSCAN (eps = 1.4, min_samples = 12) |
|---|---|---|
| Clusters | 3 (84, 175, 74) | 2 (289, 18) + 26 noise |
| Silhouette | 0.384 | 0.518 on clustered points, 0.364 with noise as a group |
| Davies–Bouldin | 0.925 | 0.516 on clustered points |
| Calinski–Harabasz | 318 | 123 |
| Stability (mean ARI, 50 × 90% subsamples) | 0.979 | 0.932 |
| Runtime (median of 50 fits) | about 8 ms (20 restarts) | under 1 ms |

The two results agree poorly (ARI 0.15):

- **K-Means** splits Kenya into urban and peri-urban, rural farming, and remote and underserved sub-counties. The remote group is mostly in the arid north and north-east.
- **DBSCAN** sees one connected spread. It separates a dense cluster of Nairobi, Kiambu, Nakuru and Kisumu suburbs, and flags unusual places as noise, such as all six Mombasa sub-counties, Westlands and Mathare.

![Clusters on the first two principal components](figures/clusters_pca.png)

![K-Means cluster profiles](figures/kmeans_profiles.png)

## Run it

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
jupyter nbconvert --to notebook --execute kenya_clustering.ipynb   # or open it in VS Code / Jupyter
```
