import pandas as pd

def open_xlsx(path):
    print(f"Reading Excel file {path}")
    transactions = []
    df = pd.read_excel(path)

    for _, row in df.iterrows():
        values = []
        for value in row:
            if pd.notna(value) and value != "":
                values.append(str(value))
        if values:
            transactions.append(values)

    return transactions

def create_client_items_dict(transactions):
    client_items = {}
    current_client_id = 1
    last_number = None

    for transaction in transactions:
        number = transaction[0]
        item = transaction[1]

        if last_number is not None and number != last_number:
            current_client_id += 1

        unique_client = str(current_client_id)
        if unique_client not in client_items:
            client_items[unique_client] = []

        if item not in client_items[unique_client]:
            client_items[unique_client].append(item)

        last_number = number

    return client_items

def create_transaction_file(transaction_list, file_path="transactions.txt"):
    # Write transactions in the format expected by apriori
    with open(file_path, 'w') as f:
        for transaction in transaction_list:
            f.write(' '.join(transaction) + '\n')
    print(f"Transactions written to {file_path}")
    return file_path

def main():
    tshekid_path = "data/tshekid_office2003.xlsx"  # update with your actual file path
    transactions = open_xlsx(tshekid_path)
    client_items = create_client_items_dict(transactions)
    transaction_list = list(client_items.values())
    create_transaction_file(transaction_list)

if __name__ == "__main__":
    main()
