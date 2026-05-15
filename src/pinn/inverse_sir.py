import torch
import torch.nn as nn
from data_loader import *

class PINN(nn.Module):
    def __init__(self):
        super().__init__()
        self.n = nn.Sequential(
            nn.Linear(1,32), 
            nn.Tanh(), 
            nn.Linear(32, 32), 
            nn.Tanh(), 
            nn.Linear(32, 3), 
            nn.Softmax(1))
        self.b = nn.Parameter(torch.tensor([0.5]))
        self.g = nn.Parameter(torch.tensor([0.5]))

    def forward(self, x):
        y = self.n(x)
        return y[:,0:1], y[:,1:2], y[:,2:3]

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

d = load_latest_run_data()
x = d[0].to(device)
y1 = d[1].to(device)
y2 = d[2].to(device)
y3 = d[3].to(device)

t = len(x)
model = PINN().to(device)
optimizer = torch.optim.Adam(model.parameters())

for i in range(10000):
    optimizer.zero_grad()
    x.requires_grad = True
    
    p1, p2, p3 = model(x)
    
    l1 = nn.MSELoss()(p2, y2) + nn.MSELoss()(p3, y3)

    d1 = torch.autograd.grad(p1, x, torch.ones_like(p1), True)[0]
    d2 = torch.autograd.grad(p2, x, torch.ones_like(p2), True)[0]
    d3 = torch.autograd.grad(p3, x, torch.ones_like(p3), True)[0]
    
    r1 = d1 - (-t * model.b * p1 * p2)
    r2 = d2 - (t * model.b * p1 * p2 - t * model.g * p2)
    r3 = d3 - (t * model.g * p2)
    
    l2 = torch.mean(r1**2) + torch.mean(r2**2) + torch.mean(r3**2)
    
    L = l1 + (1e-6 * l2)

    L.backward()
    optimizer.step()
    
    if i % 1000 == 0:
        print(f"Epoch: {i} | Loss: {L.item()}")

print("Done")
print(f"Beta: {model.b.item()}")
print(f"Gamma: {model.g.item()}")