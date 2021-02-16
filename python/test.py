import numpy as np

def _make_a_mat_t(n : int, dx : float) -> np.array:
    smat = np.ones((n+1,n))
    
    cmat = np.zeros((n,n))
    li = np.tril_indices(n)
    cmat[li] = 1.0

    dmat = np.diag(np.full(n,0.5))
    print(cmat)
    print(dmat)

    vec = np.array([np.full(n,0.5)])
    combmat = np.concatenate((vec, cmat - dmat))

    return (smat - combmat) * dx

print(_make_a_mat_t(5,1))