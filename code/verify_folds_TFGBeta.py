"""Independent AMEX numerical check for the reduced TFGBeta ODE.
Solves the full positive-equilibrium fold conditions for the ODE system in the manuscript.
At equilibrium, T=sigma/(mu+gamma*phi/(1+phi)) and lambda_1=(delta1*X+delta2*T)/phi.
Fold points are detected by det(J)=0 along the positive equilibrium branch.
"""
from __future__ import annotations
import numpy as np
from scipy.optimize import root, brentq
from scipy.linalg import eigvals

# Baseline nondimensional parameters from Table 1 in the manuscript.
r = 0.5
K = 1.0
alpha = 0.9
g1 = 0.15
sigma = 0.10
mu = 0.15
beta = 0.30
gamma = 2.0
delta1 = 0.40
delta2 = 0.03


def T_of_phi(phi: float) -> float:
    return sigma / (mu + gamma * phi / (1.0 + phi))


def lambda_of(X: float, phi: float) -> float:
    return (delta1 * X + delta2 * T_of_phi(phi)) / phi


def F1_X_phi(X: float, phi: float) -> float:
    T = T_of_phi(phi)
    return r * (1.0 - X / K) - alpha * X * T / (g1 * g1 + X * X) + beta * phi / (1.0 + phi)


def jacobian(X: float, T: float, phi: float, lam: float) -> np.ndarray:
    # d/dX of -alpha*X^2*T/(g1^2+X^2)
    dkill_dX = alpha * T * (2.0 * X * g1 * g1) / (g1 * g1 + X * X) ** 2
    return np.array([
        [r * (1.0 - 2.0 * X / K) - dkill_dX + beta * phi / (1.0 + phi),
         -alpha * X * X / (g1 * g1 + X * X),
         beta * X / (1.0 + phi) ** 2],
        [0.0,
         -mu - gamma * phi / (1.0 + phi),
         -gamma * T / (1.0 + phi) ** 2],
        [delta1, delta2, -lam],
    ])


def fold_equations(z: np.ndarray) -> np.ndarray:
    X, phi = z
    if X <= 0 or phi <= 0:
        return np.array([1e3 + min(X, phi), 1e3 + min(X, phi)])
    T = T_of_phi(phi)
    lam = lambda_of(X, phi)
    return np.array([F1_X_phi(X, phi), np.linalg.det(jacobian(X, T, phi, lam))])

folds: list[tuple[float, float, float, float]] = []
for guess_X in np.linspace(0.005, 1.5, 15):
    for guess_phi in np.logspace(-3, 1, 12):
        sol = root(fold_equations, [guess_X, guess_phi])
        if not sol.success:
            continue
        X, phi = sol.x
        if X <= 0 or phi <= 0:
            continue
        residual = np.linalg.norm(fold_equations([X, phi]), ord=np.inf)
        T = T_of_phi(phi)
        lam = lambda_of(X, phi)
        if residual < 1e-7 and lam > 0 and not any(abs(lam - item[-1]) < 1e-5 for item in folds):
            folds.append((X, T, phi, lam))

print("folds")
for X, T, phi, lam in sorted(folds, key=lambda x: x[-1]):
    ev = eigvals(jacobian(X, T, phi, lam))
    ev_str = [(float(z.real), float(z.imag)) for z in ev]
    print(f"lambda={lam:.10f}, X={X:.10f}, T={T:.10f}, phi={phi:.10f}, eig={ev_str}")

# Messenger-free positive equilibrium: phi=0, T=sigma/mu.
T0 = sigma / mu

def g(X: float) -> float:
    return r * (1.0 - X / K) - alpha * X * T0 / (g1 * g1 + X * X)

roots: list[float] = []
xs = np.linspace(1e-8, 2.0, 10000)
prev, pv = xs[0], g(xs[0])
for x in xs[1:]:
    v = g(x)
    if pv * v < 0:
        rt = brentq(g, prev, x)
        if not roots or abs(rt - roots[-1]) > 1e-6:
            roots.append(rt)
    prev, pv = x, v
print(f"messenger_free_roots={roots}, T={T0:.10f}")
