import pandas as pd
from pathlib import Path
import torch


def load_latest_run_data():
    run_path = Path(__file__).parents[2] / "run"    

    newest_file = max(run_path.iterdir(), key=lambda f: f.stat().st_birthtime if f.is_file() and f.name[-3:] == "txt" else 0)
    run = pd.read_csv(newest_file)

    inputs = newest_file.name.split(sep="_")

    runf = run/int(inputs[2])
    runf["sus"] = 1 - runf.inf - runf.imm
    runf["t"] = runf.index/max(runf.index)

    t_tensor = torch.tensor(runf.t, dtype=torch.float).view(-1, 1)
    S_tensor = torch.tensor(runf.sus, dtype=torch.float).view(-1, 1)
    I_tensor = torch.tensor(runf.inf, dtype=torch.float).view(-1, 1)
    R_tensor = torch.tensor(runf.imm, dtype=torch.float).view(-1, 1)

    return t_tensor, S_tensor, I_tensor, R_tensor
