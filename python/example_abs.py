import numpy as np
from diff_tvr import *

if __name__ == "__main__":

    dx = 0.01
    
    data = []
    for x in np.arange(0,1,dx):
        data.append(abs(x-0.5))
    data = np.array(data)
    
    n = len(data)

    data_noisy = data + np.random.normal(0,0.05,n)
    
    diff_tvr = DiffTVR(n,dx)

    deriv = diff_tvr.get_deriv_tvr(
        data=data, 
        deriv_guess=np.full(n+1,0.0), 
        alpha=0.2,
        no_opt_steps=100
        )