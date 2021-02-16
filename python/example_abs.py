from Users.oernst.software_public.tvr_differentiate.python.diff_tvr import DiffTVR
import numpy as np
import matplotlib.pyplot as plt

from diff_tvr import *

if __name__ == "__main__":

    # Data
    dx = 0.01
    
    data = []
    for x in np.arange(0,1,dx):
        data.append(abs(x-0.5))
    data = np.array(data)

    # True derivative
    deriv_true = []
    for x in np.arange(0,1,dx):
        if x < 0.5:
            deriv_true.append(-1)
        else:
            deriv_true.append(1)
    deriv_true = np.array(deriv_true)

    # Add noise
    n = len(data)
    data_noisy = data + np.random.normal(0,0.05,n)
    
    # Plot true and noisy signal
    fig1 = plt.figure()
    plt.plot(data)
    plt.plot(data_noisy)
    plt.title("Signal")
    plt.legend(["True","Noisy"])

    # Derivative with TVR
    diff_tvr = DiffTVR(n,dx)
    (deriv,_) = diff_tvr.get_deriv_tvr(
        data=data, 
        deriv_guess=np.full(n+1,0.0), 
        alpha=0.2,
        no_opt_steps=100
        )

    # Plot TVR derivative
    fig2 = plt.figure()
    plt.plot(deriv_true)
    plt.plot(deriv)
    plt.title("Derivative")
    plt.legend(["True","TVR"])

    fig1.savefig('signal.png')
    fig2.savefig('derivative.png')

    plt.show()