import chardet

base_dir = "./EF_input_250205/"
ef_file = base_dir + "EFv250925.csv"
with open(ef_file, "rb") as f:
    raw = f.read(200000)  # 读取部分内容
result = chardet.detect(raw)
print(result)

