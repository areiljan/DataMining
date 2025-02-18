import pandas as pd

df = pd.read_csv('MARKETING_SEGMENTATION_SIMPLE.CSV')

df['Age (Years)'] = df['Age (Years)'].str.replace(' years', '').astype(float)
df['Length of Residence (Months)'] = df['Length of Residence (Months)'].str.replace(' months', '').astype(float)
df['Average Revenues ($)'] = df['Average Revenues ($)'].str.replace('$', '').astype(float)
df['Income ($000)'] = df['Income ($000)'].str.replace('$', '').astype(float)
df['Percent Male'] = df['Percent Male'].str.replace('%', '').astype(float)

# normalize columns
columns = ['Average Revenues ($)', 'Risk Score', 'Age (Years)', 'Length of Residence (Months)', 'Number of Children', 'Income ($000)', 'Percent Male']
for col in columns:
    min_value = df[col].min()
    max_value = df[col].max()
    df[col] = (df[col] - min_value) / (max_value - min_value)

df2 = df.drop(columns=["Segment Name"])

num_rows = len(df2)

distance_matrix = [[0.0 for _ in range(num_rows)] for _ in range(num_rows)]

for i in range(num_rows):
    for j in range(num_rows):
        if i != j:
            # euclidean distance formula
            distance = sum(
                (df2.iloc[i, k] - df2.iloc[j, k]) ** 2
                for k in range(df2.shape[1])
                ) ** 0.5
            distance_matrix[i][j] = distance

distance_df = pd.DataFrame(distance_matrix, index=df["Segment Name"], columns=df["Segment Name"])
distance_df.index.name = None

print(distance_df.to_string())

# what is the number of unique pairwise combination of segments
# one category has (4 2) = 6 ways to pair


