# OD_Data_Portugal_Census_2021

Origin–Destination (OD) dataset derived from Portugal’s **Census 2021**, focusing on commuting flows for work and education.  
This repository provides cleaned datasets, scripts, and analytical examples to support research, urban planning, and mobility analysis.

## 📚 Data Sources

The data originates from the **Instituto Nacional de Estatística (INE), Portugal**:

- **Census 2021 – Origin–Destination Mobility Data**  
  Mobility of residents between their place of residence and place of work/study.
  Available at municipality levels.
  Extract raw data at [INE Census 2021 Mobility Dataset](https://www.ine.pt/xportal/xmain?xpid=INE&xpgid=ine_indicadores&indOcorrCod=0012340&contexto=bd&selTab=tab2).

- **INE Administrative Geographic Codes (CAOP)**  
  Official identifiers used to link flows to geographic entities.

> All datasets are public statistical outputs.  
> Users must follow INE usage, citation, and redistribution conditions.

---

## 🧠 Dataset Concepts

- **Origin (O):** Place of usual residence.  
- **Destination (D):** Place of work or educational institution.  
- **Flow:** Number of individuals moving from origin to destination.

Supports creation of:
- OD matrices
- Commuting graphs
- Spatial interaction models
- GIS visualizations
