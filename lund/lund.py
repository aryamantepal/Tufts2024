import numpy as np
from scipy.spatial.distance import pdist, squareform

'''The key part of LUND is:
1.). Build a graph.
2.). Compute diffusion distances on the graph and a kernel density estimator.
3.). Label using the LUND scheme.'''

def LearningbyUnsupervisedNonlinearDiffusion(X, t, G, p, K_known=None):
    
    n = len(X)
    C = np.zeros(n, dtype=int)

    # Calculate diffusion map
    DiffusionMap = np.zeros_like(G['EigenVecs'])
    #iterating over columns?? i think matlab is indexed from 1
    for l in range(DiffusionMap.shape[1]):
        DiffusionMap[:, l] = G['EigenVecs'][:, l] * (G['EigenVals'][l] ** t)

    # Calculate pairwise diffusion distance at time t between points in X
    DiffusionDistance = squareform(pdist(np.real(DiffusionMap)))

    # compute rho_t(x), stored as rt
    rt = np.zeros(n)
    for i in range(n):
        if p[i] != np.max(p):
            rt[i] = np.min(DiffusionDistance[p > p[i], i])
        else:
            rt[i] = np.max(DiffusionDistance[i, :])

    # Extract Dt(x) and sort in descending order
    #ignore . element wise operations handled in python.
    Dt = np.multiply(rt, p)
    m_sorting = np.argsort(-Dt) #sorting in descending order technically bc negative versions

    # Determine K based on the ratio of sorted Dt(x_{m_k})
    if K_known is not None: #nargin dne in python.
        K = K_known
    else:
        ratios = Dt[m_sorting[:n-2]] / Dt[m_sorting[1:n-1]]
        K = np.argmax(ratios)

    if K == 1:
        C = np.ones(n, dtype=int)
    else:
        # Label modes
        C[m_sorting[:K-1]] = np.arange(0, K - 1)

        # Label non-modal points according to the label of their Dt-nearest
        # neighbor of higher density that is already labeled.
        l_sorting = np.argsort(-p)
        for j in range(n):
            i = l_sorting[j]
            if C[i] == 0:  # unlabeled point
                candidates = np.where((p >= p[i]) & (C > 0))[0]
                temp_idx = np.argmin(DiffusionDistance[i, candidates])
                C[i] = C[candidates[temp_idx]]

    return C, K, Dt