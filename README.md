# OD Data Portugal Census 2021

Origin–Destination (OD) dataset derived from Portugal’s **Census 2021**, focusing on commuting flows for work and education.  

**Indicator name:**
Commuting (Interactions in the territorial unit - No.) of the employed or student resident population by Place of residence at Census date [2021] or destination (NUTS 2024 - Município) and Place of destination or residence at Census date [2021] (NUTS 2024 - Município); [see description](https://www.ine.pt/bddXplorer/htdocs/minfo.jsp?var_cd=0012340&lingua=EN).

This indicator measures the total number of commuting interactions between two territorial units, involving the resident employed or student population.
The flows represent bidirectional commuting movements between a pair of municipalities.

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
