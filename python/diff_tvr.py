import numpy as np
from scipy.linalg import solve

from typing import Tuple

class DiffTVR:

    def __init__(self, n: int, dx: float):
        self.n = n
        self.dx = dx

        self.d_mat = self._make_d_mat()
        self.a_mat = self._make_a_mat()
        self.a_mat_t = self._make_a_mat_t()

    def _make_d_mat(self) -> np.array:
        arr = np.zeros((self.n,self.n+1))
        for i in range(0,self.n):
            arr[i,i] = -1.0
            arr[i,i+1] = 1.0
        return arr / self.dx

    # TODO: improve these matrix constructors
    def _make_a_mat(self) -> np.array:
        arr = np.zeros((self.n+1,self.n+1))
        for i in range(0,self.n+1):
            if i==0:
                continue
            for j in range(0,self.n+1):
                if j==0:
                    arr[i,j] = 0.5
                elif j<i:
                    arr[i,j] = 1.0
                elif i==j:
                    arr[i,j] = 0.5
        
        return arr[1:] * self.dx

    def _make_a_mat_t(self) -> np.array:
        smat = np.ones((self.n+1,self.n))
        
        cmat = np.zeros((self.n,self.n))
        li = np.tril_indices(self.n)
        cmat[li] = 1.0

        dmat = np.diag(np.full(self.n,0.5))

        vec = np.array([np.full(self.n,0.5)])
        combmat = np.concatenate((vec, cmat - dmat))

        return (smat - combmat) * self.dx

    def make_en_mat(self, deriv_curr : np.array) -> np.array:
        eps = pow(10,-6)
        vec = 1.0/np.sqrt(pow(self.d_mat @ deriv_curr,2) + eps)
        return np.diag(vec)

    def make_ln_mat(self, en_mat : np.array) -> np.array:
        return self.dx * np.transpose(self.d_mat) @ en_mat @ self.d_mat

    def make_gn_vec(self, deriv_curr : np.array, data : np.array, alpha : float, ln_mat : np.array) -> np.array:
        return self.a_mat_t @ self.a_mat @ deriv_curr - self.a_mat_t @ (data - data[0]) + alpha * ln_mat @ deriv_curr
    
    def make_hn_mat(self, alpha : float, ln_mat : np.array) -> np.array:
        return self.a_mat_t @ self.a_mat + alpha * ln_mat
    
    def get_deriv_tvr_update(self, data : np.array, deriv_curr : np.array, alpha : float) -> np.array:
        n = len(data)
    
        en_mat = self.make_en_mat(
            deriv_curr=deriv_curr
            )

        ln_mat = self.make_ln_mat(
            en_mat=en_mat
            )

        hn_mat = self.make_hn_mat(
            alpha=alpha,
            ln_mat=ln_mat
            )

        gn_vec = self.make_gn_vec(
            deriv_curr=deriv_curr,
            data=data,
            alpha=alpha,
            ln_mat=ln_mat
            )

        return solve(hn_mat, gn_vec)

    def get_deriv_tvr(self, 
        data : np.array, 
        deriv_guess : np.array, 
        alpha : float,
        no_opt_steps : int,
        return_progress : bool = False, 
        return_interval : int = 1
        ) -> Tuple[np.array,np.array]:

        deriv_curr = deriv_guess

        if return_progress:
            deriv_st = np.full((no_opt_steps+1, len(deriv_guess)), 0)
        else:
            deriv_st = np.array([])

        for opt_step in range(0,no_opt_steps):
            update = self.get_deriv_tvr_update(
                data=data,
                deriv_curr=deriv_curr,
                alpha=alpha
                )

            deriv_curr += update

            if return_progress:
                if opt_step % return_interval == 0:
                    deriv_st[int(opt_step / return_interval)] = deriv_curr

        return (deriv_curr, deriv_st)